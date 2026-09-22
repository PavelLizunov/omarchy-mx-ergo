import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

script = Path(__file__).resolve().parents[1] / 'scripts/config-store.py'
spec = importlib.util.spec_from_file_location('config_store', script)
store = importlib.util.module_from_spec(spec)
spec.loader.exec_module(store)


class Preferences(unittest.TestCase):
    def test_roundtrip_unicode_false_and_zero(self):
        value = {'sensitivity': 0, 'autoReconnect': False, 'naturalScroll': False,
                 'accelProfile': 'flat', 'buttons': {'back': 'custom_command'},
                 'customCommands': {'back': 'printf "Привет"'},
                 'customShortcuts': {'middle': ''}}
        with tempfile.TemporaryDirectory() as d:
            path = Path(d) / 'new dir/preferences.json'
            self.assertIsNone(store.read(path))
            store.write(path, json.dumps(value))
            self.assertEqual(store.read(path), value)
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)

    def test_bad_shapes_ranges_and_limits(self):
        bad = ['null', '[]', '{broken', '{"sensitivity": NaN}', '{"sensitivity": true}',
               '{"sensitivity": 2}', '{"accelProfile": "bad"}', '{"buttons": null}',
               '{"buttons":{"back":"execute_anything"}}', '{"autoReconnect": 1}',
               '{"customCommands":{"other":"id"}}', '{"customShortcuts":{"back":5}}',
               json.dumps({'customCommands': {'back': '\x00'}}),
               json.dumps({'customShortcuts': {'back': 'a'*257}}),
               ' '*65537, '{"unknown": 1}']
        for raw in bad:
            with self.subTest(raw=raw[:80]), self.assertRaises(ValueError):
                store.validate(raw)

    def test_preserves_previous_on_failed_replace(self):
        with tempfile.TemporaryDirectory() as d:
            path = Path(d)/'preferences.json'
            store.write(path, '{"sensitivity":0}')
            original = path.read_bytes()
            with patch.object(store.os, 'replace', side_effect=OSError('disk error')):
                with self.assertRaises(OSError): store.write(path, '{"sensitivity":0.5}')
            self.assertEqual(path.read_bytes(), original)
            self.assertEqual(list(Path(d).iterdir()), [path])
            with self.assertRaises(ValueError): store.write(path, '[]')
            self.assertEqual(path.read_bytes(), original)

    def test_fifo_symlink_and_oversized_file(self):
        with tempfile.TemporaryDirectory() as d:
            path = Path(d)/'preferences.json'
            os.mkfifo(path)
            with self.assertRaises(ValueError): store.read(path)
            with self.assertRaises(ValueError): store.write(path, '{}')
            path.unlink()
            path.write_bytes(b' '*65537)
            with self.assertRaises(ValueError): store.read(path)
            link = Path(d)/'link'
            link.symlink_to(path)
            with self.assertRaises(OSError): store.read(link)
            with self.assertRaises(ValueError): store.write(link, '{}')

    def test_cli_invalid_input_does_not_replace(self):
        with tempfile.TemporaryDirectory() as d:
            path = Path(d)/'preferences.json'
            path.write_text('{}')
            command = [sys.executable, '-I', str(script)]
            good = subprocess.run(command+['read',str(path)], capture_output=True, timeout=6)
            self.assertEqual(good.returncode, 0)
            self.assertEqual(json.loads(good.stdout), {})
            bad = subprocess.run(command+['write',str(path),'null'], capture_output=True, timeout=6)
            self.assertEqual(bad.returncode, 1)
            self.assertEqual(path.read_text(), '{}')


if __name__ == '__main__': unittest.main()
