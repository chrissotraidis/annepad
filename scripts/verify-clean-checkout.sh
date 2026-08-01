#!/usr/bin/env bash

set -euo pipefail
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source "$script_dir/lib/common.sh"

require_command git
require_command mkdir
require_command mktemp
require_command cmp
require_command diff

rom=
expected_manifest=
while (( $# > 0 )); do
    case "$1" in
        --rom)
            (( $# >= 2 )) || die "--rom requires an absolute path"
            rom=$2
            shift 2
            ;;
        --expected-manifest)
            (( $# >= 2 )) || die "--expected-manifest requires an absolute path"
            expected_manifest=$2
            shift 2
            ;;
        *)
            die "usage: scripts/verify-clean-checkout.sh --rom /absolute/path/to/user-rom --expected-manifest /absolute/path/to/manifest.sha256"
            ;;
    esac
done

[[ "$rom" == /* ]] || die "--rom must be an absolute path"
[[ -f "$rom" ]] || die "ROM input does not exist"
[[ "$expected_manifest" == /* ]] || die "--expected-manifest must be an absolute path"
[[ -f "$expected_manifest" ]] || die "expected manifest does not exist"
git -C "$ANNEPAD_ROOT" rev-parse --verify HEAD >/dev/null 2>&1 || \
    die "clean-checkout verification requires a committed AnnePad HEAD"
[[ -z "$(git -C "$ANNEPAD_ROOT" status --porcelain --untracked-files=all)" ]] || \
    die "clean-checkout verification requires a clean AnnePad worktree"

verification_root=$(mktemp -d "$ANNEPAD_ROOT/build-clean-checkout.XXXXXX")
cleanup() {
    case "$verification_root" in
        "$ANNEPAD_ROOT"/build-clean-checkout.*) rm -rf -- "$verification_root" ;;
    esac
}
trap cleanup EXIT

checkout="$verification_root/checkout"
git clone --quiet --no-hardlinks --local "$ANNEPAD_ROOT" "$checkout"
git -C "$checkout" checkout --quiet --detach HEAD

(
    cd "$checkout"
    ./scripts/test-repository.sh
    ./scripts/check-prerequisites.sh
    ./scripts/fetch-sources.sh
    ./scripts/verify-sources.sh
    ./scripts/prepare-game.sh --rom "$rom"
    ./scripts/build-host-tools.sh
    ./scripts/generate-game.sh --rom "$rom"
    ./scripts/build-macos.sh
    ./scripts/build-ios-core.sh simulator
    ./scripts/build-ios-dependencies.sh simulator
    # The isolated gate proves Simulator SDK/static compatibility with the fast
    # validation core. Interactive playtesting uses the release default.
    ./scripts/build-ios-simulator.sh validation
    ./scripts/package-ios.sh
    ./scripts/test-repository.sh
    [[ -z "$(git status --porcelain --untracked-files=all)" ]] || {
        git status --short
        exit 1
    }
)

actual_manifest="$checkout/artifacts/AnnePad-0.1.0-unsigned.manifest.sha256"
if ! cmp -s "$expected_manifest" "$actual_manifest"; then
    diff -u "$expected_manifest" "$actual_manifest" || true
    die "clean-checkout canonical manifest does not match the expected candidate"
fi

mkdir -p "$ANNEPAD_ROOT/logs/clean-checkout-latest"
cp "$checkout/artifacts/AnnePad-0.1.0-unsigned.audit.txt" \
    "$ANNEPAD_ROOT/logs/clean-checkout-latest/"
cp "$checkout/artifacts/AnnePad-0.1.0-unsigned.manifest.sha256" \
    "$ANNEPAD_ROOT/logs/clean-checkout-latest/"

head_sha=$(git -C "$checkout" rev-parse HEAD)
lock_sha=$(sha256_file "$checkout/dependencies.lock.json")
note "Clean-checkout build and package verification passed."
note "annepad_head=$head_sha"
note "dependency_lock_sha256=$lock_sha"
note "evidence=logs/clean-checkout-latest"
