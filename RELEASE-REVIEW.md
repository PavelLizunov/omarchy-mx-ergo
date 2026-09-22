# Marketplace preparation review — 22 September 2026

**Verdict: scoped source checks and independent reviews pass; runtime acceptance remains incomplete.** Local implementation checks pass and the plugin loads in the current shell. The privileged helper has a scoped independent source review. Hardware/display/keyboard lifecycle acceptance and an exact submission commit are still required. No push or Marketplace submission was performed.

## Scope and contract

Repository: `PavelLizunov/omarchy-mx-ergo`; plugin ID `io.github.pavellizunov.mx-ergo`; manifest version `1.0.0` (development status). Base commit: `7953f08f1b980eadac093653e3e01c7314b73b25`. This review covers the combined development working tree, including new runtime sources, tests and assets. The candidate's source hashes are recorded in `docs/candidate.sha256`; the report and hash ledger are excluded from that ledger to avoid self-reference.

Acceptance contract:

1. Preserve approximate battery categories, explicit unknown/disconnected states and native-service ownership. No raw HID or fabricated percentages.
2. Preserve the approved trackball assets and panel layout. Keep current button shortcuts compatible, support portable installation paths, and quote shortcut operands.
3. Validate and bound persisted preferences; preserve the prior file on failed writes. Serialize configuration writes and settings application with at most one pending value/request each.
4. Restore configured assignments after Hyprland reload. Missing/corrupt preferences must not apply defaults merely because the compositor reloaded.
5. Optional administrator operations go through the separately installed root-owned helper and Polkit. Installation itself changes no controller values.
6. Keep local preparation distinct from publication and document untested acceptance paths.

## Changes made during preparation

- Removed the author MAC from manifest defaults. Empty selection requires one matching discovered device; reconnect validates and uses only a known native BlueZ device. Missing devices must be discovered/paired through normal Bluetooth controls.
- Removed the unused percentage setting. TTS compatibility paths now follow the user's configuration directory; existing aliases remain supported and are disclosed in README.
- Quoted variable `wtype` key operands. The explicit Command field intentionally retains shell-command semantics.
- Added `config-store.py`: 64 KiB read limit, regular-file checks, typed/ranged validation, mode 0600 and atomic replacement. The model serializes writers and retains only the latest queued configuration.
- Replaced temporary-file output collection in `apply-settings.py` with a capped pipe reader. Overflow, timeout and cancellation kill and reap the child.
- Added `settingsConfigured` to protect unconfigured installs and rejected preference files from reload-time unbinding. Successful native reconnect cancels pending resume timers.
- Replaced duplicated model implementation in tests with execution of production QML JavaScript functions.
- Removed the lint dependency on `/tmp/opencode`; limited missing-member suppression to dynamic QObject interfaces. Concrete-type warnings now fail; the F-key grid uses an explicit owner ID.
- Added keyboard traversal for header/languages/retry and editor controls, accessible control metadata and visible localized persistence/application/listener errors. Busy Retry is excluded from focus/activation.
- Added finite logind listener restarts, sender/path filtering, suspend cancellation and native-only reconnect. A recovered listener clears its warning without renewing the retry budget.
- Added script-aware Chinese locale fallback and asynchronous local bitmap decoding.
- Reconciled README, handbook, source map and backlog with current behavior. Replaced the tracked agent-directive file with human-facing `DEVELOPMENT.md`. Local hardware research is ignored rather than included in the candidate.

## Six-dimension review

`D` means directly inspected source/output; `I` means an inference with stated limits; `U` means unverified. This is a scoped review, not a security certification.

| Dimension | Evidence and protections | Remaining limits |
| --- | --- | --- |
| Manifest/delivery | D: permanent ID matches manifest, entry point and IPC. Manifest validation passes; all runtime imports/assets/scripts are local and present. No symlinks. MIT license and generated illustration provenance are documented. | U: submitted commit and Marketplace validation do not exist yet. Hardware illustration is not official Logitech artwork/endorsement. |
| Processes/privileges | D: `ErgoModel.qml` uses discrete argv for managed helpers; shortcut operands use `shellQuote`. User Command mode is intentionally executable. Client checks root ownership/modes of the helper and ancestors; policy permits `auth_admin` only in the active session. Root helper uses fixed paths, bounded operations and a recovery journal. | D: GPT-5.5 reviewed the unchanged privileged boundary; its test-isolation finding is fixed and rechecked. U: real enable/restore/hotplug acceptance. Custom commands and plugin code execute unsandboxed as the user. |
| Timers/cadence | D: battery telemetry is reactive. Slider/save timers are one-shot debounces; settings queue and watchdog are finite. Resume attempts are at about 2 and 12 seconds, guarded against overlap and cancelled on connection. Controller status refreshes on panel open/adapter change. | U: actual suspend/resume and a long-duration lifecycle run. Listener exit/start failure receives at most three retries at two-second intervals; sleep gates new work and cancels the current settings helper. |
| Resilience/data | D: preference types/ranges/bytes are checked before use; atomic writer preserves old file on tested failures. Child output is capped while reading. Ambiguous HID identity is rejected and stale BLE battery presence does not imply connection. | U: fresh hardware charge or health cannot be established. Read/write/apply/listener failures are visible in localized panel text; save/apply retries use existing serialized queues. |
| Memory/lifecycle | D: queues retain one pending item; native model delegates are removed on object removal; processes are owned by the QML model. Child cancellation is exercised with a real subprocess. | U: shared-shell memory/RSS over long sessions, forced termination during a preference write and full plugin disable/re-enable/removal lifecycle. A pending 500ms debounce can be lost on shutdown. |
| Theme/displays | D: QML uses host tokens and plain-text labels; `KeyboardPanel` owns popup placement/focus. Actual popup was inspected on one 1920×1080 display at scale 1.6. Qt tests cover narrow and long-label geometry. | U: multi-monitor hotplug, vertical bars, complete native keyboard-only navigation and assistive technology. Current evidence is not a claim of all-theme/all-scale support. |

Localization: ten catalogs and runtime dictionaries agree on all 113 keys. The language picker uses native names and an effective code with a translation symbol. Automated parity does not establish native-speaker review of every translation. Source labels and callouts use plain text; the optional Polkit prompt and helper errors are currently English.

## Static pattern reference matrix

Evidence refers to the working-tree sources frozen by `docs/candidate.sha256`; this table supplements the six dimensions above.

| Pattern area | Observation | Source and limits |
| --- | --- | --- |
| Delivery / MKT-001–003, SEC-009 | Observed protections | `manifest.json`, local imports/assets, no symlinks; no shipped agent directives. `DEVELOPMENT.md` describes contributor behavior. Exact published SHA remains unavailable. |
| Commands / SEC-002, SEC-008, SEC-010 | Observed protections | `ErgoModel.qml` quotes shortcut operands and uses discrete helper argv. Python runs with `-I`; the Bash wrapper uses `-p`. `bluetooth-client.py` checks the fixed root helper. Custom Command intentionally executes as the user. |
| Scheduling / SEC-001, SEC-004 | Observed protections | Model owns native services, finite queues, debounces, sleep listener and watchdogs. Three listener restarts; two reconnect attempts per resume. Config helper has its own deadline. No periodic battery CLI. Actual CPU/energy remains unknown. |
| Input / SEC-005, SEC-006 | Observed protections; remote WebP profile not applicable | Bounded preference/child-output parsing in Python, guarded status JSON, local static QML and PNG/SVG assets. No remote image transport or dynamic QML compilation. No new decoder pipeline needed. |
| Ownership | Observed protections | One pending settings request and one pending preference value; native device delegates follow model lifetime. Teardown cancels owned work. Long-session RSS and abrupt shutdown persistence remain unknown. |
| Displays / SEC-003, SEC-007 | Observed protections; partial runtime evidence | `BarWidget.qml` delegates placement/focus to the installed `KeyboardPanel`; labels use plain text and host tokens. One real display inspected. Multi-monitor/hotplug and native keyboard-only session remain unverified. |
| Localization/accessibility | Observed source coverage; partial runtime evidence | 113 keys in each of 10 catalogs, native names, script-aware fallback, button/checkbox/slider accessibility metadata. Translations used the local fallback workflow and automated parity; no native-speaker or screen-reader signoff. |

## Independent review and admission decisions

The bounded Gemini review used `ninitux/gemini-3.8-flash-high` via the fixed tool-free helper. It reviewed `ErgoModel.qml`, `scripts/config-store.py`, `scripts/apply-settings.py`, and the two Python test files before the final three adjustments below. Returned verdict: **changes_required**. This is not a final reviewer approval of the updated tree.

1. **Accept:** missing preferences could trigger default unbinding on a later `configreloaded`. Reproduced in the production-function test and fixed with `settingsConfigured`. The gate becomes true for loaded valid settings or an explicit settings application, not merely after the loader exits.
2. **Accept as consistency only:** anchor the settings-helper `file://` prefix removal. The supplied URL is a static resolved local source; the reviewer did not establish an important exploitable path. Changed to match the other helper paths.
3. **Accept as lifecycle cleanup:** stop resume timers after connection. The existing connected guard already prevented a second attempt while connected; cancelling also removes the pending timer after success.

The review's numeric line references were inaccurate; findings were verified against named functions and real source before changes. That review did not cover the privileged Bluetooth helper. Two separate Gemini helper-review attempts returned provider-filter refusals, which are not code assessments. The user explicitly authorized one GPT-5.5 read-only review as a routing exception. It found one test-isolation defect: the BASH_ENV wrapper test executed live read-only host diagnostics. The test now copies the exact wrapper beside a temporary stub client and verifies argv and environment isolation. The reviewer rechecked the fix, all 18 profile tests passed, and the scoped verdict is **verified**. Production helper/client/policy/installer hashes are unchanged. See `docs/privileged-review.md`. Live Polkit/controller/udev behavior remains untested.

The final user-session QML/model/UI review via `ninitux/gemini-3.8-flash-high` completed and reported no actionable defects. The coordinator accepts this as scoped source review, not proof of native keyboard accessibility or hardware behavior. Exact supplied hashes and limitations: `docs/qml-review.md`.

## Executed evidence

- `./tests/run.sh`: exit 0, all nine stages. Includes manifest validation, no symlinks/colors, production model/panel/recovery/sleep functions, 18 isolated profile tests, 14 apply-helper tests, five preference-store tests, single-writer queue tests, 113-key parity across ten languages, QML lint, 14 Qt diagram checks and lockscreen fixtures.
- `git diff --check`: exit 0.
- Exported the final 59-file candidate (57 ledger hashes plus ledger/report) into `/tmp/mx-ergo-final-candidate-24ezt8r0` and ran its own `tests/run.sh`: exit 0, all nine stages. The source hash check also passes. This covers delivery-relative paths independently of the development folder.
- Red/green: substituted the old reload condition in memory (without modifying live files); the new missing/corrupt-preferences assertion fails. The current production-function test passes.
- `/usr/bin/python3 -I scripts/config-store.py read "$HOME/.config/omarchy/mx-ergo.json"`: exit 0 on the existing configuration (output intentionally suppressed).
- Optional helper installed through the reviewed installer and Polkit. Source and installed helper SHA-256 both `1d95b9bb06032e3ba87004621936777adaa923393091189b60d81af81989af01`; root:root 0755. Source/installed policy SHA-256 both `7e46dcf220ca03fe3e63002a01ca741c67e871d156a3f17c3a5d95e542d997b3`; root:root 0644. `pkaction` confirms the exact exec path and `auth_admin` active-session policy.
- `scripts/low-latency.sh --status -`: exit 0, helper available, state `legacy`, no new managed profile. The old files and current controller settings were not changed by installation.
- `omarchy restart shell` while unlocked: exit 0. Live log reports model loaded and settings applied with verified button bindings. The approved main panel was inspected earlier (`assets/preview.png`). After the final restart, the plugin was opened through shell IPC; the live button editor was captured and inspected, with no MX Ergo QML errors in the observed log. This does not prove native keyboard interaction.
- Host: Omarchy 4.0.4, Qt 6.11.2, Hyprland 0.56.2 (`efb50993780079460b0cbed1363e2166a2de1d9f`). One display, scale 1.6 at capture time.

## Pre-submission actions

1. Retain the completed independent source reviews (`docs/privileged-review.md`, `docs/qml-review.md`) and their scope limits. Reopen review only for relevant source changes.
2. Perform native keyboard/language navigation and relevant display/lifecycle acceptance. Native synthetic input was unavailable in this session; isolated Qt tests are not a substitute.
3. Test optional profile enable/restore/reapply on an authorized adapter. On this machine the old rules lack a baseline; migration requires their explicit cleanup and a computer restart before a new baseline can be saved. Installation did not perform this migration.
4. Freeze a local commit covering the candidate, verify the exact snapshot, then obtain approval for its GitHub push and Marketplace submission. Recheck the live publishing guide at that point.
