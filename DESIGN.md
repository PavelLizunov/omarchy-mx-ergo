# MX Ergo panel design

Use the existing Omarchy palette, typography, control states and spacing scale.
The user prefers the visual clarity of [SL UI Library](https://github.com/SLtowl/sl-ui-library):
quiet surfaces, visible hierarchy and deliberate grouping. Its skill and navigation
previews were inspected as a reference; no HTML/CSS/JavaScript package was integrated.
Native QML components remain the implementation.

Design read: a compact desktop settings panel; calm and utilitarian, predictable
rhythm with section breaks, motion limited to native hover/focus states.

- Profile selection has a visible heading and one Add action. Manage discloses
  less frequent rename/delete operations, keeping the primary view compact.
- Manage also reveals the global switching shortcut, with a named row and saved-value summary.
- Manage, create, rename, delete and switching-shortcut forms occupy the right
  column. The profile selector/Add and full mouse keep their position on the left.
  These tools share the panel's frame and scroll independently when needed.
- Profile controls set the assignment context below the fixed shared navigation.
  The full-width mouse is the primary content immediately below that context row.
  Preserve the original image scale and five physical callouts. Reduce vertical
  overhead by grouping battery and Bluetooth details on Device, keeping short
  connection context in the header and tightening overview spacing.
  The popup is capped at 95% of available screen height; long forms scroll inside.
- Show the selected physical button as the editor title and its assigned action
  below. A profile context label prevents editing the wrong set. Open the editor
  beside the overview; retain the full mouse, profile tools and page navigation.
  Use one 736x650 scaled frame for all pages, showing a plain
  localized instruction in the unselected editor space. Editing/dismissal must
  not resize or recenter the card. Pointer/Device controls share the editor column;
  the mouse and button-profile context persist on the left. Header/navigation
  remain outside scrolling content, so alerts and forms cannot displace the tabs.
  Save updates in place. Close/Escape dismisses the editor; selecting another
  control discards unapplied drafts. Editor scrolling must not move the overview.
- Use larger theme text and full localized preset names in the callouts. Bound
  arbitrary user shortcuts/commands to a compact summary, retaining full editor
  and accessible descriptions. Close has a visible localized label and Esc tooltip.
- Page tabs use an underline; editor modes use selection fill. Label the assignment
  type, action category and available actions explicitly. Categories use a
  selector and actions use equal-width rows, so their roles are visually distinct.
- Use at least 34 scaled units for primary controls, increasing height to wrap
  long translations. Align form actions in rows and separate recording from save.
- Give Apply primary emphasis and label draft clearing explicitly. Fields have
  accessible names; assignment feedback identifies unconfirmed button application.
- Pointer preferences visibly apply across button profiles. Device discloses
  adapter administration separately; pending/error feedback remains visible when
  its details are collapsed.
- Use theme colors for text, focus, hover, selection and borders; no local palette,
  font download, decorative icon pack or runtime dependency.

## Design acceptance

Use the shared Omarchy plugin design-review procedure in `omarchy-plugin-patterns`,
specialized by the [MX Ergo state/transition matrix](docs/mx-ergo-design-review-matrix.md).
The [shared extension](docs/omarchy-design-review-proposal/README.md)
is installed in the common OpenCode and Codex patterns libraries.
The [research and coverage review](docs/design-review-research.md) records why
these checks were selected and which native evidence remains unavailable.
The latest [polish specification](docs/mx-ergo-design-polish-sdd.md) and
[verification](docs/mx-ergo-design-polish-verification.md) cover profile-form
placement, action emphasis, feedback, enlarged fonts and controlled palettes.

Use [Refactoring UI](https://refactoringui.com/) for hierarchy, grouping, spacing
and control sizing, and [The Design of Everyday Things](https://jnd.org/books/the-design-of-everyday-things-1st-ed/)
for predictable actions and feedback. These are references, not claims that a
book or component package has been integrated.

Before activation, render the actual QML consumer's Buttons, Pointer, Device,
profile management and shortcut form, plus assignment presets, shortcut, function
keys and command states. Inspect each image for clipping, overlap, hierarchy,
context and screen height. Exercise transitions and saves separately; screenshots
do not prove interaction. Reuse `tests/profiles-ui.py --capture-states DIR`; the
fixture has inert operations and cannot certify compositor placement or hardware.
