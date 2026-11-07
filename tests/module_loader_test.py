"""Load a public fake module; reject incompatible tables before game startup."""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(sys.platform == 'darwin' and shutil.which('clang++'), 'requires the macOS dynamic loader')
class ModuleLoaderTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temporary = tempfile.TemporaryDirectory(prefix='annepad-module-loader-')
        cls.root = Path(cls.temporary.name)
        (cls.root / 'librecomp').mkdir()
        (cls.root / 'recomp.h').write_text('#pragma once\n#include <cstdint>\nusing gpr = int64_t;\nstruct recomp_context { int value; };\n')
        (cls.root / 'librecomp/rsp.hpp').write_text('#pragma once\n#include <cstdint>\nenum class RspExitReason { Broke };\nusing RspUcodeFunc = RspExitReason(uint8_t*, uint32_t);\n')
        (cls.root / 'fixture.cpp').write_text(r'''
#include "game_module.h"
#include <cstdlib>
gpr address() { return 0x80000400; }
uint8_t* observed = nullptr;
void entry(uint8_t* data, recomp_context*) { observed = data; data[0] += 1; }
void overlays() { if (observed) observed[0] += 32; }
RspExitReason audio(uint8_t* data, uint32_t) { data[0] += 2; return RspExitReason::Broke; }
RspExitReason tower(uint8_t* data, uint32_t) { data[0] += 4; return RspExitReason::Broke; }
RspExitReason color(uint8_t* data, uint32_t) { data[0] += 8; return RspExitReason::Broke; }
RspExitReason jpeg(uint8_t* data, uint32_t) { data[0] += 16; return RspExitReason::Broke; }
extern "C" const AnnePadGameModule* annepad_get_game_module() {
    static AnnePadGameModule m{1,sizeof(m),"fixture",address,entry,overlays,audio,tower,color,jpeg};
    int bad = std::atoi(std::getenv("ANNEPAD_TEST_BAD"));
    switch (bad) {
    case 1: m.version++; break; case 2: m.size--; break;
    case 3: m.identity="other"; break; case 4: m.identity=nullptr; break;
    case 5: m.entrypoint_address=nullptr; break; case 6: m.entrypoint=nullptr; break;
    case 7: m.register_overlays=nullptr; break; case 8: m.audio=nullptr; break;
    case 9: m.gb_tower=nullptr; break; case 10: m.gb_tower_color=nullptr; break;
    case 11: m.jpeg=nullptr; break; case 12: return nullptr;
    }
    return &m;
}
''')
        (cls.root / 'main.cpp').write_text(r'''
#include "game_module.h"
#include <cstdlib>
gpr get_entrypoint_address();
extern "C" void recomp_entrypoint(uint8_t*,recomp_context*);
extern RspUcodeFunc aspMain, gbTowerMain, gbTowerColorMain, njpgdspMain;
namespace pokestadium { void register_overlays(); }
int main(int argc, char** argv) {
    if (annepad_game_module_ready()) return 1;
    if (!annepad_load_game_module(nullptr) || annepad_game_module_ready()) return 2;
    if (!annepad_load_game_module("missing-before-success") || annepad_game_module_ready()) return 7;
    const char* error = annepad_load_game_module(argv[1]);
    bool reject = argc > 2;
    if (reject) return error && !annepad_game_module_ready() ? 0 : 3;
    if (error || !annepad_game_module_ready() || get_entrypoint_address()!=0x80000400) return 4;
    uint8_t data[1] = {0}; recomp_context ctx{};
    recomp_entrypoint(data,&ctx); pokestadium::register_overlays();
    aspMain(data,0); gbTowerMain(data,0); gbTowerColorMain(data,0); njpgdspMain(data,0);
    if (data[0]!=63) return 5;
    return annepad_load_game_module("missing-after-success") ? 6 : 0;
}
''')
        flags = ['clang++', '-std=c++20', '-I' + str(cls.root), '-I' + str(ROOT / 'apple/module')]
        subprocess.run(flags + ['-dynamiclib', str(cls.root / 'fixture.cpp'), '-o', str(cls.root / 'fixture.dylib')], check=True)
        (cls.root / 'no_getter.cpp').write_text('extern "C" int unrelated() { return 0; }\n')
        subprocess.run(flags + ['-dynamiclib', str(cls.root / 'no_getter.cpp'), '-o', str(cls.root / 'no_getter.dylib')], check=True)
        subprocess.run(flags + ['-DANNEPAD_MODULE_ID="fixture"', str(ROOT / 'apple/module/game_module_loader.cpp'), str(cls.root / 'main.cpp'), '-o', str(cls.root / 'check')], check=True)

    @classmethod
    def tearDownClass(cls):
        cls.temporary.cleanup()

    def run_case(self, bad, reject=False, filename='fixture.dylib'):
        args = [str(self.root / 'check'), str(self.root / filename)]
        if reject:
            args.append('reject')
        subprocess.run(args, env=dict(os.environ, ANNEPAD_TEST_BAD=str(bad)), check=True, capture_output=True)

    def test_all_four_rsp_callbacks_and_cpu_entrypoint_forward(self):
        self.run_case(0)

    def test_missing_file_is_rejected(self):
        self.run_case(0, True, 'missing.dylib')

    def test_library_without_getter_is_rejected(self):
        self.run_case(0, True, 'no_getter.dylib')

    def test_incompatible_or_incomplete_tables_are_rejected(self):
        for bad in range(1, 13):
            with self.subTest(bad=bad):
                self.run_case(bad, True)


if __name__ == '__main__':
    unittest.main()
