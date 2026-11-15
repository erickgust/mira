#!/bin/sh
set -eu
source=$(dirname "$0")/shell
target="$HOME/.local/share/mira"
launcher="$HOME/.local/bin/mira"

mkdir -p "$HOME/.local/share" "$HOME/.local/bin"
rm -rf "$target"
cp -r "$source" "$target"
rm -rf "$target/tests"
printf '#!/bin/sh\nqs ipc -p "$HOME/.local/share/mira/record.qml" call recording stop >/dev/null 2>&1 || exec qs -n -p "$HOME/.local/share/mira"\n' > "$launcher"
chmod +x "$launcher"
echo "installed mira to $target and $launcher"
