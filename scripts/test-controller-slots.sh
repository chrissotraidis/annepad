#!/usr/bin/env bash

set -euo pipefail
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source "$script_dir/lib/common.sh"

header="$ANNEPAD_SOURCES/PokemonStadiumRecomp/src/main/controller_slots.h"
[[ -f "$header" ]] || die "controller slot helper is missing; run scripts/apply-patches.sh first"

build_dir="$ANNEPAD_ROOT/build-tests/controller-slots"
cmake -E make_directory "$build_dir"
"${CXX:-c++}" -std=c++17 -Wall -Wextra -Werror \
    -I"$(dirname "$header")" \
    "$ANNEPAD_ROOT/tests/controller_slots_test.cpp" \
    -o "$build_dir/controller_slots_test"
"$build_dir/controller_slots_test"

note "Controller stale-handle, neutral-input, slot, and foreground regression passed."
