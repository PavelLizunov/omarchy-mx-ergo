#!/usr/bin/env bash
set -euo pipefail

# Check lockscreen function logic
check_lockscreen() {
  local status_json="$1"
  local is_locked
  is_locked="$(python3 -c "import json, sys; d = json.loads('''$status_json'''); sys.exit(0 if (d.get('locked') or d.get('requested') or d.get('sessionLocked')) else 1)" 2>/dev/null && echo "yes" || echo "no")"
  if [[ "$is_locked" == "yes" ]]; then
    echo "LOCKED"
    return 1
  fi
  echo "UNLOCKED"
  return 0
}

# Test 1: Unlocked status
unlocked='{"locked":false,"requested":false,"pending":false,"sessionLocked":false,"secure":false}'
test "$(check_lockscreen "$unlocked")" = "UNLOCKED"

# Test 2: Locked status
locked1='{"locked":true,"requested":false,"pending":false,"sessionLocked":false,"secure":false}'
if check_lockscreen "$locked1" >/dev/null 2>&1; then
  echo "FAIL: Locked status was accepted" >&2
  exit 1
fi

# Test 3: Session locked status
locked2='{"locked":false,"requested":false,"pending":false,"sessionLocked":true,"secure":true}'
if check_lockscreen "$locked2" >/dev/null 2>&1; then
  echo "FAIL: SessionLocked status was accepted" >&2
  exit 1
fi

echo "PASS: Lockscreen guard tests passed."
