#!/usr/bin/env bash

set -euo pipefail
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source "$script_dir/lib/common.sh"

apply_patch_file() {
    local checkout=$1
    local patch_file=$2
    local label=$3

    if git -C "$checkout" apply --reverse --check "$patch_file" >/dev/null 2>&1; then
        note "Already applied: $label"
    else
        git -C "$checkout" apply --check "$patch_file"
        git -C "$checkout" apply "$patch_file"
        git -C "$checkout" apply --reverse --check "$patch_file"
        note "Applied: $label"
    fi
}

apply_patch_file \
    "$ANNEPAD_SOURCES/N64Recomp-generator/lib/fmt" \
    "$ANNEPAD_ROOT/patches/n64recomp-generator/fmt-allow-consteval-override.patch" \
    "fmt consteval override compatibility"

apply_patch_file \
    "$ANNEPAD_SOURCES/N64ModernRuntime/N64Recomp/lib/fmt" \
    "$ANNEPAD_ROOT/patches/n64recomp-generator/fmt-allow-consteval-override.patch" \
    "runtime fmt consteval override compatibility"

apply_patch_file \
    "$ANNEPAD_SOURCES/PokemonStadiumRecomp/disasm" \
    "$ANNEPAD_ROOT/patches/pokestadium-disasm/ultralib-cross-archiver.patch" \
    "ultralib cross-architecture archive creation"

apply_patch_file \
    "$ANNEPAD_SOURCES/PokemonStadiumRecomp/disasm" \
    "$ANNEPAD_ROOT/patches/pokestadium-disasm/macos-ido-eucjp-escape.patch" \
    "macOS IDO EUC-JP escape compatibility"

game_checkout="$ANNEPAD_SOURCES/PokemonStadiumRecomp"
game_release_surface="$ANNEPAD_ROOT/patches/pokemon-stadium-recomp/ios-release-surface.patch"
if git -C "$game_checkout" apply --reverse --check "$game_release_surface" >/dev/null 2>&1; then
    # The release-surface patch extends Apple-platform hunks, so its presence is
    # also the stack-aware signal that the earlier platform patch is present.
    note "Already applied: Apple platform support"
    note "Already applied: iOS release diagnostic surface exclusion"
else
    apply_patch_file \
        "$game_checkout" \
        "$ANNEPAD_ROOT/patches/pokemon-stadium-recomp/apple-platform-support.patch" \
        "Apple platform support"
    apply_patch_file \
        "$game_checkout" \
        "$game_release_surface" \
        "iOS release diagnostic surface exclusion"
fi

game_audio_repair="$ANNEPAD_ROOT/patches/pokemon-stadium-recomp/audio-active-list-repair.patch"
game_audio_sync="$ANNEPAD_ROOT/patches/pokemon-stadium-recomp/synchronous-audio-tasks.patch"
if git -C "$game_checkout" apply --reverse --check "$game_audio_sync" >/dev/null 2>&1; then
    note "Already applied: iOS release diagnostics exclusion"
    note "Already applied: iOS release diagnostic hook exclusion"
    note "Already applied: Pokemon Stadium audio active-list repair"
    note "Already applied: Pokemon Stadium synchronous audio tasks"
else
    apply_patch_file \
        "$game_checkout" \
        "$ANNEPAD_ROOT/patches/pokemon-stadium-recomp/ios-release-diagnostics.patch" \
        "iOS release diagnostics exclusion"
    apply_patch_file \
        "$game_checkout" \
        "$ANNEPAD_ROOT/patches/pokemon-stadium-recomp/ios-release-hook-surface.patch" \
        "iOS release diagnostic hook exclusion"
    apply_patch_file \
        "$game_checkout" \
        "$game_audio_repair" \
        "Pokemon Stadium audio active-list repair"
    apply_patch_file \
        "$game_checkout" \
        "$game_audio_sync" \
        "Pokemon Stadium synchronous audio tasks"
fi

apply_patch_file \
    "$game_checkout" \
    "$ANNEPAD_ROOT/patches/pokemon-stadium-recomp/controller-lifecycle-reconciliation.patch" \
    "SDL2 controller lifecycle reconciliation"

apply_patch_file \
    "$ANNEPAD_SOURCES/rt64" \
    "$ANNEPAD_ROOT/patches/rt64/ios-metal-runtime.patch" \
    "RT64 iOS Metal runtime"

apply_patch_file \
    "$ANNEPAD_SOURCES/rt64" \
    "$ANNEPAD_ROOT/patches/rt64/metal-descriptor-state-cache.patch" \
    "RT64 Metal descriptor state cache"

apply_patch_file \
    "$ANNEPAD_SOURCES/rt64" \
    "$ANNEPAD_ROOT/patches/rt64/metal-clear-state-cache.patch" \
    "RT64 Metal clear state cache"

apply_patch_file \
    "$ANNEPAD_SOURCES/rt64" \
    "$ANNEPAD_ROOT/patches/rt64/ios-render-target-limit.patch" \
    "RT64 iOS render-target limit"

apply_patch_file \
    "$ANNEPAD_SOURCES/rt64/src/contrib/nativefiledialog-extended" \
    "$ANNEPAD_ROOT/patches/rt64/ios-native-file-dialog-null.patch" \
    "RT64 iOS native-file-dialog null backend"

apply_patch_file \
    "$ANNEPAD_SOURCES/rt64/src/contrib/hlslpp" \
    "$ANNEPAD_ROOT/patches/rt64/apple-scalar-labs-declaration.patch" \
    "Apple scalar hlsl++ labs declaration"

apply_patch_file \
    "$ANNEPAD_SOURCES/N64ModernRuntime" \
    "$ANNEPAD_ROOT/patches/n64-modern-runtime/apple-audio-uaf-size-type.patch" \
    "Apple audio UAF size type declaration"

apply_patch_file \
    "$ANNEPAD_SOURCES/N64ModernRuntime" \
    "$ANNEPAD_ROOT/patches/n64-modern-runtime/static-mobile-core-profile.patch" \
    "static mobile core profile"

apply_patch_file \
    "$ANNEPAD_SOURCES/N64ModernRuntime" \
    "$ANNEPAD_ROOT/patches/n64-modern-runtime/gbcart-exact-rom-validation.patch" \
    "Transfer Pak exact ROM validation"

apply_patch_file \
    "$ANNEPAD_SOURCES/N64ModernRuntime" \
    "$ANNEPAD_ROOT/patches/n64-modern-runtime/atomic-save-lifecycle.patch" \
    "atomic save and lifecycle support"

apply_patch_file \
    "$ANNEPAD_SOURCES/N64ModernRuntime" \
    "$ANNEPAD_ROOT/patches/n64-modern-runtime/ios-release-trace-exclusion.patch" \
    "iOS release trace exclusion"

apply_patch_file \
    "$ANNEPAD_SOURCES/N64ModernRuntime" \
    "$ANNEPAD_ROOT/patches/n64-modern-runtime/synchronous-audio-tasks.patch" \
    "opt-in synchronous audio tasks"

apply_patch_file \
    "$ANNEPAD_SOURCES/N64ModernRuntime/N64Recomp" \
    "$ANNEPAD_ROOT/patches/n64recomp-runtime/no-dynamic-code-targets.patch" \
    "runtime recompiler no-dynamic-code targets"

note "Maintained source patches passed forward/reverse verification."
