#!/usr/bin/env bash

set -euo pipefail
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source "$script_dir/lib/common.sh"

require_command codesign
require_command file
require_command find
require_command lipo
require_command nm
require_command otool
require_command plutil
require_command rg
require_command xcrun

app=${1:-}
expected_profile=${2:-release}
expected_signing=${3:-unsigned}
[[ -n "$app" ]] || die "usage: scripts/audit-ios-app.sh /path/to/AnnePad.app [validation|release] [unsigned|signed]"
[[ -d "$app" ]] || die "iOS application bundle not found: $app"
case "$expected_profile" in
    validation|release) ;;
    *) die "expected profile must be validation or release" ;;
esac
case "$expected_signing" in
    unsigned|signed) ;;
    *) die "expected signing state must be unsigned or signed" ;;
esac

info="$app/Info.plist"
privacy="$app/PrivacyInfo.xcprivacy"
notices="$app/ThirdPartyNotices.txt"
[[ -f "$info" ]] || die "Info.plist is missing"
[[ -f "$privacy" ]] || die "PrivacyInfo.xcprivacy is missing"
[[ -s "$notices" ]] || die "third-party notices are missing"
plutil -lint "$info" "$privacy" >/dev/null

plist_value() {
    plutil -extract "$1" raw -o - "$info"
}

[[ "$(plist_value CFBundleIdentifier)" == com.chrissotraidis.annepad ]] || \
    die "unexpected bundle identifier"
[[ "$(plist_value CFBundleShortVersionString)" == 0.1.0 ]] || die "unexpected app version"
[[ "$(plist_value CFBundleVersion)" == 1 ]] || die "unexpected build number"
[[ "$(plist_value MinimumOSVersion)" == 16.0 ]] || die "unexpected minimum iOS version"
[[ "$(plist_value AnnePadBuildProfile)" == "$expected_profile" ]] || \
    die "app build profile is not $expected_profile"
[[ "$(plist_value ITSAppUsesNonExemptEncryption)" == false ]] || \
    die "export-compliance declaration is missing"

executable_name=$(plist_value CFBundleExecutable)
binary="$app/$executable_name"
[[ -f "$binary" ]] || die "application executable is missing"
[[ "$(lipo -archs "$binary")" == arm64 ]] || die "device executable is not arm64-only"
file "$binary" | rg -q 'Mach-O 64-bit executable arm64' || die "unexpected executable format"
xcrun vtool -show-build "$binary" | rg -q 'platform IOS$' || \
    die "executable does not target physical iOS"
if xcrun vtool -show-build "$binary" | rg -q 'IOSSIMULATOR'; then
    die "Simulator platform leaked into device executable"
fi

dependencies=$(otool -L "$binary" | tail -n +2 | awk '{print $1}')
[[ -n "$dependencies" ]] || die "executable dependency list is empty"
if printf '%s\n' "$dependencies" | rg -v '^(/System/Library/Frameworks/|/usr/lib/)'; then
    die "non-system dynamic dependency found"
fi
for framework in Foundation UIKit Metal QuartzCore; do
    printf '%s\n' "$dependencies" | rg -q "/${framework}\.framework/" || \
        die "required system framework is missing: $framework"
done

undefined_symbols=$(nm -u "$binary" 2>/dev/null || true)
forbidden_symbols='pthread_jit_write_protect_np|sys_icache_invalidate|sljit_|tcc_(compile|relocate|run)|libretro|retro_load_game'
if printf '%s\n' "$undefined_symbols" | rg -i "$forbidden_symbols"; then
    die "forbidden JIT, runtime compiler, or emulator ABI symbol found"
fi
if rg -i -q 'LiveRecomp|MAP_JIT|libretro_(api|core)|TinyCC' < <(strings -a "$binary"); then
    die "forbidden dynamic-code or emulator marker found"
fi
release_diagnostic_markers='RECOMP_AUDIO_(DEBUG|SYNTH)|\[audio-debug\]|TCP diagnostics|PSR_(ASPMAIN_(REPLAY|CAPTURE|SPIKE_DIR|DEBUG)|AUDIO_(BRIDGE|LEAD_MS|MAX_CORR|NO_DECIMATE|TARGET_MS)|AI_SMOOTH|DISABLE_AUDIO_(PCM|QUEUE)_RING|DEBUG_PORT|TURBO|AUTOBOOT)|debug server started|aspmain_(replay|capture)|spike-capture|ares_worker'
if [[ "$expected_profile" == release ]] &&
   rg -i -q "$release_diagnostic_markers" < <(strings -a "$binary"); then
    die "validation-only diagnostics leaked into release executable"
fi
defined_symbols=$(nm -gU "$binary" 2>/dev/null || true)
if [[ "$expected_profile" == release ]] &&
   rg -q 'recomp_ultra_trace_record|scheduler_trace_mark' <<<"$defined_symbols"; then
    die "validation-only runtime tracing leaked into release executable"
fi
if rg -q '/Users/|/home/|[A-Za-z]:\\Users\\' < <(strings -a "$binary"); then
    die "absolute developer-machine path leaked into executable"
fi

if [[ "$expected_signing" == signed ]]; then
    codesign --verify --deep --strict "$app" || die "signed candidate failed code-signature verification"
    [[ -e "$app/_CodeSignature" ]] || die "signed candidate has no code-signature directory"
else
    if codesign -d "$app" >/dev/null 2>&1; then
        die "unsigned candidate unexpectedly contains a code signature"
    fi
    [[ ! -e "$app/embedded.mobileprovision" ]] || die "provisioning profile leaked into bundle"
    [[ ! -e "$app/_CodeSignature" ]] || die "code-signature directory leaked into bundle"
fi
[[ ! -e "$app/assets" ]] || die "desktop launcher assets leaked into native iOS bundle"
[[ -f "$app/Assets.car" ]] || die "compiled asset catalog is missing"
find "$app" -type l -print | rg -q . && die "symbolic link found in application bundle"

forbidden_files=$(find "$app" -type f | rg -i '\.(n64|v64|z64|rom|sav|sra|eep|fla|gb|gbc|mobileprovision|p12|cer)$' || true)
[[ -z "$forbidden_files" ]] || die "forbidden private material found in bundle"
if find "$app" -type f | rg -i '(^|/)(boxart|carts)(/|\.)'; then
    die "game or desktop launcher artwork found in bundle"
fi

privacy_dump=$(plutil -p "$privacy")
for required_privacy_value in \
    NSPrivacyAccessedAPICategoryFileTimestamp C617.1 3B52.1 \
    NSPrivacyAccessedAPICategoryUserDefaults CA92.1 \
    NSPrivacyAccessedAPICategorySystemBootTime 35F9.1; do
    printf '%s\n' "$privacy_dump" | rg -q "$required_privacy_value" || \
        die "privacy manifest is missing $required_privacy_value"
done
printf '%s\n' "$privacy_dump" | rg -q '"NSPrivacyTracking" => false' || \
    die "privacy manifest tracking declaration is not false"

uuid=$(xcrun dwarfdump --uuid "$binary" | awk '{print $2}')
if [[ "$expected_signing" == signed ]]; then
    [[ -n "$uuid" ]] || die "signed candidate is missing its Mach-O UUID"
else
    [[ -z "$uuid" ]] || die "unsigned candidate contains a nondeterministic Mach-O UUID"
    uuid=absent
fi
binary_sha=$(shasum -a 256 "$binary" | awk '{print $1}')
binary_size=$(stat -f '%z' "$binary")
note "AnnePad iOS app audit passed."
note "profile=$expected_profile"
note "platform=iOS architecture=arm64 minimum_os=16.0"
note "bundle_id=com.chrissotraidis.annepad version=0.1.0 build=1"
note "binary_size=$binary_size binary_sha256=$binary_sha uuid=$uuid"
if [[ "$expected_signing" == signed ]]; then
    note "dynamic_dependencies=Apple-system-only signature=valid"
else
    note "dynamic_dependencies=Apple-system-only signature=absent provisioning=absent"
fi
note "privacy_manifest=valid app_icon=present prohibited_assets=absent rom_material=absent"
