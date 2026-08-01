#!/usr/bin/env bash

set -euo pipefail
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source "$script_dir/lib/common.sh"

require_command cmake
require_command xcrun

build_dir="$ANNEPAD_ROOT/build-tests/touch-tap-latch"
cmake -E make_directory "$build_dir"
xcrun --sdk macosx clang++ -std=c++20 -Wall -Wextra -Werror \
    -I"$ANNEPAD_ROOT/apple/app" \
    "$ANNEPAD_ROOT/tests/touch_tap_latch_test.cpp" \
    -o "$build_dir/touch_tap_latch_test"
"$build_dir/touch_tap_latch_test"
