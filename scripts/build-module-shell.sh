#!/usr/bin/env bash
# Build AnnePad's game-free iOS shell: the app, runtime and renderer without the
# generated game code. PadMint inserts a matching private AnnePadGame.dylib later.
# The shell patch is applied to the pinned game checkout only for this build.
set -euo pipefail
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source "$script_dir/lib/common.sh"

require_command cmake
require_command ninja
require_command xcrun
output=${1:-$ANNEPAD_ROOT/build-ios-module-shell/AnnePad-shell.ipa}
case "$output" in *.ipa) ;; *) die "usage: scripts/build-module-shell.sh [output.ipa]" ;; esac

"$script_dir/apply-patches.sh"
"$script_dir/verify-sources.sh"
game="$ANNEPAD_SOURCES/PokemonStadiumRecomp"
renderer="$ANNEPAD_SOURCES/rt64"
deps="$ANNEPAD_ROOT/build-ios-dependencies/device/sdl2"
work="$ANNEPAD_ROOT/build-ios-module-shell"
"$script_dir/build-ios-dependencies.sh" device

# rt64 needs its host file_to_c tool; build only that tool instead of the macOS app.
file_to_c="$work/file_to_c/file_to_c"
if [[ ! -x "$file_to_c" ]]; then
    cmake -S "$renderer/src/tools/file_to_c" -B "$work/file_to_c" -G Ninja -DCMAKE_BUILD_TYPE=Release
    cmake --build "$work/file_to_c"
fi
spirv_cross_msl="$game/build/bin/spirv_cross_msl"
dxc="$renderer/src/contrib/dxc/bin/arm64/dxc-macos"
for host_tool in "$spirv_cross_msl" "$dxc"; do
    [[ -x "$host_tool" ]] || die "missing host tool: ${host_tool#"$ANNEPAD_ROOT/"}"
done

patch="$ANNEPAD_ROOT/patches/pokemon-stadium-recomp/private-module-shell.patch"
git -C "$game" apply "$patch"
trap 'git -C "$game" apply -R "$patch"' EXIT
build="$work/xcode"
cmake -S "$game" -B "$build" -G Xcode \
    -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT=iphoneos -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0 \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_C_FLAGS="-ffile-prefix-map=$ANNEPAD_ROOT=." -DCMAKE_CXX_FLAGS="-ffile-prefix-map=$ANNEPAD_ROOT=." \
    -DCMAKE_EXE_LINKER_FLAGS=-Wl,-reproducible \
    -DCMAKE_PREFIX_PATH="$deps" -DSDL2_DIR="$deps/lib/cmake/SDL2" \
    -DANNEPAD_IOS_DIR="$ANNEPAD_ROOT/apple/app" -DANNEPAD_MODULE_SHELL=ON \
    -DDXC_PATH="$dxc" -DSPIRV_CROSS_MSL_PATH="$spirv_cross_msl" -DFILE_TO_C_PATH="$file_to_c" \
    -DANNEPAD_BUILD_PROFILE=release -DANNEPAD_VERSION="$ANNEPAD_VERSION" -DANNEPAD_BUILD="$ANNEPAD_BUILD"
app="$build/Release/AnnePad.app"
[[ ! -d "$app" ]] || cmake -E remove_directory "$app"
cmake --build "$build" --config Release --target PokemonStadiumRecomp -- \
    -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO -quiet
[[ -d "$app" ]] || die "AnnePad.app was not produced"
if find "$app" -type f \( -iname '*.z64' -o -iname '*.n64' -o -iname '*.v64' -o -iname '*.rom' \) -print | grep -q .; then
    die "ROM material leaked into the shell"
fi
if nm -j "$app/AnnePad" | grep -q '^_func_8'; then
    die "generated game code leaked into the shell"
fi
python3 "$script_dir/package-module-shell.py" "$app" "$output"
note "Built game-free iOS shell: $output"
