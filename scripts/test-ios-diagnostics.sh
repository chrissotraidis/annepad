#!/usr/bin/env bash
set -euo pipefail
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source "$script_dir/lib/common.sh"
[[ $# == 1 ]] || die "usage: test-ios-diagnostics.sh BOOTED_ISOLATED_SIMULATOR_UDID"
udid=$1
[[ "$udid" =~ ^[0-9A-Fa-f-]{36}$ ]] || die "invalid Simulator UUID"
mkdir -p "$ANNEPAD_ROOT/build-tests/diagnostics"
probe="$ANNEPAD_ROOT/build-tests/diagnostics/probe"
session=$(mktemp -d "$ANNEPAD_ROOT/build-tests/diagnostics/session.XXXXXX")
xcrun --sdk iphonesimulator clang++ -x objective-c++ -std=c++20 \
    -target arm64-apple-ios16.0-simulator "$ANNEPAD_ROOT/tests/diagnostics_probe.mm" \
    -framework Foundation -framework UIKit -framework CoreGraphics -o "$probe"
set +e
xcrun simctl spawn "$udid" "$probe" "$session" crash
status=$?
set -e
[[ "$status" == 134 ]] || die "expected a real SIGABRT termination, got $status"
xcrun simctl spawn "$udid" "$probe" "$session" verify
xcrun simctl spawn "$udid" "$probe" "$session" clean
note "Diagnostic test evidence retained at $session"
