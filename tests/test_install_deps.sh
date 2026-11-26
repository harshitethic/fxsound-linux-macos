#!/usr/bin/env bash
# Mocked check of install.sh's package-manager selection; installs nothing.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin"
cat >"$WORK/bin/sudo" <<'SH'
#!/bin/sh
printf '%s\n' "$*" >> "$SUDO_LOG"
SH
printf '#!/bin/sh\nexit 0\n' >"$WORK/bin/pacman"
cp "$WORK/bin/pacman" "$WORK/bin/apt-get"
chmod +x "$WORK/bin/sudo" "$WORK/bin/pacman" "$WORK/bin/apt-get"
: >"$WORK/sudo.log"
export SUDO_LOG="$WORK/sudo.log"

deps="$(sed -n '/^echo "==> Installing build dependencies"/,/^fi$/p' "$ROOT/install.sh")"

run_block() {
  PATH="$WORK/bin:$PATH" bash -c '
    hidden="$1"
    command() {
      if [[ "$1" == "-v" && "$2" == "$hidden" ]]; then return 1; fi
      builtin command "$@"
    }
    eval "$2"
  ' _ "$1" "$deps"
}

# pacman wins when both managers exist (Arch with apt installed from the AUR).
run_block ''
expected='pacman -S --needed --noconfirm base-devel cmake ninja pkgconf git pipewire pipewire-audio pipewire-pulse wireplumber gtk3 libx11 libxext libxrandr libxinerama libxcursor freetype2 fontconfig alsa-lib'
grep -Fxq "$expected" "$SUDO_LOG" || { echo "Unexpected pacman package list" >&2; exit 1; }
! grep -q apt-get "$SUDO_LOG"

# Debian: pacman is absent, so the apt-get branch must still be used.
: >"$SUDO_LOG"
run_block pacman
grep -q '^apt-get update$' "$SUDO_LOG"
grep -q '^apt-get install -y ' "$SUDO_LOG"
! grep -q pacman "$SUDO_LOG"

# A missing sudo must stop the installer before it tries to install anything.
if run_block sudo >/dev/null 2>&1; then
  echo "Installer accepted a missing sudo" >&2
  exit 1
fi

echo "PASS: package manager selection and sudo preflight"
