#!/usr/bin/env bash
# Safe integration test: mocks systemctl/wpctl and isolates HOME.
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
case "$1" in
  status) cat "$WPCTL_FIXTURE";;
  set-default) printf '%s\n' "$2" >> "$WPCTL_LOG";;
  *) exit 1;;
esac
SH
chmod +x "$WORK/bin/systemctl" "$WORK/bin/wpctl"
export PATH="$WORK/bin:$PATH"
export HOME="$WORK/home"
export WPCTL_FIXTURE="$WORK/sink-status.txt"
export WPCTL_LOG="$WORK/wpctl.log"

cat >"$WPCTL_FIXTURE" <<'STATUS'
Audio
 ├─ Sinks:
 │  * 54. Built-in Speakers [vol: 1.00]
 │    62. FxSound [vol: 1.00]
 ├─ Sources:
STATUS
: >"$WPCTL_LOG"
"$ROOT/uninstall.sh" >/dev/null
[[ ! -s "$WPCTL_LOG" ]] || { echo "Uninstall changed a non-FxSound default"; exit 1; }

cat >"$WPCTL_FIXTURE" <<'STATUS'
Audio
 ├─ Sinks:
 │  * 62. FxSound [vol: 1.00]
 │    54. Built-in Speakers [vol: 1.00]
 │    81. USB Headphones [vol: 1.00]
 ├─ Sources:
STATUS
: >"$WPCTL_LOG"
"$ROOT/uninstall.sh" >/dev/null
[[ "$(cat "$WPCTL_LOG")" == "54" ]] || { echo "FxSound default was not restored"; exit 1; }

cat >"$WPCTL_FIXTURE" <<'STATUS'
Audio
 ├─ Sinks:
 │  * 62. FxSound [vol: 1.00]
 ├─ Sources:
STATUS
: >"$WPCTL_LOG"
"$ROOT/uninstall.sh" >/dev/null
[[ ! -s "$WPCTL_LOG" ]] || { echo "Attempted to set a nonexistent fallback"; exit 1; }
echo "PASS: unrelated defaults preserved, FxSound defaults restored, missing fallback ignored."
