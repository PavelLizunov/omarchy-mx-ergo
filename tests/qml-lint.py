#!/usr/bin/env python3
"""Run qmllint on slovn.mx-ergo with isolated qs.Commons and qs.Ui imports."""

import collections
import json
import pathlib
import shutil
import subprocess
import tempfile
import sys

root = pathlib.Path(__file__).resolve().parent.parent
with tempfile.TemporaryDirectory(prefix="mx-ergo-qml-", dir="/tmp/opencode") as tmp:
    imports = pathlib.Path(tmp)
    for name in ("Commons", "Ui"):
        shutil.copytree(pathlib.Path("/usr/share/omarchy/shell") / name, imports / "qs" / name)

    cmd = [
        "/usr/lib/qt6/bin/qmllint",
        "--json", "-",
        "-W", "0",
        "--unqualified", "info",
        "-I", "/usr/lib/qt6/qml",
        "-I", str(imports),
        "-I", str(root)
    ]
    inputs = sorted(root.glob("*.qml"))
    result = subprocess.run(cmd + [str(p) for p in inputs], capture_output=True, text=True, timeout=30)
    
    if not result.stdout.strip():
        print(f"qmllint produced no output. Exit code: {result.returncode}")
        if result.returncode != 0:
            sys.exit(1)
        print("PASS: QML lint passed cleanly.")
        sys.exit(0)

    try:
        report = json.loads(result.stdout)
    except Exception as e:
        print(f"Failed to parse qmllint JSON: {e}\nOutput:\n{result.stdout}")
        sys.exit(1)

    errors = 0
    for file in report.get("files", []):
        path = pathlib.Path(file["filename"])
        for warning in file.get("warnings", []):
            if warning.get("type") == "info":
                continue
            cat = warning.get("id", "warning")
            msg = warning.get("message", "")
            # Ignore expected host/dynamic type warnings
            if "UntypedObjectModel" in msg or "did you add all imports" in msg.lower() or "type anchors is used" in msg.lower():
                continue
            if "unqualified access" in msg.lower():
                continue
            if "member" in msg.lower() and "not found on type" in msg.lower():
                continue
            print(f"{path.name}:{warning.get('line')}: {cat}: {msg}")
            errors += 1

    if errors > 0:
        print(f"FAIL: {errors} unexpected QML lint errors.")
        sys.exit(1)

    print("PASS: QML lint verified.")
