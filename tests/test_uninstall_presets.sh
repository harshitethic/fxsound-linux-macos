#!/usr/bin/env bash
# Test with disposable HOME and mocked session services; never modify live data.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin" "$WORK/home"
cat >"$WORK/bin/systemctl" <<'SH'
#!/bin/sh
exit 0
SH
cat >"$WORK/bin/wpctl" <<'SH'
#!/bin/sh
case "$1" in status) exit 0;; set-default) exit 0;; *) exit 1;; esac
SH
chmod +x "$WORK/bin/systemctl" "$WORK/bin/wpctl"
export PATH="$WORK/bin:$PATH" HOME="$WORK/home"

mkdir -p "$HOME/.local/share/fxsound-linux/presets"   "$HOME/.config/fxsound-linux" "$HOME/.local/libexec/fxsound-linux"   "$HOME/.local/bin" "$HOME/.local/share/applications"
printf 'MY CUSTOM PRESET\n' >"$HOME/.local/share/fxsound-linux/presets/my-own.fac"
printf 'MY EQ CONFIG\n' >"$HOME/.config/fxsound-linux/settings.json"
printf 'binary\n' >"$HOME/.local/libexec/fxsound-linux/fxsoundd"
printf 'launch\n' >"$HOME/.local/bin/fxsound-linux"
printf 'desktop\n' >"$HOME/.local/share/applications/fxsound-linux.desktop"
printf 'unrelated\n' >"$HOME/keep-me.txt"

# Bad arguments must not uninstall anything.
if "$ROOT/uninstall.sh" --wrong-option >/dev/null 2>&1; then
  echo "Invalid option unexpectedly accepted"; exit 1
fi
[[ -f "$HOME/.local/libexec/fxsound-linux/fxsoundd" ]]

"$ROOT/uninstall.sh" >/dev/null
[[ -f "$HOME/.local/share/fxsound-linux/presets/my-own.fac" ]]
[[ -f "$HOME/.config/fxsound-linux/settings.json" ]]
[[ ! -e "$HOME/.local/libexec/fxsound-linux/fxsoundd" ]]
[[ ! -e "$HOME/.local/bin/fxsound-linux" ]]
[[ ! -e "$HOME/.local/share/applications/fxsound-linux.desktop" ]]
[[ -f "$HOME/keep-me.txt" ]]

"$ROOT/uninstall.sh" --purge >/dev/null
[[ ! -e "$HOME/.local/share/fxsound-linux" ]]
[[ ! -e "$HOME/.config/fxsound-linux" ]]
[[ -f "$HOME/keep-me.txt" ]]
echo "PASS: presets survive normal uninstall; explicit purge deletes data only."
