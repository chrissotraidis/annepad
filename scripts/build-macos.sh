#!/usr/bin/env bash

set -euo pipefail
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source "$script_dir/lib/common.sh"

require_command cmake
require_command ninja
require_command lipo

game="$ANNEPAD_SOURCES/PokemonStadiumRecomp"
build_dir="$ANNEPAD_ROOT/build-macos"
[[ -f "$game/generated/lookup.cpp" ]] || \
    die "generated game source is missing; run scripts/generate-game.sh first"

"$script_dir/apply-patches.sh"
"$script_dir/verify-sources.sh"

cmake -S "$game" -B "$build_dir" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_ARCHITECTURES=arm64
cmake --build "$build_dir" --parallel

runner="$build_dir/AnnePad.app/Contents/MacOS/AnnePad"
[[ -x "$runner" ]] || die "macOS runner was not produced: $runner"
architectures=$(lipo -archs "$runner")
[[ "$architectures" == "arm64" ]] || \
    die "unexpected macOS runner architectures: $architectures"

printf '%s  %s\n' "$(shasum -a 256 "$runner" | awk '{print $1}')" \
    "${runner#"$ANNEPAD_ROOT/"}"
note "Native arm64 macOS runner passed its build and architecture gate."
