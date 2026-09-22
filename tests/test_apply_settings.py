import io
import json
import subprocess
import sys
import unittest
from unittest.mock import patch

import importlib.util
from pathlib import Path

script_path = Path(__file__).resolve().parent.parent / "scripts" / "apply-settings.py"
spec = importlib.util.spec_from_file_location("apply_settings", script_path)
app = importlib.util.module_from_spec(spec)
spec.loader.exec_module(app)

VALID_KEYS = {
    "mouse:275": "desc_275",
    "mouse:276": "desc_276",
    "mouse:274": None,
    "mouse_left": "desc_left",
    "mouse:278": None,
    "mouse_right": "desc_right",
    "mouse:279": None,
}


def _make_payload(lua="dummy_lua()", expected=None):
    if expected is None:
        expected = VALID_KEYS
    return json.dumps({"lua": lua, "expected": expected})


def _make_binds_list():
    return [
        {"key": "mouse:275", "modmask": 0, "submap": "", "description": "desc_275"},
        {"key": "mouse:276", "modmask": 0, "submap": "", "description": "desc_276"},
        {"key": "mouse_left", "modmask": 0, "submap": "", "description": "desc_left"},
        {"key": "mouse_right", "modmask": 0, "submap": "", "description": "desc_right"},
        # Non-global / unrelated row
        {"key": "mouse:274", "modmask": 64, "submap": "", "description": "other"},
        {"key": "mouse:278", "modmask": 0, "submap": "resize", "description": "other"},
        {"key": "mouse:999", "modmask": 0, "submap": "", "description": "unrelated"},
    ]


class TestApplySettings(unittest.TestCase):

    def run_main_with_args(self, args):
        with patch.object(sys, "argv", args):
            with patch("sys.stdout", new_callable=io.StringIO) as mock_out:
                with self.assertRaises(SystemExit) as cm:
                    app.main()
                return cm.exception.code, json.loads(mock_out.getvalue())

    def test_malformed_json_input(self):
        code, out = self.run_main_with_args(["apply-settings.py", "invalid json"])
        self.assertEqual(code, 1)
        self.assertFalse(out["ok"])
        self.assertEqual(out["attempts"], 0)
        self.assertIn("Invalid JSON payload", out["error"])

    def test_missing_or_invalid_keys(self):
        payload = json.dumps({"lua": "ok", "expected": {"mouse:275": "desc"}})
        code, out = self.run_main_with_args(["apply-settings.py", payload])
        self.assertEqual(code, 1)
        self.assertFalse(out["ok"])

    def test_lua_oversize(self):
        payload = json.dumps({"lua": "x" * 65537, "expected": VALID_KEYS})
        code, out = self.run_main_with_args(["apply-settings.py", payload])
        self.assertEqual(code, 1)
        self.assertIn("Lua script must be a string", out["error"])

    @patch("time.sleep", return_value=None)
    @patch.object(app, "_run_bounded")
    def test_success(self, mock_run, _mock_sleep):
        mock_run.side_effect = [
            (0, "ok\n"),
            (0, json.dumps(_make_binds_list())),
        ]
        code, out = self.run_main_with_args(["apply-settings.py", _make_payload()])
        self.assertEqual(code, 0)
        self.assertTrue(out["ok"])
        self.assertEqual(out["attempts"], 1)
        self.assertIsNone(out["error"])

    @patch("time.sleep", return_value=None)
    @patch.object(app, "_run_bounded")
    def test_nonzero_eval(self, mock_run, _mock_sleep):
        mock_run.return_value = (1, "error")
        code, out = self.run_main_with_args(["apply-settings.py", _make_payload()])
        self.assertEqual(code, 1)
        self.assertFalse(out["ok"])
        self.assertEqual(out["attempts"], 3)
        self.assertIn("eval failed", out["error"])

    @patch("time.sleep", return_value=None)
    @patch.object(app, "_run_bounded")
    def test_eval_exit0_not_ok(self, mock_run, _mock_sleep):
        mock_run.return_value = (0, "not ok")
        code, out = self.run_main_with_args(["apply-settings.py", _make_payload()])
        self.assertEqual(code, 1)
        self.assertFalse(out["ok"])
        self.assertEqual(out["attempts"], 3)
        self.assertIn("eval failed", out["error"])

    @patch("time.sleep", return_value=None)
    @patch.object(app, "_run_bounded")
    def test_missing_stale_or_duplicate_bindings(self, mock_run, _mock_sleep):
        binds = _make_binds_list()
        # Duplicate binding for mouse:275
        binds.append({"key": "mouse:275", "modmask": 0, "submap": "", "description": "desc_275"})
        mock_run.side_effect = [
            (0, "ok"),
            (0, json.dumps(binds)),
            (0, "ok"),
            (0, json.dumps(binds)),
            (0, "ok"),
            (0, json.dumps(binds)),
        ]
        code, out = self.run_main_with_args(["apply-settings.py", _make_payload()])
        self.assertEqual(code, 1)
        self.assertEqual(out["attempts"], 3)
        self.assertIn("Expected exactly one binding for mouse:275", out["error"])

    @patch("time.sleep", return_value=None)
    @patch.object(app, "_run_bounded")
    def test_null_absence_violated(self, mock_run, _mock_sleep):
        binds = _make_binds_list()
        # mouse:274 was expected None, but add a zero-modifier global binding
        binds.append({"key": "mouse:274", "modmask": 0, "submap": "", "description": "present"})
        mock_run.side_effect = [
            (0, "ok"),
            (0, json.dumps(binds)),
            (0, "ok"),
            (0, json.dumps(binds)),
            (0, "ok"),
            (0, json.dumps(binds)),
        ]
        code, out = self.run_main_with_args(["apply-settings.py", _make_payload()])
        self.assertEqual(code, 1)
        self.assertIn("Unexpected binding present for mouse:274", out["error"])

    @patch("time.sleep", return_value=None)
    @patch.object(app, "_run_bounded")
    def test_timeout(self, mock_run, _mock_sleep):
        mock_run.side_effect = subprocess.TimeoutExpired(cmd="hyprctl", timeout=5.0)
        code, out = self.run_main_with_args(["apply-settings.py", _make_payload()])
        self.assertEqual(code, 1)
        self.assertEqual(out["attempts"], 3)
        self.assertIn("Command timed out", out["error"])

    def test_output_oversize(self):
        # Real producer never exits by itself: the byte limit must stop it early.
        import time
        started = time.monotonic()
        with self.assertRaisesRegex(ValueError, "output exceeded bound"):
            app._run_bounded([sys.executable, '-c',
                              "import os; chunk=b'x'*65536\nwhile True: os.write(1,chunk)"])
        self.assertLess(time.monotonic() - started, app.TIMEOUT_SECONDS)

    def test_real_timeout(self):
        with patch.object(app, 'TIMEOUT_SECONDS', .15):
            with self.assertRaises(subprocess.TimeoutExpired):
                app._run_bounded([sys.executable, '-c', 'import time; time.sleep(10)'])

    @patch("time.sleep", return_value=None)
    @patch.object(app, "_run_bounded")
    def test_recovery_and_delays(self, run, sleep):
        run.side_effect = [(0, "error despite exit zero"), (0, "ok"), (0, "[]"),
                           (0, "ok"), (0, json.dumps(_make_binds_list()))]
        code, result = self.run_main_with_args(["apply-settings.py", _make_payload()])
        self.assertEqual((code, result["attempts"]), (0, 3))
        self.assertEqual([c.args[0] for c in sleep.call_args_list], [2, 4])

    @patch.object(app, "_run_bounded")
    def test_invalid_readbacks(self, run):
        missing = _make_binds_list()[1:]
        stale = _make_binds_list()
        stale[0]["description"] = "stale"
        for value in [None, {}, [None], [{"key": "mouse:275"}], missing, stale]:
            run.return_value = (0, json.dumps(value))
            self.assertFalse(app._check_binds(VALID_KEYS)[0], repr(value))
        run.return_value = (0, "{broken")
        self.assertFalse(app._check_binds(VALID_KEYS)[0])

    def test_real_subprocess_retry_and_cancel(self):
        import os
        import signal
        import tempfile
        import time
        with tempfile.TemporaryDirectory(prefix="mx-recovery-test-") as d:
            directory = Path(d)
            shim = directory / "hyprctl"
            shim.write_text("#!/usr/bin/env python3\n" + """
import json,os,sys,time,signal
from pathlib import Path
p=Path(os.environ['TEST_STATE'])
with p.open('a') as f: f.write(sys.argv[1]+'\\n')
if os.environ.get('TEST_HANG'):
    signal.signal(signal.SIGTERM, signal.SIG_IGN)
    pidfile=Path(os.environ['TEST_PID'])
    pidfile.with_suffix('.tmp').write_text(str(os.getpid()))
    pidfile.with_suffix('.tmp').replace(pidfile)
    time.sleep(20)
elif sys.argv[1]=='eval':
    print('error' if len(p.read_text().splitlines())==1 else 'ok')
else:
    print(os.environ['TEST_BINDS'])
""")
            shim.chmod(0o700)
            env = {**os.environ, "PATH": d + os.pathsep + os.environ['PATH'],
                   "TEST_STATE": str(directory/'state'), "TEST_PID": str(directory/'pid'),
                   "TEST_BINDS": json.dumps(_make_binds_list())}
            command = [sys.executable, '-B', str(script_path), _make_payload()]
            result = subprocess.run(command, env=env, capture_output=True, text=True, timeout=12)
            self.assertEqual(result.returncode,0,result.stderr)
            self.assertEqual(json.loads(result.stdout)['attempts'],2)
            self.assertEqual((directory/'state').read_text().splitlines(),['eval','eval','-j'])
            env['TEST_HANG']='1'
            proc = subprocess.Popen(command, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            try:
                deadline=time.monotonic()+5
                while not (directory/'pid').exists() and time.monotonic()<deadline: time.sleep(.02)
                self.assertTrue((directory/'pid').exists())
                child=int((directory/'pid').read_text())
                proc.send_signal(signal.SIGTERM)
                proc.communicate(timeout=5)
                self.assertEqual(proc.returncode,128+signal.SIGTERM)
                with self.assertRaises(ProcessLookupError): os.kill(child,0)
            finally:
                if proc.poll() is None: proc.kill(); proc.communicate()


if __name__ == "__main__":
    unittest.main()
