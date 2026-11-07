#!/usr/bin/env python3
"""Hash the maintained source contract shared by an app shell and its module."""
import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def identity(root=ROOT):
    paths = [root / 'dependencies.lock.json', root / 'version.json']
    for folder, extensions in (('apple', ('.h', '.hpp', '.cpp', '.mm', '.txt')),
                               ('patches', ('.patch',)),
                               ('cmake', ('.cmake', '.txt', '.manifest')),
                               ('scripts', ('.py', '.sh'))):
        paths.extend(path for path in (root / folder).rglob('*') if path.suffix in extensions)
    digest = hashlib.sha256()
    for path in sorted(paths, key=lambda path: path.relative_to(root).as_posix()):
        digest.update(path.relative_to(root).as_posix().encode('utf-8') + b'\0')
        digest.update(path.read_bytes().replace(b'\r\n', b'\n') + b'\0')
    return digest.hexdigest()


if __name__ == '__main__':
    print(identity())
