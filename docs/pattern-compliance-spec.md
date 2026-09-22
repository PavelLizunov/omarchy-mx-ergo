# Pattern compliance follow-up

## Intent and invariants

Close identified source-level gaps in the current candidate without changing the approved assets, panel structure, button assignments or battery uncertainty contract. Ordinary functionality remains unprivileged. No system reboot, Bluetooth reconfiguration or publication is included in local verification.

## Behavior

- Tab reaches language selection, connection, page tabs and every enabled page/editor control. Escape closes the language picker or editor before closing the panel. Focus position is visible and kept in view.
- Save/load/apply failures are localized and visible; failed operations never present successful persistence. Retry is explicit and bounded.
- Helpers have bounded output/work, lifecycle cancellation, visible failure paths and no retry storms. Resume subscription accepts only the expected logind sender/path, stops scheduled attempts on sleep, and retries listener failure a finite number of times.
- Locale fallback preserves script intent: unsupported Traditional Chinese falls back to English rather than silently selecting Simplified Chinese.
- Local bitmap decoding is asynchronous; temporary/config data and process ownership follow the existing trust model.

## Verification

Run production-function tests for navigation, error states, configuration queue, sleep/retry and locale resolution; isolated helper failure/cancellation tests; all nine stages of tests/run.sh; inspect final native panel. Review command/privilege changes independently when the configured worker is available. Native keyboard/monitor/hardware scenarios require actual authorized interaction or a user test result. Missing evidence cannot be called full compliance.
