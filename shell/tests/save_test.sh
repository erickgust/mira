#!/bin/sh
set -eu
save="$(dirname "$0")/../save.sh"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
dir="$work/Screenshots"

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

shot() {
    magick -size 8x6 xc:red "$work/frame.png"
    sh "$save" "$work/frame.png" "$dir" "4x3+2+1" "a.png" "a (1).png" "a (2).png"
}

first=$(shot)
second=$(shot)
[ "$first" = "$dir/a.png" ] || fail "first shot saved as $first"
[ "$second" = "$dir/a (1).png" ] || fail "second shot saved as $second"
[ "$(magick identify -format '%wx%h' "$first")" = "4x3" ] || fail "crop has the wrong size"
[ ! -e "$work/frame.png" ] || fail "frame was left behind"
[ -z "$(find "$dir" -name '.mira-*')" ] || fail "temporary crop was left behind"

shot >/dev/null
if shot >/dev/null 2>&1; then fail "saved with every name taken"; fi
[ "$(find "$dir" -type f | wc -l)" -eq 3 ] || fail "a file was overwritten or added"

echo "save.sh: all checks passed"
