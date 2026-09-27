# MX Ergo design polish

Date: 2026-09-27. Scope: presentation and inert consumer verification in the
installed MX Ergo repository. Candidate is prepared in isolation before activation.

## Research decision

**Verdict: Extend.** Use the existing `omarchy-plugin-patterns` workflow and native
Omarchy controls. Qt's [UI design skill](https://doc.qt.io/agentictools/skills/qt-ui-design/)
and [QML review skill](https://doc.qt.io/agentictools/skills/qt-qml-review/) add useful
checks for input, semantics and native component use. Vercel's
[interface checklist](https://github.com/vercel-labs/web-interface-guidelines/blob/main/command.md)
contributes explicit field names, visible keyboard focus, actionable feedback and
long-content checks. [Omarchy Style](https://github.com/huacnlee/omarchy-style)
is a community reference for hierarchy and spacing, not an official host contract.

No packages, MCP servers, font downloads or new runtime libraries are installed.
Web-specific DOM rules and generic Qt font/scale recommendations do not override
the installed shell's tokens. These are borrowed review questions, not copied
source text or a claim that another skill has been integrated.

## 1. Intent and invariants

Make assignment actions and feedback clear; distinguish per-profile assignments
from shared pointer preferences; keep rarely used adapter administration separate.
Preserve the full mouse illustration, five callouts, profile context and shared
736 × 650 scaled frame across Buttons, Pointer and Device. Opening or dismissing
an assignment editor must not resize or recenter the card.

Preserve configuration schemas, persisted profiles, button actions, hardware
selection, reconnection and adapter helper behavior. No pairing, discovery,
adapter change or profile save is performed to obtain design evidence.

## 2. Behavior contract

- Shortcut and command fields have explicit accessible names. Apply is the
  primary form action; Clear field changes only the unapplied shortcut draft.
  Both use the existing wrapping native control and remain keyboard operable.
- Unconfirmed settings application is described as an unconfirmed button
  assignment within the editor, with a retry instruction. It must not assert that
  the last click caused a global helper error or that a save succeeded.
- Pointer's heading uses product language. A visible note says its preferences
  apply to every button profile.
- Profile management, name/delete forms and switching-shortcut tools use the
  adjacent right column. The selector/Add stay above the mouse, whose position
  and scale remain unchanged when these forms open. Profile forms own their
  keyboard traversal, Escape and scrolling even when hosted beside the selector.
  Selecting a mouse control replaces these tools with its assignment editor.
- Device starts with advanced adapter settings collapsed. Expanding the section
  performs no adapter operation. A pending action or new failure opens details
  once; the user can collapse them and still sees a pending/error summary.
  The existing explicit profile action is keyboard reachable only when disclosed
  and enabled. All current authorization and controller-wide warnings remain.
- New text exists in all ten bundled locales and agrees with embedded catalogs.

## 3. Verification

Run the required repository checks against the isolated candidate. Exercise the
actual ErgoPanel consumer using inert operations and installed shell controls:
Return/Tab disclosure and actions, Clear versus Apply, accessible names, error
and pending summaries, independent scrolling, dismissal and stable frame. Check
all four profile forms, retained keyboard ownership, recording-before-dismissal
Escape ordering, and identical mouse position before and after management opens.

Check wrapping in ten locales, including the new advanced disclosure and primary
form actions. Check frame and control bounds at base font 12 and enlarged font 16;
measure text contrast against actual control fills in controlled light/dark
palettes. Capture actual QML states and inspect images for clipping, hierarchy
and preserved mouse size. Existing baseline plus new checks provides isolated
red evidence without reverting any live files.

Consumer fixtures trim only shell theme I/O that cannot load in qmltestrunner.
They do not prove compositor placement, running-shell theme I/O, screen reader
speech or physical pointer behavior. Native capture/control is unavailable in
this session; record that limit separately from the passing consumer checks.
