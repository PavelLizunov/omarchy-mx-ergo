# Design review research — 2026-09-27

Latest implementation: [polish specification](mx-ergo-design-polish-sdd.md) and
[verification](mx-ergo-design-polish-verification.md). The audit below predates
those corrections; its “no runtime correction” statements are historical.

## Additional primary-source skill research

Qt publishes [Qt UI Design](https://doc.qt.io/agentictools/skills/qt-ui-design/)
and [Qt QML Review](https://doc.qt.io/agentictools/skills/qt-qml-review/) through
[Qt Agentic Tools](https://doc.qt.io/agentictools/getting-started/). Their relevance
here is native component use, keyboard input, explicit field semantics and
reviewing actual QML. This session did not install their skills or MCP tools.
Generic Qt typography recipes do not replace Omarchy's installed font/scale tokens.

Vercel's [Web Interface Guidelines](https://github.com/vercel-labs/web-interface-guidelines/blob/main/command.md)
provides reusable review questions about visible focus, named fields, feedback
and long content. DOM, CSS, URL and browser-form rules remain web-specific.
The [community Omarchy guide](https://github.com/huacnlee/omarchy-style/blob/main/skills/omarchy-style/references/design-guides.md)
supports hierarchy through layout and spacing; it is not an official host API.

**Verdict: Extend** the existing Pattern/native-QML workflow for this pass.
Borrow review questions without adding another design system or runtime package.
The concrete corrections are unconfirmed-assignment wording, Apply/Clear
hierarchy, accessible field names, shared pointer scope, disclosed adapter tools,
and profile forms that no longer push the mouse below the frame. The shared
library's previously installed design procedure remains the reusable entry point.

## Conclusion

Verdict: Compose — existing OpenDesign/Omarchy guidance, established usability
references and the repository's real QML consumer checks. The missing piece was
explicit coverage of tasks, states and transitions with evidence boundaries.
Installing another visual-generation skill would not by itself close that gap.

After the user's scope correction, the initial project-local standalone skill
was removed. General review rules are installed as an extension of
`omarchy-plugin-patterns` in [the common-library proposal](omarchy-design-review-proposal/README.md).
The [MX Ergo matrix](mx-ergo-design-review-matrix.md) remains a project-specific
example. The common procedure preserves native design and defaults to findings
for audit requests. The user explicitly requested updating the shared skill,
and both presented local destinations were updated on 2026-09-27.
No new runtime package, capture service or global configuration is introduced.

## Available local skills

These are available instructions, not independent designers or test executors.
Their installed entrypoints were inspected on this machine; detailed procedures
were read where used in this task.

| Skill | Useful role | Application to MX Ergo |
| --- | --- | --- |
| `opendesign` | Context, composition and specialist routing | Use existing `DESIGN.md` and Omarchy tokens. HTML output is not native QML evidence. |
| `anti-slop` | Hierarchy, purpose, clear copy and actual interaction evidence | Filter generic tiles and unclear roles; preserve the user's preferences. |
| `omarchy-plugin-patterns` | Host/control contracts, localization and QML rerender procedure | Adapt patterns to installed host. Its rerender procedure is not a callable capture MCP. |
| `omarchy-visual-verification` | Visible states, focus, clipping and transitions | Requires actual permitted evidence; native behavior remains unverified when tools are unavailable. |
| `change-verification` | Candidate identity, regressions and acceptance limits | Keep implementation checks separate from design judgement. |
| `wireframe` | Structural alternatives before committing to a direction | Useful if hierarchy needs exploration; unnecessary for auditing the accepted layout. |
| `frontend-design` | Visual direction without an existing brand | Conditional; MX Ergo already has Omarchy styling and user direction. |
| `create-design-system` | Reusable tokens and brand rules | Conditional; existing native tokens already govern this plugin. |
| `interactive-prototype` | Exploratory clickable flows | HTML prototype can test an idea but cannot certify the installed panel. |

## External skills considered

Read-only discovery; none installed or executed. Suitability is based on primary
source guidance, not star counts or measured improvement. Maintenance/SLA and
empirical quality were not audited; a future installation needs version/license/
dependency review against its actual intended use.

| Candidate | What its source provides | Decision here |
| --- | --- | --- |
| [Vercel web-design-guidelines](https://raw.githubusercontent.com/vercel-labs/agent-skills/main/skills/web-design-guidelines/SKILL.md) and [Web Interface Guidelines](https://vercel.com/design/guidelines) | Review instructions plus practical focus, target, state and layout guidance | Useful reference for the audit. Adapt to QML; HTML/React/URL/ARIA-specific recipes do not apply directly. |
| [Anthropic frontend-design](https://github.com/anthropics/skills/blob/main/skills/frontend-design/SKILL.md) | Deliberate visual direction, restrained composition, contextual copy and self-critique | Useful for exploring a new visual direction. Does not provide this plugin's transition/hardware verification. |
| [UI UX Pro Max](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) | Searchable design guidance, design-system generation and stack-specific material | Consider for broader product exploration. No native MX Ergo/Omarchy acceptance path was demonstrated; unnecessary machinery for this review. |

Our existing [SL UI Library reference](https://github.com/SLtowl/sl-ui-library)
remains the user's visual preference recorded in `DESIGN.md`; its components are
not integrated into QML. It was not re-audited or downloaded in this research.

## Patterns with concrete use

| Reference | Pattern used in the instruction |
| --- | --- |
| [Nielsen's usability heuristics](https://www.nngroup.com/articles/ten-usability-heuristics/) | Ask whether the task/state is understandable, actions are predictable, recovery is reachable and feedback matches the latest result. An expert walkthrough is not a user study. |
| [GNOME navigation](https://developer.gnome.org/hig/guidelines/navigation.html) and [keyboard guidance](https://developer.gnome.org/hig/guidelines/keyboard.html) | Clear destinations, shallow hierarchy, keyboard operation and transient-container dismissal. Use these principles through Omarchy's own host contracts. |
| [KDE layout/navigation](https://develop.kde.org/hig/layout_and_nav/) and [status changes](https://develop.kde.org/hig/status_changes/) | Group related controls, keep contextual tools alongside global navigation, communicate results near the affected task. No Kirigami dependency is added. |
| [WCAG focus visibility](https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum.html), [target size](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html) and [contrast](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html) | Check focus visibility, actual hit areas and state-specific palette contrast. 24 CSS pixels with exceptions is a web criterion; 44 units is not a universal desktop requirement. |
| [Qt Quick Test](https://doc.qt.io/qt-6/qtquicktest-index.html) | Reuse the existing consumer test harness for reproducible interactions. Offscreen results remain distinct from Wayland/hardware behavior. |

The central project-specific pattern is stable navigation with adjacent contextual
editing: the profile/mouse stays visible while assignment or device controls use
the right column. Progressive disclosure keeps infrequent profile management
compact. Explicit save/error states communicate the actual current result.

## Additional review performed now

This was an evidence/coverage audit, not a new implementation or full test run.
The nine files in `.git/mx-stable-pages-evidence/source-hashes.json` matched their
recorded hashes before the documentation additions. This anchors the frame and
consumer/test snapshot; it does not hash every model, helper, locale, host or theme
dependency. Historical tests are therefore reported as historical evidence.

Four original QML captures were inspected again with the image tool: Buttons,
Pointer, Device and assignment-error, under
`.git/mx-stable-pages-evidence/states/`. The visible fixed frame/navigation,
preserved mouse/profile context and adjacent error/retry flow agree with the
current design contract in those fixture states. No new reproduced design defect
was found in these four settled states; this is not a full UI or native signoff.

| Area | Available evidence | Remaining limitation |
| --- | --- | --- |
| Page transitions and geometry | Current consumer checks contain all six directed transitions; previous gate reports 96 profile/editor Qt results, zero failures | Not rerun here; settled captures cannot show compositor timing. |
| Feedback, dismissal, profile and locale flows | Existing consumer tests and chronological design-verification log | Full dependency identity was not re-established here; not a new interaction pass. |
| Normal pages and assignment error | Four actual consumer renders inspected now | Inert model/software fixture; no production data/hardware claim. |
| Contrast | Previous fixture measurements cover normal and secondary text | Selection/hover/disabled combinations and user themes remain incompletely measured. |
| Scaling and assistive technology | Source/fixture constraints and accessible labels | Live scaling, screen-reader operation and complete keyboard coverage remain unverified. |
| Native capture/MCP | Callable tool inventory inspected; no Omarchy native capture/render tool found | Native-control surface is disabled. Browser controls do not capture a QML layer-shell panel. |

Older sections of `docs/button-profiles-design-verification.md` describe earlier
layouts. The final full-page correction supersedes the earlier compact
Pointer/Device and resizing behavior. Do not treat all historical claims as
simultaneously describing the current candidate.

## Using the instruction

Ask: **«Проверь дизайн MX Ergo по omarchy-plugin-patterns и матрице MX Ergo:
экраны, переходы, фокус, сохранение, ошибки и переводы. Сначала дай замечания».**

The general procedure is intended for the existing common skill, not a separate
skill in each plugin. Invoke `$omarchy-plugin-patterns` for design with screenshots
and highlighted review; use the project matrix for MX Ergo specifics. Packaging alone
does not prove effective skill discovery or future behavioral quality.

For a new UI candidate, use its own state captures and the required repository
gate; inspect actual images and record transitions separately. For a narrow audit,
select affected matrix rows and reuse only evidence with adequate provenance.
An overall native-design pass requires relevant native evidence. Missing tools
are recorded as `NOT VERIFIED`; they do not authorize installing MCP servers,
changing system configuration or bypassing disabled control.

## Current review correction

The annotated review now distinguishes confirmed concerns from attention points,
historical fixes and missing native evidence. One concrete P2 wording concern was
confirmed in the inspected `assignment-error.png` consumer fixture and matching
source: `ErgoPanel.qml:123` selects `settings_apply_error` for the assignment editor,
and `locales/ru.json:137` says “Не удалось применить настройки кнопок или указателя.”
The message covers two groups without identifying the user's current operation.
Use operation-specific feedback and available failure context. This is a usability
concern, not evidence of a new runtime/device failure; the failure state was
deliberately produced by the inert fixture. No runtime correction was made here.

Other highlights remain discussion points or previously corrected issues.
Live compositor transitions, a broader theme/scale matrix and complete assistive
technology coverage remain unverified. This update changes shared procedures and
report text, so the plugin's implementation gate was not repeated.
