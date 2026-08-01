#!/usr/bin/env bash

set -euo pipefail
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source "$script_dir/lib/common.sh"

require_command cmake
require_command find
require_command lipo
require_command nm
require_command otool
require_command rg

build_dir=${1:-"$ANNEPAD_ROOT/build-ios-core-simulator"}
platform=${2:-simulator}
profile=${3:-validation}
case "$platform" in
    simulator)
        expected_macho_platform=7
        platform_name='iOS Simulator'
        ;;
    device)
        expected_macho_platform=2
        platform_name='iOS device'
        ;;
    *)
        die "usage: scripts/audit-ios-core.sh [build-directory] [simulator|device]"
        ;;
esac
case "$profile" in
    validation) expected_shipping=OFF ;;
    release) expected_shipping=ON ;;
    *) die "usage: scripts/audit-ios-core.sh [build-directory] [simulator|device] [validation|release]" ;;
esac
cache="$build_dir/CMakeCache.txt"
[[ -f "$cache" ]] || die "iOS core build is not configured: $build_dir"
rg -q '^CMAKE_SYSTEM_NAME:UNINITIALIZED=iOS$|^CMAKE_SYSTEM_NAME:STRING=iOS$' "$cache" || \
    die "core build was not configured for iOS"
rg -q '^N64MODERN_NO_DYNAMIC_CODE:BOOL=ON$' "$cache" || \
    die "no-dynamic-code profile is not enabled"
rg -q "^ANNEPAD_SHIPPING_CORE:BOOL=$expected_shipping$" "$cache" || \
    die "unexpected AOT optimization profile for $profile build"

archives=()
while IFS= read -r archive; do
    archives+=("$archive")
done < <(find "$build_dir" -type f -name '*.a' -print | sort)
(( ${#archives[@]} > 0 )) || die "no static archives were produced"

for archive in "${archives[@]}"; do
    architectures=$(lipo -archs "$archive")
    [[ "$architectures" == "arm64" ]] || \
        die "unexpected architecture in ${archive#"$ANNEPAD_ROOT/"}: $architectures"
done

if find "$build_dir" \( -iname '*liverecomp*' -o -iname '*sljit*' \) -print | rg -q .; then
    die "dynamic-code target or artifact exists in the strict iOS build"
fi
if rg -i -q 'LiveRecomp|sljitLir' "$build_dir/build.ninja"; then
    die "dynamic-code source or target leaked into the strict iOS build graph"
fi

undefined_symbols=$(nm -u "${archives[@]}" 2>/dev/null || true)
forbidden_symbols='(^|[[:space:]_])(dlopen|dlclose|dlsym|pthread_jit_write_protect_np|sys_icache_invalidate)([[:space:]]|$)'
if printf '%s\n' "$undefined_symbols" | rg -i "$forbidden_symbols"; then
    die "forbidden dynamic-code or dynamic-loading symbol found"
fi

required=(
    "$build_dir/libAnnePadCore.a"
    "$build_dir/libAnnePadRecompiledCore.a"
    "$build_dir/runtime/librecomp/liblibrecomp.a"
    "$build_dir/runtime/ultramodern/libultramodern.a"
)
for archive in "${required[@]}"; do
    [[ -f "$archive" ]] || die "required core archive is missing: ${archive#"$ANNEPAD_ROOT/"}"
    platforms=$(otool -l "$archive" 2>/dev/null | awk '/^[[:space:]]+platform / { print $2 }' | sort -u)
    [[ "$platforms" == "$expected_macho_platform" ]] || \
        die "archive is not exclusively built for $platform_name: ${archive#"$ANNEPAD_ROOT/"}"
done

for archive in "${required[@]}"; do
    printf '%s  %s\n' "$(shasum -a 256 "$archive" | awk '{print $1}')" \
        "${archive#"$ANNEPAD_ROOT/"}"
done
note "$platform_name arm64 $profile static core passed the no-dynamic-code archive audit."
