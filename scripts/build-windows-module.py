#!/usr/bin/env python3
"""Build AnnePad's private game module on Windows, from the player's ROM.

The steps match the Mac route: rebuild pret's decompilation and require the
supported ROM's exact MD5, generate the CPU code with the pinned N64Recomp,
then compile the module with PadMint's iOS toolchain (build-game-module.py).
Make and Bash run in an isolated MSYS userland; IDO, MIPS binutils and the
fixed Rabbitizer wheel come from PadMint (PADMINT_* variables) or the flags.
Nothing is installed system-wide. Generated code and ROM copies stay in --build-dir.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path, PureWindowsPath
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
import module_sources  # noqa: E402

LOCK = json.loads((ROOT / 'dependencies.lock.json').read_text(encoding='utf-8'))
GENERATOR_LIBS = ('lib/rabbitizer', 'lib/ELFIO', 'lib/fmt', 'lib/tomlplusplus', 'lib/sljit')
# splat 0.25.0 writes host paths into .incbin lines and linker scripts; GNU as
# and ld read Windows backslashes as escapes. Write POSIX paths, nothing else.
SPLAT_FIXES = (
    ('segtypes/common/textbin.py', "f.write(f'.incbin \"{binpath}\"\\n')",
     "f.write(f'.incbin \"{binpath.as_posix()}\"\\n')"),
    ('segtypes/linker_entry.py', 'self._writeln(f"{object_path}({section});")',
     'self._writeln(f"{object_path.as_posix()}({section});")'),
)


def say(message):
    print(message, flush=True)


def run(argv, **kwargs):
    say('> ' + ' '.join(str(part) for part in argv))
    return subprocess.run([str(part) for part in argv], check=True, **kwargs)


def normalized_rom(path):
    """Big-endian z64 bytes of the supported ROM (z64, v64 or n64 input)."""
    data = bytearray(Path(path).read_bytes())
    magic = bytes(data[:4])
    if magic == bytes.fromhex('37804012'):
        data[0::2], data[1::2] = data[1::2], data[0::2]
    elif magic == bytes.fromhex('40123780'):
        for offset in range(0, len(data) - 3, 4):
            data[offset:offset + 4] = data[offset:offset + 4][::-1]
    elif magic != bytes.fromhex('80371240'):
        raise SystemExit('This is not an N64 ROM AnnePad recognizes.')
    rom = LOCK['rom']
    if len(data) != rom['size'] or hashlib.md5(data).hexdigest() != rom['md5']:
        raise SystemExit('AnnePad needs Pokemon Stadium (US) 1.0; this file is a different ROM or revision.')
    return bytes(data)


def checkout(cache, name, url, commit, submodules=()):
    folder = cache / name
    if not (folder / '.git').is_dir():
        run(['git', 'clone', '-q', url, folder])
    current = subprocess.run(['git', '-C', folder, 'rev-parse', 'HEAD'], capture_output=True, text=True).stdout.strip()
    if current != commit:
        run(['git', '-C', folder, 'fetch', '-q', 'origin', commit])
        run(['git', '-C', folder, 'checkout', '-q', commit])
    if submodules:
        run(['git', '-C', folder, 'submodule', 'update', '-q', '--init', *submodules])
    return folder


def posix(path):
    """MSYS path for a Windows path (both MSYS runtimes share /cygdrive)."""
    path = PureWindowsPath(Path(path).resolve())
    return '/cygdrive/' + path.drive[0].lower() + '/' + '/'.join(path.parts[1:])


def msvc_environment():
    vswhere = Path(os.environ.get('ProgramFiles(x86)', r'C:\Program Files (x86)'), 'Microsoft Visual Studio', 'Installer', 'vswhere.exe')
    if not vswhere.is_file():
        raise SystemExit('Install Visual Studio Build Tools with C++ (see docs/WINDOWS_MODULE.md).')
    install = subprocess.run([vswhere, '-latest', '-products', '*', '-property', 'installationPath'],
                             capture_output=True, text=True, encoding='utf-8').stdout.strip()
    arch = 'arm64' if os.environ.get('PROCESSOR_ARCHITECTURE', '').upper() == 'ARM64' else 'x64'
    vcvars = Path(install, 'VC', 'Auxiliary', 'Build', 'vcvarsall.bat')
    out = subprocess.run(f'"{vcvars}" {arch} >nul && set', shell=True, capture_output=True,
                         text=True, encoding='utf-8', errors='replace', check=True).stdout
    return dict(line.split('=', 1) for line in out.splitlines() if '=' in line)


def write_script(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(text.encode('utf-8'))


def staged_msys(work):
    """Make, Bash and coreutils from pinned MSYS2 packages, unpacked in the build folder."""
    root = work / 'msys'
    if (root / 'usr' / 'bin' / 'make.exe').is_file():
        return root
    pins = json.loads((ROOT / 'scripts' / 'windows-msys.json').read_text(encoding='utf-8'))['packages']
    downloads = work / 'msys-downloads'
    downloads.mkdir(exist_ok=True)
    staging = work / 'msys.partial'
    if staging.exists():
        shutil.rmtree(staging)
    staging.mkdir()
    for pin in pins:
        archive = downloads / pin['file']
        if not archive.is_file() or hashlib.sha256(archive.read_bytes()).hexdigest() != pin['sha256']:
            run(['curl.exe', '-fsSL', '-o', archive, pin['url']])
        if hashlib.sha256(archive.read_bytes()).hexdigest() != pin['sha256']:
            raise SystemExit(f"Download check failed for {pin['file']}.")
        run(['cmake', '-E', 'tar', 'xf', archive], cwd=staging)
    for name in ('.BUILDINFO', '.MTREE', '.PKGINFO', '.INSTALL'):
        (staging / name).unlink(missing_ok=True)
    for name in ('tmp', 'etc'):
        (staging / name).mkdir(exist_ok=True)
    staging.replace(root)
    return root


def python_environment(work, uv, wheel):
    venv = work / 'venv'
    if not venv.exists():
        run([uv, 'venv', '--python', sys.executable, venv])
    python = venv / 'Scripts' / 'python.exe'
    run([uv, 'pip', 'install', '--python', python, '-r', ROOT / 'scripts' / 'windows-requirements.txt'])
    run([uv, 'pip', 'install', '--python', python, '--no-deps', '--reinstall', wheel])
    site = venv / 'Lib' / 'site-packages' / 'splat'
    for name, old, new in SPLAT_FIXES:
        path = site / name
        text = path.read_text(encoding='utf-8')
        if new not in text:
            if text.count(old) != 1:
                raise SystemExit(f'Unexpected splat source in {name}; the pinned splat changed.')
            path.write_bytes(text.replace(old, new).encode('utf-8'))
    shutil.copyfile(python, venv / 'Scripts' / 'python3.exe')
    return venv


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--rom', type=Path, required=True)
    parser.add_argument('--toolchain', type=Path, required=True, help="PadMint's iOS toolchain file")
    parser.add_argument('--build-dir', type=Path, required=True)
    parser.add_argument('--jobs', type=int, default=os.cpu_count() or 2)
    parser.add_argument('--llvm', type=Path, default=os.environ.get('PADMINT_LLVM_ROOT'))
    parser.add_argument('--msys', type=Path, default=os.environ.get('PADMINT_MSYS_ROOT'))
    parser.add_argument('--ido', type=Path, default=os.environ.get('PADMINT_IDO_ROOT'),
                        help='Folder with ido53 and ido71 (PadMint scripts/ido-windows output)')
    parser.add_argument('--binutils', type=Path, default=os.environ.get('PADMINT_MIPS_BINUTILS'),
                        help='Folder with mips-linux-gnu-as.exe, ld, ar, objcopy, strip')
    parser.add_argument('--rabbitizer-wheel', type=Path, default=os.environ.get('PADMINT_RABBITIZER_WHEEL'))
    parser.add_argument('--uv', default=os.environ.get('PADMINT_UV') or shutil.which('uv') or 'uv')
    args = parser.parse_args()
    if os.name != 'nt':
        parser.error('This is the Windows route; on a Mac use scripts/generate-game.sh.')
    for name in ('llvm', 'ido', 'binutils', 'rabbitizer_wheel'):
        if not getattr(args, name) or not Path(getattr(args, name)).exists():
            parser.error(f'--{name.replace("_", "-")} is missing; PadMint normally supplies it.')
    work = args.build_dir.resolve()
    work.mkdir(parents=True, exist_ok=True)
    sources = LOCK['sources']
    cache = work / 'cache'
    cache.mkdir(exist_ok=True)

    say('Checking your ROM...')
    rom = normalized_rom(args.rom)

    say('Getting the pinned sources...')
    checkout(cache, 'pokestadium', sources['pokemonStadiumDisasm']['url'], sources['pokemonStadiumDisasm']['commit'])
    checkout(cache, 'PokemonStadiumRecomp', sources['pokemonStadiumRecomp']['url'], sources['pokemonStadiumRecomp']['commit'])
    checkout(cache, 'N64ModernRuntime', sources['n64ModernRuntime']['url'], sources['n64ModernRuntime']['commit'], ('N64Recomp',))
    generator = checkout(cache, 'N64Recomp-generator', sources['n64RecompGenerator']['url'],
                         sources['n64RecompGenerator']['commit'], GENERATOR_LIBS)
    for name in ('disasm', 'gen', 'msrc'):
        if (work / name).exists():
            shutil.rmtree(work / name)
    module_sources.export_decomp_source(cache / 'pokestadium', work / 'disasm')
    module_sources.export_tree(cache / 'PokemonStadiumRecomp', work / 'gen', sources['pokemonStadiumRecomp']['commit'],
                               module_sources.patch_files('pokemon-stadium-recomp', module_sources.GAME_PATCHES))
    module_sources.export_module_sources(cache, work / 'msrc')

    say('Preparing the decompilation tools...')
    msys = args.msys or staged_msys(work)
    venv = python_environment(work, args.uv, args.rabbitizer_wheel)
    tools_bin = work / 'bin'
    clang = posix(Path(args.llvm) / 'bin' / 'clang.exe')
    write_script(tools_bin / 'cpp', f'#!/bin/bash\nexec "{clang}" -E -xc++ "$@"\n')
    for version, folder in (('7.1', 'ido71'), ('5.3', 'ido53')):
        cc = posix(Path(args.ido) / folder / 'usr' / 'bin' / 'cc.exe')
        # TMPDIR and USR_LIB resolve inside IDO's own isolated MSYS runtime.
        write_script(work / 'disasm' / 'tools' / 'ido' / 'windows' / version / 'cc',
                     f'#!/bin/bash\nTMPDIR=/tmp USR_LIB=/usr/bin exec "{cc}" "$@"\n')
    baserom = work / 'disasm' / 'baseroms' / 'us' / 'baserom.z64'
    baserom.parent.mkdir(parents=True, exist_ok=True)
    baserom.write_bytes(rom)
    temp = work / 'tmp'
    temp.mkdir(exist_ok=True)
    python3 = posix(venv / 'Scripts' / 'python3.exe')
    flags = f'PYTHON="{python3}" COLOR=0 RUN_CC_CHECK=0'
    write_script(work / 'make.sh', '\n'.join([
        '#!/bin/bash', 'set -eo pipefail', 'export PYTHONUTF8=1',
        f'export TMPDIR="{posix(temp)}"',
        f'export PATH="/usr/bin:{posix(tools_bin)}:{posix(args.binutils)}:{posix(venv / "Scripts")}"',
        f'cd "{posix(work / "disasm")}"',
        f'make extract {flags}', f'make -j{args.jobs} rom {flags}', '']))

    say('Rebuilding the ROM from the decompilation (checks it matches yours)...')
    run([Path(msys) / 'usr' / 'bin' / 'bash.exe', posix(work / 'make.sh')])
    rebuilt = work / 'disasm' / 'build' / 'pokestadium-us.z64'
    if hashlib.md5(rebuilt.read_bytes()).hexdigest() != LOCK['rom']['md5']:
        raise SystemExit('The rebuilt ROM does not match the supported ROM; nothing was generated.')

    say('Building the code generator...')
    env = msvc_environment()
    env['CXXFLAGS'] = '-DFMT_USE_CONSTEVAL=0'
    fmt = generator / 'lib' / 'fmt'
    patch = ROOT / 'patches' / 'n64recomp-generator' / 'fmt-allow-consteval-override.patch'
    if subprocess.run(['git', '-C', fmt, 'apply', '--reverse', '--check', patch], capture_output=True).returncode:
        run(['git', '-C', fmt, 'apply', patch])
    recomp = work / 'n64recomp-build'
    run(['cmake', '-S', generator, '-B', recomp, '-G', 'Ninja', '-DCMAKE_BUILD_TYPE=Release', '-DWITH_ARES_BRIDGE=OFF'], env=env)
    run(['cmake', '--build', recomp, '--target', 'N64RecompCLI', '--parallel', args.jobs], env=env)

    say('Generating the game code...')
    gen = work / 'gen'
    (gen / 'disasm' / 'build').mkdir(parents=True, exist_ok=True)
    shutil.copyfile(work / 'disasm' / 'build' / 'pokestadium-us.elf', gen / 'disasm' / 'build' / 'pokestadium-us.elf')
    (gen / 'baserom.z64').write_bytes(rom)
    try:
        run([recomp / 'N64Recomp.exe', 'game.toml'], cwd=gen, stdout=subprocess.DEVNULL)
    finally:
        for copy in (gen / 'baserom.z64', baserom, rebuilt):
            copy.unlink(missing_ok=True)
    generated = sorted(path for path in (gen / 'generated').rglob('*') if path.is_file())
    say(f'Generated {len(generated)} files.')

    say('Compiling the game module...')
    run([sys.executable, ROOT / 'scripts' / 'build-game-module.py', '--toolchain', args.toolchain,
         '--llvm', args.llvm, '--generated', gen / 'generated', '--game-source', work / 'msrc' / 'game',
         '--runtime-source', work / 'msrc' / 'runtime', '--build-dir', work / 'module', '--jobs', args.jobs])


if __name__ == '__main__':
    main()

