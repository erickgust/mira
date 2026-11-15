#!/bin/sh
frame=$1
dir=$2
geometry=$3
shift 3
crop="$dir/.mira-$$-crop.png"
trap 'rm -f "$frame" "$crop"' EXIT

mkdir -p "$dir" || exit 1
magick "$frame" -crop "$geometry" +repage "$crop" || exit 1
sh "$(dirname "$0")/claim.sh" "$crop" "$dir" "$@"
