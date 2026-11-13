#!/usr/bin/env bash

set -euo pipefail
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source "$script_dir/lib/common.sh"

require_command cmake
require_command xcrun

build_dir="$ANNEPAD_ROOT/build-tests/touch-visibility"
cmake -E make_directory "$build_dir"
xcrun --sdk macosx clang++ -std=c++20 -Wall -Wextra -Werror \
    -I"$ANNEPAD_ROOT/apple/app" \
    "$ANNEPAD_ROOT/tests/touch_visibility_test.cpp" \
    -o "$build_dir/touch_visibility_test"
"$build_dir/touch_visibility_test"

note "Touch visibility policy tests passed."
