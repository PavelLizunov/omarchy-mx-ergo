#!/bin/bash
# Logitech MX Ergo - Low Latency & High Polling Rate Setup (125 Hz)
# Supports:
#   --enable  (default) : Sets 7.5ms-11.25ms intervals and disables USB autosuspend
#   --disable           : Restores default kernel intervals (30ms-50ms) and standard USB autosuspend

set -euo pipefail

action="${1:---enable}"

if [[ "$action" == "--disable" || "$action" == "--revert" ]]; then
  if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root (via pkexec or sudo)." >&2
    exit 1
  fi

  # 1. Restore standard kernel intervals (30ms - 50ms)
  for dev in /sys/kernel/debug/bluetooth/hci*; do
    if [[ -d "$dev" ]]; then
      echo 24 > "$dev/conn_min_interval" 2>/dev/null || true
      echo 40 > "$dev/conn_max_interval" 2>/dev/null || true
    fi
  done

  # 2. Remove persisted tmpfiles configuration
  rm -f /etc/tmpfiles.d/bluetooth-low-latency.conf

  # 3. Remove udev performance rules
  rm -f /etc/udev/rules.d/50-bluetooth-performance.rules

  # 4. Restore USB power management to auto
  for p in /sys/bus/usb/devices/*/power/control; do
    dir=$(dirname "$p")
    parent=$(dirname "$dir")
    if [[ -f "$parent/idVendor" && -f "$parent/idProduct" ]]; then
      v=$(cat "$parent/idVendor" 2>/dev/null || true)
      p_id=$(cat "$parent/idProduct" 2>/dev/null || true)
      if [[ "$v" == "04ca" && "$p_id" == "4000" ]]; then
        echo "auto" > "$p" 2>/dev/null || true
      fi
    fi
  done

  # 5. Reload udev
  udevadm control --reload 2>/dev/null || true
  udevadm trigger --subsystem-match=usb 2>/dev/null || true

  echo "Standard Bluetooth configuration restored."
  exit 0
fi

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root (via pkexec or sudo)." >&2
  exit 1
fi

# 1. Apply to active kernel bluetooth debugfs if present
for dev in /sys/kernel/debug/bluetooth/hci*; do
  if [[ -d "$dev" ]]; then
    echo 6 > "$dev/conn_min_interval" 2>/dev/null || true
    echo 9 > "$dev/conn_max_interval" 2>/dev/null || true
  fi
done

# 2. Persist low-latency connection intervals across reboots via systemd-tmpfiles
mkdir -p /etc/tmpfiles.d
cat << 'EOF' > /etc/tmpfiles.d/bluetooth-low-latency.conf
# Logitech MX Ergo - Low Latency BLE Intervals (7.5ms - 11.25ms = ~90-133 Hz)
w /sys/kernel/debug/bluetooth/hci0/conn_min_interval - - - - 6
w /sys/kernel/debug/bluetooth/hci0/conn_max_interval - - - - 9
EOF

# 3. Disable USB autosuspend for the Bluetooth controller to prevent initial motion stutter
mkdir -p /etc/udev/rules.d
cat << 'EOF' > /etc/udev/rules.d/50-bluetooth-performance.rules
# Prevent USB autosuspend and enable wakeup on Bluetooth controllers
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="04ca", ATTR{idProduct}=="4000", ATTR{power/control}="on", ATTR{power/wakeup}="enabled"
EOF

# 4. Reload udev and apply rules
udevadm control --reload 2>/dev/null || true
udevadm trigger --subsystem-match=usb 2>/dev/null || true

echo "Low-latency Bluetooth configuration successfully applied."
exit 0
