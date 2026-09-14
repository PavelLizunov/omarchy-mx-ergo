# Agent Directives & Repository Rules

## Quick Reference

- **Plugin ID:** `io.github.pavellizunov.mx-ergo`
- **Working Folder:** `~/.config/omarchy/plugins/slovn.mx-ergo/`
- **Supported Hardware:** Logitech MX Ergo (`046d:b01d`), Bluetooth BLE connection.
- **Primary References:**
  - `MODULES.md` — Source ownership, component interfaces, and targeted checks.
  - `HANDBOOK.md` — Hardware telemetry contracts and Hyprland Lua commands.
  - `BACKLOG.md` — Development roadmap and open tasks.

## Non-Negotiable Safety Rules

1. **Omarchy Lockscreen Guard (Upstream Bug #9441):**
   - Never reload or alter active plugins while `omarchy-shell lock status` indicates the screen is locked or requested (`locked: true` or `sessionLocked: true`).
   - Reloading plugins during session lock causes a fatal Quickshell session lock crash in Omarchy Quattro.

2. **No Competing Raw HID Readers:**
   - Do NOT attempt to read or write to `/dev/hidraw*` directly from user processes.
   - The Linux kernel driver `hid-logitech-hidpp` already owns the device node, and direct uncoordinated writes can desynchronize device power management.
   - All status reads belong in the reactive C++ models (`Quickshell.Bluetooth` / `Quickshell.Services.UPower`).

3. **Strict Uncertainty & Data Integrity:**
   - Never coerce unknown or disconnected battery states to 0% or false.
   - Disconnected trackball state is an explicit state (`batteryPercent: null`).

4. **Zero Hardcoded Hex Colors:**
   - Never insert hardcoded hex color codes (`#hex`) into QML files.
   - All colors must derive strictly from Omarchy design tokens (`Color.*`, `bar.foreground`, `Style.*`).

5. **Mandatory Verification Protocol:**
   - Before completing any task or committing changes, run:
     ```bash
     ./tests/run.sh
     ```
   - Every check must exit with 0.
