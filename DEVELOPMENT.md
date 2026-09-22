# Development contract

Plugin ID: `io.github.pavellizunov.mx-ergo`. The entry point is `BarWidget.qml`; the working directory name is not an API. See [source ownership](MODULES.md), [hardware and runtime contracts](HANDBOOK.md), and [remaining work](BACKLOG.md).

## Runtime safety

Check `omarchy-shell lock status` before editing or reloading an active plugin. A locked, requested, pending, or session-locked state blocks activation because of the shared shell's session-lock crash risk (upstream #9441). Use the supported `omarchy restart shell` only while unlocked.

Battery status belongs to the reactive `Quickshell.Bluetooth` and `Quickshell.Services.UPower` models. No competing direct `/dev/hidraw*` readers or writers are supported. Unknown and disconnected states must remain explicit; they are not zero charge or proof of a healthy battery.

QML colors come from Omarchy tokens (`Color`, `Style`, and the injected bar palette). The optional administrator helper is separate from plugin runtime code and is installed only by a deliberate administrator action.

## Verification

Run `./tests/run.sh` before accepting or committing implementation changes. Every check must exit zero. Passing isolated tests is not evidence of untested native lifecycle, hardware or accessibility behavior. See [release review](RELEASE-REVIEW.md) for the exact acceptance limits.

Marketplace publication, Git pushes and system changes are separate actions from local development. Preparation does not authorize publication.
