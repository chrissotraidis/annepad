#!/usr/bin/env bash

set -euo pipefail
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source "$script_dir/lib/common.sh"

require_command awk
require_command comm
require_command dscacheutil
require_command find
require_command id
require_command jq
require_command plutil
require_command rg
require_command sips
require_command sleep
require_command tr
require_command xcrun

duration=${ANNEPAD_SOAK_SECONDS:-180}
[[ "$duration" =~ ^[1-9][0-9]*$ && "$duration" -ge 30 ]] || \
    die "ANNEPAD_SOAK_SECONDS must be an integer of at least 30"

app=${ANNEPAD_SIMULATOR_APP:-}
if [[ -z "$app" ]]; then
    app=$(find "$ANNEPAD_ROOT/build-ios-app-simulator-release" \
        -type d -name AnnePad.app -path '*Release*' -print -quit 2>/dev/null || true)
fi
[[ -n "$app" && -d "$app" ]] || \
    die "Release Simulator app not found; set ANNEPAD_SIMULATOR_APP"
app=$(CDPATH= cd -- "$app" && pwd)

[[ "$#" -gt 0 ]] || die \
    "usage: scripts/soak-ios-simulators.sh SIMULATOR_UDID [SIMULATOR_UDID ...]"

bundle_id=$(plutil -extract CFBundleIdentifier raw "$app/Info.plist")
[[ -n "$bundle_id" ]] || die "application bundle identifier is missing"

run_stamp=$(date -u '+%Y%m%dT%H%M%SZ')
evidence_dir="$ANNEPAD_ROOT/logs/simulator-soak-$run_stamp"
mkdir -p "$evidence_dir"

user_name=$(id -un)
user_dir=$(dscacheutil -q user -a name "$user_name" | awk '/^dir: / {print $2; exit}')
[[ -n "$user_dir" ]] || die "could not resolve the current user directory"

wait_with_progress() {
    local seconds=$1
    local label=$2
    local elapsed=0
    while [[ "$elapsed" -lt "$seconds" ]]; do
        local remaining=$((seconds - elapsed))
        local step=5
        [[ "$remaining" -lt "$step" ]] && step=$remaining
        sleep "$step"
        elapsed=$((elapsed + step))
        if [[ "$elapsed" -eq "$seconds" || $((elapsed % 30)) -eq 0 ]]; then
            note "$label: ${elapsed}/${seconds}s"
        fi
    done
}

for udid in "$@"; do
    [[ "$udid" =~ ^[0-9A-Fa-f-]{36}$ ]] || die "invalid Simulator UDID: $udid"
    device_name=$(xcrun simctl list devices -j | jq -er \
        --arg udid "$udid" '.devices[][] | select(.udid == $udid) | .name' | head -1)
    safe_name=$(printf '%s' "$device_name" | tr -cs 'A-Za-z0-9._-' '_')
    device_evidence="$evidence_dir/$safe_name"
    mkdir -p "$device_evidence"

    crash_dir="$user_dir/Library/Developer/CoreSimulator/Devices/$udid/data/Library/Logs/CrashReporter"
    before_crashes="$device_evidence/crashes-before.txt"
    after_crashes="$device_evidence/crashes-after.txt"
    new_crashes="$device_evidence/crashes-new.txt"
    if [[ -d "$crash_dir" ]]; then
        find "$crash_dir" -type f -name '*AnnePad*' -print | LC_ALL=C sort > "$before_crashes"
    else
        : > "$before_crashes"
    fi

    note "Soaking $device_name ($udid) for ${duration}s."
    xcrun simctl boot "$udid" >/dev/null 2>&1 || true
    xcrun simctl bootstatus "$udid" -b
    xcrun simctl install "$udid" "$app"
    xcrun simctl launch --terminate-running-process "$udid" "$bundle_id" \
        > "$device_evidence/launch-initial.txt"

    first_phase=$((duration / 2))
    second_phase=$((duration - first_phase))
    wait_with_progress "$first_phase" "$device_name foreground"

    xcrun simctl launch "$udid" com.apple.Preferences \
        > "$device_evidence/launch-settings.txt"
    wait_with_progress 5 "$device_name background"
    xcrun simctl launch "$udid" "$bundle_id" \
        > "$device_evidence/launch-restored.txt"
    wait_with_progress "$second_phase" "$device_name restored"

    final_png="$device_evidence/final.png"
    landscape_png="$device_evidence/final-landscape.png"
    xcrun simctl io "$udid" screenshot "$final_png" >/dev/null
    cp "$final_png" "$landscape_png"
    pixel_width=$(sips -g pixelWidth "$final_png" | awk '/pixelWidth:/ {print $2}')
    pixel_height=$(sips -g pixelHeight "$final_png" | awk '/pixelHeight:/ {print $2}')
    if [[ "$pixel_height" -gt "$pixel_width" ]]; then
        # simctl stores landscape-only app frames in portrait device coordinates.
        # Keep the raw capture and add a human-readable evidence copy.
        sips -r -90 "$landscape_png" >/dev/null
    fi
    xcrun simctl spawn "$udid" log show --style compact \
        --last "$((duration + 90))s" --predicate 'process == "AnnePad"' \
        > "$device_evidence/AnnePad.log" 2>&1 || true

    if [[ -d "$crash_dir" ]]; then
        find "$crash_dir" -type f -name '*AnnePad*' -print | LC_ALL=C sort > "$after_crashes"
    else
        : > "$after_crashes"
    fi
    comm -13 "$before_crashes" "$after_crashes" > "$new_crashes"
    [[ ! -s "$new_crashes" ]] || \
        die "$device_name produced a new AnnePad crash report; see $new_crashes"

    # Relaunching an already foregrounded app returns its existing PID. Requiring
    # the PID to stay fixed catches a silent exit that produced no crash report.
    xcrun simctl launch "$udid" "$bundle_id" > "$device_evidence/launch-final.txt"
    restored_pid=$(awk -F': ' 'NR == 1 {print $2}' "$device_evidence/launch-restored.txt")
    final_pid=$(awk -F': ' 'NR == 1 {print $2}' "$device_evidence/launch-final.txt")
    [[ "$restored_pid" =~ ^[0-9]+$ && "$final_pid" == "$restored_pid" ]] || \
        die "$device_name did not remain resident through the restored soak phase"
    note "$device_name passed foreground, background/restore, crash, and final-launch gates."
done

note "Simulator soak passed. Evidence: ${evidence_dir#"$ANNEPAD_ROOT/"}"
