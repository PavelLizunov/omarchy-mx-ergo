# Development contract

Plugin ID: `io.github.pavellizunov.mx-ergo`. The entry point is `BarWidget.qml`; the working directory name is not an API. See [source ownership](MODULES.md), [hardware and runtime contracts](HANDBOOK.md), and [remaining work](BACKLOG.md).

## Document roles

The active project instruction set is `AGENTS.md`, `CLAUDE.md` (entry pointer),
and `DEVELOPMENT.md`. Workspace instructions remain owned by the parent `AGENTS.md`.
README, MODULES, HANDBOOK, BACKLOG and DESIGN are project references, not new
execution authority. Dated reviews, investigations, specifications and capture
ledgers under `docs/` are evidence or reference material, not current orders.
Retain them unless a specific removal batch is authorized.

Historical review hashes in `docs/candidate.sha256` identify the older snapshot;
they do not verify the current working tree. Check evidence dependencies before
reusing a screenshot or review. Never refresh old hashes to imply a fresh review.

## Runtime safety

Check `omarchy-shell lock status` before editing or reloading an active plugin. A locked, requested, pending, or session-locked state blocks activation because of the shared shell's session-lock crash risk (upstream #9441). Use the supported `omarchy restart shell` only while unlocked.

Battery status belongs to the reactive `Quickshell.Bluetooth` and `Quickshell.Services.UPower` models. No competing direct `/dev/hidraw*` readers or writers are supported. Unknown and disconnected states must remain explicit; they are not zero charge or proof of a healthy battery.

QML colors come from Omarchy tokens (`Color`, `Style`, and the injected bar palette). The optional administrator helper is separate from plugin runtime code and is installed only by a deliberate administrator action.

## Verification

For panel design/UX reviews, use the shared `omarchy-plugin-patterns` procedure
with the [MX Ergo matrix](docs/mx-ergo-design-review-matrix.md).
The [common-library extension](docs/omarchy-design-review-proposal/README.md)
records an earlier shared-library update. Discover the currently loaded skill
and preview tools before relying on it; the archived report does not prove loading.

Run `./tests/run.sh` before accepting or committing implementation changes. Every check must exit zero for full product acceptance. Run `python3 -B tests/repository-docs.py` for the independent documentation and active-set gate. Passing isolated tests is not evidence of untested native lifecycle, hardware or accessibility behavior. The dated [release review](RELEASE-REVIEW.md) records earlier acceptance limits, not current-candidate results.

Record original baseline failures separately from new regressions. An unrelated
pre-existing failure blocks a full product PASS, not independent verified hygiene
work. Stop only the affected batch when its invariant or safety boundary fails;
do not skip, weaken or relabel the original failing test. Current known baseline
failure and remaining acceptance work belong in [BACKLOG.md](BACKLOG.md).

## Git checkpoints

For this project, the owner requests regular commits and pushes of coherent,
verified task-owned changes to a working branch. Preserve unrelated dirty work;
use an isolated publication worktree when necessary. Never push to the default
branch or include other tasks implicitly. Record known original test failures
without claiming a green product gate. Later explicit no-commit/no-push scope wins.

Marketplace submission, merges, releases and system changes remain separate
from these Git checkpoints and require their own applicable authorization.
