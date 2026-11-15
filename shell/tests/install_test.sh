#!/bin/sh
set -eu
repo="$(cd "$(dirname "$0")/../.." && pwd)"
home=$(mktemp -d)
trap 'rm -rf "$home"' EXIT

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

mkdir -p "$home/.local/share/mira/stale"
HOME="$home" sh "$repo/install.sh" >/dev/null
HOME="$home" sh "$repo/install.sh" >/dev/null

target="$home/.local/share/mira"
launcher="$home/.local/bin/mira"
for file in shell.qml thumbnail.qml record.qml Overlay.qml logic.js save.sh claim.sh finish.sh; do
    [ -f "$target/$file" ] || fail "$file was not installed"
done
[ ! -e "$target/tests" ] || fail "tests were installed"
[ ! -e "$target/stale" ] || fail "an old install was not replaced"
[ -x "$launcher" ] || fail "launcher is not executable"
[ "$(sed -n 2p "$launcher")" = 'qs ipc -p "$HOME/.local/share/mira/record.qml" call recording stop >/dev/null 2>&1 || exec qs -n -p "$HOME/.local/share/mira"' ] || fail "launcher runs the wrong command"

echo "install.sh: all checks passed"
