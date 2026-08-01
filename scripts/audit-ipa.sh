#!/usr/bin/env bash

set -euo pipefail
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source "$script_dir/lib/common.sh"

require_command find
require_command mkdir
require_command mktemp
require_command mv
require_command rg
require_command unzip
require_command zipinfo

ipa=${1:-}
[[ -n "$ipa" ]] || die "usage: scripts/audit-ipa.sh /path/to/AnnePad-unsigned.ipa"
[[ -f "$ipa" ]] || die "IPA not found: $ipa"
case "$ipa" in
    "$ANNEPAD_ROOT"/artifacts/*.ipa) ;;
    *) die "IPA audit input must be an explicit path under artifacts/" ;;
esac

archive_listing=$(zipinfo -1 "$ipa")
[[ -n "$archive_listing" ]] || die "IPA archive is empty"
if printf '%s\n' "$archive_listing" | rg -q '(^/|(^|/)\.\.(/|$)|\\)'; then
    die "unsafe IPA archive path found"
fi
if printf '%s\n' "$archive_listing" | rg -v '^Payload/$|^Payload/AnnePad\.app/$|^Payload/AnnePad\.app/.+'; then
    die "unexpected IPA archive path found"
fi

staging=$(mktemp -d "$ANNEPAD_ROOT/build-audit-ipa.XXXXXX")
cleanup() {
    case "$staging" in
        "$ANNEPAD_ROOT"/build-audit-ipa.*) rm -rf -- "$staging" ;;
    esac
}
trap cleanup EXIT
unzip -q "$ipa" -d "$staging/extracted"

top_level=$(find "$staging/extracted" -mindepth 1 -maxdepth 1 -print)
[[ "$top_level" == "$staging/extracted/Payload" ]] || die "IPA has unexpected top-level content"
app="$staging/extracted/Payload/AnnePad.app"
[[ -d "$app" ]] || die "Payload/AnnePad.app is missing"

app_report="$staging/app-audit.txt"
"$script_dir/audit-ios-app.sh" "$app" release > "$app_report"

manifest_tmp="$staging/AnnePad-0.1.0-unsigned.manifest.sha256"
canonical_tree_manifest "$staging/extracted" "$manifest_tmp"
canonical_sha=$(sha256_file "$manifest_tmp")
raw_sha=$(sha256_file "$ipa")
archive_size=$(stat -f '%z' "$ipa")
file_count=$(wc -l < "$manifest_tmp" | tr -d ' ')

base=${ipa%.ipa}
manifest_output="$base.manifest.sha256"
report_output="$base.audit.txt"
report_tmp="$staging/AnnePad-0.1.0-unsigned.audit.txt"
{
    printf 'AnnePad unsigned IPA audit\n'
    printf '==========================\n\n'
    printf 'result=PASS\n'
    printf 'candidate=%s\n' "$(basename "$ipa")"
    printf 'archive_size=%s\n' "$archive_size"
    printf 'archive_sha256=%s\n' "$raw_sha"
    printf 'canonical_manifest_sha256=%s\n' "$canonical_sha"
    printf 'canonical_file_count=%s\n\n' "$file_count"
    cat "$app_report"
    printf '\nArchive policy: only Payload/AnnePad.app; no ROM/save, launcher artwork,\n'
    printf 'provisioning profile, code signature, credential, or unexpected dynamic library.\n'
    printf 'Canonical digest covers sorted uncompressed path, byte size, and SHA-256.\n'
} > "$report_tmp"

mv -f "$manifest_tmp" "$manifest_output"
mv -f "$report_tmp" "$report_output"

note "Unsigned IPA audit passed."
note "archive_sha256=$raw_sha"
note "canonical_manifest_sha256=$canonical_sha"
note "manifest=${manifest_output#"$ANNEPAD_ROOT/"}"
note "report=${report_output#"$ANNEPAD_ROOT/"}"
