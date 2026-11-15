#!/bin/sh
source=$1
dir=$2
shift 2
for name; do
    if ln "$source" "$dir/$name" 2>/dev/null; then
        printf '%s\n' "$dir/$name"
        exit 0
    fi
done
echo "no free file name in $dir" >&2
exit 1
