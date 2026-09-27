# Button profile presentation verification — 2026-09-27

## Scope

Reviewed against exact pre-revision copies in `.git/mx-profile-design-baseline`,
not against HEAD, which also includes earlier Bluetooth/battery/profile work.
Native QML presentation changes only: profile hierarchy and disclosure, shared
control sizing, page navigation and category/action selection. No model, helper,
Bluetooth operation, profile schema or command behavior changed in this revision.
The user selected SL UI Library as a visual reference; its skill and native web
navigation previews were inspected. No library source package was integrated.

## Evidence

- `bash tests/run.sh`: exit 0; full repository gate, including 47 isolated Qt
  results for the revised profile manager and actual ErgoPanel consumer.
- `python3 -B tests/profiles-ui.py`: exit 0; profile CRUD/cancel/record/clear/apply,
  busy controls, dropdown and Tab, plus all 18 preset actions, category keyboard
  selection without assignment, successful choice returning to the diagram,
  bulk-switch control visibility and Escape. Profile layout bounds cover 10 locales
  at widths 280/380. Tests use inert model operations and never write live settings.
- `python3 -B tests/profiles-ui.py --capture-panel .git/mx-profile-design-overview.png`:
  exit 0; actual full-panel and editor QML renders were inspected for hierarchy,
  clipping, spacing and consistent sizes. Mock names/status belong to the fixture.
- `git diff --check`: exit 0.
- Default fixture palette contrast: foreground/background 11.56:1; secondary text
  composed over the background 8.58:1. This does not measure all hover/selection
  states or every user theme.

A focus check found that focusing the Dropdown wrapper bypassed its focusable
trigger. The profile entry path now focuses the real trigger; regression passed.
The dropdown row height is set through its native `rowHeight` contract, ensuring
it matches the Add control rather than only expanding the wrapper.

Test output and tested implementation hashes are in `.git`, outside distributed
plugin source. Source review was direct; no independent reviewer signoff.

## Consumer and remaining limits

Before activation, the running plugin reported two profiles with active TTS/STT,
the five existing assignments and no load/application error. Current preferences
SHA-256: `9c7420a34246766f9c5b59495815a93ce8815405d8b648a585d0d5c5cde73544`.
The existing legacy migration baseline is no longer the live configuration;
user-created profiles must be preserved.

The session became locked during final checks. Activation is pending an unlocked
session under DEVELOPMENT.md's shared-shell safety guard. No restart was attempted
while locked. The running shell has not yet been verified to load this presentation
revision. Native desktop control is unavailable; offscreen Qt checks do not verify
live theme I/O, hardware clicks, screen readers or other desktop hosts.

## Delivery gate

- PASS: clear profile/assignment/category hierarchy; native theme tokens; matching
  control heights and wrapped labels; working controls in the exercised Qt paths.
- PASS: calm design direction, deliberate grouping and native hover/focus motion.
- NOT VERIFIED: every production palette/state, native desktop interactions and
  activation while the session remains locked.
- PASS: prose is tied to executed checks; no source-integration or native-UI claim.

Local commit remains deferred because earlier uncommitted work shares these files.
No remote publication, configuration edit or Bluetooth mutation was performed.

## Compact correction and activation — 2026-09-27

User feedback identified excessive vertical length. The normal overview now has
five assignment rows; Diagram replaces them with a smaller physical map on request.
Manage also discloses the global shortcut. The supported KeyboardPanel height API
caps the whole popup at 80% of available card height, retaining internal scrolling.
The normal inert Qt fixture renders at 380 × 540 rather than 380 × 812.

`bash tests/run.sh` exited 0 on this final revision, including 48 Qt results. The
additional consumer check verifies compact height, five reachable rows, optional
diagram callout editing and return to the list. Cursor-scroll regression and QML
lint passed. The final isolated QML overview image was inspected.

The earlier pending activation is resolved. Session lock status was unlocked;
one supported `omarchy restart shell` exited 0, then the plugin's existing open
route exited 0. Fresh shell log `/run/user/1000/quickshell/by-id/ydfps2szlt/log.log`
reported model loading and successful assignment verification without errors in
these UI components. `profileStatus` retained two profiles, active TTS/STT and the
same five action IDs, with no busy/load/application error. Preference SHA-256
remained `9c7420a34246766f9c5b59495815a93ce8815405d8b648a585d0d5c5cde73544`.
Native visual interaction, screen-reader behavior and hardware clicks remain
unverified; the image is an isolated render, not a live desktop capture.

## Mouse-first correction — 2026-09-27

The compact list revision is superseded by explicit user direction: the mouse
must remain the primary overview at its original width. Restored TrackballMap to
full panel content width and placed profiles after the complete illustration.
Removed the view toggle/list and its unused labels. The image remains 70% of map
width, with its original 1.5 aspect ratio and hotspot coordinates. Reduced only
the upper diagram gap; battery details and idle recovery tools belong to Device,
while active recovery cancellation remains available across pages. The header
shows short profile context. Overview gaps are smaller; the native popup is capped
at 95% of available card height with its existing internal scrolling.

`bash tests/run.sh` exited 0 on the final implementation. Actual Qt checks verify
unchanged illustration width, the complete image preceding profile management,
all five callouts, editor return, Device recovery availability and a normal
content height at most 650. Cursor order now follows diagram then profiles.
Trackball geometry/hotspot/connector tests passed. The actual isolated overview
render was inspected: 380 × 644, compared with the earlier 380 × 812. Native image
scale is preserved; the shorter height comes from layout around the mouse.

An unlocked session allowed one supported shell restart (exit 0) and plugin open
(exit 0). Fresh log `/run/user/1000/quickshell/by-id/2meswquzlt/log.log` reported model
loading and successful assignment verification, without errors in the edited QML.
Immediately before and after activation, profileStatus reported two profiles,
active Main and the same five action IDs, with no busy/load/application error.
The latest pre-activation preference SHA-256 was preserved:
`77fec8c85ba20307d1b03539917f1bf7a58a60b21355b114a3e196d9fe26d1a4`.
This replaces the older configuration snapshot; no earlier selection was restored.
Native visual interaction and hardware remain outside the isolated Qt evidence.
No Bluetooth operation or system configuration edit was performed.

## Adjacent assignment editor — 2026-09-27

The replacement editor is superseded by the user's request to retain context.
The real consumer now keeps the mouse, profiles and tabs visible and adds a right
editor column. Opening/saving does not reset overview scrolling or image scale.
The selected physical control is highlighted. Save stays in place; Close/Escape
dismisses the editor and returns keyboard focus to the map. Choosing another
control reloads saved values, discarding unapplied drafts; a profile/page change
closes the editor. The host passes its actual content insets so widening the card
cannot change the overview's original width. Only presentation/focus changed.

The repository gate exited 0 (`.git/mx-aside-verification.log`, 51 profile/editor
Qt results); the final capture run exited 0 with 27 consumer results. Eleven actual
QML states were inspected under `.git/mx-aside-states`: Buttons, two assignment
categories, category popup, shortcut, expanded F-keys, command, Pointer, Device,
profile management and global shortcut. Normal renders are 380x644 and 736x644
while editing. Native test interactions cover retained geometry/context, category
browsing, all 18 choices, independent scrolling, drafts, profile changes and Escape.
The fixture uses inert operations and installed theme/control sources; these are
isolated QML renders, not desktop captures. Live compositor placement, other screen
sizes, theme variations, screen readers and physical mouse inputs are unverified.

The local shell automatically reloaded the watched installed plugin as source and
repository evidence changed. An initial lock-status request briefly failed, then
returned unlocked; no supported or manual shell restart was issued this turn.
The existing plugin-open IPC returned 0. Model load and assignment verification
were observed in `/run/user/1000/quickshell/by-id/2meswquzlt/log.log`; no edited-QML
errors were observed. Existing startup recovery also ran after automatic reloads
while the saved mouse was disconnected; no manual Bluetooth operation was issued.
This illustrates a development-host limitation: repeated file changes under the
installed plugin can retrigger existing lifecycle work.

The latest pre-activation snapshot, rather than an older selection, is the
preservation reference: two profiles, active TTS/STT, unchanged five action IDs,
no profile/load/application error; preference SHA-256
`9c7420a34246766f9c5b59495815a93ce8815405d8b648a585d0d5c5cde73544`.
Implementation hashes are in `.git/mx-aside-snapshot.json`; earlier unrelated
uncommitted work is preserved, and a covering commit remains deferred.

## Design issue 1: profile context — 2026-09-27

Moved the existing profile controls from below the illustration to directly below
Buttons navigation. The selector now sets the context before the five assignments.
The general hero shows connection context instead of repeating the profile name.
Keyboard overview traversal follows profiles, then the diagram. No model, helper,
Bluetooth, schema, control sizing or image geometry changes. Existing profile
Add/Manage forms and transactions are preserved.

The change was prepared and checked in a separate candidate, so test iterations
did not rewrite the active plugin. The new consumer test failed against the old
layout (52 passed, 1 failed), then passed after relocation. The repository gate
exited 0 with 53 profile/editor Qt results; capture runs exited 0 with 29 consumer
results. Actual profile-picker keyboard interactions verify switching while
editing, discarded draft isolation, rejection retaining the old profile/editor,
and a disabled picker while busy. Geometry checks verify the selector precedes
assignments, image width is unchanged, and overview height remains at most 650.

The actual isolated overview, adjacent editor, management, global shortcut and
expanded function-key states were visually inspected. Normal overview/editor
renders remain 380x644 / 736x644. Full current-screen placement, actual hardware
input and screen-reader behavior are not certified by these isolated QML checks.
The pre-installation live reference is two profiles, active TTS/STT, five unchanged
action IDs and no application errors; preference SHA-256
`9c7420a34246766f9c5b59495815a93ce8815405d8b648a585d0d5c5cde73544`.

## Design issue 3: assignment feedback — 2026-09-27

The editor now labels the selected assignment, keeps draft guidance separate, and
shows applying, saving, confirmed success or explicit failure with the existing
Retry action. Pending includes debounce and queued work. Success requires the
latest helper readback and confirmed preference storage; an older successful
helper cannot certify a newer choice. Existing profile/assignment commands,
configuration schema, mouse geometry and Bluetooth behavior are preserved.
`profileStatus` adds read-only verification/persistence fields for diagnosis.

The source was prepared in an isolated candidate. New consumer checks against
the old panel failed (53 passed, 13 failed: missing feedback controls); the final
repository gate `bash tests/run.sh` exited 0, including 66 profile/editor Qt
results, 14 TrackballMap results and QML lint. Production-function tests cover
stale success, current failure/retry, settings debounce/queues, queued newer
preferences and failed/successful writes. Consumer tests exercise drafts, actual
Apply/Enter controls, errors/retry, storage gating and 10 locale layout bounds.

`python3 -B tests/profiles-ui.py --capture-states feedback-states` exited 0 with
42 Qt results. Actual isolated renders of draft, applying, saving, saved and error
were inspected. The sidebar keeps its independent scrolling; overview remains
380x644 and editing 736x644 in the Russian fixture. Tests verify unchanged mouse
scale and bounded normal height. The inert model, isolated theme and software Qt
renderer do not certify native screen placement, hardware events or accessibility.
Review was direct, not an independent reviewer signoff. A local commit remains
deferred because earlier uncommitted features share the edited files.

## Assignment editor dismissal — 2026-09-27

Repeated selection of the same callout or physical hotspot now dismisses the
editor; another button still switches it. Primary clicks on unused background
also dismiss it. Background handlers sit below controls; editor content has a
shield, movement cancels dismissal, and a per-press popup guard prevents one
outside click from closing both a nested dropdown and its editor. Existing
Close/Escape, draft discard, recording cancellation and map focus are reused.
No model, settings helper, Bluetooth, schema or geometry changes.

The isolated old panel failed the new dismissal checks (67 passed, 3 failed).
`bash tests/run.sh` exited 0 on the final candidate: 70 profile/editor Qt results,
14 TrackballMap results and QML lint. Actual controls exercise callouts/hotspots,
blank primary/secondary clicks, draft reopening, fields/text selection, action
choices, held popup-dismissal presses, keyboard popup closure, profile popup,
gutter drags, actual editor scrolling at height 450, recording and Escape.

`python3 -B tests/profiles-ui.py --capture-states dismiss-states` exited 0 with
46 Qt results. Actual before/after background-dismissal renders were inspected;
736x644 returns to 380x644 with unchanged mouse width and assignment. These use
inert models/software Qt and do not certify native pointer placement, screen
readers or hardware. No native capture/Omarchy render MCP is available through
this host's tools. Review is direct; no independent reviewer signoff. Installed
activation evidence and source hashes are retained under .git. A covering commit
is deferred because prior uncommitted features share these files.

## Design issues 2/4/5/6 and translations — 2026-09-27

Buttons now reserves its two-column card before selection, with localized guidance
in the empty editor space. Opening/closing preserves requested width and mouse
scale; Pointer/Device remain compact. Larger callout text uses full preset names,
while arbitrary user commands/shortcuts retain bounded summaries. The editor labels
assignment type, action category and available actions. Close has a visible label
and an editor-specific Esc tooltip; previous dismissal gestures remain. Reopening
a button restores the category of its saved action, even after browsing elsewhere.
Category navigation and language changes do not write assignments.

The candidate was isolated from the watched installed plugin. The initial stable
width/prompt check failed against the old source (70 passed, 1 failed); final
`bash tests/run.sh` exited 0 with 83 profile/editor Qt results, 14 TrackballMap
results, QML lint and the model/configuration/recovery/sleep/lock checks.
`python3 -B tests/profiles-ui.py --capture-states finish-states` exited 0 with
59 consumer Qt results. Evidence and final source hashes are retained under
`.git/mx-design-finish-evidence` after installation.

Translation checks cover 177 catalog/runtime keys in each of ten locales, exact
key sets, nonempty strings, Unicode, static UI key references, existing positional
%1 replacements and supported/unsupported language fallback. Actual consumer
checks exercise all 18 preset labels across ten locales and five callouts, dynamic
retranslation without writes, narrow editor bounds and visible translated Close.
Russian Play/Pause, abbreviated workspace/window/media/tab names and shortcut
wording were corrected. Standard keyboard identifiers and user profile names
remain data. Changed non-English/Russian units use local translation fallback and
AI review; there is no independent fluent-human translation signoff.

Actual QML renders of overview/editor in all ten locales, category menu/system,
draft/applying/saving/saved/error, shortcut/function keys/command, Pointer/Device
and profile management/shortcut were visually inspected. The Russian normal
overview/editor fixture is 736x646 with unchanged image width. Long editor or
management forms use existing scrolling. Tests evaluate the actual installed
host cardOrigin and width fitting across screen edges and four bar positions;
unchanged inputs give the same origin on editor activation/dismissal. This does
not certify native Wayland positioning under every external geometry/theme/state
change. The isolated inert model/software renderer is not a live desktop capture,
hardware event test or screen-reader review. Review was direct. A covering local
commit remains deferred because earlier uncommitted work shares these files.

## Full page-frame correction — 2026-09-27

The earlier issue-6 scope covered only assignment open/close: Pointer/Device still
requested 380-wide cards and their shorter bodies resized the popup. Device battery
and recovery content appeared before navigation, moving the tab row. This failed
the user's expected stable navigation. A new consumer check reproduced the page
width change against the installed version (83 passed, 1 failed).

All pages now request the same scaled 736x650 frame. Header/navigation are outside
scrolling content. The original mouse and button-profile context persist on the
left; Pointer/Device use the same right column as the editor. Recovery is in the
right header; active cancellation remains reachable on other pages and while
editing. Existing model/helper/settings/Bluetooth operations and saved data are
unchanged. Keyboard navigation includes shared context and scrolls the appropriate
column. Language choice/forms/status can add scroll content without resizing.

`bash tests/run.sh` exited 0 with 96 profile/editor Qt results, 14 TrackballMap
results, QML lint and all repository checks. Actual tab clicks cover page pairs;
normal mouse geometry and navigation/frame size remain equal. Forms, language,
errors and actual wheel scrolling leave header/navigation fixed. Real Pointer
controls use inert setters; keyboard Device focus scrolls long telemetry into the
right viewport without scrolling the mouse. Ten locale checks use 620x450 bounds
for all three pages. Production-function checks evaluate the actual installed
host width/height fitting and cardOrigin for all pages/editor states, screen edges
and four bar positions. No host package/source changes are made.

Rendering uses the existing real QML consumer with inert operations. Native
Omarchy capture/render MCP is not connected in this session: callable-tool search
found no such capability; local MCP configuration lists only node_repl/homelab_obs.
The patterns skill contains a QML rerender procedure rather than a callable MCP.
These renders and host-source geometry do not certify live Wayland transitions,
screen-reader operation, animation timing or every theme/scale. Direct review is
not independent reviewer signoff. Logs, inspected renders and exact source hashes
are retained under `.git/mx-stable-pages-evidence` after activation. A covering
local commit remains deferred because earlier uncommitted features share files.

For the narrower right column, acceleration/recovery reuse the existing wrapping
ErgoControl. Ten locale checks inspect actual caption Text bounds; longer recovery
headers reserve their height above right-column content. Recovery cancellation is
exercised on all pages and while editing with inert callbacks. The fixture battery
label follows localized battery_normal instead of a fixed Russian example; the
production battery model is unchanged.

The final capture command exited 0 with 72 consumer Qt results. Full Russian
Buttons/Pointer/Device/editor, draft/saved/error/category/command/function-key and
profile-management/shortcut renders were inspected. Pointer/Device right-column
renders in all ten locales were also inspected at exact pixel size in review
strips assembled from unchanged original PNGs. Each normal state is 736x650.
The reviewed snapshot contains no locale/catalog, model, helper or stored-profile
changes. Activation evidence is separate from these inert-model render results.
