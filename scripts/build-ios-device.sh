#!/usr/bin/env bash

set -euo pipefail
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source "$script_dir/lib/common.sh"

require_command cmake
require_command find
require_command rg
require_command xcrun

profile=${1:-validation}
signing=${2:-unsigned}
case "$profile" in
    validation) build_suffix= ;;
    release) build_suffix=-release ;;
    *) die "usage: scripts/build-ios-device.sh [validation|release]" ;;
esac
case "$signing" in
    unsigned)
        signing_suffix=
        # Keep the normal hash-derived LC_UUID: launchers such as LiveContainer
        # require it. -reproducible makes the rest of the link insensitive to
        # incidental input metadata without suppressing that load command.
        linker_flags=-Wl,-reproducible
        ;;
    signed)
        [[ "$profile" == release ]] || die "signed builds require the release profile"
        [[ -n "${DEVELOPMENT_TEAM:-}" ]] || die "signed builds require DEVELOPMENT_TEAM in the local environment"
        signing_suffix=-signed
        linker_flags=
        ;;
    *) die "usage: scripts/build-ios-device.sh [validation|release] [unsigned|signed]" ;;
esac

core_build="$ANNEPAD_ROOT/build-ios-core-device$build_suffix"
core_archive="$core_build/libAnnePadRecompiledCore.a"
deps_prefix="$ANNEPAD_ROOT/build-ios-dependencies/device/sdl2"
build_dir="$ANNEPAD_ROOT/build-ios-app-device$build_suffix$signing_suffix"
game="$ANNEPAD_SOURCES/PokemonStadiumRecomp"
renderer="$ANNEPAD_SOURCES/rt64"

# Always run the incremental core build. Generated AOT sources can change while
# an older archive remains present; auditing that stale archive is not enough.
"$script_dir/build-ios-core.sh" device "$profile"
"$script_dir/build-ios-dependencies.sh" device
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
    -DCMAKE_OSX_SYSROOT=iphoneos \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0 \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_C_FLAGS="-ffile-prefix-map=$ANNEPAD_ROOT=." \
    -DCMAKE_CXX_FLAGS="-ffile-prefix-map=$ANNEPAD_ROOT=." \
    -DCMAKE_EXE_LINKER_FLAGS="$linker_flags" \
    -DCMAKE_PREFIX_PATH="$deps_prefix" \
    -DSDL2_DIR="$deps_prefix/lib/cmake/SDL2" \
    -DANNEPAD_IOS_DIR="$ANNEPAD_ROOT/apple/app" \
    -DANNEPAD_RECOMPILED_ARCHIVE="$core_archive" \
    -DDXC_PATH="$dxc" \
    -DSPIRV_CROSS_MSL_PATH="$spirv_cross_msl" \
    -DFILE_TO_C_PATH="$file_to_c" \
    -DANNEPAD_BUILD_PROFILE="$profile" \
    -DDEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-}"

# Xcode's incremental build can preserve resources removed from the project.
# Recreate only the known app product so bundle audits cannot be fooled by stale
# desktop launcher content.
candidate_app="$build_dir/Release/AnnePad.app"
if [[ -d "$candidate_app" ]]; then
    cmake -E remove_directory "$candidate_app"
fi

if [[ "$signing" == signed ]]; then
    cmake --build "$build_dir" --config Release --target PokemonStadiumRecomp -- \
        -destination 'generic/platform=iOS' \
        CODE_SIGNING_ALLOWED=YES CODE_SIGNING_REQUIRED=YES \
        DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM"
else
    cmake --build "$build_dir" --config Release --target PokemonStadiumRecomp -- \
        -destination 'generic/platform=iOS' \
        CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
fi

app=$(find "$build_dir" -type d -name AnnePad.app -path '*Release*' -print -quit)
[[ -n "$app" ]] || die "AnnePad.app was not produced"
if find "$app" -type f \( -iname '*.z64' -o -iname '*.n64' -o -iname '*.v64' -o -iname '*.rom' \) -print | rg -q .; then
    die "ROM material leaked into the iOS device application bundle"
fi

"$script_dir/audit-ios-app.sh" "$app" "$profile" "$signing"
note "Built ROM-free $signing iOS device app: ${app#"$ANNEPAD_ROOT/"}"
