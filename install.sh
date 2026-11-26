#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$(uname -s)" == "Darwin" ]]; then
  exec "$ROOT/macos/install.sh" "$@"
fi

JUCE_DIR="$ROOT/linux/.deps/JUCE"
BUILD_DIR="$ROOT/linux/build-release"

echo "==> FxSound Linux installer"

echo "==> Installing build dependencies"
command -v sudo >/dev/null 2>&1 || { echo "sudo is required to install packages; install it as root first." >&2; exit 1; }
if command -v pacman >/dev/null 2>&1; then
  # Arch ships dev headers in the runtime packages; --needed avoids a full system upgrade.
  sudo pacman -S --needed --noconfirm \
    base-devel cmake ninja pkgconf git pipewire pipewire-audio pipewire-pulse wireplumber \
    gtk3 libx11 libxext libxrandr libxinerama libxcursor \
    freetype2 fontconfig alsa-lib
elif command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y \
    build-essential cmake ninja-build pkg-config git \
    libpipewire-0.3-dev libspa-0.2-dev \
    libgtk-3-dev libx11-dev libxext-dev libxrandr-dev \
    libxinerama-dev libxcursor-dev \
    libfreetype6-dev libfontconfig1-dev libasound2-dev
else
  echo "No supported package manager found (apt-get or pacman)." >&2
  echo "See linux/README.md for manual build instructions." >&2
  exit 1
fi

if [[ ! -f "$JUCE_DIR/CMakeLists.txt" ]]; then
  echo "==> Fetching JUCE 6.1.6"
  mkdir -p "$(dirname "$JUCE_DIR")"
  git clone --depth 1 --branch 6.1.6 \
    https://github.com/juce-framework/JUCE.git "$JUCE_DIR"
fi

echo "==> Configuring FxSound Linux"
cmake -S "$ROOT/linux" -B "$BUILD_DIR" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DFXSOUND_BUILD_PIPEWIRE=ON \
  -DFXSOUND_JUCE_DIR="$JUCE_DIR"

echo "==> Building"
cmake --build "$BUILD_DIR"

echo "==> Running DSP checks"
"$BUILD_DIR/dsp_smoke"
"$BUILD_DIR/preset_audio_test" "$ROOT/linux/factory-presets/1.fac"

echo "==> Installing for $USER"
FXSOUND_DAEMON="$BUILD_DIR/fxsound_pipewire" \
FXSOUND_UI="$BUILD_DIR/fxsound_linux_ui_artefacts/Release/FxSound Linux" \
  "$ROOT/linux/install-user.sh"

echo
echo "FxSound Linux is installed."
echo "Open it from your app menu, or run: fxsound-linux"
