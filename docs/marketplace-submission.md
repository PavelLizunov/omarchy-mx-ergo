# Marketplace submission draft

Local draft only. Read `RELEASE-REVIEW.md` and finish its acceptance items before sending.

- Repository: https://github.com/PavelLizunov/omarchy-mx-ergo
- Name: Logitech MX Ergo
- Plugin ID: `io.github.pavellizunov.mx-ergo`
- Manifest version: `1.0.0` — development candidate
- Commit: **not frozen; do not submit the old repository HEAD**
- Kind: bar-widget
- Category: Hardware
- Tags: trackball, bluetooth, logitech, input, battery
- Preview: `assets/preview.png`

## Description

Connection status, approximate battery reporting, a five-button assignment diagram and Hyprland pointer controls for the Logitech MX Ergo. The panel follows the Omarchy theme and supports ten interface languages.

## Dependencies and privileges

Requires Omarchy Quattro, Quickshell Bluetooth/UPower, BlueZ, UPower, the tested Hyprland Lua interface, Python 3 and `dbus-monitor`. Some actions need `wtype`, `playerctl`, `wpctl`, Voxtype, Overview or the TTS plugin. The README lists shortcut compatibility aliases.

Ordinary functionality runs with user permissions inside the unsandboxed shared shell. An optional Bluetooth controller profile requires separate manual installation of a root-owned helper and an explicit Polkit administrator prompt for changes. It changes controller intervals and USB power management, persists after plugin removal, and affects other devices on that controller. It does not increase radio power or guarantee smoother input. No plugin downloads, remote builds or network requests are performed.

## Limitations

Charge values are approximate; no exact percentage or battery-health guarantee. Pointer settings are per device, but button bindings are global in Hyprland. The optional helper has recovery and removal instructions; target-hardware acceptance remains pending. The privileged boundary and user-session candidate have scoped independent source reviews. This is a community plugin, not an official Logitech application.

## Validation

All nine local test stages pass, including isolated profile/recovery/persistence tests and offscreen diagram interactions. The live panel loads on the recorded host. See `RELEASE-REVIEW.md` for source hashes, installed-helper identity and explicit untested limits.

## Submission route

Recheck https://plugins.omarchy.org/publish.html immediately before submission. The guide links a GitHub issue form; preparing this draft does not authorize opening or submitting it, pushing the candidate, or creating a release.
