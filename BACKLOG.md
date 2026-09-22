# Development status

The plugin remains a development candidate (manifest `1.0.0`). Marketplace preparation is local; no submission approval is implied.

## Implemented and covered by local checks

- Reactive BlueZ/UPower telemetry with HID identity matching and explicit unknown/disconnected states.
- Approximate battery categories; no fabricated percentages or full-battery gauge.
- Five-button diagram, replacement editor, explicit draft commits and return after selection.
- Three-page panel using the ROG Cetra width and host theme/typography.
- Automatic language preference, ten native language names and explicit script-aware fallback.
- Keyboard traversal of header/languages/editor, accessible button/checkbox/slider metadata, visible failure and Retry states.
- Bounded logind-listener restart, suspend cancellation and native-only reconnect.
- Single-flight Hyprland settings recovery after config reload, with bounded verification and retries.
- Portable device defaults and TTS paths; shell-quoted shortcut operands.
- Bounded validated preferences, serialized atomic saves and preserved prior file on write failure.
- Optional root-owned Bluetooth helper, explicit Polkit actions and physical-adapter recovery journal.
- Production-function, isolated filesystem/process, locale, QML and Qt diagram checks in `tests/run.sh`.

## Before Marketplace submission

- [x] Independent read-only review of the privileged helper/client/installer/policy (GPT-5.5, explicit routing exception); fixture-isolation finding fixed and rechecked.
- [x] Independent static review of the final QML/model/helper candidate through Gemini; no actionable findings, runtime limits retained.
- [ ] Native end-to-end keyboard/accessibility review across pages and language picker.
- [ ] Multi-monitor, vertical bar, display hotplug and additional scale checks.
- [ ] Live optional-profile enable/restore and udev reapply on an authorized test adapter. Installation alone does not establish those results.
- [ ] Legacy profile migration on the development machine requires recognized-rule cleanup followed by a computer restart; original values were not recorded by the old code.
- [ ] Recheck the earlier report of text appearing over the plugin during prolonged use; current screenshots alone cannot establish its cause.
- [ ] Freeze the reviewed commit, push with approval, then submit the exact candidate with approval.

## Documented limitations

Exact charge and battery health are unavailable through the current interface. Global Hyprland button bindings affect other mice; removal needs a configuration reload to restore file-defined mappings. Config read/write errors, binding recovery failures and stopped sleep monitoring are visible in the panel. Hardware DPI is not controlled by this plugin; sensitivity is a compositor multiplier.
