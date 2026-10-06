# Development history

This standalone repository exists so the Linux and macOS port work is visible as its own project rather than being hidden inside a GitHub fork.

The project is derived from the official open-source FxSound repository and keeps upstream attribution and AGPL licensing. The old Windows-only repository history is represented by the first upstream baseline commit; the commits after that baseline are the real port-development milestones.

## Linux port

The Linux work was developed as a sequence of real commits:

- Native PipeWire FxSound port
- Windows-style buffering cadence
- Native CI build and DSP tests
- Windows FxSound parity improvements
- Preset EQ bypass correctness
- RTKit realtime DSP scheduling
- Windows-parity engine status
- Safety fix to avoid disabling unrelated audio services
- One-command public installer
- Clean user uninstaller
- Downloadable CI artifact
- v0.1.0-alpha release marker
- Public README/install guide
- UI screenshot and executable installer docs
- GCC 15 / JUCE compatibility
- Cleanup of inherited unrelated workflows

## macOS port

The Mac work then added:

- Native CoreAudio FxSound daemon
- Apple Silicon arm64 build
- BlackHole 2ch stable system-audio routing
- Real upstream DfxDsp and factory .fac presets
- JUCE desktop UI
- FxSound app icon
- Native minimize and same-instance restore behavior
- UI auto-start minimized at login
- Audio daemon auto-start and abnormal-exit recovery
- Persistent preset, EQ, output and audio-control state
- Immediate effect/EQ autosave
- Clean shutdown / JUCE singleton lifetime fix
- Exact factory-EQ preservation
- Same-band EQ no-op fix
- Experimental native CoreAudio process-tap backend
- macOS 26 JUCE SDK compatibility patch
- One-command macOS installer/uninstaller
- macOS GitHub Actions build
- Cross-platform root install flow

## Validation performed

The macOS v0.2.2 pass included:

- Fresh JUCE 6.1.6 configure/build from scratch
- DSP smoke test
- Factory preset audio test
- 25/25 UI/control QA checks
- All five actual effect sliders
- EQ gain and EQ frequency controls
- 5/10/15/20/31-band switching
- Volume Leveling, Master Gain, Balance and Filter Q
- Power, preset and output selectors
- Compact/full UI
- Dark/light theme
- Always-on-Top
- Restore Defaults
- Native minimize
- Same-process second-launch restore
- Native menu popup
- Login-minimized behavior
- Clean Quit without crash
- Live end-to-end audio routing
- 0 underruns / 0 overruns in the final live test

## Why this repository is standalone

GitHub does not count normal commits made only in a fork toward the public contribution graph. The port was originally developed in a fork of fxsound2/fxsound-app.

This repository preserves the actual port milestones as a standalone project, while still crediting FxSound upstream in the source, README and license.
