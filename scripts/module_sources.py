"""Export pinned public sources without changing a cache's worktree or Git objects."""
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
GAME_PATCHES = (
    'apple-platform-support', 'ios-release-diagnostics', 'ios-release-surface',
    'ios-release-hook-surface', 'audio-active-list-repair', 'synchronous-audio-tasks',
    'controller-lifecycle-reconciliation', 'private-module-shell',
)
RUNTIME_PATCHES = (
    'apple-audio-uaf-size-type', 'static-mobile-core-profile', 'gbcart-exact-rom-validation',
    'atomic-save-lifecycle', 'ios-release-trace-exclusion', 'synchronous-audio-tasks',
)


def sha256(path):
    digest = hashlib.sha256()
    with Path(path).open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


def relative_path(name):
    path = PurePosixPath(name)
    if (not name or '\\' in name or ':' in name or path.is_absolute()
            or any(part in ('', '.', '..') for part in name.split('/'))):
        raise ValueError('Unsafe source path: ' + name)
    return path


def git_environment():
    env = dict(os.environ)
    for name in ('GIT_DIR', 'GIT_WORK_TREE', 'GIT_INDEX_FILE', 'GIT_OBJECT_DIRECTORY',
                 'GIT_ALTERNATE_OBJECT_DIRECTORIES'):
        env.pop(name, None)
    env.update(GIT_OPTIONAL_LOCKS='0', GIT_NO_LAZY_FETCH='1')
    return env


def export_tree(checkout, destination, revision, patches=(), children=None):
    """Read committed objects plus exact patches; child entries follow gitlink pins.

    A child maps its path to (patches, grandchildren). Omitted gitlinks are
    recorded but not exported, so unused decomp/UI/emulator sources stay out of
    the module and host-generator build trees. Existing destinations are refused.
    """
    checkout, destination = Path(checkout).resolve(), Path(destination).resolve()
    if destination == checkout or checkout in destination.parents:
        raise ValueError('Prepared output must be outside the source cache')
    children = children or {}
    env = git_environment()
    git = ['git', '-c', 'safe.directory=' + str(checkout), '-C', str(checkout)]
    actual = subprocess.check_output(git + ['rev-parse', 'HEAD'], env=env, encoding='utf-8').strip()
    if actual != revision:
        raise ValueError('Source revision mismatch: ' + str(checkout))
    objects = subprocess.check_output(git + ['rev-parse', '--path-format=absolute', '--git-path', 'objects'],
                                      env=env, encoding='utf-8').strip()
    destination.mkdir(parents=True, exist_ok=False)
    files, links, patch_hashes = {}, {}, {}
    with tempfile.TemporaryDirectory(prefix='annepad-source-') as temporary:
        scratch = Path(temporary)
        (scratch / 'objects').mkdir()
        # Even the blobs created by git apply go to scratch, not the source cache.
        env.update(GIT_INDEX_FILE=str(scratch / 'index'), GIT_OBJECT_DIRECTORY=str(scratch / 'objects'),
                   GIT_ALTERNATE_OBJECT_DIRECTORIES=objects)
        subprocess.run(git + ['read-tree', revision], env=env, check=True)
        for patch in patches:
            patch = Path(patch)
            data = patch.read_bytes().replace(b'\r\n', b'\n')
            subprocess.run(git + ['apply', '--cached', '-'], input=data, env=env, check=True)
            patch_hashes[patch.name] = hashlib.sha256(data).hexdigest()
        entries = subprocess.check_output(git + ['ls-files', '--stage', '-z'], env=env).split(b'\0')
        with subprocess.Popen(git + ['cat-file', '--batch'], env=env,
                              stdin=subprocess.PIPE, stdout=subprocess.PIPE) as reader:
            for entry in entries:
                if not entry:
                    continue
                header, encoded_name = entry.split(b'\t', 1)
                mode, oid, stage = header.split()
                name = encoded_name.decode('utf-8')
                relative = relative_path(name)
                if stage != b'0':
                    raise ValueError('Unmerged source entry: ' + name)
                if mode == b'160000':
                    links[name] = oid.decode()
                    continue
                if mode not in (b'100644', b'100755'):
                    raise ValueError('Unsupported linked source entry: ' + name)
                reader.stdin.write(oid + b'\n')
                reader.stdin.flush()
                result = reader.stdout.readline().split()
                if len(result) != 3 or result[:2] != [oid, b'blob']:
                    raise ValueError('Missing pinned source object: ' + name)
                data = reader.stdout.read(int(result[2]))
                if len(data) != int(result[2]) or reader.stdout.read(1) != b'\n':
                    raise ValueError('Truncated pinned source object: ' + name)
                path = destination.joinpath(*relative.parts)
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(data)
                path.chmod(int(mode, 8) & 0o777)
                files[name] = hashlib.sha256(data).hexdigest()
            reader.stdin.close()
            if reader.wait():
                raise ValueError('Could not read pinned source objects')
    if not set(children) <= set(links):
        raise ValueError('A selected child is not a pinned gitlink')
    descendants = {}
    for name, (patches, grandchildren) in children.items():
        descendants[name] = export_tree(checkout / name, destination / name, links[name], patches, grandchildren)
    return {'revision': revision, 'patches': patch_hashes, 'files': files,
            'gitlinks': links, 'children': descendants}


def verify_tree(root, record):
    root = Path(root)
    if (not root.is_dir() or root.is_symlink()
            or (hasattr(root, 'is_junction') and root.is_junction())):
        raise ValueError('Prepared source must be an unlinked directory: ' + str(root))
    expected = dict(record['files'])
    for child, child_record in record['children'].items():
        for name, digest in flattened_files(child_record).items():
            expected[child + '/' + name] = digest
    actual = {}
    for path in root.rglob('*'):
        if path.is_symlink() or (hasattr(path, 'is_junction') and path.is_junction()):
            raise ValueError('Linked prepared source: ' + str(path))
        if path.is_file():
            actual[path.relative_to(root).as_posix()] = sha256(path)
    if actual != expected:
        raise ValueError('Prepared source inventory changed: ' + str(root))


def flattened_files(record):
    files = dict(record['files'])
    for child, child_record in record['children'].items():
        for name, digest in flattened_files(child_record).items():
            files[child + '/' + name] = digest
    return files


def patch_files(folder, names):
    return tuple(ROOT / 'patches' / folder / (name + '.patch') for name in names)


def export_module_sources(cache, destination):
    cache, destination = Path(cache), Path(destination)
    lock = json.loads((ROOT / 'dependencies.lock.json').read_text(encoding='utf-8'))['sources']
    destination.mkdir(parents=True, exist_ok=False)
    game = export_tree(cache / 'PokemonStadiumRecomp', destination / 'game',
                       lock['pokemonStadiumRecomp']['commit'],
                       patch_files('pokemon-stadium-recomp', GAME_PATCHES))
    runtime = export_tree(cache / 'N64ModernRuntime', destination / 'runtime',
                          lock['n64ModernRuntime']['commit'],
                          patch_files('n64-modern-runtime', RUNTIME_PATCHES),
                          {'N64Recomp': (patch_files('n64recomp-runtime', ('no-dynamic-code-targets',)), {})})
    if runtime['gitlinks']['N64Recomp'] != lock['n64RecompRuntime']['commit']:
        raise ValueError('Runtime recompiler pin differs from the lock')
    return {'game': game, 'runtime': runtime}


def export_decomp_source(checkout, destination):
    lock = json.loads((ROOT / 'dependencies.lock.json').read_text(encoding='utf-8'))['sources']
    return export_tree(checkout, destination, lock['pokemonStadiumDisasm']['commit'],
                       patch_files('pokestadium-disasm', ('ultralib-cross-archiver',
                                   'macos-ido-eucjp-escape', 'windows-make-processes')))
