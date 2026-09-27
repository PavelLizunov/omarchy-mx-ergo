# MX Ergo review matrix

Project example for the shared Omarchy plugin design-review procedure.
The general rules belong to `omarchy-plugin-patterns`; the installed extension is
in [the integration proposal](omarchy-design-review-proposal/README.md).

Use this as a selectable acceptance matrix. Full panel reviews cover every row;
focused changes cover affected rows and explain exclusions. Expectations come
from `DESIGN.md` and current behavior, not from fixture dimensions alone.

## Tasks and observable outcomes

| Area | Exercise | Expected outcome |
| --- | --- | --- |
| Context | Open Buttons, Pointer and Device | Page, active profile and selected button have distinct roles. Mouse remains primary at its established scale. Global pointer settings are not presented as per-profile settings. |
| Navigation | Buttons→Pointer, Pointer→Buttons, Buttons→Device, Device→Buttons, Pointer→Device, Device→Pointer | With unchanged external geometry, requested frame, navigation position and mouse scale remain stable. Content changes inside the appropriate column. |
| Editor | Open each of five controls; switch controls; close and reopen | Mouse/profile context persists. Reopening uses the saved assignment/category. Unapplied drafts follow the documented discard behavior. |
| Modes | Action/category, shortcut, function keys, command, Default | Modes, categories and actions are distinguishable. Browsing/category changes do not save. Explicit assignment actions perform their documented writes. |
| Feedback | Draft→applying→saving→saved; application or storage error→Retry; newer queued choice | Feedback refers to the current choice. Success requires latest helper verification and confirmed storage. Old success cannot certify a pending/failed update. |
| Dismissal | Close, Escape, repeated callout/hotspot, blank primary click; nested popup; text selection, drag, scroll | Closing is reachable. A popup consumes its own dismissal. Fields, text selection and scrolling do not accidentally dismiss the editor. Focus and recording follow the current contract. |
| Profiles | Select, Add, Manage, rename/delete, global switching shortcut | Names/context are clear; uncommon operations are disclosed. Test mutations with an inert model. Protect existing profiles and final-profile constraints. |
| Pointer/Device | Sensitivity, acceleration, natural scroll, auto reconnect, recovery/cancel and diagnostic information | Controls work in the fixture; wrapping does not cover content. Cancellation remains reachable. UI appearance does not prove physical input or radio recovery. |
| Scroll/focus | Long management form, telemetry, error and language selection; keyboard navigation | Header/navigation stay fixed. Focused control is visible. Right-column navigation does not scroll the mouse. Opening/closing forms does not resize the frame. |
| Text | All supported locales on changed pages; longest labels, CJK, user names/commands | No inaccessible clipping, overlap or hidden action. Reactive translation does not write settings. User data/machine tokens remain unchanged. Key completeness does not prove translation fluency. |
| Host fit | Screen edges, bar positions, fitted frame, editor open/closed | Internal layout remains bounded; host placement follows its actual installed contract. Source-function geometry checks do not prove live Wayland placement. |

## Appearance and accessibility

- Inspect hierarchy, grouping, alignment, spacing, legibility, selected/hover/focus/
  disabled/error states and visual versus actual hit areas. Avoid claims based
  only on a contact sheet; inspect originals at usable size.
- Use existing normal and constrained 620×450 fixture cases as regression points.
  They are logical fixture dimensions, not a universal supported-screen minimum.
  Include relevant host scaling/font settings if the permitted harness supports
  them; otherwise record their absence.
- Measure text contrast using actual palette/state values, including opacity.
  [WCAG AA's contrast thresholds](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html)
  are 4.5:1 for normal text and 3:1 for large text; use them as reference criteria,
  record applicable exemptions and the native UI adaptation. A single fixture
  palette does not certify arbitrary Omarchy themes or all control states.
- WCAG 2.2's pointer target minimum is 24×24 **CSS pixels**, with exceptions;
  it is not a universal 44-unit desktop rule or an automatic conversion to QML.
  The project uses at least 34 scaled units for primary controls. Measure actual
  hit areas, spacing and scale; inspect small hotspots as well as visible buttons.
- Exercise keyboard entry, movement, activation and Escape through the host's
  actual contract. Check visible focus and return focus. Record Tab/Shift+Tab,
  arrows, Return/Space and popup behavior individually where applicable.
- Inspect accessible names/roles in source; screen-reader behavior requires an
  actual accessibility consumer. Source attributes alone do not establish it.
- A short permitted live recording is needed for animation/temporal placement
  claims. Static captures show settled states only. No animation change means
  no requirement to create an unrelated recording campaign.

## Evidence surfaces

| Surface | Can establish | Cannot establish by itself |
| --- | --- | --- |
| Source review | Contracts, dependencies, semantics, likely faults | Visible runtime outcome |
| QML capture | Actual consumer layout/text in a stated fixture | Live theme I/O, native placement, physical input |
| Qt consumer interaction | Click/key/scroll outcome with inert model | Production helper/hardware outcome |
| Host-source geometry | Fitting/origin behavior for specified inputs | Compositor timing or external geometry changes |
| Live shell state/log | Loaded candidate and observed model status/errors | Mouse movement, complete visual/a11y quality |
| Permitted native capture/interaction | Observed desktop state/transition | All themes/devices or unexercised timing |
| User observation | Reported behavior on that task/device | Independent instrumented measurement |

Record date, candidate identity, source/test dependencies, host/theme/scale,
fixture versus live model, steps, expected and observed outcomes, command exit
status, inspected artifact paths and limitations. For reused evidence, say what
still matches and which dependencies were not matched. HEAD alone is inadequate
for this dirty working tree. Historical sections of the verification log are
chronological; earlier compact-page claims are superseded by later corrections.

## Existing verification routes

Run from the repository root when relevant and authorized:

```bash
bash tests/run.sh
python3 -B tests/profiles-ui.py --capture-states .git/mx-design-review-states
```

Use a fresh candidate-specific capture destination instead of overwriting prior
evidence. `--capture-states` runs consumer tests and writes actual QML state PNGs;
it is not an Omarchy capture MCP. The runner copies installed host controls and
isolates theme I/O while rendering with offscreen/software Qt and inert operations.
It does not launch a second shell. A render run does not replace the full required
implementation gate or image inspection.

Relevant owning checks:

- `tests/profiles-ui/tst_editor.qml`: frame/page transitions, editor/dismissal,
  feedback, locale bounds, recovery cancellation and Pointer/Device interactions.
- `tests/profiles-ui/tst_profiles.qml`: profile controls and management flows.
- `tests/panel-scroll.js`, `tests/panel-navigation.js`: production navigation and
  installed host fitting/origin contracts.
- `tests/i18n-completeness.js`: catalog/runtime keys, placeholders and fallback.

A new behavior may need a focused regression that fails on the old consumer.
Do not add tests merely to match instruction wording or increase a count.

## Decision and finding format

`PASS` requires observed evidence for that criterion and surface; `FAIL` requires
an observed violation; `NOT VERIFIED` identifies unavailable or missing evidence;
`N/A` includes a scope reason. A partial fixture pass cannot be promoted to a
full native pass. Findings may be hypotheses until reproduced.

Prioritize by impact: P1 blocks a task, loses assignments or shows false success;
P2 causes navigation/focus/geometry/legibility problems; P3 is a minor consistency
or preference improvement. State preference explicitly.

```text
Criterion / surface / status / evidence / remaining gap
Finding: priority; task; state→transition; steps; expected; observed;
source or inspected image; smallest correction; confidence/limits
```
