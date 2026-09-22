# Privileged boundary review — 22 September 2026

The user explicitly authorized one GPT-5.5 read-only independent review as an exception to the normal Gemini route. The worker had no authority for system changes, publishing or child agents.

## Scope and result

Base HEAD: `7953f08f1b980eadac093653e3e01c7314b73b25`, with the working-tree sources below. Reviewed: helper, policy, installer, unprivileged client/wrapper, profile tests and README optional-profile contract.

Initial verdict: **changes_required**. One finding: `test_wrapper_ignores_bash_env` ran the production wrapper against live read-only host diagnostics, violating fixture isolation. No production privilege-escalation defect was established.

Accepted correction: copy the unchanged wrapper into the test's temporary directory next to a stub Python client, then check the exact forwarded argv and absence of the BASH_ENV marker. The production helper boundary was unchanged.

Final scoped verdict: **verified**. The reviewer reread that correction and reran `python3 -B tests/bluetooth-profile.py`: 18 tests, exit 0. Coordinator verification included the same production suite in `./tests/run.sh`.

## Reviewed source hashes

| Source | SHA-256 |
| --- | --- |
| `system/omarchy-mx-ergo-bluetooth` | `1d95b9bb06032e3ba87004621936777adaa923393091189b60d81af81989af01` |
| `system/io.github.pavellizunov.mx-ergo.bluetooth.policy` | `7e46dcf220ca03fe3e63002a01ca741c67e871d156a3f17c3a5d95e542d997b3` |
| `scripts/install-bluetooth-helper.sh` | `055e467ec17ecfe2811552b2a87c6b535e0e377417b85d2e7d5d182f39bedceb` |
| `scripts/bluetooth-client.py` | `8a66fed1e08146fb1985594d303578368ae7f7509774cc97584144c0f7fd3c91` |
| `scripts/low-latency.sh` | `1d9c3c051a7ce027e6750222e96fb9eeb2ce5c5fd906d5e1aa1fed217a1ce950` |
| `tests/bluetooth-profile.py` (corrected) | `a88fbbd45b494dedff2586db7c1739ab26a0b228fe76a7663a19a5c4159cead7` |

## Protections and limits

Observed source protections: fixed root-owned executable and Polkit action; active administrator authentication; validated operations and adapter names; physical adapter identity checks; baseline saved before writes; protected journal/rule paths; pending recovery retained on partial failure; externally changed values not overwritten automatically. No raw HID, network, credential collection or sudoers mutation was observed in this scope.

The review did not execute the installer, authorization prompt, controller changes, udev hotplug, removal or hardware recovery. It did not review the broader QML candidate. Scoped source approval is not a live hardware or security certification.
