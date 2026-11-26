// Scene used only by the MakerWorld listing images (see tools/promo.sh).
use <../drawer_front_spacer.scad>

view = "set"; // set | side | center

module piece(type) color("#e8a33d") spacer(type);

// Center piece behind, side pieces in front, so every labelled wall is visible.
if (view == "set") {
    translate([-30, -22, 0]) piece("side");
    translate([ 30, -22, 0]) piece("side");
    translate([  0,  30, 0]) piece("center");
} else {
    piece(view);
}
