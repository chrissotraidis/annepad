#!/usr/bin/env bash

set -euo pipefail

ANNEPAD_ROOT=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
ANNEPAD_LOCK="$ANNEPAD_ROOT/dependencies.lock.json"
# One version for the app, its release and PadMint: version.json.
ANNEPAD_VERSION=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$ANNEPAD_ROOT/version.json")
ANNEPAD_BUILD=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["build"])' "$ANNEPAD_ROOT/version.json")
ANNEPAD_SOURCES="$ANNEPAD_ROOT/external/sources"

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

note() {
    printf '%s\n' "$*"
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

configured_build_jobs() {
    local build_jobs=${ANNEPAD_BUILD_JOBS:-}
    if [[ -n "$build_jobs" ]]; then
        [[ "$build_jobs" =~ ^[1-9][0-9]*$ ]] || \
            die "ANNEPAD_BUILD_JOBS must be a positive integer"
    fi
    printf '%s\n' "$build_jobs"
}

sha256_file() {
    shasum -a 256 "$1" | awk '{print $1}'
}

canonical_tree_manifest() {
    local tree=$1
    local output=$2
    [[ -d "$tree" ]] || die "canonical manifest tree is missing: $tree"
    case "$output" in
        "$tree"/*) die "canonical manifest output must be outside its input tree" ;;
    esac

    (
        cd "$tree"
        while IFS= read -r path; do
            local_path=${path#./}
            size=$(stat -f '%z' "$path")
            digest=$(sha256_file "$path")
            printf '%s  %s  %s\n' "$digest" "$size" "$local_path"
        done < <(find . -type f -print | LC_ALL=C sort)
    ) > "$output"
}

lock_value() {
    local source_name=$1
    local field=$2
    jq -er --arg name "$source_name" --arg field "$field" \
        '.sources[$name][$field]' "$ANNEPAD_LOCK"
}

assert_revision() {
    local checkout=$1
    local expected=$2
    local label=$3
    [[ -d "$checkout/.git" || -f "$checkout/.git" ]] || die "missing checkout for $label: $checkout"
    local actual
    actual=$(git -C "$checkout" rev-parse HEAD)
    [[ "$actual" == "$expected" ]] || die "$label revision mismatch: expected $expected, found $actual"
}

disable_push() {
    local checkout=$1
    if git -C "$checkout" remote get-url origin >/dev/null 2>&1; then
        git -C "$checkout" remote set-url --push origin DISABLED
    fi
}

fetch_detached() {
    local source_name=$1
    local destination=$2
    local label=$3
    local url revision status earlier
    url=$(lock_value "$source_name" url)
    revision=$(lock_value "$source_name" commit)

    # A rerun finds this source already at the pinned commit, with AnnePad's own patches
    # applied to its files; apply-patches.sh recognizes those and verify-sources.sh checks the
    # result. Staged changes mean a checkout that never finished (an empty index), not patches.
    if [[ -d "$destination/.git" && "$(git -C "$destination" rev-parse -q --verify HEAD 2>/dev/null)" == "$revision" ]] \
        && git -C "$destination" diff --cached --quiet --ignore-submodules=dirty 2>/dev/null; then
        disable_push "$destination"
        return 0
    fi
    # Anything else in the way (a download that stopped partway, or changes at another
    # commit) is kept under a new name, never deleted, and the source is downloaded again.
    if [[ -e "$destination" ]]; then
        if [[ ! -d "$destination/.git" ]] \
            || ! status=$(git -C "$destination" status --porcelain --untracked-files=no --ignore-submodules=dirty 2>/dev/null) \
            || [[ -n "$status" ]]; then
            earlier="$destination.earlier-$(date +%Y%m%d-%H%M%S)"
            mv "$destination" "$earlier"
            note "$label was incomplete or changed, maybe from a download that stopped partway."
            note "Kept it as $earlier (nothing deleted) and downloading it again."
        fi
    fi
    if [[ ! -e "$destination" ]]; then
        git clone --filter=blob:none --no-checkout "$url" "$destination"
    fi

    git -C "$destination" fetch --depth=1 origin "$revision"
    git -C "$destination" checkout --detach "$revision"
    assert_revision "$destination" "$revision" "$label"
    disable_push "$destination"
}

verify_clean_checkout() {
    local checkout=$1
    local label=$2
    [[ -z "$(git -C "$checkout" status --porcelain --untracked-files=no --ignore-submodules=dirty)" ]] || \
        die "$label has tracked modifications: $checkout"
}
