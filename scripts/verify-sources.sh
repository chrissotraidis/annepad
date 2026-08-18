#!/usr/bin/env bash

set -euo pipefail
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source "$script_dir/lib/common.sh"

require_command git
require_command jq

game="$ANNEPAD_SOURCES/PokemonStadiumRecomp"
runtime="$ANNEPAD_SOURCES/N64ModernRuntime"
renderer="$ANNEPAD_SOURCES/rt64"
generator="$ANNEPAD_SOURCES/N64Recomp-generator"

assert_revision "$game" "$(lock_value pokemonStadiumRecomp commit)" PokemonStadiumRecomp
assert_revision "$game/disasm" "$(lock_value pokemonStadiumDisasm commit)" pokemonStadiumDisasm
assert_revision "$game/disasm/tools/n64splat" "$(lock_value n64splat commit)" n64splat
assert_revision "$game/recomp-ui" "$(lock_value recompUi commit)" recomp-ui
assert_revision "$generator" "$(lock_value n64RecompGenerator commit)" N64Recomp-generator
assert_revision "$runtime" "$(lock_value n64ModernRuntime commit)" N64ModernRuntime
assert_revision "$runtime/N64Recomp" "$(lock_value n64RecompRuntime commit)" N64Recomp-runtime
assert_revision "$renderer" "$(lock_value rt64 commit)" rt64

verify_clean_checkout "$game/recomp-ui" recomp-ui
verify_clean_checkout "$generator" N64Recomp-generator

renderer_changes=$(git -C "$renderer" diff --name-only --ignore-submodules=dirty)
expected_renderer_changes=$'CMakeLists.txt\nsrc/apple/rt64_apple.h\nsrc/apple/rt64_apple.mm\nsrc/common/rt64_user_paths.cpp\nsrc/hle/rt64_present_queue.cpp\nsrc/metal/rt64_metal.cpp\nsrc/metal/rt64_metal.h\nsrc/render/rt64_render_target.cpp\nsrc/render/rt64_shader_library.cpp\nsrc/shaders/TextureSampler.hlsli'
[[ "$renderer_changes" == "$expected_renderer_changes" ]] || \
    die "rt64 has unexpected tracked modifications"
git -C "$renderer" apply --reverse --check \
    "$ANNEPAD_ROOT/patches/rt64/ios-metal-runtime.patch"
git -C "$renderer" apply --reverse --check \
    "$ANNEPAD_ROOT/patches/rt64/metal-descriptor-state-cache.patch"
git -C "$renderer" apply --reverse --check \
    "$ANNEPAD_ROOT/patches/rt64/metal-clear-state-cache.patch"
git -C "$renderer" apply --reverse --check \
    "$ANNEPAD_ROOT/patches/rt64/ios-render-target-limit.patch"

renderer_nfd="$renderer/src/contrib/nativefiledialog-extended"
renderer_nfd_changes=$(git -C "$renderer_nfd" status --porcelain --untracked-files=all)
expected_renderer_nfd_changes=$' M CMakeLists.txt\n M src/CMakeLists.txt\n?? src/nfd_null.cpp'
[[ "$renderer_nfd_changes" == "$expected_renderer_nfd_changes" ]] || \
    die "rt64 nativefiledialog has unexpected modifications"
git -C "$renderer_nfd" apply --reverse --check \
    "$ANNEPAD_ROOT/patches/rt64/ios-native-file-dialog-null.patch"

runtime_changes=$(git -C "$runtime" diff --name-only --ignore-submodules=dirty)
expected_runtime_changes=$'librecomp/CMakeLists.txt\nlibrecomp/include/librecomp/audio_uaf_protect.hpp\nlibrecomp/include/librecomp/mods.hpp\nlibrecomp/src/audio_uaf_protect.cpp\nlibrecomp/src/files.cpp\nlibrecomp/src/gbcart.cpp\nlibrecomp/src/mods.cpp\nlibrecomp/src/overlays.cpp\nlibrecomp/src/pi.cpp\nlibrecomp/src/recomp.cpp\nultramodern/include/ultramodern/ultra_trace.hpp\nultramodern/include/ultramodern/ultramodern.hpp\nultramodern/src/events.cpp\nultramodern/src/threadqueue.cpp\nultramodern/src/ultra_trace.cpp'
[[ "$runtime_changes" == "$expected_runtime_changes" ]] || \
    die "N64ModernRuntime has unexpected tracked modifications"
git -C "$runtime" apply --reverse --check \
    "$ANNEPAD_ROOT/patches/n64-modern-runtime/apple-audio-uaf-size-type.patch"
git -C "$runtime" apply --reverse --check \
    "$ANNEPAD_ROOT/patches/n64-modern-runtime/static-mobile-core-profile.patch"
git -C "$runtime" apply --reverse --check \
    "$ANNEPAD_ROOT/patches/n64-modern-runtime/gbcart-exact-rom-validation.patch"
git -C "$runtime" apply --reverse --check \
    "$ANNEPAD_ROOT/patches/n64-modern-runtime/atomic-save-lifecycle.patch"
git -C "$runtime" apply --reverse --check \
    "$ANNEPAD_ROOT/patches/n64-modern-runtime/ios-release-trace-exclusion.patch"
git -C "$runtime" apply --reverse --check \
    "$ANNEPAD_ROOT/patches/n64-modern-runtime/synchronous-audio-tasks.patch"

runtime_recompiler_changes=$(git -C "$runtime/N64Recomp" diff --name-only --ignore-submodules=dirty)
[[ "$runtime_recompiler_changes" == "CMakeLists.txt" ]] || \
    die "N64Recomp-runtime has unexpected tracked modifications"
git -C "$runtime/N64Recomp" apply --reverse --check \
    "$ANNEPAD_ROOT/patches/n64recomp-runtime/no-dynamic-code-targets.patch"

renderer_hlslpp="$renderer/src/contrib/hlslpp"
[[ "$(git -C "$renderer_hlslpp" diff --name-only)" == \
    "include/hlsl++/platforms/scalar.h" ]] || \
    die "rt64 hlsl++ has unexpected tracked modifications"
git -C "$renderer_hlslpp" apply --reverse --check \
    "$ANNEPAD_ROOT/patches/rt64/apple-scalar-labs-declaration.patch"

game_changes=$(git -C "$game" status --porcelain --untracked-files=all --ignore-submodules=dirty)
expected_game_changes=$' M CMakeLists.txt\n M extras.c\n M game.toml\n M include/trace.h\n M src/main/main.cpp\n M src/main/recomp_audio_debug.h\n M src/main/rsp_aspmain_hook.cpp\n M src/main/rt64_render_context.cpp\n?? n64recomp\n?? src/main/controller_slots.h\n?? src/main/non_windows_platform.cpp'
[[ "$game_changes" == "$expected_game_changes" ]] || \
    die "PokemonStadiumRecomp has unexpected modifications"
git -C "$game" apply --reverse --check \
    "$ANNEPAD_ROOT/patches/pokemon-stadium-recomp/synchronous-audio-tasks.patch"

# Later game patches intentionally extend hunks from the Apple, release-surface,
# and hook-surface patches, so those earlier patches cannot be reverse-checked
# independently against the final stacked tree. Recreate the stack from HEAD in
# a disposable directory and byte-compare every maintained game source instead.
game_patch_scratch=$(mktemp -d "${TMPDIR:-/tmp}/annepad-game-patches.XXXXXX")
cleanup_game_patch_scratch() {
    if [[ -n "${game_patch_scratch:-}" && -d "$game_patch_scratch" ]]; then
        find "$game_patch_scratch" -depth -delete
    fi
}
trap cleanup_game_patch_scratch EXIT
git -C "$game" archive HEAD \
    CMakeLists.txt \
    extras.c \
    game.toml \
    include/trace.h \
    src/main/main.cpp \
    src/main/recomp_audio_debug.h \
    src/main/rsp_aspmain_hook.cpp \
    src/main/rt64_render_context.cpp | tar -xf - -C "$game_patch_scratch"
(
    cd "$game_patch_scratch"
    git apply "$ANNEPAD_ROOT/patches/pokemon-stadium-recomp/apple-platform-support.patch"
    git apply "$ANNEPAD_ROOT/patches/pokemon-stadium-recomp/ios-release-diagnostics.patch"
    git apply "$ANNEPAD_ROOT/patches/pokemon-stadium-recomp/ios-release-surface.patch"
    git apply "$ANNEPAD_ROOT/patches/pokemon-stadium-recomp/ios-release-hook-surface.patch"
    git apply "$ANNEPAD_ROOT/patches/pokemon-stadium-recomp/audio-active-list-repair.patch"
    git apply "$ANNEPAD_ROOT/patches/pokemon-stadium-recomp/synchronous-audio-tasks.patch"
    git apply "$ANNEPAD_ROOT/patches/pokemon-stadium-recomp/controller-lifecycle-reconciliation.patch"
)
for maintained_path in \
    CMakeLists.txt \
    extras.c \
    game.toml \
    include/trace.h \
    src/main/main.cpp \
    src/main/controller_slots.h \
    src/main/recomp_audio_debug.h \
    src/main/rsp_aspmain_hook.cpp \
    src/main/rt64_render_context.cpp \
    src/main/non_windows_platform.cpp; do
    cmp "$game_patch_scratch/$maintained_path" "$game/$maintained_path" >/dev/null || \
        die "PokemonStadiumRecomp patch stack mismatch: $maintained_path"
done
cleanup_game_patch_scratch
game_patch_scratch=
trap - EXIT

disasm_changes=$(git -C "$game/disasm" diff --name-only --ignore-submodules=dirty)
expected_disasm_changes=$'lib/ultralib/Makefile\nsrc/fragments/62/fragment62_35DF70.c'
[[ "$disasm_changes" == "$expected_disasm_changes" ]] || \
    die "pokemonStadiumDisasm has unexpected tracked modifications"
git -C "$game/disasm" apply --reverse --check \
    "$ANNEPAD_ROOT/patches/pokestadium-disasm/ultralib-cross-archiver.patch"
git -C "$game/disasm" apply --reverse --check \
    "$ANNEPAD_ROOT/patches/pokestadium-disasm/macos-ido-eucjp-escape.patch"

fmt="$generator/lib/fmt"
[[ "$(git -C "$fmt" diff --name-only)" == "include/fmt/base.h" ]] || \
    die "generator fmt has unexpected tracked modifications"
git -C "$fmt" apply --reverse --check \
    "$ANNEPAD_ROOT/patches/n64recomp-generator/fmt-allow-consteval-override.patch"

runtime_fmt="$runtime/N64Recomp/lib/fmt"
[[ "$(git -C "$runtime_fmt" diff --name-only)" == "include/fmt/base.h" ]] || \
    die "runtime fmt has unexpected tracked modifications"
git -C "$runtime_fmt" apply --reverse --check \
    "$ANNEPAD_ROOT/patches/n64recomp-generator/fmt-allow-consteval-override.patch"

# This exact n64splat pin stores one CRLF blob while declaring LF in its own
# .gitattributes, so git 2.36 reports a filtered diff after an otherwise exact
# checkout. Prove the raw worktree bytes still equal the committed blob and
# reject every other tracked change.
n64splat="$game/disasm/tools/n64splat"
n64splat_status=$(git -C "$n64splat" status --porcelain --untracked-files=no --ignore-submodules=dirty)
if [[ -n "$n64splat_status" ]]; then
    [[ "$n64splat_status" == " M src/splat/segtypes/n64/i1.py" ]] || \
        die "n64splat has unexpected tracked modifications"
    expected_blob=$(git -C "$n64splat" rev-parse HEAD:src/splat/segtypes/n64/i1.py)
    actual_blob=$(git -C "$n64splat" hash-object --no-filters src/splat/segtypes/n64/i1.py)
    [[ "$actual_blob" == "$expected_blob" ]] || die "n64splat line-ending exception does not match committed bytes"
fi

[[ -L "$game/lib/N64ModernRuntime" ]] || die "runtime assembly link is missing"
[[ -L "$game/lib/rt64" ]] || die "renderer assembly link is missing"
[[ -L "$game/n64recomp" ]] || die "generator assembly link is missing"

for checkout in "$game" "$game/disasm" "$game/recomp-ui" "$runtime" \
    "$runtime/N64Recomp" "$renderer" "$generator"; do
    push_url=$(git -C "$checkout" remote get-url --push origin 2>/dev/null || true)
    [[ "$push_url" == "DISABLED" ]] || die "push is not disabled for $checkout"
done

note "Source revisions, cleanliness, assembly links, and push guards passed."
