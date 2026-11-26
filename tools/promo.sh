#!/usr/bin/env bash
# Renders the MakerWorld listing images into makerworld/images/.
# 4:3 is the web cover ratio and 3:4 the app cover ratio.
#
#   tools/promo.sh
#
# Requires: openscad (manifold backend, which honours color()) and magick.
set -euo pipefail

OPENSCAD="${OPENSCAD:-openscad}"
FONT="${FONT:-/System/Library/Fonts/Supplemental/Arial Bold.ttf}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCENE="$ROOT/tools/promo_scene.scad"
OUT="$ROOT/makerworld/images"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$OUT"

# render <file> <width,height> <view> <camera>
render() {
  "$OPENSCAD" -o "$1" --backend=manifold --render=true "--imgsize=$2" \
    --colorscheme=Tomorrow --projection=p "--camera=$4" --viewall --autocenter \
    -D "view=\"$3\"" "$SCENE" >/dev/null 2>&1
  # a blank render fails silently; a standard deviation near 0 gives it away
  local sd
  sd="$(magick identify -format "%[standard-deviation]" "$1")"
  if awk -v v="$sd" 'BEGIN{exit !(v<100)}'; then
    echo "render is practically empty: $1" >&2
    exit 1
  fi
}

render "$OUT/cover_4x3.png" 1600,1200 set 0,0,0,62,0,20,0
# --viewall crops the parts in portrait renders, so the 3:4 cover is built from
# the 4:3 one: trim the background and center it on a 1200x1600 canvas.
BG="$(magick "$OUT/cover_4x3.png" -format "%[pixel:p{0,0}]" info:)"
magick "$OUT/cover_4x3.png" -trim +repage -resize 1120x1520 \
  -background "$BG" -gravity center -extent 1200x1600 "$OUT/cover_3x4.png"
render "$TMP/side.png"      1200,900  side 0,0,0,62,0,28,0
render "$TMP/center.png"    1200,900  center 0,0,0,62,0,28,0

FONT_ARGS=()
[ -f "$FONT" ] && FONT_ARGS=(-font "$FONT")
magick montage -background white -fill "#222222" -pointsize 52 "${FONT_ARGS[@]}" \
  -label "Side piece" "$TMP/side.png" -label "Center piece" "$TMP/center.png" \
  -tile 2x1 -geometry +12+12 "$OUT/pieces.png"

for f in "$OUT"/*.png; do
  magick identify -format "%f %wx%h\n" "$f"
done
