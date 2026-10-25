# Development status

The plugin is a preview release candidate (manifest `1.1.0-rc.1`). The owner requested verification and publication on 25 October 2026. GitHub release publication and Marketplace approval are separate outcomes. See [current release evidence](docs/release-1.1.0-rc.1.md).

## Implemented with local checks

The 2026-10-08 original working-tree baseline failed the offscreen profile-form
Backtab assertion at `tests/profiles-ui/tst_editor.qml:942`. On 25 October, the
complete suite passes on Omarchy 4.5.0rc1 / Qt 6.12.0, including that unchanged
assertion and 103 profile/editor cases. This does not establish which host change
resolved the earlier failure or prove native hardware acceptance.

- Reactive BlueZ/UPower telemetry with HID identity matching and explicit unknown/disconnected states.
- Approximate battery categories; no fabricated percentages or full-battery gauge.
- Five-button diagram, adjacent editor, explicit draft commits and in-place assignment updates.
- Three-page panel using a fixed 736 by 650 scaled frame and host theme/typography.
- Automatic language preference, ten native language names and explicit script-aware fallback.
- Keyboard traversal of header/languages/editor, accessible button/checkbox/slider metadata, visible failure and Retry states.
- Bounded logind-listener restart, suspend cancellation and native-only reconnect.
- Single-flight Hyprland settings recovery after config reload, with bounded verification and retries.
- Portable device defaults and TTS paths; shell-quoted shortcut operands.
- Bounded validated preferences, serialized atomic saves and preserved prior file on write failure.
- Optional root-owned Bluetooth helper, explicit Polkit actions and physical-adapter recovery journal.
- Production-function, isolated filesystem/process, locale, QML and Qt diagram checks in `tests/run.sh`.

## Before Marketplace submission

Earlier independent helper and QML reviews are historical evidence in
[the dated release review](RELEASE-REVIEW.md), not acceptance of today's dirty
working tree. Re-establish them on the actual release candidate.

- [x] Recheck the original profile-form Backtab failure: unchanged assertion passes on the current Qt host; earlier cause remains unconfirmed.
- [x] Complete local test gate passes, including QML lint and 103 profile/editor cases.
- [ ] Re-establish current-candidate independent static review (not performed in this release pass).
- [ ] Native end-to-end keyboard/accessibility review across pages and language picker.
- [ ] Multi-monitor, vertical bar, display hotplug and additional scale checks.
- [ ] Live optional-profile enable/restore and udev reapply on an authorized test adapter. Installation alone does not establish those results.
- [ ] Legacy profile migration on the development machine requires recognized-rule cleanup followed by a computer restart; original values were not recorded by the old code.
- [ ] Recheck the earlier report of text appearing over the plugin during prolonged use; current screenshots alone cannot establish its cause.
- [ ] Record exact GitHub release commit and publication outcome. Marketplace submission remains a separate listing action.

## Documented limitations

Exact charge and battery health are unavailable through the current interface. Global Hyprland button bindings affect other mice; removal needs a configuration reload to restore file-defined mappings. Config read/write errors, binding recovery failures and stopped sleep monitoring are visible in the panel. Hardware DPI is not controlled by this plugin; sensitivity is a compositor multiplier.
