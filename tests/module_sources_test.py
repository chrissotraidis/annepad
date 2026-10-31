"""Pinned exports preserve source caches and reject changed prepared inputs."""
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('module_sources', ROOT / 'scripts/module_sources.py')
sources = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sources)


def git(path, *args):
    return subprocess.check_output(['git', '-C', str(path), *args], stderr=subprocess.PIPE).strip()


def repository(path):
    path.mkdir()
    git(path, 'init', '-q')
    git(path, 'config', 'core.autocrlf', 'false')
    (path / 'value.txt').write_bytes(b'original\n')
    git(path, 'add', 'value.txt')
    git(path, '-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
        'commit', '-qm', 'public fixture')
    return git(path, 'rev-parse', 'HEAD').decode()


class SourceExportTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='annepad source 日本語 ')
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.cache = self.root / 'cache'
        self.pin = repository(self.cache)

    def test_patched_export_ignores_dirty_cache_and_preserves_git_objects(self):
        (self.cache / 'value.txt').write_bytes(b'unrelated local edit\n')
        (self.cache / 'private.bin').write_bytes(b'private fixture remains here')
        patch = self.root / 'change.patch'
        patch.write_bytes(b'--- a/value.txt\n+++ b/value.txt\n@@ -1 +1 @@\n-original\n+maintained\n')
        before = {p.relative_to(self.cache).as_posix(): p.read_bytes()
                  for p in self.cache.rglob('*') if p.is_file()}
        output = self.root / 'output'
        record = sources.export_tree(self.cache, output, self.pin, (patch,))
        self.assertEqual((output / 'value.txt').read_bytes(), b'maintained\n')
        self.assertFalse((output / 'private.bin').exists())
        self.assertEqual(before, {p.relative_to(self.cache).as_posix(): p.read_bytes()
                                  for p in self.cache.rglob('*') if p.is_file()})
        sources.verify_tree(output, record)

    def test_gitlink_selects_child_pin_and_omits_unused_children(self):
        pin = repository(self.cache / 'child')
        git(self.cache, 'update-index', '--add', '--cacheinfo', '160000,' + pin + ',child')
        git(self.cache, '-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
            'commit', '-qm', 'pinned child')
        parent = git(self.cache, 'rev-parse', 'HEAD').decode()
        output = self.root / 'output'
        record = sources.export_tree(self.cache, output, parent, children={'child': ((), {})})
        self.assertEqual(record['children']['child']['revision'], pin)
        sources.verify_tree(output, record)
        omitted = self.root / 'omitted'
        sources.export_tree(self.cache, omitted, parent)
        self.assertFalse((omitted / 'child').exists())

    def test_wrong_revision_and_existing_output_are_preserved(self):
        with self.assertRaisesRegex(ValueError, 'revision mismatch'):
            sources.export_tree(self.cache, self.root / 'wrong', '0' * 40)
        self.assertFalse((self.root / 'wrong').exists())
        output = self.root / 'output'
        output.mkdir()
        (output / 'keep').write_bytes(b'keep')
        with self.assertRaises(FileExistsError):
            sources.export_tree(self.cache, output, self.pin)
        self.assertEqual((output / 'keep').read_bytes(), b'keep')

    def test_output_inside_cache_is_rejected_before_writing(self):
        with self.assertRaisesRegex(ValueError, 'outside the source cache'):
            sources.export_tree(self.cache, self.cache / 'output', self.pin)
        self.assertFalse((self.cache / 'output').exists())

    def test_prepared_tree_rejects_modified_missing_and_extra_files(self):
        for change in ('modified', 'missing', 'extra'):
            with self.subTest(change=change):
                output = self.root / change
                record = sources.export_tree(self.cache, output, self.pin)
                if change == 'modified':
                    (output / 'value.txt').write_bytes(b'wrong')
                elif change == 'missing':
                    (output / 'value.txt').unlink()
                else:
                    (output / 'unexpected.h').write_bytes(b'wrong')
                with self.assertRaisesRegex(ValueError, 'inventory changed'):
                    sources.verify_tree(output, record)

    def test_unsafe_paths_are_rejected(self):
        for name in ('../a', 'a/../b', '/absolute', 'C:/file', 'a\\b', 'a//b', './a'):
            with self.subTest(name=name), self.assertRaises(ValueError):
                sources.relative_path(name)


if __name__ == '__main__':
    unittest.main()
