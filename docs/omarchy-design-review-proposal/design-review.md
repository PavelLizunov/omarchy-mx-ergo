# Omarchy plugin design review

Review one authorized plugin's actual consumer interface. Use this for design/UX
audits, visible changes and reports such as «экраны прыгают», «непонятно, что за
что отвечает» or «проверь дизайн». Default to findings for audit requests; apply
fixes only within the user's authorized scope. This procedure grants no desktop,
hardware, publication or system-configuration authority.

## Establish the native design contract

Read the plugin's design/behavior documents and relevant current source. Record
plugin ID/kind, intended tasks, host/client version, candidate HEAD plus dirty-file
identity, consumer entry points, available tools and test surface. A bar popover,
menu and full overlay need different geometry; do not impose one plugin's layout
on another. Keep preferences and unrelated work intact.

Use this source order:

1. Explicit user invariants and project design contract.
2. Installed host components/tokens, then the matching official shell reference:
   [Omarchy shell](https://github.com/omacom/omarchy/blob/quattro/docs/omarchy-shell.md)
   and [theming](https://github.com/omacom/omarchy/blob/quattro/docs/theming.md).
   Record revision/version; a moving upstream branch is not the installed API.
3. Community guidance such as
   [Omarchy Style](https://github.com/huacnlee/omarchy-style), particularly its
   Design Guides. It is an external community source, not an official contract;
   review version/license and compare any adopted rule with the installed host.

For QML, inspect actual Color/Style/Border contracts and reusable Ui components
where provided. Use semantic palette roles, theme typography, scaled spacing,
native state affordances, intrinsic sizes and theme-owned geometry. Treat fixed
font/radius/control-size recipes as version-specific examples. Reserve bounds
across hover/focus/selection so a border or label does not shift the control.
Avoid introducing a second design system when host facilities meet the need.

## Review tasks, states and transitions

First perform an expert walkthrough: can someone identify the context, find the
needed action, predict its result, understand feedback and leave/recover? Identify
unclear grouping, labels, extra navigation and misplaced primary content through
a concrete task. This is not an observed user study or a numeric usability score.

Build a bounded matrix for the plugin. Broad reviews cover all user-visible
destinations and meaningful directed transitions. A narrow change covers affected
paths and explains exclusions; avoid a speculative Cartesian product of states.

| Area | Observable acceptance question |
| --- | --- |
| Hierarchy/context | Are navigation, context, content and actions distinct? Does primary content retain the user's intended prominence? Are global versus item-specific settings clear? |
| Navigation/geometry | Do destination switches, editor entry/exit, menus and disclosures preserve expected bounds/anchors under unchanged external geometry? Is resizing intentional and understandable? |
| Feedback | Are loading, empty, unavailable, denied, pending, saved and failed states distinguishable where applicable? Does success correspond to the current operation rather than stale state? |
| Recovery/dismissal | Can the user leave, cancel or retry? Do nested popups receive dismissal first? Do text selection, dragging and scrolling avoid accidental dismissal? |
| Controls/forms | Do actual clicks/keys produce the documented outcome? Do browse/draft operations avoid unintended writes? Are disabled/destructive controls and side effects understandable? |
| Focus/scroll | Is focused content visible and focus restored appropriately? Do fixed navigation and the correct scroll container retain their intended roles? |
| Content/locales | Do short, long and user-supplied values fit? Do changed supported locales retranslate without unwanted operations? Preserve identifiers and user data. |
| Theme/scale | Do applicable palettes, font/spacing scales, screen bounds and bar positions retain readable content and usable targets? Record untested environments. |

Pair rendered states with separate interaction checks. Screenshots show settled
appearance; they do not establish the route between states. On failures inspect
the resulting state, not only a click being accepted.

## Accessibility and motion

Check keyboard entry/traversal/activation and Escape through the installed host's
contract. Record relevant Tab/Shift+Tab, arrows, Return/Space, popup ordering,
visible focus and return focus. Accessible names/roles in source do not prove
screen-reader behavior; that needs an actual accessibility consumer.

Measure contrast for the actual palette/state, including alpha composition. Use
[WCAG contrast](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html),
[focus visibility](https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum.html)
and [target size](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html)
as explicit reference criteria, with native adaptation and applicable exceptions.
CSS pixels, QML logical units and physical pixels are different units; do not
declare a universal 44-unit desktop requirement. Measure hit areas as well as
visible controls. One palette cannot certify every user theme.

For animation/timing changes, inspect a short permitted recording or equivalent
temporal UI evidence. Static renders cannot establish live movement. Keep motion
tied to a meaningful state change and respect the product's reduced-motion path
where it exists. Do not create a recording campaign for unrelated changes.

## Evidence and tool boundaries

For obtaining and annotating images, read [visual-review](visual-review.md).
It connects capture capabilities, consumer QML fixtures, evidence manifests and
the clickable review. Use it for «сделай скрины и выдели проблемы»; no capture
service or MCP is installed by these instructions.

Reuse the owning plugin's actual QML consumer/render/interaction harness and gate;
do not create approximate HTML as proof of native behavior. Use inert operations
for risky settings, commands, deletion and recovery during a design audit.
Keep rendering paths and command names in project documents, not this shared
guide. Inspect every claimed image with an available image viewer.

Record each evidence surface separately:

- Source review: contracts/dependencies; no observed runtime outcome.
- Consumer QML renders: fixture layout/text; no live theme I/O or compositor proof.
- Consumer interaction tests: exercised fixture outcome; no hardware guarantee.
- Host-source geometry: specified fitting/origin inputs; no timing guarantee.
- Live shell state/log/capture: the observed production path only.
- User observation: reported behavior; distinguish it from instrumented evidence.

Discover actual capture/MCP/UI capabilities before use. An instruction to rerender
is not a callable MCP. Missing native control remains unavailable: do not bypass
disabled surfaces with shell input/capture, start another shared shell, change
themes/configuration or reset hardware to manufacture evidence. Use supplied
captures or report the missing check. Follow authorized activation and lock guards.

For reused evidence, record candidate/dependency matches and omissions. HEAD
alone does not identify a dirty tree; a matching panel hash does not identify
the model, locales, host, fixture and theme. Chronological evidence may describe
superseded designs. Repeat only checks needed for a concrete changed risk.

## Deliver findings and bounded acceptance

Use `PASS`, `FAIL`, `NOT VERIFIED` or `N/A` per criterion **and evidence surface**.
Missing material native evidence prevents an overall native verification claim;
it does not prevent delivering the artifact or reporting a scoped fixture pass.
Direct review is not independent signoff. Independent review follows the owning
workflow and permitted model/tool route; this guide does not authorize delegation.

Each finding includes impact/priority, task, state→transition, reproduction,
expected versus observed outcome, source/inspected artifact, confidence/limits
and the smallest useful correction. Separate taste/preferences from demonstrated
defects. For requested visual discussion, annotate authentic captures/renders in
an available interactive surface, preserving the originals and naming their
provenance. Present hypotheses as attention points, not confirmed bugs.

End with actual checks, reused evidence, changed files if any and remaining gaps.
For implementation acceptance run the repository's required gate; documentation-
only work needs reference/schema checks. Skill validation proves packaging,
not the quality of its future design decisions.
