#!/bin/sh
frame=$1
dir=$2
geometry=$3
shift 3
crop="$dir/.mira-$$-crop.png"
trap 'rm -f "$frame" "$crop"' EXIT

mkdir -p "$dir" || exit 1
magick "$frame" -crop "$geometry" +repage "$crop" || exit 1
for name; do
    if ln "$crop" "$dir/$name" 2>/dev/null; then
        printf '%s\n' "$dir/$name"
        exit 0
    fi
done
echo "no free file name in $dir" >&2
exit 1
