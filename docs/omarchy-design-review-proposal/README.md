# Shared Omarchy design-review extension

## Intent and scope

Extend the existing `omarchy-plugin-patterns` skill with general design and
capture/annotation references, explicit invocation and task routing. Keep plugin-specific acceptance
examples in their owning projects. The initial standalone MX Ergo skill has been
removed; the [MX Ergo matrix](../mx-ergo-design-review-matrix.md) is an example.

The [prepared reference](design-review.md) covers native design sources, task
walkthroughs, states/transitions, hierarchy, feedback, focus, translations,
theme/scale and evidence boundaries. It does not impose MX Ergo's mouse, dimensions,
three pages, controls or test commands on another plugin. No added executor,
dependency, model delegation, system change or publication is implied.

Verdict: Extend — `omarchy-plugin-patterns` — existing shared routing and references
already cover native host, localization and rerendering. One design-review
references close the task/transition and screenshot/annotation gaps without a duplicate global skill.

## Behavior contract

1. Intent/invariants: a user invokes the same shared skill in any Omarchy plugin
   project. Preserve the actual native design, authorized scope and unrelated work;
   MX Ergo's geometry and hardware are examples, not shared requirements.
2. Interface: `$omarchy-plugin-patterns` plus a design-review request loads
   `references/design-review.md` and `references/visual-review.md`. The report uses
   inspected authentic images, selectable regions and distinct finding/attention/
   fixed/not-verified labels. Discover real capture and inline tools per session;
   unsupported MCP/native interaction remains unavailable.
3. Verification: validate both skill packages, every local reference, adaptation
   preservation and the actual installed entrypoints. Reuse prior interaction
   evidence for unchanged report controls, inspect the reported image/source and
   syntax-check changed report text. Missing capture/browser/live transition
   evidence must not become a pass. Documentation installation changes no runtime.

## Ready-made Omarchy guidance

An existing community skill closely matches this need:
[huacnlee/omarchy-style](https://github.com/huacnlee/omarchy-style), including its
[Design Guides](https://github.com/huacnlee/omarchy-style/blob/abd42e1b16a867445353e74958829ba8ebc48e19/skills/omarchy-style/references/design-guides.md).
It covers composition, theme resolution, type/spacing/component geometry and
interaction. Repository revision inspected: `abd42e1b16a867445353e74958829ba8ebc48e19`
(2026-09-07), MIT license reported by the repository API. Its source baseline is
Omarchy `945549699026df6c888a6b1bd4e06fbf55a67595`; that is not this host version.
The corpus was not installed or executed, and its 589-line brand system was not
audited in full. It describes itself as official in places; this research treats
it as community guidance and independently checks adopted runtime facts.

Official primary sources are the
[shell contract](https://github.com/omacom/omarchy/blob/quattro/docs/omarchy-shell.md)
and [theming reference](https://github.com/omacom/omarchy/blob/quattro/docs/theming.md),
plus actual installed components. Upstream `quattro` resolved to
`fd961e5300c317025e561329e6e6a622eb4ad0b4` during research. Installed packages:
Omarchy `4.0.4-1`, Qt Declarative `6.11.2-1`, Quickshell `0.3.1-1`.
Installed Style/Button/PanelHero source excerpts confirm native theme/scale/state
contracts. This is a source comparison, not a full theme or runtime certification.

Keep Omarchy Style as a source reference in the shared review procedure. Any
future adoption/copy needs its actual version/license review; typography, radius
and component defaults yield to the installed host and user preferences.

## Concrete installation proposal

The following exact local destinations were inspected read-only:

1. Canonical Git/OpenCode library:
   `/home/slovn/.config/opencode/skills/omarchy-plugin-patterns`, HEAD `06b1b4c`,
   remote `https://github.com/PavelLizunov/omarchy-plugin-patterns`, clean at inspection.
2. Codex's adapted installed copy:
   `/home/slovn/.codex/skills/omarchy-plugin-patterns`.
   Preserve its Codex adaptation and source metadata.

Each patch adds `references/design-review.md`, `references/visual-review.md` and
Codex UI metadata in `agents/openai.yaml`; updates the skill description/routing
and documents explicit design-review invocation in `README.md` and `SKILL.md`.
It also removes obsolete fixed document counts. The patches are separate
because the two entrypoints/READMEs differ.

- [OpenCode/canonical patch](opencode-patterns.patch)
- [Codex adapted-copy patch](codex-patterns.patch)
- [Destination source hashes](destinations.json)

The user explicitly requested updating the shared skill after these two concrete
destinations were presented (2026-09-27). This authorizes their local update.
Installation evidence is recorded after validation; no remote push, release or
Marketplace submission is part of the update.

Installed and checked on 2026-09-27; see [verification](verification.md).

## Verification contract

Check destination source hashes immediately before applying. Stop on divergence
and refresh the patch instead of overwriting newer work. Check both patches with
the actual Git patch parser, then check local links, skill frontmatter, the existing
adaptation/routing and task scope. Validate packaging separately from behavioral
coverage. These are documentation changes, so no mouse/Bluetooth exercise or shell
restart is required. Report installation and client discovery separately.
