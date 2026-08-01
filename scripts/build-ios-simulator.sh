#!/usr/bin/env bash

set -euo pipefail
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source "$script_dir/lib/common.sh"

require_command cmake
require_command find
require_command rg
require_command xcrun

core_build="$ANNEPAD_ROOT/build-ios-core-simulator"
core_archive="$core_build/libAnnePadRecompiledCore.a"
deps_prefix="$ANNEPAD_ROOT/build-ios-dependencies/simulator/sdl2"
build_dir="$ANNEPAD_ROOT/build-ios-app-simulator"
game="$ANNEPAD_SOURCES/PokemonStadiumRecomp"
renderer="$ANNEPAD_SOURCES/rt64"

if [[ ! -f "$core_archive" ]]; then
    "$script_dir/build-ios-core.sh" simulator
else
    "$script_dir/audit-ios-core.sh" "$core_build" simulator
fi
"$script_dir/build-ios-dependencies.sh" simulator
"$script_dir/apply-patches.sh"
"$script_dir/verify-sources.sh"

file_to_c="$ANNEPAD_ROOT/build-macos/file_to_c"
spirv_cross_msl="$game/build/bin/spirv_cross_msl"
dxc="$renderer/src/contrib/dxc/bin/arm64/dxc-macos"
for host_tool in "$file_to_c" "$spirv_cross_msl" "$dxc"; do
    [[ -x "$host_tool" ]] || die "missing host tool: ${host_tool#"$ANNEPAD_ROOT/"}"
done

cmake -S "$game" -B "$build_dir" -G Xcode \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT=iphonesimulator \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0 \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_PREFIX_PATH="$deps_prefix" \
    -DSDL2_DIR="$deps_prefix/lib/cmake/SDL2" \
    -DANNEPAD_IOS_DIR="$ANNEPAD_ROOT/apple/app" \
    -DANNEPAD_RECOMPILED_ARCHIVE="$core_archive" \
    -DDXC_PATH="$dxc" \
    -DSPIRV_CROSS_MSL_PATH="$spirv_cross_msl" \
    -DFILE_TO_C_PATH="$file_to_c" \
    -DDEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-}"

cmake --build "$build_dir" --config Release --target PokemonStadiumRecomp -- \
    -destination 'generic/platform=iOS Simulator' \
    CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO

app=$(find "$build_dir" -type d -name AnnePad.app -path '*Release*' -print -quit)
[[ -n "$app" ]] || die "AnnePad.app was not produced"
if find "$app" -type f \( -iname '*.z64' -o -iname '*.n64' -o -iname '*.v64' -o -iname '*.rom' \) -print | rg -q .; then
    die "ROM material leaked into the iOS application bundle"
fi

note "Built ROM-free iOS Simulator app: ${app#"$ANNEPAD_ROOT/"}"
