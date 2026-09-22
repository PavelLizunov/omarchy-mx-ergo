#!/usr/bin/env python3
import json
import signal
import subprocess
import sys
import os
import selectors
import time

MAX_LUA_LEN = 65536
MAX_OUTPUT_BYTES = 1048576  # 1 MiB bounded read
TIMEOUT_SECONDS = 5.0
DELAYS = [0.0, 2.0, 4.0]
EXPECTED_KEYS = {
    "mouse:275",
    "mouse:276",
    "mouse:274",
    "mouse_left",
    "mouse:278",
    "mouse_right",
    "mouse:279",
}


def _handle_signal(signum, frame):
    raise SystemExit(128 + signum)


def _validate_payload(raw_json: str):
    if len(raw_json) > 131072:
        raise ValueError("Payload too large")
    try:
        data = json.loads(raw_json)
    except Exception:
        raise ValueError("Invalid JSON payload")

    if not isinstance(data, dict):
        raise ValueError("Payload must be a JSON object")

    lua = data.get("lua")
    if not isinstance(lua, str) or not lua.strip() or len(lua) > MAX_LUA_LEN:
        raise ValueError("Lua script must be a string <= 65536 chars")

    expected = data.get("expected")
    if not isinstance(expected, dict) or set(expected.keys()) != EXPECTED_KEYS:
        raise ValueError("Expected bindings must match required keys")

    for k, v in expected.items():
        if v is not None and (not isinstance(v, str) or len(v) > 4096):
            raise ValueError(f"Invalid target for {k}")

    return lua, expected


def _run_bounded(cmd):
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    deadline = time.monotonic() + TIMEOUT_SECONDS
    output = bytearray()
    try:
        with selectors.DefaultSelector() as selector:
            selector.register(proc.stdout, selectors.EVENT_READ)
            while True:
                remaining = deadline - time.monotonic()
                if remaining <= 0 or not selector.select(remaining):
                    raise subprocess.TimeoutExpired(cmd, TIMEOUT_SECONDS)
                chunk = os.read(proc.stdout.fileno(), min(65536, MAX_OUTPUT_BYTES + 1 - len(output)))
                if not chunk:
                    break
                output.extend(chunk)
                if len(output) > MAX_OUTPUT_BYTES:
                    raise ValueError("Command output exceeded bound")
        remaining = max(0, deadline - time.monotonic())
        return proc.wait(timeout=remaining), output.decode("utf-8", errors="replace")
    finally:
        if proc.poll() is None:
            proc.kill()
        proc.wait()
        proc.stdout.close()


def _check_binds(expected: dict):
    rc, out = _run_bounded(["hyprctl", "-j", "binds"])
    if rc != 0:
        return False, "hyprctl binds command failed"

    try:
        binds = json.loads(out)
        if not isinstance(binds, list) or any(
            not isinstance(b, dict) or not isinstance(b.get("key"), str)
            or type(b.get("modmask")) is not int or not isinstance(b.get("submap"), str)
            for b in binds
        ):
            return False, "Invalid binds data format"
    except Exception:
        return False, "Failed to parse binds JSON"

    for key, target in expected.items():
        matches = [
            b for b in binds
            if b.get("key") == key
            and b.get("modmask") == 0
            and b.get("submap") == ""
        ]

        if target is None:
            if len(matches) != 0:
                return False, f"Unexpected binding present for {key}"
        else:
            if len(matches) != 1:
                return False, f"Expected exactly one binding for {key}"
            if matches[0].get("description") != target:
                return False, f"Description mismatch for {key}"

    return True, None


def main():
    if len(sys.argv) != 2:
        out = {"ok": False, "attempts": 0, "error": "Invalid arguments"}
        print(json.dumps(out))
        sys.exit(1)

    try:
        lua, expected = _validate_payload(sys.argv[1])
    except ValueError as e:
        out = {"ok": False, "attempts": 0, "error": str(e)}
        print(json.dumps(out))
        sys.exit(1)

    attempts = 0
    last_error = "Unknown error"

    for delay in DELAYS:
        attempts += 1
        if delay > 0:
            time.sleep(delay)

        try:
            rc, out = _run_bounded(["hyprctl", "eval", lua])
            if rc != 0 or out.strip() != "ok":
                last_error = "hyprctl eval failed"
                continue

            ok, err = _check_binds(expected)
            if ok:
                print(json.dumps({"ok": True, "attempts": attempts, "error": None}))
                sys.exit(0)
            last_error = err or "Verification failed"

        except subprocess.TimeoutExpired:
            last_error = "Command timed out"
        except ValueError as e:
            last_error = str(e)
        except Exception:
            last_error = "Execution error"

    print(json.dumps({"ok": False, "attempts": attempts, "error": last_error}))
    sys.exit(1)


if __name__ == "__main__":
    signal.signal(signal.SIGINT, _handle_signal)
    signal.signal(signal.SIGTERM, _handle_signal)
    main()
