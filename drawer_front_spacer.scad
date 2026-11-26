// Drawer Front Spacer (side and center pieces)
// Keeps an even gap between stacked drawer fronts during installation.
// Both pieces are engraved on both walls. The side piece works on either side:
// rotate it around its vertical (in use) axis.
// All dimensions in mm.

/* [Main] */
// Which part to generate
part = "all"; // [all:Full set - 2 side + 1 center, side:Side piece, center:Center piece]
// Nominal board thickness
board_thickness = 18; // [3:0.1:40]
// Gap between drawer fronts (thickness of the middle divider)
front_gap = 4; // [1:0.1:20]

/* [Advanced] */
// Total clearance added to the board thickness (channel = board + clearance)
clearance = 0.30; // [0:0.05:2]
// Length of each arm, measured from the divider
arm_length = 20; // [8:0.5:80]
// Height of the side piece, including the base
side_height = 20; // [8:0.5:80]
// Height of the center piece
center_height = 40; // [8:0.5:150]
// Thickness of each wall
wall_thickness = 3.65; // [1.6:0.05:10]
// Base thickness (the center piece has no base)
base_thickness = 3; // [0.8:0.1:10]

/* [Hidden] */
// Fixed values (not shown in the Customizer)
part_spacing = 20; // distance between parts when generating the full set
text_depth = 1.2;
letter_height = 4;
text_font = "Liberation Sans:style=Bold"; // bold sans-serif: easy to print and read
text_margin = 1; // minimum distance from the text to the top/bottom edges
$fn = 48;
eps = 0.01;

channel_width = board_thickness + clearance;
width         = channel_width + 2 * wall_thickness;
length        = 2 * arm_length + front_gap;

assert(channel_width > 0, "The channel width must be greater than zero");
assert(side_height > base_thickness,
       "side_height must be greater than base_thickness");
assert(wall_thickness > text_depth,
       "The engraving would cut through the wall: increase wall_thickness");

echo(str("Channel width: ", channel_width, " mm"));
echo(str("Side piece: ", length, " x ", width, " x ", side_height, " mm"));
echo(str("Center piece: ", length, " x ", width, " x ", center_height, " mm"));

// ---------- Body ----------

// H profile (seen from above). Centered on the origin, bottom face at Z = 0.
// With base: the H sits on a closed floor (side piece).
// Without base: the channels run through the full height (center piece).
module body(has_base, h) {
    floor_z = has_base ? base_thickness : -eps;

    difference() {
        translate([-length / 2, -width / 2, 0])
            cube([length, width, h]);

        // one pocket on each side of the divider
        for (s = [-1, 1])
            translate([s * (front_gap + arm_length + eps) / 2,
                       0,
                       (h + eps + floor_z) / 2])
                cube([arm_length + eps,
                      channel_width,
                      h + eps - floor_z], center = true);
    }
}

// ---------- Text ----------

// Approximate width of each character, as a multiple of the letter height
// (only used to know when a label has to shrink)
function char_width(c) =
    c == "M" ? 1.22 :
    c == " " || c == "." || c == "," ? 0.41 :
    0.81;

function label_width(t, i = 0) =
    i >= len(t) ? 0 : char_width(t[i]) + label_width(t, i + 1);

// Centered label, read from top to bottom.
// Shrinks proportionally if it does not fit the piece height.
module label(t, h) {
    k = min(1, (h - 2 * text_margin) / (label_width(t) * letter_height));
    // 0.955 = ratio between capital letter height and the text() "size"
    rotate(-90)
        text(t, size = k * letter_height / 0.955, font = text_font,
             halign = "center", valign = "center");
}

// 2D text on the front face: X = piece length, Y = height (centered).
module labels_2d(h) {
    // The two labels form a group centered on the piece, with the same
    // space between them and up to each end.
    space = (length - 2 * letter_height) / 3;
    offset_x = (space + letter_height) / 2; // from piece center to each label

    translate([offset_x, 0])
        label(str(board_thickness, " MM"), h);

    translate([-offset_x, 0])
        label(str(front_gap, "MM"), h);
}

// Volume to subtract from the front wall (-Y).
module engraving(h) {
    translate([0, -width / 2 + text_depth, h / 2])
        rotate([90, 0, 0])
            linear_extrude(text_depth + eps)
                labels_2d(h);
}

// ---------- Assembly ----------

module spacer(type) {
    is_center = type == "center";
    h = is_center ? center_height : side_height;

    difference() {
        body(has_base = !is_center, h = h);
        engraving(h);

        // Same engraving on the back wall, rotated around the X axis
        // (vertical in use) so it reads upright from both sides.
        translate([0, 0, h]) rotate([180, 0, 0]) engraving(h);
    }
}

parts = part == "all" ? ["side", "center", "side"] : [part];

// parts lined up along Y, centered on the origin
for (i = [0 : len(parts) - 1])
    translate([0, (i - (len(parts) - 1) / 2) * (width + part_spacing), 0])
        spacer(parts[i]);
