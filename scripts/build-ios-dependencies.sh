#!/usr/bin/env bash

set -euo pipefail
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source "$script_dir/lib/common.sh"

require_command cmake
require_command curl
require_command shasum
require_command tar

platform=${1:-simulator}
case "$platform" in
    simulator)
        sdk=iphonesimulator
        destination='generic/platform=iOS Simulator'
        ;;
    device)
        sdk=iphoneos
        destination='generic/platform=iOS'
        ;;
    *)
        die "usage: scripts/build-ios-dependencies.sh [simulator|device]"
        ;;
esac

sdl_version=2.32.10
sdl_sha256=5f5993c530f084535c65a6879e9b26ad441169b3e25d789d83287040a9ca5165
deps_root="$ANNEPAD_ROOT/build-ios-dependencies"
download_root="$deps_root/downloads"
source_root="$deps_root/sources"
prefix_root="$deps_root/$platform"

fetch_archive() {
    url=$1
    expected_sha=$2
    archive=$3
    if [[ ! -f "$archive" ]]; then
        curl -fL --retry 3 --retry-delay 2 "$url" -o "$archive"
    fi
    actual_sha=$(shasum -a 256 "$archive" | awk '{print $1}')
    [[ "$actual_sha" == "$expected_sha" ]] || \
        die "checksum mismatch for $archive: expected $expected_sha, found $actual_sha"
}

extract_archive() {
    archive=$1
    destination_path=$2
    marker=$3
    if [[ -f "$destination_path/.annepad-source" ]] && \
       [[ "$(<"$destination_path/.annepad-source")" == "$marker" ]]; then
        return
    fi
    rm -rf -- "$destination_path"
    mkdir -p "$destination_path"
    tar -xf "$archive" -C "$destination_path" --strip-components=1
    printf '%s\n' "$marker" > "$destination_path/.annepad-source"
}

mkdir -p "$download_root" "$source_root" "$prefix_root"
sdl_archive="$download_root/SDL2-$sdl_version.tar.gz"

fetch_archive \
    "https://github.com/libsdl-org/SDL/releases/download/release-$sdl_version/SDL2-$sdl_version.tar.gz" \
    "$sdl_sha256" "$sdl_archive"
sdl_source="$source_root/SDL2-$sdl_version"
sdl_prefix="$prefix_root/sdl2"
extract_archive "$sdl_archive" "$sdl_source" "SDL2-$sdl_version"

sdl_config=static-metal-no-loadso-v1
if [[ ! -f "$sdl_prefix/lib/libSDL2.a" ]] || \
   [[ ! -f "$sdl_prefix/.annepad-config" ]] || \
   [[ "$(<"$sdl_prefix/.annepad-config")" != "$sdl_config" ]]; then
    rm -rf -- "$deps_root/build-$platform-sdl2" "$sdl_prefix"
    cmake -S "$sdl_source" -B "$deps_root/build-$platform-sdl2" -G Xcode \
        -DCMAKE_SYSTEM_NAME=iOS \
        -DCMAKE_OSX_SYSROOT="$sdk" \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0 \
        -DCMAKE_OSX_ARCHITECTURES=arm64 \
        -DCMAKE_INSTALL_PREFIX="$sdl_prefix" \
        -DSDL_SHARED=OFF \
        -DSDL_STATIC=ON \
        -DSDL_LOADSO=OFF \
        -DSDL_OPENGL=OFF \
        -DSDL_OPENGLES=OFF \
        -DSDL_VULKAN=OFF \
        -DSDL_TEST=OFF \
        -DSDL_TESTS=OFF
    cmake --build "$deps_root/build-$platform-sdl2" --config Release \
        --target install -- -destination "$destination" CODE_SIGNING_ALLOWED=NO
    printf '%s\n' "$sdl_config" > "$sdl_prefix/.annepad-config"
fi

note "Built pinned iOS dependencies for $platform under ${prefix_root#"$ANNEPAD_ROOT/"}."
