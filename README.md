# Logitech MX Ergo for Omarchy Quattro

Battery categories, button profiles and pointer settings for the Logitech MX Ergo
trackball over Bluetooth or a Logitech Unifying receiver.

> **1.1.0-rc.1 — preview release, not a stable hardware signoff.** The complete
> local suite passes on Omarchy 4.5.0rc1 and Qt 6.12.0, including 103 offscreen
> profile/editor checks. See [release evidence](docs/release-1.1.0-rc.1.md) and
> [remaining acceptance work](BACKLOG.md).

Read [installation and removal](#installation-and-removal) before enabling it.
Requires Linux with Omarchy Quattro and the Hyprland Lua interface used here.

<a href="preview.png"><img src="preview.png" alt="MX Ergo Buttons page in the light palette, rendered offscreen with inert data" width="330"></a>

This is an offscreen example, not a desktop or hardware verification.
[Capture provenance](assets/screenshots/current/evidence.json) records its inputs.

## Features

- Approximate charge categories with explicit unknown, disconnected and conflicting
  source states. No synthetic percentage or filled battery gauge.
- Five-button assignments, independent named profiles, keyboard profile switching
  and an adjacent editor with explicit shortcut/command drafts.
- Per-device sensitivity, acceleration and natural scrolling.
- Bounded settings recovery after configuration reload, startup and wake.
- Ten interface languages and native Omarchy theme controls.

The bar indicator is hidden while disconnected by default. The widget setting
`hideWhenDisconnected` can keep it visible; an explicitly saved `false` is
preserved. When hidden, open the panel with
`omarchy-shell io.github.pavellizunov.mx-ergo open` to access recovery controls.

Detailed behavior and screenshots are in the [usage guide](docs/guide.md).

## Installation and removal

The plugin runs **unsandboxed** as your user inside the shared Omarchy shell.
Button commands can execute shell commands. Button bindings are global and can
replace mappings used by other mice. Review the source and
[security disclosure](docs/guide.md#architecture--security-disclosure) first.
The optional administrator helper is separate and affects the entire controller;
normal battery, button and pointer controls work without it.

Install and enable with Omarchy's plugin manager:

```bash
omarchy plugin add \
  https://github.com/PavelLizunov/omarchy-mx-ergo.git --enable
```

Updates follow the repository's default branch, not this uncommitted checkout or
a pinned reviewed release:

```bash
omarchy plugin update io.github.pavellizunov.mx-ergo
```

Before removal, restore any optional Bluetooth profile and resolve pending
restoration. Disable the plugin, then reload the normal Hyprland configuration
to restore file-defined button mappings. Do not reload an active plugin while
locked or while a lock is requested. Remove with:

```bash
omarchy plugin remove io.github.pavellizunov.mx-ergo
```

Removal keeps saved preferences and does not uninstall the optional helper or
undo arbitrary custom commands. Read the
[helper removal procedure](docs/guide.md#removing-the-optional-helper).

## Known limitations

Charge precision, measurement freshness and battery health are unavailable.
A Bluetooth connection report does not prove pointer movement. Global button
bindings affect other mice; unsaved foreign mappings cannot be restored
implicitly. Hardware DPI is not controlled. The optional latency profile has no
measured input-rate or latency benefit. Older versions cannot load the new
profile format; retain a preferences backup before downgrading.

The original profile-form Backtab assertion passes on the current Qt host; the
assertion was not weakened. Text overlapping the plugin was previously reported
with no confirmed cause. Native keyboard-only
accessibility, hardware recovery and broader display/scale compatibility still
need acceptance. See [BACKLOG.md](BACKLOG.md) for the current status.

## Development and verification

Clone or edit outside the installed plugin directory. This checkout is separate
from the copy loaded by Omarchy. Source changes do not deploy themselves.
Read [DEVELOPMENT.md](DEVELOPMENT.md) for instruction roles and verification.

```bash
python3 -B tests/repository-docs.py
./tests/run.sh
```

The first command checks documentation and test-runner contracts independently.
The complete suite includes isolated model/helper tests, locale checks, QML lint
and offscreen Qt interactions. These do not replace live shell or hardware
acceptance. Historical reviews and hashes describe their recorded snapshots,
not a new all-green result for this working tree.

## Detailed reference

These links preserve the earlier README section anchors:

### Screenshots

[Light and dark offscreen captures](docs/guide.md#screenshots).

<a id="light-theme"></a><a id="dark-theme"></a>

### Button profiles

[Profile management, switching, persistence and downgrade limits](docs/guide.md#button-profiles).

### Architecture & Security Disclosure

[Execution, privileges, processes and input boundaries](docs/guide.md#architecture--security-disclosure).

### Setup and development

[Dependencies, pairing, device selection and supported shell operations](docs/guide.md#setup-and-development).

### Optional Bluetooth latency profile

[Administrator installation, operation and recovery](docs/guide.md#optional-bluetooth-latency-profile).

<a id="installation-administrator-action"></a><a id="operation-and-recovery"></a>
<a id="legacy-profile-migration"></a>

#### Removing the optional helper

[Restore before removing the privileged helper](docs/guide.md#removing-the-optional-helper).

### Verification

[Original verification scope](docs/guide.md#verification),
[source map](MODULES.md), [engineering handbook](HANDBOOK.md) and
[dated release review](RELEASE-REVIEW.md).

## License

[MIT License](LICENSE). Copyright (c) 2026 Pavel Lizunov.
[Trackball icon details](assets/README.md).
