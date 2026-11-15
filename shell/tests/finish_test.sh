#!/bin/sh
set -eu
finish="$(dirname "$0")/../finish.sh"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
dir="$work/Screencasts"
mkdir -p "$dir"

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

record() {
    ffmpeg -v error -y -f lavfi -i testsrc=size=64x48:rate=10 -t 1 "$dir/.mira-test-recording.mp4"
    sh "$finish" "$dir/.mira-test-recording.mp4" "$dir" "a.mp4" "a (1).mp4"
}

first=$(record)
second=$(record)
[ "$first" = "$dir/a.mp4" ] || fail "first recording saved as $first"
[ "$second" = "$dir/a (1).mp4" ] || fail "second recording saved as $second"
[ ! -e "$dir/.mira-test-recording.mp4" ] || fail "temporary recording was left behind"
if record >/dev/null 2>&1; then fail "saved with every name taken"; fi

: > "$dir/.mira-test-recording.mp4"
if sh "$finish" "$dir/.mira-test-recording.mp4" "$dir" "b.mp4" 2>/dev/null; then fail "an empty recording was kept"; fi
[ ! -e "$dir/b.mp4" ] || fail "an empty recording was saved"
[ ! -e "$dir/.mira-test-recording.mp4" ] || fail "an empty recording was left behind"

echo "finish.sh: all checks passed"
