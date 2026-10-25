# Marketplace submission draft — 1.1.0-rc.1

The owner requested verification and publication on 25 October 2026. This file
records listing material; it does not mean Marketplace approval was granted.
The exact candidate is the commit referenced by GitHub tag `v1.1.0-rc.1`.

- Repository: https://github.com/PavelLizunov/omarchy-mx-ergo
- Name: Logitech MX Ergo
- Plugin ID: `io.github.pavellizunov.mx-ergo`
- Manifest version: `1.1.0-rc.1` — preview release
- Kind: bar-widget; entry point: `BarWidget.qml`; panel owned internally
- Category: Hardware
- Allowed tags: bar, hyprland, quickshell
- Preview: `preview.png` (recorded inert offscreen example)

## Description

Approximate battery categories, named five-button profiles, keyboard profile
switching, target-only Bluetooth recovery and Hyprland pointer controls for the
Logitech MX Ergo. Ten interface languages and native Omarchy theme controls.

## Dependencies and privileges

Requires Omarchy Quattro, Quickshell Bluetooth/UPower, BlueZ/bluez-utils, UPower,
the tested Hyprland Lua interface, Python 3 and `dbus-monitor`. Some actions need
`wtype`, `playerctl`, `wpctl`, Voxtype, Overview or the TTS plugin. The usage guide
lists compatibility aliases and optional dependencies.

The plugin runs unsandboxed as the user. Custom Command actions intentionally
execute shell commands; button bindings are global. The optional root-owned
Bluetooth helper is installed separately and uses explicit Polkit authorization.
Ordinary functionality needs no administrator helper or build toolchain. No
plugin downloads, remote builds or network calls are performed.

## Evidence and limits

The complete local suite passes on Omarchy 4.5.0rc1 and Qt 6.12.0, including 103
profile/editor interactions and the unchanged historical Backtab assertion.
See [current release evidence](release-1.1.0-rc.1.md). Earlier source reviews apply
only to their recorded snapshots. Physical mouse behavior, native accessibility,
sleep/wake, multi-monitor and optional controller writes remain unverified in
this release pass. Charge precision and measured latency benefits are unavailable.

The current catalog does not contain this plugin ID. A GitHub release does not
create a Marketplace listing. Submission uses the live upstream SUBMISSION.md
format and needs maintainer approval before the public card becomes available.
The live card/copy installation path remains pending until publication there.
