#!/bin/sh
set -eu
source=$(dirname "$0")/shell
target="$HOME/.local/share/mira"
launcher="$HOME/.local/bin/mira"

mkdir -p "$HOME/.local/share" "$HOME/.local/bin"
rm -rf "$target"
cp -r "$source" "$target"
rm -rf "$target/tests"
printf '#!/bin/sh\nexec qs -n -p "$HOME/.local/share/mira"\n' > "$launcher"
chmod +x "$launcher"
echo "installed mira to $target and $launcher"
