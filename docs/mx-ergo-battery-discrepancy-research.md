# MX Ergo battery reports and plugin status: investigation

Date: 2026-09-24. Device: original MX Ergo B01D, firmware `MPM06.10_0025`,
Bluetooth address `C2:B5:BB:BB:65:02`. This document records observations and
source-level deductions. It does not identify the physical state of charge.

## Current observations

| Layer | Observation | Meaning and limit |
| --- | --- | --- |
| User and input stack | User reports that the pointer moves; `hyprctl devices -j` lists `logitech-mx-ergo-multi-device-trackball-`. | Input works. A listed input device alone would not prove live events, but the user confirmed movement. |
| BlueZ | `bluetoothctl info` reports Paired, Bonded, Trusted, and Connected `yes` for `…65:02`; Battery1 reports 100, source `GATT Battery Service`. | BlueZ's connection and battery properties are distinct from the plugin's QML state. |
| Remote GATT | A `GattCharacteristic1.ReadValue` on Battery Level UUID 2A19 returned one byte `0x64` (100) at 23:45:43 MSK. The characteristic has the `read` flag and no `notify` flag. | A fresh read returned 100 from the GATT path; it is not just an old Battery1 property. It does not validate sensor accuracy or physical charge. An earlier packet capture independently confirmed an ATT Read Response of `0x64`. |
| Linux HID++ driver | `/sys/class/power_supply/hidpp_battery_29/uevent` reports `POWER_SUPPLY_CAPACITY_LEVEL=Normal` and `STATUS=Discharging`. There is no `capacity` or `voltage_now` file. The linked HID device has ID `0005:0000046D:0000B01D` and `HID_UNIQ=c2:b5:bb:bb:65:02`. | The kernel battery device belongs to this BLE mouse. `Normal` is its stored coarse HID++ category. We did not capture a fresh HID++ packet for this transition. |
| UPower 1.91.3 | `BatteryLevel=6` (Normal), `Percentage=55` (UPower CLI says “should be ignored”), `IconName=battery-low-symbolic`, `WarningLevel=1` (None). | All three battery presentation values derive from the same coarse kernel category. |
| Installed plugin | `Battery.js` maps `battery-low-symbolic` to `low`, maps BlueZ 100 to `full`, then chooses the lower tier. The user also reports that the plugin currently says disconnected while pointer input still works. | The displayed Low is a plugin category error. The disconnected display is a separate live-state mismatch; the exact failing QML property has not been observed. |

The running Omarchy shell's `listShellConfig` returns `deviceAddress=…65:02`
for this plugin, matching BlueZ and the HID device. Its IPC exposes open/close
methods but no read-only method for the plugin model's `btDevice` and `connected`
properties. The shell log shows the plugin loaded at 23:30:49 without an observed
QML error. These facts rule out a stale address in the current shell configuration,
but do not establish why the displayed connection state differs.

## Protocol and mapping

Logitech's [HID++ 2.0 protocol index](https://github.com/Logitech/cpg-docs/blob/master/hidpp20/README.rst)
defines feature `0x1000` and feature discovery. The published
[HID++ draft, pp. 9–10](https://lekensteyn.nl/files/logitech/logitech_hidpp_2.0_specification_draft_2012-06-04.pdf)
states that `GetBatteryCapability` returns `NumberOfLevels` and a mileage flag.
When the count is below ten or mileage is disabled, software maps reports into
four categories. The earlier device capture recorded feature `0x1000` capability
reply `ff 08 11 04 04 c0 78 0a`: four levels, rechargeable, mileage disabled.
Its status reply `ff 08 01 5a 32 00` carried code 90, next threshold 50,
discharging. Code 90 maps to Full; it was not a measured 90% charge. See the
prior local capture in the installed plugin's `research/battery-protocol.md` and
`research/battery-evidence.json`.

The downloaded, pinned [Linux v7.2 `hid-logitech-hidpp.c`](https://github.com/torvalds/linux/blob/v7.2/drivers/hid/hid-logitech-hidpp.c)
maps feature `0x1000` discharge codes below 11 to Critical, below 30 to Low,
below 81 to Normal, and 81–100 to Full. With fewer than ten levels or no mileage,
it exports `CAPACITY_LEVEL` rather than numeric `CAPACITY`. The driver tries
feature `0x1000` before `0x1004`, voltage `0x1001`, and ADC `0x1F20`; successful
use of `0x1000` does not prove the mouse lacks every other possible feature.
The host runs kernel `7.2.5-3-omarchy`; the v7.2 source explains the observed
exports, but is not a source audit of the Omarchy patchset.

The exact [UPower v1.91.3 supply mapping](https://gitlab.freedesktop.org/upower/upower/-/blob/v1.91.3/src/linux/up-device-supply.c)
assigns kernel `Normal` to UPower `BatteryLevel=Normal` and a compatibility
`Percentage=55`. Its [icon mapping](https://gitlab.freedesktop.org/upower/upower/-/blob/v1.91.3/src/up-daemon.c)
deliberately maps coarse Normal to `battery-low-symbolic`; coarse Low and Critical
map to `battery-caution-symbolic`. Therefore icon name is not the battery category.
The [UPower device API](https://upower.freedesktop.org/docs/Device.html) says the
percentage is approximate when `BatteryLevel` is set and warns that icon names
may differ from end-user expectations. It recommends `BatteryLevel` first.

The [Quickshell 0.3.1 `UPowerDevice` API](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.UPower/UPowerDevice/)
exposes `percentage` and `iconName` but does not expose UPower `BatteryLevel`.
The plugin used `iconName` as a fallback and thereby labeled Normal as Low.
This error is independent of the GATT/HID++ disagreement.

BlueZ's [GATT API](https://bluez.readthedocs.io/en/latest/gatt-api/) documents
`ReadValue` as a request to read the characteristic and describes `Value` as
cached. The fresh read above returned 100. The Battery Level characteristic has
no notification flag, so an unchanged BlueZ property between reads may be stale;
this does not explain the fresh response. The device's firmware may produce
different representations on HID++ and GATT. We have not established why.

## Official Logitech software checked

Logitech documents [MX Ergo support in Logi Options+](https://support.logi.com/hc/en-my/articles/25528092585879-Supported-devices-Logi-Options)
and says older Logitech Options is supported on
[Windows and macOS](https://support.logi.com/hc/nl/articles/360033892654-Compatibiliteit-van-Logitech-Options-met-Linux-en-Chrome).
We downloaded the Windows `logioptionsplus_installer.exe` from the
[official Logitech download page](https://support.logi.com/hc/en-us/articles/38826089168279-Logi-Options).
Its SHA-256 is
`3ed465b68280a68c8f1fa8b1769c06325052237946c9e1915f8e2b3ebe2f5fe9`.
Static inspection identified a 48 MB Windows PE setup program with download UI
strings; the inspected strings did not expose HID++ battery logic. It was not
executed or installed. Reverse engineering that bootstrapper cannot currently
override the direct device capture and open Linux driver evidence.

## Conclusions and next evidence

1. The plugin's **Low** label is wrong for UPower's current **Normal** category.
   Fixing this means reading the category itself for the selected mouse, ideally
   UPower `BatteryLevel` or its matched kernel `capacity_level`, instead of
   inferring it from `IconName`. Numeric `55%` must not be displayed as measured.
2. The mouse really returned GATT `100` on a fresh read, while the kernel's
   HID++ path currently holds Normal. Neither proves physical charge. Display
   source-qualified conflicting readings rather than silently choosing one.
3. User-confirmed pointer movement, BlueZ Connected `yes`, and a matching shell
   address conflict with the plugin's reported disconnected state. A targeted
   read-only QML diagnostic of the selected address and the three state flags
   (`connected`, `paired`, `bonded`) is needed to isolate this separate mismatch.
4. To explain the Full → Normal transition, capture a future driver-coordinated
   HID++ status response together with a fresh GATT read at the same time, then
   compare again after a known charge/discharge event. Avoid speculative percent
   conversions, HID writes to the active mouse, and claims about a physical
   battery defect without those observations.

Research actions did not disconnect the mouse, remove bonds, restart Bluetooth,
or change the installed plugin. No implementation tests were run.

## Follow-up on 2026-09-25

The plugin now reads `capacity_level` only from the HID power supply whose
metadata matches the selected MX Ergo. It no longer treats UPower's
`battery-low-symbolic` icon as a Low category. When the HID++ and BlueZ
categories disagree, the panel labels both sources. The coarse combined label
uses the lower category; no synthetic percentage is displayed.

After one Omarchy shell restart, the live model selected `…65:02`, logged
`connected=true`, `paired=true`, `bonded=true`, and changed its display category
from BlueZ High to HID++ Normal when the sysfs file loaded. This resolves the
observed plugin category error and shows that the current runtime model receives
the matching BlueZ record. It does not explain the physical charge or prove why
the panel showed disconnected in the earlier session. The full local plugin
suite passed; this was not a physical battery calibration test.
