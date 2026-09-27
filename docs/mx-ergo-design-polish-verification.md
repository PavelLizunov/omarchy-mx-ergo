# Design polish verification — 2026-09-27

**Verdict: verified for the stated consumer fixture; native visual acceptance
remains incomplete.** This is direct in-session review, not independent signoff or
a production/Marketplace certificate.

## Scope and corrections

Installed repository: `/home/slovn/.config/omarchy/plugins/slovn.mx-ergo`, local
`master` at `7e968c0`. The dirty baseline and isolated candidate are under
`.git/mx-design-polish/`; `source-hashes.json` identifies all 102 initial files.
Earlier Bluetooth/battery/profile changes were preserved. This pass changes UI,
five messages in each locale, consumer checks, documentation and current images.
Runtime model, helpers, preferences and hardware selection are unchanged.

| Finding | Correction | Evidence |
| --- | --- | --- |
| P2: profile forms pushed the mouse below the frame | Manage/create/rename/delete/switching-shortcut tools occupy the right column; selector and mouse stay left | Before renders in `states-before-profile-placement/`; current `release-states/profile-*.png`; four-form mouse-position/keyboard regression |
| P2: assignment error named buttons and pointer without identifying the task | Editor says button assignment is unconfirmed and offers Retry | Current assignment-error render; error/retry interaction and all-locale feedback checks |
| Form action hierarchy and draft clearing were unclear | Apply uses primary emphasis; Clear field changes only the draft; fields have explicit names | Return/clear/apply consumer checks, wrapping and measured contrast |
| Shared pointer scope and rare adapter administration needed separation | Shared-scope note; explicit advanced disclosure; pending/error feedback survives collapse | Pointer/Device images and keyboard disclosure tests with inert adapter counter |

The adapter disclosure performs no hardware operation. Existing warnings and
explicit profile-action authorization remain. Profile forms retain their own
keyboard ownership after being hosted in the adjacent column; first Escape stops
recording and the next dismisses the form. Assignment editing replaces tools in
place. Buttons/Pointer/Device and editor transitions retain the shared frame.

## Executed checks

- Isolated original implementation plus the first new checks:
  `python3 -B tests/profiles-ui.py`, exit 5; 96 passed, 5 failed. Failures were
  missing disclosure/form-control/name behavior, not a reproduced contrast defect.
  Log: `.git/mx-design-polish/ui-baseline.log`. Live files were not reverted.
- Final candidate: `bash tests/run.sh`, exit 0, all nine stages. 102 profile/editor
  Qt results and 14 diagram results pass; manifest, model/helper, recovery,
  persistence, sleep, locale, lint and lockscreen checks also pass.
  Log: `.git/mx-design-polish/delivery-gate.log`.
- `python3 -B tests/profiles-ui.py --capture-states ../release-states`, exit 0:
  78 editor results including capture; 83 actual QML PNGs written.
  Log: `.git/mx-design-polish/release-capture.log`.
- All ten locales match the embedded runtime dictionary: 181 keys each. The five
  changed messages have complete entries and unchanged technical tokens/meaning
  of uncertainty. Local translation fallback and anti-slop review were used;
  no qualified human language signoff is claimed.
- Changed controls wrap in all ten locales at the constrained 620 × 450 fixture.
  Font 16 versus base 12 is checked with dark Russian and light German palettes;
  a light Japanese base-12 case also passes. Frame and mouse size remain stable.
  Clear/Apply/Close text against actual alpha-composited fills, including focused
  Apply, meets 4.5:1 in those controlled cases. Arbitrary themes are not certified.
- The inline review embeds five identical inspected source PNGs, fits under 1 MiB
  and passes script syntax. Browser checks exercised all six annotations, three
  page comparisons and keyboard Enter. At width 320 controls/text fit without
  horizontal clipping. The temporary preview tab/server were closed.

## Images and provenance

The final originals inspected with the image tool include Buttons, Pointer,
Device, assignment-workspaces/error/command/function-keys, profile-create/delete/
shortcut, device-advanced/error-collapsed and all four normal light-palette views.
Earlier candidate originals additionally inspected include profile management/
rename, adapter busy/error, enlarged dark/light cases and French/Japanese/Chinese
advanced views. Those sources match the final presentation behavior except for
the documented final heading/disclosure refinements; do not promote every one
of the 83 final captures to an individually inspected result.

Current public examples and input hashes are in
`assets/screenshots/current/evidence.json`. The consumer uses actual installed
Omarchy controls and copies theme tokens into a temporary fixture, trimming only
Quickshell I/O unavailable to qmltestrunner. Backend: offscreen/software Qt.
Host packages: Omarchy 4.0.4-1, Qt base 6.11.2-3, Qt declarative 6.11.2-1,
Quickshell 0.3.1-1. The original 736 × 650 frame is preserved at base font 12.

## Limits and publication

No native-control/capture surface for the running QML shell is available. Browser
checks validate the review, not the native plugin. Live compositor placement,
theme I/O, screen-reader speech, physical mouse/radio behavior and fluent human
translation review remain outside this pass. No new capture MCP or skill package
was installed. The reusable Pattern procedure was installed in the prior step;
this pass borrows review questions documented in the SDD without changing it.

Remote readback still shows plugin `master` at `3bb9f7c` and shared skill `main`
at `c76dbe0`; the historical screenshot-guide branch is `01aafb5`. Latest plugin
and design-skill edits have not been pushed. A local Codex adaptation has no
separate Git remote. Publishing an exact candidate to either repository requires
the concrete authorization in AGENTS.md; development/restart permission does not
authorize a remote push, release or Marketplace submission. No new covering local
commit was created while this pass was prepared against the existing dirty tree.

## Installed consumer observation

The unlocked installed directory received the 35 changed candidate files once;
all activated hashes matched the isolated candidate. `omarchy restart shell`
returned exit 0. The subsequent `profileStatus` response matched the previous
active ID/name, both profiles and all five assignments. It reported `verified`
and `saved`, with no application/save pending work. The preference file SHA-256
remained unchanged. This confirms load and settings state, not native appearance
or physical mouse input. Relevant runtime source hashes still match the capture
manifest. The installation receipt is `.git/mx-design-polish/activated-paths.json`.
