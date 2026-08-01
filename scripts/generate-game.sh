#!/usr/bin/env bash

set -euo pipefail
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source "$script_dir/lib/common.sh"

usage() {
    printf 'usage: %s --rom /absolute/path/to/user-rom\n' "$(basename "$0")" >&2
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

"$script_dir/verify-sources.sh"
"$script_dir/prepare-game.sh" --rom "$rom_path"
"$script_dir/build-host-tools.sh"

game="$ANNEPAD_SOURCES/PokemonStadiumRecomp"
disasm="$game/disasm"
normalized="$ANNEPAD_ROOT/generated/rom/baserom.z64"
cp "$normalized" "$game/baserom.z64"
chmod 600 "$game/baserom.z64"

note "Building the pinned pret disassembly and matching ROM..."
rebuilt="$disasm/build/pokestadium-us.z64"
elf="$disasm/build/pokestadium-us.elf"
expected_md5=$(jq -er '.rom.md5' "$ANNEPAD_LOCK")
if [[ -f "$rebuilt" && -f "$elf" && "$(md5 -q "$rebuilt")" == "$expected_md5" ]]; then
    note "Reusing the hash-verified matching ROM and ELF."
else
    PATH="$disasm/.venv/bin:$PATH" make -C "$disasm" RUN_CC_CHECK=0 init
    PATH="$disasm/.venv/bin:$PATH" make -C "$disasm" RUN_CC_CHECK=0
fi

[[ -f "$rebuilt" ]] || die "matching ROM build did not produce $rebuilt"
[[ -f "$elf" ]] || die "matching ROM build did not produce $elf"
rebuilt_md5=$(md5 -q "$rebuilt")
[[ "$rebuilt_md5" == "$expected_md5" ]] || \
    die "rebuilt ROM mismatch: expected $expected_md5, found $rebuilt_md5"

note "Generating ahead-of-time game source..."
(cd "$game" && "$ANNEPAD_ROOT/build-host-tools/N64Recomp" game.toml)

generated="$game/generated"
[[ -f "$generated/lookup.cpp" ]] || die "AOT generation did not produce lookup.cpp"
(cd "$generated" && find . -type f -print0 | LC_ALL=C sort -z | \
    xargs -0 shasum -a 256) > "$ANNEPAD_ROOT/generated/aot-manifest.sha256"

file_count=$(find "$generated" -type f | wc -l | tr -d ' ')
manifest_hash=$(shasum -a 256 "$ANNEPAD_ROOT/generated/aot-manifest.sha256" | awk '{print $1}')
note "Matching ROM MD5: $rebuilt_md5"
note "Generated AOT files: $file_count"
note "AOT manifest SHA-256: $manifest_hash"
