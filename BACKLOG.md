# Development status

The plugin remains a development candidate (manifest `1.0.0`). Marketplace preparation is local; no submission approval is implied.

## Implemented with local checks

The 2026-10-08 original working-tree baseline passed the Python, JavaScript,
manifest and QML lint checks, but failed the offscreen profile-form Backtab focus
assertion at `tests/profiles-ui/tst_editor.qml:942`. This is not an all-green gate.

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

- [ ] Diagnose and resolve the original profile-form Backtab focus failure without weakening the assertion.
- [ ] Re-establish current-candidate independent static review and a green complete test gate.
- [ ] Native end-to-end keyboard/accessibility review across pages and language picker.
- [ ] Multi-monitor, vertical bar, display hotplug and additional scale checks.
- [ ] Live optional-profile enable/restore and udev reapply on an authorized test adapter. Installation alone does not establish those results.
- [ ] Legacy profile migration on the development machine requires recognized-rule cleanup followed by a computer restart; original values were not recorded by the old code.
- [ ] Recheck the earlier report of text appearing over the plugin during prolonged use; current screenshots alone cannot establish its cause.
- [ ] Freeze the reviewed commit, push with approval, then submit the exact candidate with approval.

## Documented limitations

Exact charge and battery health are unavailable through the current interface. Global Hyprland button bindings affect other mice; removal needs a configuration reload to restore file-defined mappings. Config read/write errors, binding recovery failures and stopped sleep monitoring are visible in the panel. Hardware DPI is not controlled by this plugin; sensitivity is a compositor multiplier.
