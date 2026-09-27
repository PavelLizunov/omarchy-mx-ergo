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
    def profile_config(self):
        profile = {'id': 'main', 'name': 'Основной',
                   'buttons': {k: 'default' for k in store.BUTTONS},
                   'customShortcuts': {k: '' for k in store.BUTTONS},
                   'customCommands': {k: '' for k in store.BUTTONS}}
        profile['buttons']['back'] = 'profile_next'
        profile['buttons']['forward'] = 'custom_command'
        profile['customCommands']['forward'] = 'printf "Привет"'
        return {'version': 2, 'activeProfileId': 'main', 'profileShortcut': 'CTRL + F12',
                'profiles': [profile], 'sensitivity': 0, 'autoReconnect': False}

    def test_profiles_roundtrip_and_validation(self):
        value = self.profile_config()
        with tempfile.TemporaryDirectory() as d:
            path = Path(d) / 'profiles.json'
            store.write(path, json.dumps(value))
            self.assertEqual(store.read(path), value)
        bad = []
        for key, val in [('version', True), ('version', 3), ('activeProfileId', 'missing'),
                         ('profiles', []), ('profiles', None), ('profileShortcut', 12),
                         ('profileShortcut', 'a'*257)]:
            cfg = self.profile_config(); cfg[key] = val; bad.append(cfg)
        for key, val in [('id', '../outside'), ('name', ''), ('name', 'a'*81), ('name', 'a\n'),
                         ('buttons', {'back': 'mute'}), ('customShortcuts', None)]:
            cfg = self.profile_config(); cfg['profiles'][0][key] = val; bad.append(cfg)
        cfg = self.profile_config(); cfg['profiles'] *= 2; bad.append(cfg)
        cfg = self.profile_config(); cfg['buttons'] = {}; bad.append(cfg)
        cfg = self.profile_config(); del cfg['profileShortcut']; bad.append(cfg)
        for cfg in bad:
            with self.subTest(cfg=cfg), self.assertRaises(ValueError): store.validate(json.dumps(cfg))

    def test_profile_count_and_serialized_size_bounds(self):
        cfg = self.profile_config()
        template = cfg['profiles'][0]
        cfg['profiles'] = [{**template, 'id': 'p'+str(i)} for i in range(32)]
        cfg['activeProfileId'] = 'p0'
        self.assertEqual(len(store.validate(json.dumps(cfg))['profiles']), 32)
        cfg['profiles'].append({**template, 'id': 'overflow'})
        with self.assertRaises(ValueError): store.validate(json.dumps(cfg))
        # Compact input can fit while the persisted pretty JSON exceeds the cap.
        cfg = self.profile_config()
        cfg['profiles'] = []
        for i in range(29):
            p = json.loads(json.dumps(template)); p['id'] = 'p'+str(i)
            p['customCommands']['back'] = 'x'*1730
            cfg['profiles'].append(p)
        cfg['activeProfileId'] = 'p0'
        raw = json.dumps(cfg, separators=(',', ':'))
        self.assertLess(len(raw.encode()), store.MAX_BYTES)
        self.assertGreater(len(json.dumps(cfg, ensure_ascii=False, indent=2).encode()), store.MAX_BYTES)
        with tempfile.TemporaryDirectory() as d:
            path = Path(d)/'preferences.json'; path.write_text('{}')
            with self.assertRaises(ValueError): store.write(path, raw)
            self.assertEqual(path.read_text(), '{}')

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
