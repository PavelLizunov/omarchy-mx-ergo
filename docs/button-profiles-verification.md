# Button profiles verification — 2026-09-26

## Scope and result

Implemented the approved [profile specification](button-profiles-sdd.md) in the
installed user-owned plugin checkout. The starting tree was dirty at `7e968c0`;
existing Bluetooth, battery and screenshot work was preserved. Feature review
compared the edited QML files against their exact pre-task contents, rather than
attributing all changes against HEAD to this feature.

Verified in scope: profile migration and independent assignment sets; candidate
application and bounded rollback; deletion/retry and busy/stale-result guards;
global shortcut parsing and foreign binding protection; wheel pulse admission;
atomic v2 persistence; profile management controls and keyboard recording.

## Executed checks

All of these exited 0 on the final source snapshot:

- `bash tests/run.sh`: manifest validation, source/tree guards, all existing
  model and helper checks, localization, QML lint, Qt interaction and lock guards.
- `node tests/button-profiles.js`: production QML functions for migration,
  independence, commit/rollback, queue, persistence, shortcuts and wheel latch.
- `python3 -B tests/config-store.py`: 7 checks, including v2 shapes, count/byte
  limits, Unicode roundtrip and preservation of previous files on failure.
- `python3 -B tests/test_apply_settings.py`: 17 checks, including conflict-before-
  mutation, callback handle ownership, release flags and bounded execution.
- `python3 -B tests/profiles-ui.py`: 25 Qt results, including creation, rename,
  delete, draft cancellation, dropdown/Tab navigation, recording and clear/apply,
  plus layout bounds for all 10 locales at widths 280 and 380.
- `python3 -B tests/profiles-ui.py --capture .git/mx-profile-ui-preview.png`:
  an additional capture check; the actual QML image was inspected for clipping,
  wrapping and contrast. It is an isolated fixture, not a live desktop capture.
- `git diff --check`: no whitespace errors.

The first narrow French recorder check found an overflow. Wrapped button labels
fixed it; the affected layout checks and the complete repository gate then passed.

## Installed consumer path

Loaded the final source with the supported local shell restart while unlocked.
The shell logged `MX Ergo: named button profiles v2 ready` and successful binding
verification. `profileStatus` reported one `main` profile named `Main`, the five
original action IDs, no busy operation, and no load/application error. The
original open route still opened the panel. `nextProfile` with one profile was a
safe no-op. Existing preference bytes and mouse-binding descriptions, modifier
masks and submaps matched the pre-task snapshot. Startup did not rewrite the
legacy preference file. New schema persistence was tested in isolated fixtures.

Tested implementation hashes were unchanged at the installed verification step.
Full check output and internal before/after evidence remain in `.git`, outside
the distributed plugin sources. No publication or remote push was performed.

## Limits and review

Direct source and command-boundary self-review; no independent model signoff.
Native desktop control was unavailable. Qt tests use the installed shell controls
with inert copies of theme tokens because Quickshell's embedded core plugin is
not loadable by qmltestrunner. These checks do not verify live theme I/O, hardware
button presses, screen-reader behavior, or compatibility on other hosts. Locale
key/parity and layout checks passed; new translations have no fluent human review.

The live user configuration was not populated with test profiles or a test hotkey.
Actual multi-profile switching through the mouse and keyboard remains a hardware
acceptance check. Readback cannot decode a Hyprland Lua callback to prove its
external command ran. The inherited global scope of mouse bindings remains.

Local commit is deferred: shared files also contain earlier uncommitted work;
this feature has not been combined with that work into a commit.
