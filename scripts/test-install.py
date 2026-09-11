#!/usr/bin/env python3
"""Installer failure/replacement tests using a synthetic builder, not real app evidence."""
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class InstallTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='specter-installer-test-')
        self.root = Path(self.temp.name)
        scripts = self.root / 'source' / 'scripts'
        scripts.mkdir(parents=True)
        self.installer = scripts / 'install.sh'
        shutil.copy2(ROOT / 'scripts/install.sh', self.installer)
        self.destination = self.root / 'Applications with spaces'
        self.app = self.destination / 'Specter.app'
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        self.env = dict(os.environ, PATH=f'{self.bin}:{os.environ["PATH"]}')
        self.write_script(scripts / 'build-app.sh', '''
if [[ "${FAIL_BUILD:-0}" == 1 ]]; then exit 24; fi
mkdir -p "$SPECTER_APP_OUTPUT/Contents/MacOS"
cp "$FIXTURE_PLIST" "$SPECTER_APP_OUTPUT/Contents/Info.plist"
printf new > "$SPECTER_APP_OUTPUT/Contents/MacOS/Specter"
''')
        self.write_script(self.bin / 'codesign', 'exit "${FAIL_SIGNATURE:-0}"')
        self.plist = self.root / 'Info.plist'
        self.plist.write_bytes(plistlib.dumps({'CFBundleIdentifier': 'app.specter.terminal'}))
        self.env['FIXTURE_PLIST'] = str(self.plist)

    def tearDown(self):
        self.temp.cleanup()

    def write_script(self, path, body):
        path.write_text('#!/bin/bash\nset -euo pipefail\n' + body + '\n')
        path.chmod(0o755)

    def old_app(self, identifier='app.specter.terminal'):
        (self.app / 'Contents').mkdir(parents=True)
        (self.app / 'Contents/Info.plist').write_bytes(plistlib.dumps({'CFBundleIdentifier': identifier}))
        (self.app / 'old-marker').write_text('keep me')

    def run_install(self, *args, succeeds=True):
        result = subprocess.run([str(self.installer), '--destination', str(self.destination), *args],
                                env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode == 0, succeeds, result.stdout + result.stderr)
        return result

    def assert_clean(self):
        self.assertFalse(list(self.destination.glob('.specter-install*')))

    def test_fresh_install_with_spaces(self):
        self.run_install()
        self.assertEqual((self.app / 'Contents/MacOS/Specter').read_text(), 'new')
        self.assert_clean()

    def test_existing_app_requires_replace(self):
        self.old_app()
        self.run_install(succeeds=False)
        self.assertEqual((self.app / 'old-marker').read_text(), 'keep me')
        self.assert_clean()

    def test_replace_keeps_backup(self):
        self.old_app()
        self.run_install('--replace')
        backups = list(self.destination.glob('Specter.backup.*.app'))
        self.assertEqual(len(backups), 1)
        self.assertEqual((backups[0] / 'old-marker').read_text(), 'keep me')
        self.assertTrue((self.app / 'Contents/MacOS/Specter').exists())
        self.assert_clean()

    def test_build_failure_preserves_old_app(self):
        self.old_app()
        self.env['FAIL_BUILD'] = '1'
        self.run_install('--replace', succeeds=False)
        self.assertTrue((self.app / 'old-marker').exists())
        self.assert_clean()

    def test_signature_failure_preserves_old_app(self):
        self.old_app()
        self.env['FAIL_SIGNATURE'] = '1'
        self.run_install('--replace', succeeds=False)
        self.assertTrue((self.app / 'old-marker').exists())
        self.assert_clean()

    def test_failed_final_move_restores_backup(self):
        self.old_app()
        self.write_script(self.bin / 'mv', '''
case "$1" in */.specter-install.*/Specter.app) exit 25 ;; esac
exec /bin/mv "$@"
''')
        self.run_install('--replace', succeeds=False)
        self.assertTrue((self.app / 'old-marker').exists())
        self.assertFalse(list(self.destination.glob('Specter.backup.*.app')))
        self.assert_clean()

    def test_unrelated_bundle_is_preserved(self):
        self.old_app('example.some-other-app')
        self.run_install('--replace', succeeds=False)
        self.assertTrue((self.app / 'old-marker').exists())
        self.assert_clean()

    def test_symlink_is_preserved(self):
        self.destination.mkdir()
        self.app.symlink_to(self.root / 'missing-target')
        self.run_install('--replace', succeeds=False)
        self.assertTrue(self.app.is_symlink())
        self.assert_clean()

    def test_concurrent_installer_is_refused(self):
        lock = self.destination / '.specter-install.lock'
        lock.mkdir(parents=True)
        self.run_install(succeeds=False)
        self.assertTrue(lock.is_dir())
        self.assertFalse(self.app.exists())

    def test_invalid_option_does_not_install(self):
        self.run_install('--bad-option', succeeds=False)
        self.assertFalse(self.destination.exists())

    def test_missing_destination_does_not_install(self):
        self.run_install('--destination', succeeds=False)
        self.assertFalse(self.destination.exists())


if __name__ == '__main__':
    unittest.main(verbosity=2)
