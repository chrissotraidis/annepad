"""Public regressions against the exact pinned, patched decomp tools.

Prepare the locked public disassembly checkout first. No ROM or game-generated
source is needed; source contents are read from Git objects, never local edits.
"""
import importlib.util
from pathlib import Path
import runpy
import sys
import tempfile
import textwrap
from types import ModuleType, SimpleNamespace
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('module_sources', ROOT / 'scripts/module_sources.py')
sources = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sources)
CACHE = ROOT / 'external/sources/PokemonStadiumRecomp/disasm'


class Failure(Exception):
    pass


@unittest.skipUnless((CACHE / '.git').exists(), 'prepare the locked public disassembly source first')
class WindowsDecompTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temporary = tempfile.TemporaryDirectory(prefix='annepad decomp 日本語 ')
        cls.root = Path(cls.temporary.name)
        cls.source = cls.root / 'source'
        cls.record = sources.export_decomp_source(CACHE, cls.source)

    @classmethod
    def tearDownClass(cls):
        cls.temporary.cleanup()

    def test_jpeg_payload_is_closed_and_complete_before_rename(self):
        payload = b'\xff\xd8public fixture\xff\xd9'
        source = self.root / 'fixture.presjpeg'
        source.write_bytes(b'PRESJPEG' + (12).to_bytes(4, 'big') + payload)
        with mock.patch.object(sys, 'argv', ['extract_presjpeg.py', str(source)]), \
                mock.patch.dict(sys.modules, {'crunch64': ModuleType('crunch64')}):
            runpy.run_path(str(self.source / 'tools/extract_presjpeg.py'), run_name='__main__')
        self.assertFalse(source.exists())
        self.assertEqual(source.with_suffix('.jpeg').read_bytes(), payload)

    def merge(self, *symbols):
        # Exercise the pinned tool's internal merge block, retaining its actual
        # relocation redirection bookkeeping. It has no standalone public API.
        path = self.source / 'tools/asm-processor/asm_processor.py'
        text = path.read_text(encoding='utf-8')
        start = text.index('        # Get rid of duplicate symbols, favoring ones that are not UNDEF.')
        end = text.index('        new_syms = newer_syms', start) + len('        new_syms = newer_syms')
        state = dict(new_syms=list(symbols), SHN_UNDEF=0, STB_LOCAL=0, STT_OBJECT=1, Failure=Failure)
        exec(compile(textwrap.dedent(text[start:end]), str(path), 'exec'), state)
        return state

    def symbol(self, section, value):
        return SimpleNamespace(name='public_section', bind=1, st_shndx=section, st_value=value)

    def test_identical_section_symbol_redirects_relocations(self):
        first, second = self.symbol(2, 0), self.symbol(2, 0)
        state = self.merge(first, second)
        self.assertEqual(state['new_syms'], [first])
        self.assertIs(second.replace_by, first)
        self.assertEqual(state['old_syms'], [second])

    def test_conflicting_section_or_value_still_fails(self):
        for other in ((3, 0), (2, 4)):
            with self.subTest(other=other), self.assertRaisesRegex(Failure, 'defined twice'):
                self.merge(self.symbol(2, 0), self.symbol(*other))

    def test_undefined_symbol_redirects_to_definition(self):
        undefined, defined = self.symbol(0, 0), self.symbol(2, 4)
        state = self.merge(undefined, defined)
        self.assertEqual(state['new_syms'], [defined])
        self.assertIs(undefined.replace_by, defined)


if __name__ == '__main__':
    unittest.main()
