#!/usr/bin/env bash

set -euo pipefail
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source "$script_dir/lib/common.sh"

"$script_dir/apply-patches.sh"
"$script_dir/verify-sources.sh"
require_command cmake
require_command ninja

source_dir="$ANNEPAD_SOURCES/N64Recomp-generator"
build_dir="$ANNEPAD_ROOT/build-host-tools"

cmake -S "$source_dir" -B "$build_dir" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DWITH_ARES_BRIDGE=OFF \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_CXX_FLAGS=-DFMT_USE_CONSTEVAL=0
build_jobs=$(configured_build_jobs)
if [[ -n "$build_jobs" ]]; then
    cmake --build "$build_dir" --target N64RecompCLI RSPRecomp --parallel "$build_jobs"
else
    cmake --build "$build_dir" --target N64RecompCLI RSPRecomp --parallel
fi

for tool in "$build_dir/N64Recomp" "$build_dir/RSPRecomp"; do
    [[ -x "$tool" ]] || die "host tool was not produced: $tool"
    architectures=$(lipo -archs "$tool")
    [[ "$architectures" == "arm64" ]] || die "unexpected host tool architectures for $tool: $architectures"
    printf '%s  %s\n' "$(shasum -a 256 "$tool" | awk '{print $1}')" "${tool#"$ANNEPAD_ROOT/"}"
done

note "Native arm64 host tools passed."
