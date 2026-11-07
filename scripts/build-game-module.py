#!/usr/bin/env python3
"""Compile AnnePad's private game module from verified generated CPU code.

PadMint supplies its LLVM and the iOS SDK toolchain prepared for the matching
shell. The result exports only annepad_get_game_module; PadMint checks its
imports against the shell and inserts it.
"""
import argparse
import os
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ROOT / 'external' / 'sources'


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--toolchain', type=Path, required=True)
    parser.add_argument('--llvm', type=Path, default=os.environ.get('PADMINT_LLVM_ROOT'))
    parser.add_argument('--generated', type=Path, default=SOURCES / 'PokemonStadiumRecomp' / 'generated')
    parser.add_argument('--game-source', type=Path, default=SOURCES / 'PokemonStadiumRecomp')
    parser.add_argument('--runtime-source', type=Path, default=SOURCES / 'N64ModernRuntime')
    parser.add_argument('--build-dir', type=Path, default=ROOT / 'build-ios-game-module')
    parser.add_argument('--jobs', type=int, default=os.cpu_count() or 2)
    args = parser.parse_args()
    if not args.llvm or not Path(args.llvm).is_dir():
        parser.error('PadMint must supply PADMINT_LLVM_ROOT, or pass --llvm with its LLVM folder')
    if args.jobs < 1:
        parser.error('--jobs must be positive')
    build = args.build_dir.resolve()
    subprocess.run(['cmake', '-S', str(ROOT / 'cmake' / 'game-module'), '-B', str(build), '-G', 'Ninja',
                    '-DCMAKE_BUILD_TYPE=Release', f'-DCMAKE_TOOLCHAIN_FILE={args.toolchain.resolve()}',
                    f'-DANNEPAD_GENERATED={args.generated.resolve()}',
                    f'-DANNEPAD_GAME_SOURCE={args.game_source.resolve()}',
                    f'-DANNEPAD_RUNTIME_SOURCE={args.runtime_source.resolve()}'], check=True)
    subprocess.run(['cmake', '--build', str(build), '--parallel', str(args.jobs)], check=True)
    module = build / 'AnnePadGame.dylib'
    nm = Path(args.llvm) / 'bin' / ('llvm-nm.exe' if os.name == 'nt' else 'llvm-nm')
    exports = subprocess.run([str(nm), '-g', '--defined-only', '-j', str(module)],
                             check=True, capture_output=True, text=True).stdout.split()
    if exports != ['_annepad_get_game_module']:
        raise SystemExit(f'the module must export only _annepad_get_game_module, not {exports}')
    print(f'Private module: {module}')


if __name__ == '__main__':
    main()
