#!/usr/bin/env bash

set -euo pipefail
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source "$script_dir/lib/common.sh"

require_command ditto
require_command mkdir
require_command mktemp
require_command mv
require_command plutil
require_command zip

default_app="$ANNEPAD_ROOT/build-ios-app-device-release/Release/AnnePad.app"
app="$default_app"
output="$ANNEPAD_ROOT/artifacts/AnnePad-0.1.0-unsigned.ipa"
allow_build=true
custom_app=false

while (( $# > 0 )); do
    case "$1" in
        --app)
            (( $# >= 2 )) || die "--app requires a path"
            app=$2
            custom_app=true
            shift 2
            ;;
        --output)
            (( $# >= 2 )) || die "--output requires a path"
            output=$2
            shift 2
            ;;
        --no-build)
            allow_build=false
            shift
            ;;
        *)
            die "usage: scripts/package-ios.sh [--app path] [--output path] [--no-build]"
            ;;
    esac
done

if $allow_build && ! $custom_app; then
    "$script_dir/build-ios-device.sh" release
fi

if [[ ! -d "$app" ]] || \
   [[ "$(plutil -extract AnnePadBuildProfile raw -o - "$app/Info.plist" 2>/dev/null || true)" != release ]]; then
    if $custom_app; then
        die "caller-supplied application is missing or not release-profile"
    fi
    die "release-profile AnnePad.app is missing; omit --no-build to build it"
fi

"$script_dir/audit-ios-app.sh" "$app" release

case "$output" in
    "$ANNEPAD_ROOT"/artifacts/*.ipa) ;;
    *) die "unsigned IPA output must be an explicit path under artifacts/" ;;
esac

mkdir -p "$ANNEPAD_ROOT/artifacts"
staging=$(mktemp -d "$ANNEPAD_ROOT/build-package-ios.XXXXXX")
cleanup() {
    case "$staging" in
        "$ANNEPAD_ROOT"/build-package-ios.*) rm -rf -- "$staging" ;;
    esac
}
trap cleanup EXIT

mkdir -p "$staging/Payload"
ditto "$app" "$staging/Payload/AnnePad.app"
(
    cd "$staging"
    zip -X -q -r AnnePad-unsigned.ipa Payload
)
mv -f "$staging/AnnePad-unsigned.ipa" "$output"

"$script_dir/audit-ipa.sh" "$output"
note "Packaged audited ROM-free unsigned IPA: ${output#"$ANNEPAD_ROOT/"}"
