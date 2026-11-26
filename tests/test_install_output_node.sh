#!/usr/bin/env bash
# Isolated check that install-user.sh saves a physical sink, not FxSound itself.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin" "$WORK/home"
cat >"$WORK/bin/systemctl" <<'SH'
#!/bin/sh
exit 0
SH
printf '#!/bin/sh\nexit 0\n' >"$WORK/bin/sleep"
cat >"$WORK/bin/wpctl" <<'SH'
#!/bin/sh
case "$1" in
  status)
    [ -z "${2:-}" ] || { echo "unknown wpctl status option: $2" >&2; exit 1; }
    cat "$WPCTL_STATUS";;
  inspect)
    name="$(awk -v id="${2:-}" '$1 == id { print $2; exit }' "$WPCTL_NAMES")"
    [ -n "$name" ] || exit 1
    printf '  * node.name = "%s"\n' "$name";;
  set-default) printf '%s\n' "$2" >> "$WPCTL_LOG";;
  *) exit 1;;
esac
SH
chmod +x "$WORK/bin/systemctl" "$WORK/bin/sleep" "$WORK/bin/wpctl"
export PATH="$WORK/bin:$PATH"
export HOME="$WORK/home"
export WPCTL_STATUS="$WORK/sink-status.txt"
export WPCTL_NAMES="$WORK/node-names.txt"
export WPCTL_LOG="$WORK/wpctl.log"
: >"$WPCTL_LOG"
: >"$WORK/daemon"
: >"$WORK/ui"
chmod +x "$WORK/daemon" "$WORK/ui"

cat >"$WPCTL_NAMES" <<'NAMES'
54 alsa_output.pci-0000_00_1f.3.analog-stereo
62 fxsound_sink
70 usb_headset
NAMES

cat >"$WPCTL_STATUS" <<'STATUS'
Audio
 ├─ Sinks:
 │  * 54. Built-in Audio Analog Stereo [vol: 1.00]
 │    62. FxSound [vol: 1.00]
 ├─ Sources:
STATUS

FXSOUND_DAEMON="$WORK/daemon" FXSOUND_UI="$WORK/ui" "$ROOT/linux/install-user.sh" >/dev/null
[[ "$(cat "$HOME/.config/fxsound-linux/output-node")" == "alsa_output.pci-0000_00_1f.3.analog-stereo" ]] ||
  { echo "Default sink was not saved" >&2; exit 1; }

# A saved choice must survive a reinstall.
printf 'usb_headset\n' >"$HOME/.config/fxsound-linux/output-node"
FXSOUND_DAEMON="$WORK/daemon" FXSOUND_UI="$WORK/ui" "$ROOT/linux/install-user.sh" >/dev/null
[[ "$(cat "$HOME/.config/fxsound-linux/output-node")" == "usb_headset" ]] ||
  { echo "Reinstall overwrote the saved output" >&2; exit 1; }

# If FxSound itself is default, the installer must pick a physical sink.
rm "$HOME/.config/fxsound-linux/output-node"
cat >"$WPCTL_STATUS" <<'STATUS'
Audio
 ├─ Sinks:
 │  * 62. FxSound [vol: 1.00]
 │    70. USB Headset [vol: 1.00]
 ├─ Sources:
STATUS
FXSOUND_DAEMON="$WORK/daemon" FXSOUND_UI="$WORK/ui" "$ROOT/linux/install-user.sh" >/dev/null
[[ "$(cat "$HOME/.config/fxsound-linux/output-node")" == "usb_headset" ]] ||
  { echo "FxSound sink was saved as the output" >&2; exit 1; }

echo "PASS: installer saves a physical sink and skips FxSound"
