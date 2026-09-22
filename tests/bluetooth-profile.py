#!/usr/bin/env python3
"""Production profile logic in a temporary sysfs/etc tree. Never uses root or host writes."""
import importlib.machinery
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import ast
import xml.etree.ElementTree as ET

REPO = Path(__file__).resolve().parent.parent

def load(name, path):
    loader = importlib.machinery.SourceFileLoader(name, str(path))
    spec = importlib.util.spec_from_loader(name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module

helper = load('mx_profile', REPO / 'system/omarchy-mx-ergo-bluetooth')
client = load('mx_client', REPO / 'scripts/bluetooth-client.py')


class ProfileTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='mx-profile-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.profile = helper.Profile(self.root, os.geteuid())
        self.reloads = []
        self.profile.reload_rules = lambda: self.reloads.append(True)
        self.usb = self.root / 'sys/devices/pci/usb1/1-2.4'
        self.debug = self.root / 'sys/kernel/debug/bluetooth/hci7'
        self.hci = self.root / 'sys/class/bluetooth/hci7'
        for path in [self.usb / 'power', self.debug, self.hci, self.root / 'proc/sys/kernel/random']:
            path.mkdir(parents=True)
        (self.hci / 'device').symlink_to(self.usb)
        for name, value in [('idVendor','1234'),('idProduct','abcd'),('serial','unique'),('power/control','auto')]:
            (self.usb / name).write_text(value + '\n')
        (self.debug / 'conn_min_interval').write_text('12\n')
        (self.debug / 'conn_max_interval').write_text('22\n')
        self.boot = self.root / 'proc/sys/kernel/random/boot_id'
        self.boot.write_text('11111111-1111-1111-1111-111111111111\n')

    def enable(self):
        with self.profile.locked():
            self.profile.enable('hci7')

    def test_round_trip_keeps_first_baseline(self):
        self.enable()
        original = self.profile.state()['original']
        self.assertEqual(original, {'min':12, 'max':22, 'power':'auto'})
        self.enable()
        self.assertEqual(self.profile.state()['original'], original)
        self.assertEqual(self.profile.status('hci7')['state'], 'applied')
        self.profile.disable()
        self.assertEqual(self.profile.values(self.profile.device('hci7')), original)
        self.assertFalse(self.profile.rule.exists())
        self.assertIsNone(self.profile.state())

    def test_disconnected_cleanup_then_restore(self):
        self.enable()
        (self.hci / 'device').unlink()
        self.profile.disable()
        self.assertFalse(self.profile.rule.exists())
        self.assertEqual(self.profile.status('-')['state'], 'restore_pending')
        (self.hci / 'device').symlink_to(self.usb)
        self.profile.disable()
        self.assertIsNone(self.profile.state())

    def test_missing_debugfs_still_removes_persistence(self):
        self.enable()
        (self.debug / 'conn_min_interval').unlink()
        with self.assertRaises(OSError):
            self.profile.disable()
        self.assertFalse(self.profile.rule.exists())
        self.assertEqual(self.profile.state()['phase'], 'restore_pending')

    def test_renumbered_adapter_is_identified_by_device(self):
        self.enable()
        self.hci.rename(self.hci.with_name('hci8'))
        self.debug.rename(self.debug.with_name('hci8'))
        self.profile.disable()
        self.assertEqual(self.profile.values(self.profile.device('hci8'))['min'], 12)

    def test_foreign_device_never_receives_saved_values(self):
        self.enable()
        (self.usb / 'serial').write_text('different\n')
        self.profile.disable()
        self.assertEqual(self.profile.state()['phase'], 'restore_pending')
        self.assertEqual((self.debug / 'conn_min_interval').read_text().strip(), '6')

    def test_reload_failure_restores_values_and_retains_journal(self):
        def fail():
            raise subprocess.CalledProcessError(1, 'udevadm')
        self.profile.reload_rules = fail
        with self.assertRaises(helper.ProfileError):
            self.enable()
        self.assertEqual(self.profile.values(self.profile.device('hci7'))['min'], 12)
        self.assertFalse(self.profile.rule.exists())
        self.assertEqual(self.profile.state()['phase'], 'restore_pending')
        self.profile.reload_rules = lambda: None
        self.profile.disable()
        self.assertIsNone(self.profile.state())

    def test_partial_hardware_write_can_be_recovered(self):
        write = self.profile.write_values
        def fail_once(device, values):
            self.profile.write_values = write
            (self.debug / 'conn_min_interval').write_text('6\n')
            raise OSError('injected write failure')
        self.profile.write_values = fail_once
        with self.assertRaisesRegex(helper.ProfileError, 'original settings restored'):
            self.enable()
        self.assertEqual(self.profile.values(self.profile.device('hci7'))['min'], 12)
        self.assertIsNone(self.profile.state())

    def test_foreign_rules_and_symlinks_are_not_overwritten(self):
        self.profile.rule.parent.mkdir(parents=True)
        self.profile.rule.write_text('unrelated configuration\n')
        with self.assertRaises(helper.ProfileError):
            self.enable()
        self.assertEqual(self.profile.rule.read_text(), 'unrelated configuration\n')
        self.profile.rule.unlink()
        victim = self.root / 'victim'
        victim.write_text('untouched')
        self.profile.rule.symlink_to(victim)
        with self.assertRaises(helper.ProfileError):
            self.enable()
        self.assertEqual(victim.read_text(), 'untouched')

    def test_foreign_changes_are_not_clobbered_by_restore(self):
        self.enable()
        (self.debug / 'conn_max_interval').write_text('50\n')
        with self.assertRaisesRegex(helper.ProfileError, 'externally'):
            self.profile.disable()
        self.assertEqual((self.debug / 'conn_max_interval').read_text().strip(), '50')
        self.assertFalse(self.profile.rule.exists())

    def test_adapter_replaced_during_operation_is_rejected(self):
        device = self.profile.device('hci7')
        (self.usb / 'serial').write_text('replacement\n')
        with self.assertRaisesRegex(helper.ProfileError, 'Adapter changed'):
            self.profile.write_values(device, helper.TARGET)
        self.assertEqual((self.debug / 'conn_min_interval').read_text().strip(), '12')

    def test_single_flight(self):
        with self.profile.locked():
            with self.assertRaises(BlockingIOError):
                with self.profile.locked():
                    pass

    def legacy(self):
        self.profile.legacy_config.parent.mkdir(parents=True)
        self.profile.legacy_rule.parent.mkdir(parents=True, exist_ok=True)
        self.profile.legacy_config.write_text('# MX Ergo: controller defaults, not measured input timing\n'
            'w /sys/kernel/debug/bluetooth/hci7/conn_min_interval - - - - 6\n'
            'w /sys/kernel/debug/bluetooth/hci7/conn_max_interval - - - - 9\n')
        self.profile.legacy_rule.write_text('# MX Ergo: USB autosuspend off for the selected controller at this USB port\n'
            'ACTION=="add|change", SUBSYSTEM=="usb", KERNEL=="1-2.4", ATTR{idVendor}=="1234", ATTR{idProduct}=="abcd", ATTR{power/control}="on"\n')

    def test_legacy_cleanup_requires_fresh_boot_before_new_baseline(self):
        self.legacy()
        self.assertEqual(self.profile.status('-')['state'], 'legacy')
        with self.assertRaises(helper.ProfileError):
            self.enable()
        self.profile.remove_legacy()
        self.assertFalse(self.profile.legacy())
        self.assertEqual(self.profile.status('-')['state'], 'restart')
        with self.assertRaises(helper.ProfileError):
            self.enable()
        self.boot.write_text('22222222-2222-2222-2222-222222222222\n')
        self.enable()
        self.assertEqual(self.profile.state()['original']['min'],12)

    def test_foreign_legacy_file_survives(self):
        self.legacy()
        self.profile.legacy_rule.write_text('foreign\n')
        with self.assertRaises(helper.ProfileError):
            self.profile.remove_legacy()
        self.assertEqual(self.profile.legacy_rule.read_text(),'foreign\n')

    def test_reapply_uses_identity_and_does_not_overwrite_baseline(self):
        self.enable()
        (self.debug / 'conn_max_interval').write_text('22\n')
        (self.debug / 'conn_min_interval').write_text('12\n')
        self.profile.reapply('hci7')
        self.assertEqual(self.profile.values(self.profile.device('hci7')),helper.TARGET)
        self.assertEqual(self.profile.state()['original']['min'],12)

    def test_status_does_not_create_state(self):
        self.assertFalse(self.profile.status('-')['configured'])
        self.assertFalse(self.profile.store.exists())

    def test_client_only_authorizes_fixed_system_helper(self):
        self.assertEqual(client.command('--enable','hci7',True),
            ['/usr/bin/pkexec',client.HELPER.as_posix(),'--enable','hci7'])
        self.assertIsNone(client.command('--enable','hci7',False))
        self.assertNotIn('pkexec', ' '.join(client.command('--status','-',True)))
        for action, adapter in [('--reapply','hci7'),('--enable','../hci7'),('--enable','hci7;id')]:
            with self.assertRaises(ValueError):
                client.command(action, adapter, True)
        unsafe = self.root / 'writable-helper'
        unsafe.write_text('placeholder')
        unsafe.chmod(0o777)
        self.assertFalse(client.trusted_helper(unsafe,os.geteuid()))

    def test_privileged_entrypoint_and_policy_contract(self):
        source = (REPO / 'system/omarchy-mx-ergo-bluetooth').read_text()
        ast.parse(source)
        self.assertTrue(source.startswith('#!/usr/bin/python3 -I'))
        policy = ET.parse(REPO / 'system/io.github.pavellizunov.mx-ergo.bluetooth.policy').getroot()
        self.assertEqual(policy.find('.//allow_active').text, 'auth_admin')
        self.assertEqual(policy.find('.//allow_any').text, 'no')
        self.assertEqual(policy.find('.//allow_inactive').text, 'no')
        self.assertEqual(policy.find('.//annotate').text, helper.HELPER)
        result = subprocess.run(['bash', '-n', str(REPO/'scripts/install-bluetooth-helper.sh')], capture_output=True)
        self.assertEqual(result.returncode, 0)
        with self.assertRaises(helper.ProfileError):
            helper.main(['--enable','hci7','--root',str(self.root)])

    def test_wrapper_ignores_bash_env(self):
        marker = self.root / 'injected'
        envfile = self.root / 'bashenv'
        envfile.write_text('touch ' + str(marker))
        wrapper = self.root / 'low-latency.sh'
        wrapper.write_bytes((REPO / 'scripts/low-latency.sh').read_bytes())
        wrapper.chmod(0o755)
        (self.root / 'bluetooth-client.py').write_text(
            'import json, sys\nprint(json.dumps({"args": sys.argv[1:]}))\n')
        result = subprocess.run([str(wrapper),'--status','-'],
            env=dict(os.environ,BASH_ENV=str(envfile)),capture_output=True,text=True,timeout=5)
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertFalse(marker.exists())
        self.assertEqual(json.loads(result.stdout), {'args': ['--status', '-']})


if __name__ == '__main__':
    unittest.main()
