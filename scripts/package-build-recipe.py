#!/usr/bin/env python3
"""Package clean wrapper source, pins, prepared-tree fingerprints and license texts.

This is explicitly a build recipe, not a complete/offline corresponding-source
archive: restricted game-derived inputs and dependency source remain external.
"""
import hashlib
import io
import json
from pathlib import Path
import re
import subprocess
import tarfile

ROOT = Path(__file__).resolve().parents[1]
def git(path, *args):
    return subprocess.check_output(['git', '-C', str(path), *args])
def digest(data):
    return hashlib.sha256(data).hexdigest()
def main():
    if git(ROOT, 'status', '--porcelain', '--untracked-files=normal').strip():
        raise SystemExit('Commit the intended wrapper changes before packaging.')
    subprocess.run([str(ROOT / 'scripts/verify-sources.sh')], check=True)
    commit = git(ROOT, 'rev-parse', 'HEAD').decode().strip()
    entries = {}
    with tarfile.open(fileobj=io.BytesIO(git(ROOT, 'archive', 'HEAD'))) as wrapper:
        for member in wrapper:
            if member.isfile():
                entries['wrapper/' + member.name] = (wrapper.extractfile(member).read(), member.mode)
            elif member.issym():
                raise SystemExit('Review wrapper symlinks before adding them to a recipe.')
    components = []
    for name in ['PokemonStadiumRecomp', 'N64ModernRuntime', 'N64Recomp-generator', 'rt64']:
        root = ROOT / 'external/sources' / name
        paths = git(root, 'ls-files', '--recurse-submodules', '-z').decode().split('\0')
        files = []
        for relative in filter(None, paths):
            path = root / relative
            if not path.is_file() or path.is_symlink():
                continue
            data = path.read_bytes()
            files.append({'path': relative, 'sha256': digest(data), 'mode': oct(path.stat().st_mode & 0o777)})
            if re.match(r'(?i)^(licen[cs]e|copying|notice|copyright)([._-].*)?$', path.name):
                entries['licenses/' + name + '/' + relative] = (data, 0o644)
        components.append({'name': name, 'commit': git(root, 'rev-parse', 'HEAD').decode().strip(),
            'submodules': git(root, 'submodule', 'status', '--recursive').decode().splitlines(),
            'prepared_tracked_files': files})
    sdl = ROOT / 'build-ios-dependencies/sources/SDL2-2.32.10/LICENSE.txt'
    entries['licenses/SDL2/LICENSE.txt'] = (sdl.read_bytes(), 0o644)
    entries['source-provenance.json'] = (json.dumps({'wrapper_commit': commit,
        'scope': 'wrapper build recipe and license inventory; dependency and restricted generated sources are not included',
        'components': components}, indent=2).encode() + b'\n', 0o644)
    entries['README.txt'] = (b'''AnnePad build recipe and license inventory

wrapper/ contains the exact committed app integration, build scripts, patch
series, dependency lock, and local build instructions. source-provenance.json
records selected Git commits, recursive gitlinks, and prepared-file hashes.
licenses/ preserves license texts found in the selected source graph, including
build-only dependencies; inclusion does not mean every component ships.

This is NOT a complete corresponding-source archive or an offline rebuild kit.
Dependencies are fetched from the locked upstream URLs. Game-derived generated
source, ROMs, upstream binary captures, disassembly and desktop launcher trees
are not redistributed here. Read wrapper/docs/MODERNIZATION.md and
wrapper/docs/LEGAL-AND-ASSET-BOUNDARIES.md for unresolved source-delivery scope.
No third-party license is changed by this archive.
''', 0o644)
    manifest = ''.join(digest(data) + '  ' + name + '\n' for name, (data, _) in sorted(entries.items()))
    entries['MANIFEST.sha256'] = (manifest.encode(), 0o644)
    output = ROOT / 'artifacts/AnnePad-0.1.0-build4-build-recipe.tar.gz'
    output.parent.mkdir(exist_ok=True)
    import gzip
    with output.open('wb') as raw, gzip.GzipFile(fileobj=raw, mode='wb', filename='', mtime=0) as gz:
        with tarfile.open(fileobj=gz, mode='w') as archive:
            for name, (data, mode) in sorted(entries.items()):
                info = tarfile.TarInfo(name)
                info.size, info.mode, info.mtime = len(data), mode, 0
                archive.addfile(info, io.BytesIO(data))
    print(output)
    print(digest(output.read_bytes()))
if __name__ == '__main__':
    main()
