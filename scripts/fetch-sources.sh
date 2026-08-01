#!/usr/bin/env bash

set -euo pipefail
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source "$script_dir/lib/common.sh"

require_command git
require_command jq
mkdir -p "$ANNEPAD_SOURCES"

game="$ANNEPAD_SOURCES/PokemonStadiumRecomp"
runtime="$ANNEPAD_SOURCES/N64ModernRuntime"
renderer="$ANNEPAD_SOURCES/rt64"
generator="$ANNEPAD_SOURCES/N64Recomp-generator"

fetch_detached pokemonStadiumRecomp "$game" PokemonStadiumRecomp
fetch_detached n64ModernRuntime "$runtime" N64ModernRuntime
fetch_detached rt64 "$renderer" rt64
fetch_detached n64RecompGenerator "$generator" N64Recomp-generator

git -C "$game" submodule sync -- disasm recomp-ui
git -C "$game" submodule update --init --depth=1 disasm recomp-ui
git -C "$game/disasm" submodule sync -- tools/n64splat
git -C "$game/disasm" submodule update --init --depth=1 tools/n64splat

git -C "$runtime" submodule sync --recursive
git -C "$runtime" submodule update --init --depth=1 \
    N64Recomp thirdparty/miniz thirdparty/o1heap thirdparty/xxHash

required_n64recomp_submodules=(lib/ELFIO lib/fmt lib/rabbitizer lib/sljit lib/tomlplusplus)
git -C "$runtime/N64Recomp" submodule sync -- "${required_n64recomp_submodules[@]}"
git -C "$runtime/N64Recomp" submodule update --init --depth=1 "${required_n64recomp_submodules[@]}"
git -C "$generator" submodule sync -- "${required_n64recomp_submodules[@]}"
git -C "$generator" submodule update --init --depth=1 "${required_n64recomp_submodules[@]}"

# RT64 owns a large but pinned recursive dependency graph. Avoid a second mutable
# manifest: gitlinks under the locked parent commit are the exact source of truth.
git -C "$renderer" submodule sync --recursive
git -C "$renderer" submodule update --init --recursive --depth=1

mkdir -p "$game/lib"
ln -sfn ../../N64ModernRuntime "$game/lib/N64ModernRuntime"
ln -sfn ../../rt64 "$game/lib/rt64"
ln -sfn ../../N64ModernRuntime/thirdparty/concurrentqueue "$game/lib/concurrentqueue"
ln -sfn ../N64Recomp-generator "$game/n64recomp"

disable_push "$game"
git -C "$game" submodule foreach --quiet --recursive \
    'if git remote get-url origin >/dev/null 2>&1; then git remote set-url --push origin DISABLED; fi'
for checkout in "$runtime" "$renderer" "$generator"; do
    disable_push "$checkout"
    git -C "$checkout" submodule foreach --quiet --recursive \
        'if git remote get-url origin >/dev/null 2>&1; then git remote set-url --push origin DISABLED; fi'
done

"$script_dir/apply-patches.sh"
"$script_dir/verify-sources.sh"
note "Pinned sources are ready at $ANNEPAD_SOURCES"
