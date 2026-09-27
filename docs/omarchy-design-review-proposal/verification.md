# Shared skill update verification — 2026-09-27

## Installed scope

Both presented local destinations were updated after the user's explicit request:

- `/home/slovn/.config/opencode/skills/omarchy-plugin-patterns`
- `/home/slovn/.codex/skills/omarchy-plugin-patterns`

Each has the updated `SKILL.md` and `README.md`, new `references/design-review.md`,
`references/visual-review.md` and `agents/openai.yaml`. Codex's existing adaptation,
source metadata, screenshot-rerender reference and unrelated guides were preserved.
No runtime plugin, desktop settings, capture server, model route or publication
changed. No local commit was made for this documentation update.

## Executed checks

| Check | Outcome |
| --- | --- |
| Both original destination SKILL/README SHA-256 values against `destinations.json` | PASS before application; new destinations absent |
| `git apply --check` for each candidate patch | PASS, exit 0 |
| Actual application of both local patches | PASS, exit 0 |
| `git apply --reverse --check` for each final patch against its installed destination | PASS, exit 0; checks correspondence without reverting files |
| `quick_validate.py` against both installed skill folders | PASS, exit 0 |
| Markdown local-reference existence across both updated packages | PASS, 38 references checked |
| Shared reference bytes against the prepared reference files | PASS, both destinations match |
| UI metadata name/default prompt and Codex adaptation anchors | PASS |
| Canonical repository `git diff --check` | PASS, exit 0 |

This is direct packaging/content review, not an independent design-effectiveness
evaluation. The existing Codex catalog includes the exact skill name; invocation
in a newly opened chat and OpenCode client discovery were not exercised here.
Another chat must confirm actual loading before claiming it used the skill.

## MX Ergo review evidence

Four unchanged authentic consumer PNGs were inspected: Buttons, Pointer, Device
and assignment error. Embedded report image bytes and 736×650 dimensions match
those originals. Eight of nine earlier recorded dependency hashes still match;
`DESIGN.md` changed for documentation links. The model/host/theme dependency set
was not re-established in full; this is not a renewed full implementation gate.

The report now names the P2 error-wording concern explicitly. Its image shows a
deliberately simulated failure, not a new physical mouse incident. General UI
interaction controls retain prior browser click evidence; updated text/default
selection/state version have fresh fragment/image and script-syntax checks.
The fragment is below 1 MB, embeds four matching PNGs and makes no data requests.
No fresh browser interaction pass or live Wayland transition pass is claimed.

Live motion/placement, broader theme/scale coverage and full assistive-technology
acceptance remain NOT VERIFIED. No QML implementation or hardware behavior was
changed by this task, so no mouse exercise, implementation suite or shell restart
was needed.
