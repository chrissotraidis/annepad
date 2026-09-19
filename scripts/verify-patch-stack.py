#!/usr/bin/env python3
"""Compare effective tracked source with a patch stack without editing it."""

import os
from pathlib import Path
import subprocess
import sys
import tempfile


def verify(checkout, patches):
    checkout = Path(checkout).resolve()
    patches = [str(Path(p).resolve()) for p in patches]
    # An alternate index lets Git reconstruct the expected tree without
    # touching the user's index, working sources, generated files or gitlinks.
    with tempfile.TemporaryDirectory(prefix="annepad-source-check-") as scratch:
        env = dict(os.environ, GIT_INDEX_FILE=str(Path(scratch) / "index"))
        command = ["git", "-C", str(checkout)]
        subprocess.run(command + ["read-tree", "HEAD"], env=env, check=True)
        for patch in patches:
            subprocess.run(command + ["apply", "--cached", patch], env=env, check=True)
        subprocess.run(command + ["diff", "--exit-code", "--quiet",
                                  "--no-ext-diff", "--ignore-submodules=all"],
                       env=env, check=True)


if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit("usage: verify-patch-stack.py CHECKOUT PATCH [PATCH ...]")
    try:
        verify(sys.argv[1], sys.argv[2:])
    except subprocess.CalledProcessError:
        sys.exit("error: prepared source differs from its exact patch stack")
