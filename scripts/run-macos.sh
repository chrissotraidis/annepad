#!/usr/bin/env bash

set -euo pipefail
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source "$script_dir/lib/common.sh"

usage() {
    printf 'usage: %s --rom /absolute/path/to/pokemon-stadium-us-1.0.z64\n' \
        "$(basename "$0")" >&2
    exit 64
}

rom_path=
while (($#)); do
    case "$1" in
        --rom)
            (($# >= 2)) || usage
            rom_path=$2
            shift 2
            ;;
        *) usage ;;
    esac
done
[[ -n "$rom_path" ]] || usage
[[ "$rom_path" == /* ]] || die "ROM path must be absolute"
[[ -f "$rom_path" ]] || die "ROM does not exist: $rom_path"

runner="$ANNEPAD_ROOT/build-macos/AnnePad.app/Contents/MacOS/AnnePad"
[[ -x "$runner" ]] || die "macOS runner is missing; run scripts/build-macos.sh first"

mkdir -p "$ANNEPAD_ROOT/logs"
log="$ANNEPAD_ROOT/logs/macos-latest.log"
note "Launching native macOS runner; log: $log"
(
    cd "$ANNEPAD_ROOT/build-macos"
    PSR_AUTOBOOT=1 "$runner" "$rom_path"
) 2>&1 | tee "$log"
