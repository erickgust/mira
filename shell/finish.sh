#!/bin/sh
recording=$1
dir=$2
shift 2
trap 'rm -f "$recording"' EXIT

packets=$(ffprobe -v error -select_streams v -count_packets -show_entries stream=nb_read_packets -of csv=p=0 "$recording" 2>/dev/null)
if ! [ "${packets:-0}" -gt 0 ] 2>/dev/null; then
    echo "the recording is empty" >&2
    exit 1
fi
sh "$(dirname "$0")/claim.sh" "$recording" "$dir" "$@"
