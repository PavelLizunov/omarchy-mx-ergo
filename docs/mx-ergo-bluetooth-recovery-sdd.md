# MX Ergo Bluetooth recovery SDD

Status: investigation and implementation contract, 2026-09-25. The repository recovery implementation passes the local test suite and its files match the installed plugin. The manual button has now been tried twice against live BlueZ: the first attempt failed, and the second, after a reboot, restored the saved `…65:03` bond and user-confirmed pointer movement. A one-shot startup attempt for disconnected bonds is installed but awaits a normal future-boot check. The stronger input-verification path below remains a design proposal, not implemented.

## 1. Intent and invariants

### Outcome and scope

Make the plugin describe the MX Ergo's Bluetooth state honestly and provide a bounded, explicit recovery action when BlueZ reports a connection but channel 2 is still searching and the pointer does not work. Also identify the separate Omarchy Bluetooth panel behavior that can leave an unpaired device looking connected. The plugin can prevent a misleading status and help recover a stored bond; it cannot guarantee that the mouse, controller, BlueZ, kernel, and HID input path will never fail again.

The repository owns `ErgoModel.qml`, `ErgoPanel.qml`, translations, and its documentation. The installed Omarchy Bluetooth panel and `omarchy-bluetooth-device` helper live under `/usr/share/omarchy`; this SDD describes their required behavior but does not authorize editing those packaged files. `/home/slovn/.config/omarchy/shell.json` is outside this repository. Its explicit plugin `deviceAddress` was updated to the user-confirmed working bond `C2:B5:BB:BB:65:03` under the user's narrow standing exception; a later address change still requires a new BlueZ pair/bond check and pointer confirmation. No remote issue, PR, or release is part of this SDD.

### Non-negotiable invariants

- An automatic wake retry may call `Connect` only for one unambiguously selected, already paired and bonded MX Ergo that BlueZ reports disconnected. It must never automatically disconnect a reported connection, forget a device, pair a new address, change trust, or toggle the adapter.
- The manual recovery button is available even when the selected bonded MX Ergo says `Connected=yes`. Only an explicit click may disconnect that exact BlueZ device object; a later address change or object replacement aborts the attempt.
- Recovery never deletes a bond, restarts `bluetoothd`, powers the adapter off/on, modifies controller-wide settings, or operates on ROG CETRA or another device. A different advertised MX Ergo address is diagnostic information, never an automatic replacement for the selected bond.
- Every recovery attempt has a single owner and finite deadlines. Sleep and object loss request cancellation; model destruction stops its owned discovery process. Discovery already owned by Omarchy or another client must remain active. A pending BlueZ `Connect` can outlive abrupt plugin destruction, so the plugin must not claim confirmed cancellation in that case.
- `Connected`, `Trusted`, `Paired`, `Bonded`, service resolution, HID registration, and actual pointer movement are different claims. UI text must say which one was observed. A BlueZ success notification must not be described as proof that the pointer works.
- Preserve receiver (Unifying) behavior and existing pointer configuration. An uncertain Bluetooth identity or battery source remains unknown rather than being selected by name alone.

## 2. Evidence and causal boundary

### Observed on this host

Environment: BlueZ/bluez-utils 5.87-2, kernel 7.2.5-3-omarchy, Omarchy 4.0.4-1, Quickshell 0.3.1, `hci0` Lite-On USB adapter `04ca:4000`. The user directly observed that the channel 2 LED was searching while Omarchy and the plugin showed connected, and later confirmed working pointer movement after a fresh pairing.

The local `/var/log/pacman.log` has no package transaction on September 24–25;
its last transaction was September 23 and did not update BlueZ, the kernel,
Quickshell, or Omarchy. Thus no same-day upgrade of those packages explains the
timing by itself. This does not rule out changing device state, radio conditions,
desktop configuration, or a latent software defect.

| Observation | What it establishes | What it does not establish |
| --- | --- | --- |
| Old random-address record `C2:B5:BB:BB:64:FF` initially had `Connected=yes`, `Paired=yes`, `Bonded=yes`, `Trusted=yes`; the mouse did not move and channel 2 kept blinking. Targeted `Disconnect` changed only its link to `Connected=no` and retained the bond. | A bonded BlueZ connection report can disagree with usable input; target-only disconnect preserves the old bond. | Which component first lost the HID path, or why BlueZ still reported connected. |
| Normal `Connect` to `…64:FF` ended with `org.bluez.Error.Failed le-connection-abort-by-local`. An 8-second scan did not see the mouse. A later, longer scan found the old address after about 20–35 seconds, but connection during that scan still failed. | A brief scan is insufficient evidence of absence; discovery alone did not recover that record in the observed attempt. | That BlueZ issue #2503 is the same defect, or that every reconnect requires discovery. |
| After the user started pairing again, records `…65:00` and then `…65:01` appeared. `…65:01` was once `Connected=yes`, `Trusted=yes`, `Paired=no`, `Bonded=no`, with no MX Ergo in Hyprland's mouse list. Target-only pair attempts hung both before and after clearing the *unpaired* ghost record. | A live LE link and trust can exist without a completed bond or HID device. Clearing the unpaired record alone did not solve pairing. | That `…65:00` and `…65:01` are proven privacy rotations of the same BlueZ identity, or that trust alone caused the hang. |
| An adapter power cycle occurred during investigation; its first power-on failed, its second succeeded. Later, with the user reporting fresh rapid blinking, scanning saw `…65:01` within about 6 seconds and `Pair` succeeded immediately. BlueZ then reported `Paired/Bonded/Trusted/Connected=yes`, services resolved, the kernel created `uhid` and `logitech-hidpp-device`, Hyprland listed the MX Ergo mouse, and the user confirmed pointer motion. | One complete recovery succeeded when pairing was initiated promptly in a fresh pairing window. | Which of the power cycle, fresh pairing window, advertising timing, or another factor made that attempt succeed; long-term stability. |
| On 2026-09-24 around 23:17 MSK, the user again saw slow channel-2 blinking and no pointer motion. Saved `…65:01` still had `Paired/Bonded/Trusted/Connected=yes`, `ServicesResolved=true`, a `/sys/class/input/event16` MX Ergo endpoint, and a Hyprland mouse entry. A target-only disconnect cleared `Connected`; the saved address then advertised at −28 dBm during LE discovery, but `Connect` ended in `le-connection-abort-by-local`. | This recurrence includes a stale-looking BlueZ connection report despite service resolution and endpoint registration. The saved address was observable during this failed recovery, so total advertising absence is not a sufficient explanation for this attempt. | Whether the mouse sent input events during the reported connection, whether BlueZ received a suitable report at the exact connection instant, or which layer initiated the abort. |
| After the user changed channel 2 to rapid pairing blink, the mouse appeared as new random address `…65:02` at −28 dBm. `Pair` completed promptly; BlueZ then showed `Paired/Bonded/Connected=yes`, `Trust` set `Trusted=yes`, and the user confirmed actual pointer motion. The prior bonds were retained. | A second fresh pairing restored input; the address changes across pairing attempts are reproducible on this mouse. | Whether this is BLE privacy rotation, device firmware behavior, or a host-side identity mismatch. A new pairing is a different experiment from reconnecting the old bond. |

### Recurrence on 2026-09-25

The computer did not suspend overnight. The shell logged the selected `…65:02`
changing from connected to disconnected at 03:08 MSK. At 06:42 its `Connect`
request timed out. BlueZ still had `Paired=yes`, `Bonded=yes`, and `Trusted=yes`
for `…65:02`, but no MX Ergo HID device was registered. The user saw slow
channel-2 blinking and no pointer movement. Power-cycling the mouse, briefly
switching channels, and direct `Connect` did not restore the link. Several
short BlueZ discovery windows reported no devices; a phone could see the mouse
when the user made channel 2 blink rapidly.

After one authorized `hci0` power cycle at 06:54, the next discovery window
saw many nearby BLE devices. The shell then logged the *old* `…65:02` bond
connected from 06:55:38 to 06:55:53, before a fresh pairing completed.
Pointer movement was not checked during those 15 seconds. The old link's
disconnect coincided with entering rapid pairing mode. This sequence shows
that an adapter reset was followed by a temporary old-bond link, but does not
isolate the original radio failure or prove that reset was required.

Rapid pairing advertised a new random address `…65:03`. `Pair` and `Trust`
completed; BlueZ reported Paired/Bonded/Trusted/Connected, Hyprland registered
the MX Ergo mouse, and the user confirmed pointer movement. The plugin's
`deviceAddress` was changed to `…65:03` after that confirmation; JSON
validation and the shell's selected-address log both passed.

A later document-only plugin reload recreated the model with stale target
`…65:02`, even though both `shell.json` and `listShellConfig` contained
`…65:03`. One supported `omarchy restart shell` restored the model target to
`…65:03` while the mouse stayed connected. The host's plugin reload/settings
path was not traced, so this is an observed reload inconsistency rather than
an attributed plugin defect. Recheck the model target after changing
`deviceAddress`; a correct JSON file alone is not sufficient evidence.

The user then powered the mouse off for five seconds and back on without
entering pairing mode. BlueZ kept the `…65:03` bond but did not reconnect
automatically, and direct `Connect` ended in
`org.bluez.Error.Failed le-connection-abort-by-local`. During the next bounded
LE discovery, BlueZ changed this **same saved record** to `Connected=yes` at
06:59:53, Hyprland registered its HID input, and the user again confirmed
pointer movement. No second adapter reset or new pairing was needed for this
recovery. Discovery and connection were observed together; a controlled HCI
trace is still needed to establish the exact causal mechanism.

For a bonded disconnected mouse, this evidence favors one bounded, owned
discovery window before asking the user to re-pair. The plugin's manual
scan-and-connect path has since recovered input once and failed once on the
same saved bond; its result depends on lower-layer state and timing. Do not
turn this incident's manual adapter reset into an automatic plugin action; it
affects the controller and was not needed for the second recovery.

### Live plugin attempts and reboot on 2026-09-25

At about 07:43 MSK, the user clicked the installed plugin's recovery button
while `…65:03` was reportedly connected. The plugin disconnected that exact
record, retained `Paired/Bonded/Trusted=yes`, and started its own LE discovery.
The Quickshell `Connect` request ended with a D-Bus reply timeout at 07:43:57.
The scan later stopped (`Discovering=no`), but the mouse remained unusable.
One subsequent manual `bluetoothctl scan le` plus `connect …65:03` first
returned `le-connection-abort-by-local`; during the same bounded scan, the
saved address was seen at about −32 dBm and then BlueZ reported
`Connected=yes, ServicesResolved=yes`. This did not require a new pairing.
The user did not confirm pointer movement during that manual attempt before
rebooting, so it is only a link/HID observation.

The user rebooted at 09:47:22 MSK. At 09:47:46, the plugin selected the
bonded `…65:03` record with `Connected=false`; pressing channel 2 did not
restore usable input automatically. The kernel registered a MX Ergo UHID
endpoint at 09:47:49, but that alone did not establish working input. The
user then clicked recovery in the plugin. From 09:48:37 to 09:48:39,
`bluetoothd` logged 172 `report_value_cb() bt_uhid_input: Invalid argument
(22)` messages. At 09:48:39 the kernel logged one ACL packet for an unknown
connection handle and BlueZ said `No matching connection for device`. The
selected record changed to `Connected=yes`; at 09:48:40 a new MX Ergo
HID++/UHID endpoint was registered. Afterward `Discovering=no`, the ROG CETRA
remained connected, and the user confirmed that channel 2 moved the pointer.

In [BlueZ 5.87's HOG code](https://github.com/bluez/bluez/blob/5.87/profiles/input/hog-lib.c),
that log follows a received GATT HID report notification whose handoff to
UHID returned `EINVAL`. The [BlueZ UHID helper](https://github.com/bluez/bluez/blob/5.87/src/shared/uhid.c)
can return `EINVAL` for a missing UHID object or propagate the kernel's
error; [Linux UHID input handling](https://github.com/torvalds/linux/blob/v7.2/drivers/hid/uhid.c)
returns `EINVAL` when its input endpoint is not running. These source paths
make a transient HID handoff failure plausible, but the journal alone does
not identify which device emitted the notification or which return path fired,
and it does not prove that the errors caused the earlier
reconnect failure. No synchronized HCI or uniquely attributed input trace
was captured. The current plugin logs recovery stage, saved-address report,
result, and elapsed time for the next reproduction.

### Boot recovery extension: Micro-Spec

**Intent and invariants.** With the existing `autoReconnect` preference enabled,
make one bounded attempt per plugin-model lifetime after preferences and the
selected bonded record become available. Run it only while BlueZ reports the
selected record disconnected. It must not disconnect a reported connection,
pair, trust, change address, reset Bluetooth, or touch another device. A
manual recovery click or an independently established link consumes this
startup opportunity, so a later ordinary disconnect does not start a hidden
scan. A shell restart may create one new model lifetime and hence one new
startup opportunity. This behavior cannot guarantee reconnection if the
mouse does not advertise during the bounded window.

**Behavior contract.** Five seconds after both configuration and a unique
selected paired/bonded record are ready, recheck the state and invoke the
existing owned scan-and-connect state machine in a mode that refuses
`Connected=yes` even if the state changed at the last moment. The existing
45-second approximate scan/connect bound, cancellation on sleep/shutdown,
same-address capture, and own-session cleanup apply. `autoReconnect=false`
disables startup scheduling. The UI keeps its BlueZ-report wording and never
claims pointer movement without the user confirming it.

**Verification.** Simulate disconnected bonded startup, an already connected
mouse, disabled preference, incomplete bond, multiple adapters, a manual
click winning the race, selection changes, and a late `Connected=yes` before
the timer fires. Check no automatic `disconnect`, pair, trust, adapter change,
or repeated scan in one model lifetime. Run the existing full plugin checks,
then inspect the installed log on a future ordinary boot; do not reboot the
current working desktop merely to force this acceptance case. The simulations,
full plugin suite, installed manifest validation, and shell-load check passed;
the future-boot behavior has not yet been field tested. If BlueZ is
connected but the pointer is dead, only the explicit manual action applies.

The exact dates, command outputs, and original constraints are in `/tmp/mx-ergo-bluetooth-handoff.md` and the session log. The handoff describes an earlier state and is superseded by the later observations above. A privileged HCI trace was not available (`btmon` returned `Operation not permitted`); no packet-level root cause has been established.

### Source-proven semantics and a separate Omarchy defect

BlueZ defines `Paired` as completed pairing information exchange, `Bonded` as persisted pairing information, `Connected` as a current connection, and `Trusted` as an independently writable property. Its `Pair()` connects, pairs, and discovers services; `Connect()` can report success if **at least one** supported profile connects. Therefore none of those flags alone proves an operating pointer. See the [BlueZ Device API](https://github.com/bluez/bluez/blob/master/doc/org.bluez.Device.rst). The [BlueZ LE CLI documentation](https://github.com/bluez/bluez/blob/master/doc/bluetoothctl-le.rst) says a LE connection needs an advertising report and may return `le-connection-abort-by-local` if none arrives before timeout. That describes the error, but does not identify why this mouse's earlier attempt failed.

The installed `/usr/share/omarchy/bin/omarchy-bluetooth-device` `pair` path suppresses the result of `bluetoothctl pair`, then unconditionally runs `trust` and `connect`. Its `connect` path also trusts before connecting. The installed Bluetooth `Panel.qml` treats `trusted` as enough to choose `connect` instead of `pair`, refuses an action whenever `connected` is true, and treats `connected` alone as completion. `Model.js` places every `connected` device in the Connected section. This is a demonstrated control-flow defect: it permits a trusted, unpaired LE record to appear complete and blocks a new pairing action. The observed `…65:01` state is consistent with that defect, but the investigation did not trace the exact UI click that created it; causation for that particular record remains unproven.

[BlueZ issue #2503](https://github.com/bluez/bluez/issues/2503) reports a similar reconnect error and discovery-dependent success for a Trezor Safe 7. Its device, adapter, and successful experiment differ from ours. Treat it as a testable lead only. BlueZ documents that a privacy-enabled device's pre-pair address can differ from its identity address after pairing, but the appearance of several MX Ergo addresses in our scans is not proof that this mechanism caused the record changes.

Working hypotheses for a future failure, ranked by what the present evidence can test rather than by assumed likelihood:

| Hypothesis | Supporting observation | Observation that would weaken or reject it |
| --- | --- | --- |
| The saved BlueZ identity is not matched to the report needed for connection, or the mouse advertises a new pairing identity. | `…64:FF` was often absent; later `…65:00/01/02` appeared. `…65:01` did advertise during discovery before a failed connect, narrowing this hypothesis for that attempt. | A synchronized HCI trace proves the proper target advertisement and identity resolution reached BlueZ during connection creation. |
| BlueZ/controller/kernel LE connection handling aborts despite a client-visible advertisement. | Both `…64:FF` and `…65:01` returned `le-connection-abort-by-local`; the latter advertised at −28 dBm during discovery. Issue #2503 remains a similar report only. | An HCI trace shows that the controller did not receive a usable target report during the actual connection attempt; or a controlled scan/no-scan comparison yields no relevant difference. |
| LE connects but encryption, GATT/HID resolution, or input delivery fails. | On the latest recurrence `Connected=yes`, `ServicesResolved=true`, and an MX Ergo `uhid`/Hyprland endpoint coexisted with no user-observed pointer movement. | A synchronized trace shows mouse-specific input events reaching the compositor while the pointer still appears stuck, which shifts attention to compositor mapping. |
| Omarchy's helper/panel masks a failed pairing as success. | Its source suppresses pair errors and checks `connected` alone. | A captured reproduction of the specific failed pairing that bypasses the helper would reject its involvement in that occurrence, although the source defect remains. |

### Decision on implementation approach

**Verdict: Extend** the existing Quickshell/BlueZ integration and the plugin's single recovery action. No new daemon, privilege, dependency, persistent polling loop, or Bluetooth-wide reset is justified by the evidence. The host-panel correction is a separate, generic Omarchy change; plugin code cannot repair that panel's command routing.

The implementation is constrained by the installed APIs. [BlueZ 5.87's `bluetoothctl` source](https://github.com/bluez/bluez/blob/5.87/client/main.c) shows that `scan le` starts discovery on its default controller, prints `Discovery started` after the method reply, and leaves the noninteractive process running to receive device changes. The [Quickshell 0.3.1 Bluetooth source](https://github.com/quickshell-mirror/quickshell/blob/v0.3.1/src/bluetooth/bluez.cpp) tracks BlueZ `Device1` objects, including disconnected bonds, while its [device source](https://github.com/quickshell-mirror/quickshell/blob/v0.3.1/src/bluetooth/device.cpp) exposes connect/disconnect failure through the state returning from `Connecting`/`Disconnecting`. Those sources justify the proposed interfaces, but do not replace a runtime check on this host.

### Which signals are actually used

| Signal or observation | Known interpretation | Used by the plugin now? |
| --- | --- | --- |
| BlueZ `Connected`, `Paired`, `Bonded` for the selected record | BlueZ link and saved pairing state, not working pointer input | Yes, through Quickshell for status and recovery admission. |
| Fresh LE advertisement seen by this client's scan | The saved address was reported during this scan, not proof that a connection will succeed | Implemented in explicit recovery; future attempts now log whether this client's scan saw the saved address. Another address is diagnostic only. |
| HID++ battery feature `0x1000` | The Linux driver decodes this MX Ergo's coarse battery category | Indirectly: the plugin reads the matched kernel `capacity_level`; it does not send HID++ commands. |
| Bluetooth GATT Battery Level `0x2A19` | BlueZ's reported numeric battery value; freshness and physical accuracy are separate questions | Yes, through Quickshell/BlueZ, labelled as an approximate report. |
| BlueZ `ServicesResolved` and kernel `uhid`/`eventX` endpoint | Service discovery and registered input endpoint, not actual event flow | Collected manually during diagnosis; not used to claim pointer movement in the plugin. |
| HID++ wireless status `0x1D4B`, raw mouse events, LED blink state, HCI packets | Published feature or potential observations, but no demonstrated mapping from them to this failure | No. The plugin cannot read the LED; no failure-time HCI trace or attributed mouse-event capture exists. |

Logitech's [HID++ index](https://github.com/Logitech/cpg-docs/blob/master/hidpp20/README.rst)
and the [Linux driver](https://github.com/torvalds/linux/blob/v7.2/drivers/hid/hid-logitech-hidpp.c)
cover battery decoding; [Solaar's feature list](https://github.com/pwr-Solaar/Solaar/blob/master/docs/features.md)
also documents read-only wireless status. That does not establish that any
published HID++ field reports whether this physical mouse is moving the
pointer. Adding a field to the plugin before measuring it in a failed session
would only create another possible false success indicator.

### What can be guaranteed

There are two indistinguishable states under the plugin's current observations: a bonded mouse that is connected but idle, and a bonded mouse whose BlueZ record says connected while no usable pointer input arrives. Both can have `Connected=yes`, `Paired=yes`, `Bonded=yes`, and no recent input event. No timer or reconnect policy based only on those fields can always distinguish them. Therefore the plugin cannot guarantee automatic detection of the user's physical failure or safely disconnect every ghost link without sometimes interrupting a working mouse. BlueZ also permits `Connect()` to succeed when only one supported profile connects, and `ServicesResolved=yes` confirms service discovery rather than input delivery ([Device API](https://github.com/bluez/bluez/blob/5.87/doc/org.bluez.Device.rst)).

| Claim | Achievable contract | Boundary |
| --- | --- | --- |
| No misleading success in this plugin | Display `link reported` for BlueZ state; reserve `input verified` for a separate, current observation of this mouse's input. Clear verification after disconnect, device replacement, suspend, or loss of the observed input endpoint. | The installed Omarchy Bluetooth panel has its own incorrect success path and needs a separate host patch. |
| No unintended Bluetooth side effects | Admit only the captured bonded object, allow disconnect only after a click, start and release the attempt's own discovery session, and never pair, forget, power-cycle, or touch another device. | This becomes an implementation guarantee only after controlled state-machine and discovery-ownership checks. A frozen process or failed host service is outside the plugin's control. |
| Bounded answer to a recovery request | End with an explicit link/error/timeout/cancel result and an independent saved-address observation. Never silently retry forever. | A bounded failure is a correct outcome; it does not make the mouse work. |
| Mouse input works now | Require a short user-initiated challenge: identify the MX Ergo HID endpoint, observe a mouse-specific event if permissions allow, then have the user confirm visible cursor movement. Report separately which steps were observed. | Endpoint presence and kernel events do not alone prove compositor delivery; user confirmation is time-limited, not a promise of continued operation. |
| The MX Ergo always remains usable | No software-only guarantee is possible with one wireless mouse, battery, radio path, adapter, and host. A separately working pointing device or the supported Unifying path can provide a fallback. | Redundancy improves availability but cannot guarantee this physical MX Ergo will always function. |

[Logitech's Easy-Switch guide](https://support.logi.com/hc/es-mx/articles/360023189234-Funci%C3%B3n-Easy-Switch-de-Logitech-MX-Ergo) distinguishes rapid blinking (discoverable, seeking **new pairing**), slow blinking (seeking an existing connection), and steady light (connection established). Thus a rapidly blinking channel after a long press is a pairing workflow, not evidence that the saved bond should reconnect. It does **not** prove the old host bond was erased or explain the earlier ghost connection. The plugin cannot read the LED; the user must supply that observation when diagnosing a recurrence.

The minimum reliable product contract is fail-closed reporting plus the explicit target-only recovery already drafted. For stronger confirmation, add an optional, short-lived input challenge only after checking that the selected BlueZ object maps uniquely to a kernel HID/input device. The Linux [evdev interface](https://docs.kernel.org/input/input.html) exposes per-device events, but [libinput's tools documentation](https://wayland.freedesktop.org/libinput/doc/latest/tools.html) notes that access to `/dev/input/event*` usually requires root. Do not add a privileged or continuously running input listener just to label the plugin Connected; if unique attribution or access is unavailable, ask for user confirmation and display `input unverified`. A changed cursor position by itself is insufficient when another pointer can move it.

To pursue a lasting root-cause fix, capture one failed attempt and one successful attempt with synchronized LED state, BlueZ properties, kernel/HID registration, and, if separately authorized, a short HCI trace. A controlled scan/no-scan comparison on the *same saved bond* can test the BlueZ/kernel hypothesis; a new pairing address or fast pairing blink is a different experiment. Only after the failure layer is identified should a specific BlueZ/kernel/firmware or Omarchy host change be proposed and checked against recurrence. Until then, automatic adapter resets or silent re-pairing would hide evidence and can interrupt unrelated devices.

## 3. Interface and behavior contract

### State model and user language

Derive UI state from the selected BlueZ object and, where available, a separately labelled HID observation. Do not collapse unknown into false or into success.

| BlueZ state for selected record | Plugin classification | Allowed action |
| --- | --- | --- |
| No unique record, or explicit configured address missing | `Selection unavailable` or `Pinned record missing` | Explain selection; no automatic selection of a same-name replacement. |
| `Connected=yes`, `Paired=no` or `Bonded=no` | `Bluetooth link reported; pairing incomplete` | No bonded recovery; explain that a new pairing is required. Do not display a normal BLE battery as proof of input. |
| `Connected=no`, `Paired=yes`, `Bonded=yes` | `Bonded; disconnected` | Existing automatic wake `Connect` and explicit manual recovery may operate on this record. |
| `Connected=yes`, `Paired=yes`, `Bonded=yes` | `Bonded Bluetooth link reported` | Manual recovery remains available; do not silently disconnect. HID endpoint or physical movement is still unverified unless independently observed. |
| Bonded link plus a corresponding Hyprland input endpoint | `Pointer endpoint detected` | Show as a stronger diagnostic, not as proof that events are flowing. A matching name is insufficient to attribute the endpoint if multiple identical mice or a receiver are present. |
| User confirms pointer movement after recovery | `Working in this observed session` | This is the acceptance observation for the physical fault; the plugin must not fabricate it. |

An explicit `deviceAddress` selects exactly that BlueZ record. Without one, a sole bonded match or the sole connected bonded match may be chosen; multiple equivalent records are ambiguous. Remembering a previous address is acceptable only while that BlueZ object remains available and uniquely identifiable. A newly advertised same-name address is shown as a possible new pairing candidate, with its actual paired/bonded state, but is never automatically trusted, paired, connected, or written into configuration.

### Plugin manual recovery state machine

Input: user click, selected object identity/address, adapter identity, and current BlueZ properties. Output records the BlueZ link outcome, whether this client's discovery stream showed a fresh report for the selected address, whether a different same-name address appeared, and any phase error/timeout. Keep exactly one attempt in flight. The action becomes **Cancel recovery** while active and remains disabled only during child-process cleanup; preserve normal UI responsiveness. For example, `Connected=yes` with no report visible to this client must say both facts; it must not be reported as an advertised-address match or as working input.

1. **Admission:** require a syntactically valid selected address, a unique object on the active enabled adapter, and `Paired=yes` plus `Bonded=yes`. Capture that object and adapter. For the `bluetoothctl` implementation, require exactly one adapter: the CLI chooses its own default and cannot be assumed to match a different Quickshell selection. Reject stale or ambiguous selection without side effects. Automatic wake behavior is a separate path and never calls this state machine for a reported-connected object.
2. **Disconnect, only when currently reported connected:** call `Disconnect()` on the captured object after the click and wait at most 5 seconds for `Connected=no`. On timeout/error, stop; do not scan or issue `Connect`. If already disconnected, advance without calling `Disconnect`.
3. **Acquire a discovery observation:** start one owned LE discovery session even if another client is already discovering, so the attempt has its own observable window and can release only its own session. Wait at most 5 seconds for the attempt's session to start. A global `adapter.discovering=true` alone is not proof that this attempt owns a session or saw the target. If the implementation cannot establish its own session, fail clearly and leave any pre-existing discovery untouched. The existing `bluetoothctl --timeout 60 scan le` child is a candidate, but its output and ownership behavior must be validated before relying on it; a direct BlueZ D-Bus session is an alternative if CLI output is not reliable. The [BlueZ Adapter API](https://github.com/bluez/bluez/blob/master/doc/org.bluez.Adapter.rst) gives each client its own discovery session and makes `StopDiscovery` release only that client's session.
4. **Observe fresh advertising:** begin the timer after the owned session starts. Watch for a timestamped report of the *captured address* during this attempt; record same-name, different-address reports separately as diagnostics. Keep the owned discovery session active for up to about 45 seconds because this host once took 20–35 seconds to see the saved address. Never infer a *client-visible* fresh report from a cached Device object, a previous RSSI, the global `discovering` flag, or a same-name address. Absence from this client's output is `not observed by this client`, not proof that the controller or BlueZ saw no advertising. Quickshell 0.3.1 exposes `paired`, `bonded`, and `connected`, but [its documented BluetoothDevice API](https://quickshell.org/docs/v0.3.1/types/Quickshell.Bluetooth/BluetoothDevice/) has no RSSI property, so a fresh-report signal needs an explicitly verified source rather than an invented QML field.
5. **Connect:** call `Connect()` once on the same captured bonded object while this discovery session is active: immediately after a fresh target report, or after a short scan warm-up (candidate 10 seconds) if no report is exposed to the client. BlueZ may receive or resolve an advertising report internally that the chosen client API does not emit; refusing all such attempts would create a false negative. Bound the connect call to about 35 seconds and the entire owned scan to about 45 seconds. Abort if the object disappears, the adapter changes/disables, or the selection changes. Report link outcome and client-visible advertising outcome independently. `Connected=yes` means only `link reported`; a method error or timeout is a failed attempt. Never act on a different address or fall through to pairing it.
6. **Cleanup:** on every handled exit, stop/close only the session acquired in step 3, cancel timers, discard late events, and release captured objects. If the helper has not exited, keep the action busy until its own process is reaped or a bounded cleanup deadline reports failure. Never set the shared adapter `discovering=false` to clean up a process-owned session. Request cancellation on sleep or explicit user cancellation. Abrupt plugin unload kills the owned scan but cannot confirm that a pending BlueZ `Connect` has ended; its later result must be treated as unknown.

The timing numbers are candidate upper bounds for implementation, not measured guarantees. With scan observation and connection overlapping, the nominal scan is at most about 45 seconds after startup; allow an additional bounded disconnect/start/cleanup margin in the parent and a longer hard timeout for its child. If a connect started late, end it within the parent deadline rather than leaving an orphan. Early success or failure ends the attempt immediately. Rate-limit repeated clicks through the single-flight state, without an automatic retry storm.

### Working-tree implementation versus this contract

The uncommitted draft keeps a manual action visible for a reported-connected bond, disconnects only the selected object, starts an owned `bluetoothctl` discovery session on a one-adapter host, reads its discovery output, and distinguishes a fresh client-visible target report from a warm-up connection attempt. It keeps the scan active for the bounded connect attempt, offers explicit cancellation, and reports whether the saved address was seen. The plugin also distinguishes an unpaired link from a bonded BlueZ connection report. Local model, recovery, startup, localization, QML lint, offscreen UI, and lockscreen checks pass; the installed manifest validates and the shell selected the correct address after reload. The installed manual version restored user-confirmed pointer movement once after reboot and failed once before reboot; in both attempts discovery ended. A successful BlueZ link still requires a separate physical input check.

The 2026-09-25 Astra review found that the earlier cancellation ended the scan but could leave Quickshell's `Connect()` pending. The worktree now issues a target-only `bluetoothctl disconnect` when cancellation or timeout occurs during `Connecting`, waits for the command and Quickshell state to settle, and reports an unconfirmed stop rather than claiming cancellation on failure. A pending Quickshell connection blocks a new manual recovery. The wake retry now waits for the first `Connect` to settle and is discarded after a 60-second deadline or selection change. These changes passed local simulations and static checks, but their live BlueZ behavior and installed copy have not yet been accepted at this point in the document. [BlueZ Device1](https://github.com/bluez/bluez/blob/5.87/doc/org.bluez.Device.rst) permits `Disconnect()` to cancel a preceding `Connect`; [Quickshell 0.3.1](https://github.com/quickshell-mirror/quickshell/blob/v0.3.1/src/bluetooth/device.cpp) refuses its QML `disconnect()` while `Connected=false`, so an exact-address BlueZ command is required for that pending phase.

### Separate Omarchy host correction

For the generic Bluetooth panel/helper, a later separately authorized change should:

- Propagate `pair` success/failure and timeout instead of `|| true`; trust and connect only after `Paired=yes` and `Bonded=yes` are observed for the same record. A failed pair must end visibly with a retryable error.
- Route `Connected=yes` with `Paired=no` or `Bonded=no` to an incomplete-pairing state, not to successful Connected. A user-requested repair may disconnect only that selected record, wait for `Connected=no`, and then pair its freshly observed address. `Trusted=yes` alone must not route the action to `connect`.
- Complete a pairing action only when pairing/bonding is confirmed, with profile/HID state reported separately. Preserve other device rows, their own discovery sessions, and their ongoing connections.

This is a proposed host contract, not a patch to `/usr/share/omarchy` and not an attribution of every BLE failure to Omarchy.

### Pairing and address changes

If the saved address has disappeared or only a new, unbonded address advertises, the bonded recovery path must stop. The user can put channel 2 into rapid pairing mode (Logitech documents holding Easy-Switch for three seconds), scan, pair the newly advertised record while the pairing window is active, and verify `Paired=yes` and `Bonded=yes` before trust/connect. This is a separate, explicit pairing flow; the plugin must not remove old bonds or silently retarget `deviceAddress`. Two observed successful attempts followed fresh rapid blinking and prompt pairing, but the exact condition that made them succeed remains unknown. See [Logitech's MX Ergo Bluetooth instructions](https://support.logi.com/hc/en-ch/articles/360023356693-Connect-the-Logitech-MX-Ergo-to-a-computer-using-Bluetooth-or-Unifying-receiver).

## 4. Verification and investigation plan

The user subsequently requested verification. `bash tests/run.sh` passed on 2026-09-25, including model/recovery simulations, all 10 locales, QML lint, offscreen QML interaction tests, and lockscreen checks. After copying the files to the installed plugin, `omarchy plugin validate`, QML lint, and the recovery simulation passed there too; the shell logged a reload. The button was then exercised twice against live BlueZ, with one failure and one user-confirmed pointer recovery; both attempts ended their discovery sessions. This is field evidence for a bounded manual fallback, not proof of a guaranteed reconnect. The manual `bluetoothctl` sequence above is separate radio evidence.

### Smallest implementation checks

1. **Pure state/selection checks:** unique bonded record; duplicate MX Ergo names; pinned address missing; trusted-unpaired-connected ghost; bonded-connected ghost; receiver-only path; null/unknown flags. Assert the UI and allowed action for each table row above.
2. **Recovery state-machine checks with controlled fake signals:** click while `Connected=yes`; confirm only the captured address is disconnected and `Connect` waits for `Connected=no` plus owned discovery startup. Check early connect on a fresh target report and one delayed connect when no client-visible target report arrives; these cases must produce distinct diagnostics. Cover only a different address, immediate disconnect/connect method failure exposed by Quickshell state, scan failure, timeout, object replacement, adapter loss, sleep, and late callbacks. Check that a selected address stays fixed when several bonded same-name records exist. Ensure zero `pair`, `forget`, trust, adapter-power, or service-restart calls.
3. **Discovery ownership check:** begin Omarchy or another client's scan first, run one recovery attempt, then verify that its own session stops and the other scan remains active. Also verify cleanup when no other scan exists and that a second adapter prevents this CLI-based flow. Inspect actual `bluetoothctl` output/session behavior on BlueZ 5.87 before accepting the parser; if it cannot provide a fresh report reliably, use an owned D-Bus session and do not falsely accept cached data.
4. **Consumer path:** activate only the task-owned plugin build in an unlocked Omarchy session when authorized; press the button through the real panel, inspect BlueZ properties, kernel HID registration, `hyprctl devices -j`, and user-confirmed cursor movement. A positive BlueZ link without an HID endpoint or movement is partial, not a pass. Keep ROG CETRA connected and verify no other target was operated on.
5. **Host fix, if separately undertaken:** drive the real helper/panel through successful pair, failed pair, timed-out pair, connected-unpaired, trusted-unpaired, and ordinary bonded reconnect. Ensure command errors remain visible and unrelated devices are unchanged. This is outside this repository's acceptance until a host change is authorized.
6. **Optional input challenge, if separately scoped:** prove a unique mapping from selected BlueZ record to kernel `eventX` and Hyprland mouse before claiming mouse-specific input. With permitted device access, observe one short user-requested relative-motion or button event from that node. Separately ask the user whether the visible pointer moved. Cover unavailable permissions, multiple identical mice, event from another pointer, endpoint disappearing, and an idle mouse; all must remain `input unverified` rather than a false success. Do not keep a background input recorder.

### Evidence to collect on the next recurrence

Without disrupting a currently working mouse, record a synchronized timeline: user-observed LED pattern and channel, BlueZ `info` (address type, Paired/Bonded/Trusted/Connected/ServicesResolved/UUIDs), adapter discovery state, fresh advertisements per address, `journalctl` messages for `bluetoothd` and kernel HID, and Hyprland input enumeration. Record whether the failing address advertised **during** the connection attempt and whether a different address appeared. Do one bounded target-only attempt rather than repeated adapter or service resets.

#### Immediate capture, before recovery

When the pointer first stops, note the local time, channel number, and whether
the channel LED blinks slowly or rapidly. Do not long-press Easy-Switch, re-pair,
disconnect, or scan before the first snapshot: those operations change the state
being diagnosed. For the currently pinned record `C2:B5:BB:BB:65:03`, collect:

```bash
date --iso-8601=seconds
bluetoothctl info C2:B5:BB:BB:65:03
bluetoothctl show
for property in Connected Paired Bonded ServicesResolved; do
  busctl get-property org.bluez /org/bluez/hci0/dev_C2_B5_BB_BB_65_03 org.bluez.Device1 "$property"
done
hyprctl devices -j | jq -r '.mice[]? | select(.name|test("mx.ergo";"i"))'
for name_file in /sys/class/input/event*/device/name; do
  if rg -qi 'MX Ergo' "$name_file"; then
    printf '%s: ' "$name_file"
    cat "$name_file"
    readlink -f "${name_file%/name}"
  fi
done
journalctl -u bluetooth -b --since '5 minutes ago' --no-pager -o short-iso
journalctl -k -b --since '5 minutes ago' --no-pager -o short-iso
```

These are read-only commands; the journal excerpts may contain addresses of
other devices and should stay local. If the pinned address changes, replace it
in both `bluetoothctl` and the D-Bus object path only after confirming the new
record. `Connected=yes`, `ServicesResolved=true`, or an existing `eventX` node
does not establish that mouse events are arriving. On 2026-09-25 the working
baseline had all four D-Bus flags `true`, one MX Ergo Hyprland mouse, and
`event16` under `uhid/0005:046D:B01D.0033`; the event number is not stable.

After the snapshot, one explicitly clicked plugin recovery attempt can be
compared with a second snapshot and the user's observation of pointer motion.
If the snapshots do not distinguish the failure stage, compare short `btmon`
HCI traces of one failed and one successful attempt when local privileges are
available. Inspect advertising, connection termination, encryption, GATT/HID
resolution, and `uhid` registration. An attributed input-event observation is
still needed to locate an HID-to-pointer failure. `btmon` previously returned
`Operation not permitted`; do not request a password or bypass privilege
controls to obtain a trace. Keep raw traces out of Git and remove other
devices' addresses before any external report.

Interpretation gates:

- No fresh target advertisement within the bounded window: classify as *not observed*. Investigate mouse pairing/advertising state and whether a different address appears; do not call it a BlueZ regression from this alone.
- Fresh target advertisement but `Connect` aborts locally: investigate BlueZ/controller/kernel path with HCI timing. Issue #2503 becomes stronger evidence only if the same device succeeds under a controlled scan/no-scan comparison or a trace matches the failure mechanism.
- Bonded `Connected=yes` but no HID endpoint: inspect services, encryption, `uhid`, and input registration; neither BlueZ link nor battery data establishes usable input.
- HID endpoint exists but pointer does not move: inspect input events and device mapping separately; the plugin cannot infer movement from BlueZ flags.

### Acceptance boundary

The repository fix is acceptable only when the manual flow handles a false `Connected` report for the selected bonded record, reports whether a fresh target advertisement was visible to its client, attempts only the selected saved bond, leaves other discovery sessions and devices untouched, and distinguishes BlueZ link status from working input in the UI. A stronger `input verified` claim requires the separate challenge above and is valid only for that observed session. The Omarchy host logic requires a separate patch and separate acceptance. Neither acceptance claim establishes the lower-level root cause or guarantees that the fault cannot recur.
