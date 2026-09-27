# Button profiles

## Intent and invariants

Provide named independent sets of the five existing button assignments. Migrate
every existing preset, shortcut and command into Main without loss. Pointer,
battery and Bluetooth behavior remain shared. Use the existing shell and bounded
settings helper; no additional dependencies, polling or privileged operations.

## Behavior and data

- Preferences v2: `version: 2`, `profiles`, `activeProfileId`, `profileShortcut`,
  plus the existing general preferences. Each profile has a stable ID, editable
  name and complete `buttons`, `customShortcuts`, `customCommands` maps.
- Maximum 32 profiles, names 1–80 characters, existing field limits and 64 KiB
  total serialized preferences. Invalid data never triggers default application.
- Buttons page: selector, Add (independent copy), Rename and Delete. The last
  profile cannot be removed. Active deletion first verifies a neighboring profile.
- `profile_next` cycles in list order through the same model path as the selector
  and `omarchy-shell io.github.pavellizunov.mx-ergo nextProfile`. A separate global
  keyboard shortcut is optional, initially empty, and can be recorded or typed.
  Mouse switching can be assigned to the same button across all profiles.
- Physical switch bindings run on release, without repeat. Horizontal wheel axes
  have no release event in Hyprland 0.56.2; their IPC wrapper latches until 750 ms
  without another pulse. Duplicate aliases are coalesced by a 250 ms cooldown.
  A switch already in progress admits no
  second switch or button edit. All five assignments apply in one Lua request.
- Commit active selection only after helper verification. Failure attempts one
  bounded rollback to the previous selection; rollback failure leaves an explicit
  unverified state. No success claim follows a stale generation or failed helper.
- Keyboard conflicts cause no replacement of foreign bindings. Cleanup checks
  the plugin description, release behavior and callback ID against a plugin-owned
  Lua binding handle. Hyprland exposes callback IDs, not command text, in readback.
- Last selection persists and is reapplied on Hyprland reload. Existing global
  mouse-bind scope remains documented; this feature does not make binds per device.

## Verification

Check migration/roundtrip, profile independence and deletion, keyboard parsing and
conflicts, generated release bindings, successful commit, failed target/rollback,
busy and stale results, persistence and reload. Run the repository checks; use
isolated mocks for binding mutations. Confirm the installed shell loads the new
entry point and preserves its original assignments. Native UI/hardware interaction
is a separate evidence boundary when computer control is unavailable.

## Presentation revision — 2026-09-27

Preserve the profile data, assignments and application transaction. Separate
profile selection from physical button assignments with visible headings and a
divider. Manage reveals rename/delete; the global switching shortcut has its own
label and saved-value summary. Forms separate record/clear from cancel/apply.
Controls use a shared minimum height of 34 scaled units and wrap long labels.
The category selector navigates the preset catalog without applying anything;
one full-width action row emits the explicit assignment. Opening the editor
selects the current action's category. The host yields keyboard ownership to an
open category popup. Escape and successful choice retain the existing return path.

Check all 18 preset actions through the real consumer QML panel with inert model
operations, category keyboard selection, bulk-switch visibility, Escape and return
to the diagram. Retain profile CRUD/draft/recording and 10-locale narrow-layout
checks. Inspect actual isolated QML renders, then load the installed source only
while the session is unlocked. Isolated renders do not prove live theme I/O or
hardware input.

### Compact overview correction

Default to five assignment rows. Diagram is a reversible presentation toggle,
replaces the list, and still opens the same editor from physical callouts. Leaving
an editor returns to the compact list. Move the global shortcut launcher under
Manage. Cap the popup through KeyboardPanel's supported height API at 80% of the
available card height; long content stays in the existing internal Flickable.
Preserve profile contents and all assignment/setter paths. Verify compact normal
height, all five rows, diagram/callout editing, Escape and existing cursor scroll.

### Mouse-first correction (supersedes compact list)

The user requires the beautiful mouse to be the primary overview at its original
width. Restore full-width TrackballMap by default, then profile controls below it.
Remove the list/diagram toggle. Preserve image aspect ratio and hotspot calibration;
only reduce the gap above the illustration. Put detailed battery and idle recovery
tools on Device, retaining active recovery cancellation across pages. Short profile
context remains in the hero. Reduce overview gaps and cap total popup height at
95% of available card height. Existing scrolling handles long forms or small screens.
Verify unchanged image width, full mouse preceding profiles, five callouts, editor
return, Device recovery availability, bounded normal height and cursor order.

## In-place assignment correction (2026-09-27)

Intent: selecting a physical control must retain the mouse and current profile.
Keep the original overview width and image scale; open a separate editor column
on its right. Widen only while editing, fit the host screen, and scroll the editor
independently without increasing popup height. No Bluetooth or model changes.

Contract: clicking another physical control loads its saved assignment and
discards unapplied drafts. Explicit choices update the assignment while the
editor remains open. Close/Escape discards drafts and returns keyboard focus to
the selected mouse control. Changing page/profile closes the editor. Existing
recording, categories and profile transaction guards retain their behavior.

Verification: render actual consumer QML before/after and exercise selection,
category browsing, save, close, draft switching and profile changes. Assert
unchanged image geometry, visible profile context and bounded independent
scrolling. Run the repository gate, then inspect supported shell activation.
Offscreen rendering does not certify live compositor placement or hardware input.

## Design issue 1: profile context (2026-09-27)

Intent and invariants: make the active profile and selector visible before
assignments, preserving the original mouse size, five callouts, native controls,
normal panel height and existing profile transactions. No Bluetooth/model changes.

Contract: place the existing profile controls immediately under Buttons navigation
and above the mouse. Remove the duplicate profile name from the general hero.
Keyboard traversal follows profiles, then the diagram. Add/Manage retain their
existing forms. Selecting a new profile closes the editor and discards its draft
only when activeProfileId changes; a rejected switch retains the old selection.

Verification: use the real consumer's profile picker to switch while editing;
check draft isolation, rejected/busy selection, top-of-section geometry, unchanged
image scale and normal height. Inspect overview/editor/profile form renders and
run the repository gate in an isolated candidate before updating installed files.

## Design issue 3: assignment feedback (2026-09-27)

Intent and invariants: make the selected assignment, unapplied draft and actual
application/persistence result readable in the adjacent editor. Preserve mouse
geometry, profile context, explicit Apply/Enter, bounded helper/write queues and
all existing Bluetooth behavior. No new process, timer, dependency or disk schema.

Contract: label the requested assignment separately from its status. Typing,
recording, chips and Clear only change drafts; mode/category browsing writes
nothing. Presets/Reset apply immediately; shortcuts/commands require Apply/Enter.
Busy feedback includes debounce, queued requests and running workers. Confirm
applied-and-saved only after the latest settings generation passes helper
readback and preferences were loaded or successfully written, with no pending
write/application or load/save/application error. A stale helper success never
confirms a newer choice. Failed application or persistence stays explicit and
uses the existing Retry path. Loading/defaults without confirmation are unverified.

Verification: exercise real model functions for stale success, current failure,
latest success and queued/failed/retried writes. Exercise real consumer controls
for drafts, Apply/Enter, presets, pending/success/errors/retry and profile changes.
Inspect isolated QML feedback states, retain geometry/height checks, run the
repository gate in a candidate, and preserve latest live preferences on loading.
Offscreen fixtures do not certify hardware button actions or compositor placement.

## Assignment editor dismissal (2026-09-27)

Intent and invariants: dismiss the adjacent editor without aiming at the close
icon. Keep the whole shell popup, mouse scale, explicit saves and existing
Close/Escape behavior. No model, Bluetooth, persistence or host changes.

Contract: clicking the selected callout or physical hotspot again closes the
editor; choosing a different button continues to switch its content. A primary
click on unused panel background closes only the editor. Editor content, fields,
controls, text selection and scrolling are protected. An open category/profile
popup owns the first outside click. Dismissal cancels recording, discards unapplied
drafts and restores map focus without applying anything or moving overview scroll.
The existing host outside-click path continues to close the whole plugin panel.

Verification: exercise real callouts/hotspots, blank clicks, protected controls,
field selection, scroll drags, nested popups, recording, draft reopening and
Escape in the isolated consumer fixture. Inspect before/after QML renders, run
the repository gate, and load the checked candidate while unlocked. Offscreen
interaction does not prove native popup positioning or hardware input.

## Remaining design issues and translation check (2026-09-27)

Intent and invariants: complete issues 2/4/5/6 with readable localized action names,
clear assignment hierarchy, a visible Close control and stable editor placement.
Preserve mouse scale, short normal height, actual save/error feedback, draft/gesture
semantics, profile data and Bluetooth behavior. Reuse existing host/theme controls.

Contract: Buttons reserves the same two-column width before and during editing;
an unselected editor shows a localized instruction. Pointer/Device retain their
compact page width. Editor activation/dismissal no longer changes the card width
and therefore cannot trigger host horizontal recentering. Screen fitting remains
the existing host contract. Callout text uses larger theme sizes, full preset names
and up to four lines; arbitrary user shortcuts/commands remain bounded to two
lines, with full text in the editor/accessibility description. The hierarchy is
assignment type, action category, available actions. Reopening a button restores
the category of its saved action without applying changes. Close is visibly labeled
and has a localized editor-specific Esc tooltip.

Translations: keep the existing I18n backend, stable machine/action IDs and stored
values. Rename the obsolete return-to-buttons UI key to Close; add whole messages
for hierarchy and unselected editor. Review changed units with context; correct
Russian English leakage and abbreviated labels. Validate all ten catalog/runtime
key sets, static UI lookups, existing single-%1 substitution contracts, fallback
and live QML retranslation without writes. Non-English/Russian translations use
the local translation fallback and are AI-reviewed drafts, not human signoff.

Verification: red/green consumer test for constant card width and visible prompt;
exercise all 18 action labels across ten locales, narrow bounds and language
changes, Close/Esc/gestures and draft isolation. Evaluate actual installed host
cardOrigin with the real consumer width at screen edges/four bar positions; this
is geometry evidence, not a native pointer/Wayland capture. Inspect actual QML
normal/editor/category/shortcut/command/error and locale renders. Run repository
gate in a candidate, then load exact checked files unlocked and preserve latest
live preferences. Independent fluent-language/a11y/native-layout review remains
outside available local verification.

## Stable frame across pages (2026-09-27)

Intent: finish issue 6 across the whole panel, not only the assignment editor.
Preserve the original mouse scale, profile data, model operations, native theme
and existing dismissal/draft/save semantics. No Bluetooth/configuration changes.

Contract: all three pages request the same 736x650 scaled frame. The existing host
still fits it to screen bounds. A persistent header/navigation stays above scroll
content. Mouse and named button-profile context remain in the left column; Pointer
and Device controls share the editor column on the right. Idle recovery appears
in the right header on Device; active cancellation remains available everywhere.
Long forms, language choice and status messages scroll internally without resizing
the frame. Keyboard navigation includes shared profiles/map and scrolls the column
containing the selected control. Page changes close drafts and reset scroll/focus
using the existing lifecycle. Visible headings make button profiles distinct from
global Pointer/Device settings.

Verification: reproduce current page width/height changes in the isolated consumer;
exercise each page-to-page pair, editor open/close, forms, language and errors.
Assert constant frame/navigation and normal mouse geometry; evaluate the actual
host fitting/origin for all pages and four bar positions. Exercise real pointer
controls with inert model setters and keyboard scrolling. Render/inspect all pages
and significant states, including ten languages and narrow/short bounds. Required
repository gate precedes activation, preserving latest live profile/preferences.
Native capture MCP is absent; offscreen consumer and host-source geometry are
evidence of those contracts, not live Wayland animation/hardware verification.
