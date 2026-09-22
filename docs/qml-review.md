# Final user-session source review — 22 September 2026

Independent bounded review via the installed `opencode-gemini` helper, configured model `ninitux/gemini-3.8-flash-high`. Tools and child agents were denied. Transport status: completed, exit 0, finish reason stop. Base HEAD: `7953f08f1b980eadac093653e3e01c7314b73b25`, with attached current sources below.

## Result and admission

The reviewer reported no concrete actionable defects and returned a scoped static PASS for the supplied contract. It covered native telemetry/identity, helper serialization and bounds, suspend/retry ownership, visible errors, panel keyboard logic, explicit editing and locale fallback.

Coordinator admission: accept as an independent source assessment with no new changes requested. The review did not provide line-by-line anchors or execute code; its broad wording about accessibility and guarantees is not adopted as runtime proof. The coordinator's separate production-function, Python and Qt tests remain the executed evidence. Receiver association still cannot identify the same physical mouse across transports using an unrelated BLE MAC.

## Exact supplied sources

| Source | SHA-256 |
| --- | --- |
| `ErgoModel.qml` | `3f17937ca98a4a77facce6cab537306e3f46d0d7b0dfbd5d09611cf17d2d36a6` |
| `ErgoPanel.qml` | `5e667456d483a9961dfbe41bbfff31081c7ef8bee96ba27cf666d02cd4135616` |
| `BarWidget.qml` | `371874a8c830c32417ce34a534ac9f00c0a604e2381b13ce0b75ee7f4dd38007` |
| `TrackballMap.qml` | `16d18556ecd27d5fefb355365d32a44200cea5a828b3b6a8e50d38c2096e7fe4` |
| `PowerDevice.qml` | `e9a8fd81297f11e8fa7a66e3289120c2bb6f99c66f0e6f0b32ceaa0f3b31cbaa` |
| `Battery.js` | `299ca82ac96dd448bd11139d3bec077bf5d63d6033b1f44a7670363bcf27208a` |
| `I18n.js` | `8f4aff82060d1a266fe5b62f6f8585f36b7e9f92b3d2a7b0b877eac8aa67a909` |
| `scripts/config-store.py` | `372e77cb5d30cda36ea5b91c297a9d28d0709decf728d1ea54405fafd4ab9db3` |
| `scripts/apply-settings.py` | `d445eb7ec248fec674e2995c44295d8bf21a313dc1110bcd658b59e3e2db4e48` |
| `docs/pattern-compliance-spec.md` | `21769390b70d423380aa42dd82f2e148e165c133778e538190a1dafdbe6f951e` |

## Limits

No native desktop keystrokes, device suspend/resume, logind restart, multiple displays, controller writes or Polkit prompts were exercised by the reviewer. The separately reviewed privileged boundary was excluded from this assignment. Translation catalog parity is covered by the local suite, not native-speaker review.
