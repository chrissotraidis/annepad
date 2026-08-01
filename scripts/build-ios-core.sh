#!/usr/bin/env bash

set -euo pipefail
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source "$script_dir/lib/common.sh"

require_command cmake
require_command ninja
require_command xcrun

platform=${1:-simulator}
profile=${2:-validation}
case "$platform" in
    simulator)
        sdk=iphonesimulator
        ;;
    device)
        sdk=iphoneos
        ;;
    *)
        die "usage: scripts/build-ios-core.sh [simulator|device]"
        ;;
esac

case "$profile" in
    validation)
        shipping_core=OFF
        build_suffix=
        ;;
    release)
        shipping_core=ON
        build_suffix=-release
        ;;
    *)
        die "usage: scripts/build-ios-core.sh [simulator|device] [validation|release]"
        ;;
esac

build_dir="$ANNEPAD_ROOT/build-ios-core-$platform$build_suffix"
sdk_path=$(xcrun --sdk "$sdk" --show-sdk-path)

[[ -f "$ANNEPAD_SOURCES/PokemonStadiumRecomp/generated/lookup.cpp" ]] || \
    die "generated game source is missing; run scripts/generate-game.sh first"

"$script_dir/apply-patches.sh"
"$script_dir/verify-sources.sh"

cmake -S "$ANNEPAD_ROOT/apple/core" -B "$build_dir" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT="$sdk_path" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0 \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DANNEPAD_SHIPPING_CORE="$shipping_core" \
    -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO \
    -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED=NO

build_jobs=${ANNEPAD_BUILD_JOBS:-}
if [[ -n "$build_jobs" ]]; then
    [[ "$build_jobs" =~ ^[1-9][0-9]*$ ]] || \
        die "ANNEPAD_BUILD_JOBS must be a positive integer"
    cmake --build "$build_dir" --target AnnePadCore --parallel "$build_jobs"
else
    cmake --build "$build_dir" --target AnnePadCore --parallel
fi
"$script_dir/audit-ios-core.sh" "$build_dir" "$platform" "$profile"
