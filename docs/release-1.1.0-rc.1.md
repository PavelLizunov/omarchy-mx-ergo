# MX Ergo 1.1.0-rc.1

Release pass requested by the owner on 25 October 2026 (UTC). This is a preview
release, not a stable hardware or Marketplace verification claim.

## Candidate identity

The complete local feature set matches recovery checkpoint
`0447a3cfc34353767ed1a5bc91899650bb72c5a9`, apart from current workspace guidance.
That checkpoint descends from the public default branch through the profile,
design, documentation and connection-recovery work. The release is assembled in
an isolated worktree; the original active branch and index are preserved.

The release tag identifies the exact published commit. Marketplace approval and
live listing installation availability are not implied by a GitHub release.

## Included functionality

- Named five-button profiles, independent assignments and keyboard switching.
- Adjacent button editor, explicit drafts and ten interface languages.
- Reactive approximate battery categories, explicit unavailable/conflicting data.
- Native BlueZ reconnection and bounded target-only discovery/recovery.
- Current scoped bar settings take precedence over stale Loader values.
- Serialized preference writes and bounded Hyprland reload/startup/wake recovery.
- Optional administrator Bluetooth helper remains separate and optional.

## Changes in this release pass

- Replace block-scoped `var` declarations reported by Qt 6.12 with `let`.
- Remove redundant same-name QML IDs shadowing object-valued properties; retain
  one distinct ID where the status process exposes its additional property.
- Limit the offscreen fixture's Commons registration to actual visual theme
  dependencies and strip runtime-only Quickshell imports from its inert copy.
  Production shell components and original assertions are not replaced.
- Qualify the Color singleton in profile controls and QtTest fixtures to avoid
  the current Qt name collision; retain real native controls and palettes.
- Identify the preview release explicitly in the manifest and current docs.

## Executed checks

Host: Omarchy 4.5.0rc1, Qt 6.12.0, Linux x86_64.

`./tests/run.sh` passes: documentation contracts, manifest validation, no
symlinks, theme-color contract, production-function model/recovery/profile tests,
18 isolated Bluetooth-helper tests, 17 settings-helper tests, seven preference
store tests, ten catalogs with 181 keys each, QML lint, diagram interactions,
103 profile/editor interactions and lockscreen fixtures.

The original Backtab assertion passes unchanged on this host. Its earlier failure
is retained as historical evidence; no causal claim about the old host is made.
Offscreen fixtures use installed native controls with inert theme I/O and model
operations. They do not execute physical Bluetooth or desktop input.

## Remaining limits

No new independent model review, screen-reader session, physical mouse-button
acceptance, suspend/resume, controller-profile enable/restore, udev hotplug,
multi-monitor or long-session acceptance was performed in this pass. Earlier
source reviews apply only to their recorded hashes. The running installation has
two saved profiles; those user preferences must not be replaced by release files.

The native updater expects the installation directory to equal the manifest ID.
This workstation still uses the historical directory `slovn.mx-ergo`, so the
README update command is not an in-place updater for that legacy directory.
The regular fresh-install destination uses the correct permanent ID.

Plugins remain unsandboxed user code. Button bindings are global, custom commands
are intentionally executable, charge precision is unavailable and the optional
controller helper has no measured latency benefit. See README and usage guide.
