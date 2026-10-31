"""The real shell CMake helper retains callbacks without unused compiler stubs."""
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(sys.platform == 'darwin' and shutil.which('cmake') and shutil.which('clang++'),
                     'requires the macOS linker and CMake')
class ModuleLinkTests(unittest.TestCase):
    def test_retained_runtime_callbacks_resolve_and_unused_stub_is_absent(self):
        with tempfile.TemporaryDirectory(prefix='annepad public link ') as temporary:
            root = Path(temporary)
            (root / 'librecomp').mkdir()
            (root / 'recomp.h').write_text(
                '#pragma once\n#include <cstdint>\nusing gpr=int64_t;\nstruct recomp_context {};\n')
            (root / 'librecomp/rsp.hpp').write_text(
                '#pragma once\n#include <cstdint>\nenum class RspExitReason { Broke };\n'
                'using RspUcodeFunc = RspExitReason(uint8_t*, uint32_t);\n')
            exports = [name for name in (ROOT / 'cmake/runtime-exports.txt').read_text().splitlines()
                       if name.startswith('_')]
            functions = []
            for index, name in enumerate(exports):
                functions.append(f'extern "C" int callback{index}() __asm("{name}");\n'
                                 f'extern "C" int callback{index}() {{ return 123; }}\n')
            functions.append('extern "C" const char* unused_runtime_stub() '
                             '{ return "LiveRecomp public fixture must be stripped"; }\n')
            (root / 'runtime.cpp').write_text(''.join(functions))
            (root / 'main.cpp').write_text(
                '#include <dlfcn.h>\nint main() {\n'
                'auto callback = reinterpret_cast<int(*)()>(dlsym(RTLD_DEFAULT,"pause_self"));\n'
                'return callback && callback()==123 ? 0 : 1;\n}\n')
            (root / 'CMakeLists.txt').write_text(f'''
cmake_minimum_required(VERSION 3.28)
project(PublicModuleLink LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)
add_library(public_runtime STATIC runtime.cpp)
add_executable(public_shell main.cpp)
target_include_directories(public_shell PRIVATE "${{CMAKE_CURRENT_SOURCE_DIR}}")
target_link_libraries(public_shell PRIVATE public_runtime)
target_link_options(public_shell PRIVATE -Wl,-dead_strip)
set(ANNEPAD_IOS_DIR "{ROOT.as_posix()}/apple/app")
include("{ROOT.as_posix()}/cmake/ModuleShell.cmake")
annepad_module_shell(public_shell)
''')
            output = root / 'build'
            for command in (['cmake', '-S', str(root), '-B', str(output), '-DCMAKE_BUILD_TYPE=Release'],
                            ['cmake', '--build', str(output), '--parallel', '1']):
                result = subprocess.run(command, capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            binary = output / 'public_shell'
            subprocess.run([str(binary)], check=True, capture_output=True)
            symbols = set(subprocess.check_output(['nm', '-gjU', str(binary)], text=True).split())
            self.assertTrue(set(exports) <= symbols)
            self.assertNotIn('_unused_runtime_stub', symbols)
            self.assertNotIn(b'LiveRecomp public fixture', binary.read_bytes())


if __name__ == '__main__':
    unittest.main()
