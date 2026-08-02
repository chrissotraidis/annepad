#!/usr/bin/env bash

set -euo pipefail
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source "$script_dir/lib/common.sh"

require_command git
require_command jq

jq empty "$ANNEPAD_LOCK"
for script in "$ANNEPAD_ROOT"/scripts/*.sh "$ANNEPAD_ROOT"/scripts/lib/*.sh; do
    bash -n "$script"
done
[[ "$(ANNEPAD_BUILD_JOBS=2 configured_build_jobs)" == "2" ]] || \
    die "valid ANNEPAD_BUILD_JOBS value was not preserved"
if (ANNEPAD_BUILD_JOBS=0 configured_build_jobs >/dev/null 2>&1); then
    die "zero ANNEPAD_BUILD_JOBS value was accepted"
fi
if (ANNEPAD_BUILD_JOBS=two configured_build_jobs >/dev/null 2>&1); then
    die "non-numeric ANNEPAD_BUILD_JOBS value was accepted"
fi
"$ANNEPAD_ROOT/scripts/test-touch-tap-latch.sh"

required_docs=(
    GOAL.md RESEARCH.md REPOSITORY-INVENTORY.md ARCHITECTURE.md PLAN.md
    STATUS.md BLOCKERS.md DECISIONS.md TESTING.md BUILDING.md
    LEGAL-AND-ASSET-BOUNDARIES.md PERFORMANCE-AND-COMPLETION-AUDIT.md
    RELEASE-CHECKLIST.md HISTORY.md WORKLOG.md
)
for document in "${required_docs[@]}"; do
    [[ -s "$ANNEPAD_ROOT/docs/$document" ]] || die "missing required document: docs/$document"
done

forbidden_pattern='\.(n64|v64|z64|rom|sav|sra|eep|fla|gb|gbc|ipa|mobileprovision|p12|cer|xcarchive)$'
tracked_forbidden=$(git -C "$ANNEPAD_ROOT" ls-files | rg -i "$forbidden_pattern" || true)
[[ -z "$tracked_forbidden" ]] || die "forbidden tracked file(s): $tracked_forbidden"

unexpected_nested=$(git -C "$ANNEPAD_ROOT" ls-files | rg '(^|/)\.git(/|$)' || true)
[[ -z "$unexpected_nested" ]] || die "nested git metadata is tracked: $unexpected_nested"

rom_md5=$(jq -er '.rom.md5' "$ANNEPAD_LOCK")
rom_size=$(jq -er '.rom.size' "$ANNEPAD_LOCK")
[[ "$rom_md5" == "ed1378bc12115f71209a77844965ba50" ]] || die "unexpected supported ROM digest"
[[ "$rom_size" == "33554432" ]] || die "unexpected supported ROM size"

note "Repository policy, document, JSON, shell syntax, and forbidden-file checks passed."
