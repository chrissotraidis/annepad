#!/usr/bin/env bash

set -euo pipefail
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source "$script_dir/lib/common.sh"

require_command codesign
require_command xcrun

device=
app="$ANNEPAD_ROOT/build-ios-app-device-release-signed/Release/AnnePad.app"
while (( $# > 0 )); do
    case "$1" in
        --device)
            (( $# >= 2 )) || die "--device requires an attached-device identifier or name"
            device=$2
            shift 2
            ;;
        --app)
            (( $# >= 2 )) || die "--app requires a signed AnnePad.app path"
            app=$2
            shift 2
            ;;
        *)
            die "usage: scripts/install-ios-device.sh --device identifier [--app signed-app]"
            ;;
    esac
done

[[ -n "$device" ]] || die "--device is required"
[[ -d "$app" ]] || die "signed app not found: $app"
"$script_dir/audit-ios-app.sh" "$app" release signed

xcrun devicectl device install app --device "$device" "$app"
xcrun devicectl device process launch --device "$device" \
    --terminate-existing com.chrissotraidis.annepad
note "Installed and launched AnnePad on the requested attached device."
