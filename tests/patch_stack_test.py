"""Regression for edits that still pass git apply --reverse --check."""

import importlib.util
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location(
    "patch_stack", Path(__file__).resolve().parents[1] / "scripts/verify-patch-stack.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class PatchStackTest(unittest.TestCase):
    def test_exact_source_and_index_preservation(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            def git(*args):
                return subprocess.check_output(["git", "-C", str(root), *args])
            git("init", "-q")
            git("config", "user.name", "Fixture")
            git("config", "user.email", "fixture@example.invalid")
            source = root / "source.c"
            source.write_text("int value = 1;\n" + "\n" * 20)
            git("add", "source.c")
            git("commit", "-qm", "baseline")
            source.write_text("int value = 2;\n" + "\n" * 20)
            patch = root / "change.patch"
            patch.write_bytes(git("diff", "--binary"))
            index_before = (root / ".git/index").read_bytes()
            module.verify(root, [patch])
            source.write_text(source.read_text() + "int unreviewed = 3;\n")
            # The old check accepts this extra change in a patched file.
            git("apply", "--reverse", "--check", str(patch))
            with self.assertRaises(subprocess.CalledProcessError):
                module.verify(root, [patch])
            self.assertEqual(index_before, (root / ".git/index").read_bytes())
            self.assertIn("unreviewed", source.read_text())


if __name__ == "__main__":
    unittest.main()
