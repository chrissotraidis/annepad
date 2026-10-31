#!/usr/bin/env python3
"""Zip a built AnnePad.app as Payload/AnnePad.app in a deterministic unsigned IPA."""
import sys
from pathlib import Path
import zipfile


def main(app, output):
    app, output = Path(app), Path(output)
    if not (app / 'Info.plist').is_file():
        raise SystemExit(f'not an app bundle: {app}')
    output.parent.mkdir(parents=True, exist_ok=True)
    partial = output.with_suffix('.ipa.partial')
    with zipfile.ZipFile(partial, 'w', zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(p for p in app.rglob('*') if p.is_file() and not p.is_symlink()):
            info = zipfile.ZipInfo('Payload/AnnePad.app/' + path.relative_to(app).as_posix(), (1980, 1, 1, 0, 0, 0))
            info.external_attr = (path.stat().st_mode & 0o777) << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(info, path.read_bytes())
    partial.replace(output)


if __name__ == '__main__':
    if len(sys.argv) != 3:
        raise SystemExit('usage: package-module-shell.py AnnePad.app output.ipa')
    main(*sys.argv[1:])
