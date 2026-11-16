#!/bin/sh
set -eu
card="$(cd "$(dirname "$0")/.." && pwd)/card.sh"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

cat > "$work/qs" <<'FAKE'
#!/bin/sh
echo "$*" >> "$QS_LOG"
[ "$1" = list ] && printf 'Instance a:\n  Process ID: 11\n\nInstance b:\n  Process ID: 22\n'
exit 0
FAKE
chmod +x "$work/qs"

PATH="$work:$PATH" QS_LOG="$work/log" sh "$card"
dir=$(dirname "$card")
expected="list -p $dir/thumbnail.qml
ipc --pid 11 call card replace
ipc --pid 22 call card replace
-p $dir/thumbnail.qml"
[ "$(cat "$work/log")" = "$expected" ] || fail "card.sh ran: $(cat "$work/log")"

echo "card.sh: all checks passed"
