# Capture and clickable design review

Use with [design-review](design-review.md) when the user asks to see plugin
screens, compare states or highlight problems. Deliver authentic images and
selectable annotations that another plugin project can reproduce. Plugin-specific
dimensions, imports, fixtures and commands belong in that project's documents.

## Select the evidence surface

Inventory the tools actually available in this session before making a capture
claim. Separate these capabilities:

| Surface | Suitable evidence | Limits |
| --- | --- | --- |
| Allowed native UI/capture tool or existing capture MCP | Running plugin, focus, menus, live transitions | Only its documented operations and authorized desktop scope |
| Project QML consumer harness | Reproducible layout and interactions with controlled data | Fixture, offscreen backend and imported host components may differ from the desktop |
| User-supplied image or recording | What the user observed | Record uncertain revision/state instead of guessing |
| Inline visualization/browser | Clickable image annotations and comparison | Operates the report; does not control the native plugin |

A rerender guide is not an MCP server. Do not invent a tool name, configure a new
server or bypass disabled native capture/control through a shell command. Inspect
documented capture tools if available; otherwise use the existing QML harness or
provided images and mark live verification unavailable. Do not create mock HTML
or generated pictures as evidence of the QML interface.

## Capture the actual consumer

1. Read the owning QML entry point and harness. Confirm that the fixture loads the
   actual candidate component, rather than a separate reconstruction. Check
   fixture imports and any stubs against the installed host version.
2. Use inert models for writes, commands, device recovery and destructive actions.
   Label fixture data. Inspect startup hooks, helpers and imports before running
   the harness; an offscreen platform alone does not isolate side effects.
3. Capture the task's meaningful states: normal, editor/menu, draft, pending,
   success, failure/retry and dismissal where present. Add long values, locale,
   theme and scale cases for concrete changed risks. Include the owning surface
   when checking overall fit; a tightly cropped control cannot show screen bounds.
4. Wait for a defined settled condition, not an arbitrary sleep alone. Write PNGs
   into an owned evidence directory. Keep reference and candidate images separate
   and unchanged. Identify state, locale, theme and scale in filenames/metadata.
5. Inspect each delivered image using the environment's real image-viewing tool.
   Check exact labels, selected values, imagery, clipping, overlap and bounds.
   An existing but unviewed PNG is not visual verification.

Where a Qt Quick Test runner already exists, `QT_QPA_PLATFORM=offscreen` and
`QT_QUICK_BACKEND=software` are a possible rendering path. Use the project's runner
and import paths; these environment settings do not launch the production shell
or prove compositor behavior. Do not start another shared Quickshell instance.

For sharper text, optionally render the actual QML tree at 2× pixel density while
preserving logical dimensions. Verify that the backend redraws text/vectors at
that density; resizing a PNG adds no detail. Display reference and candidate at
the same logical width and retain the original pixels. Call the result a QML
rerender, with any differences in theme/data disclosed.

## Preserve identity and provenance

Maintain one small project-local evidence manifest alongside captures. Record:

- plugin ID, consumer entry point, HEAD and dirty candidate identity;
- hashes of relevant QML, model, locales, helpers, fixture and host dependencies;
- host/Qt/Quickshell versions, backend, palette, font/spacing scale and dimensions;
- for each image: path/hash, state, fixture/live/user origin, logical and pixel
  dimensions, capture time and inspected status;
- interaction path, expected/observed result, executed gate and missing coverage.

Keep sensitive desktop data out of reports. HEAD alone cannot identify an edited
tree. Reuse evidence only while relevant dependencies still match; record unknown
dependencies. A pending/error fixture proves that state can render, not that the
real operation failed. A live successful click requires checking its result.

For geometry changes, compare directed transitions, including editor entry/exit
and returning to the original page. Record panel origin, bounds, primary-content
size, navigation anchor, scroll and focus. A before/after pair can show settled
differences; actual movement or animation needs permitted temporal evidence.

## Build the clickable review

Use the host's available inline visualization capability. In Codex, discover and
read the installed `visualize` skill when available; follow its current output,
resource, size and interaction rules. It is a presentation capability, not an
Omarchy capture MCP. If absent, deliver viewed images with numbered findings, or
an authorized local browser report; state that inline interaction is unavailable.

Use one selected image with a compact list of numbered findings. Selecting a
finding changes the image, highlighted region and explanation. Add page/state
switching only when comparison needs it. Keep the original screenshot pixels
intact; place boxes/numbers in a separate overlay. Essential information must be
available without hover and selection must work with native keyboard controls.

Store each annotation as data:

```json
{
  "id": "error-scope",
  "image": "assignment-error.png",
  "region": {"x": 394, "y": 150, "width": 327, "height": 80},
  "kind": "finding",
  "priority": "P2",
  "title": "Error does not identify the operation",
  "observed": "The message names two settings groups in one-button editing.",
  "expected": "Identify the current operation and useful retry context.",
  "evidence": "Inspected consumer fixture and matching source",
  "limitation": "Not a live device failure"
}
```

The coordinates above illustrate one image; calculate each project's own regions.
Record whether coordinates use source pixels or logical units. For an uncropped
image of width W and height H, place the overlay with `left=100*x/W`,
`top=100*y/H`, `width=100*w/W`, `height=100*h/H` percent. Anchor it to the displayed
image box, preserving aspect ratio. Recalculate for a crop or letterboxing; never
silently reuse boxes from another state.

Distinguish annotation kinds in visible text:

- **Finding:** observed defect or concrete usability concern; describe its impact.
- **Attention:** hypothesis or preference to discuss, not a reproduced defect.
- **Fixed:** a historical issue with matching correction evidence.
- **Not verified:** a material check missing from the stated evidence surface.

Use these separately from acceptance `PASS/FAIL/NOT VERIFIED/N/A`. Never make all
highlights look like confirmed errors, or turn an intentionally rendered error
state into a new reported incident. Do not invent a score or independent signoff.

In Codex inline reports, embed allowed local image data as required by the current
`visualize` skill. Keep the report self-contained, with no data fetching, tracking
or system actions. UI selection is presentation state and supplies no approval.
Use only the available host API; tool instructions take precedence over examples.

## Verify the report and deliver

Read back the saved report and check asset identity, region bounds, escaped text,
size and script syntax. If an allowed browser is available, click every finding
and comparison control and inspect resulting image/region/text; check keyboard
selection and a narrow layout. A browser screenshot validates the report, not
the production plugin. If browser verification is unavailable, label that limit
and retain previously valid interaction evidence only for unchanged behavior.

Deliver the actual inspected images or supported inline content reference, with
a short findings summary. State the candidate/evidence surface and live gaps.
Keep audit-only requests read-only. Apply requested corrections in the owning
plugin, recapture affected states and compare against retained originals. Finish
owned capture jobs/windows; no shell restart is needed for report generation.
