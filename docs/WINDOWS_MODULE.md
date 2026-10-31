# Windows module work

This is an unreleased maintainer build route. The published PadMint recipe still
offers only its existing Mac route. Releases remain paused under `AGENTS.md`.
No compiler bundle, generated game code, app shell, or personal IPA is published
by this work.

## Preserve the original build

The Windows prototype keeps the pinned pret Make graph, including its per-file
IDO 5.3/7.1 selection, `libultra` I_P/FIXUPS=1 build, archive member order, and
`libleo` postprocessing. A small isolated MSYS environment runs Make and Bash;
native Windows Python, GNU MIPS tools, IDO and LLVM perform the actual work.
The working directory can contain spaces and Japanese characters. Child-only
`USR_LIB` and `TMPDIR` settings give the old IDO tools stable POSIX paths inside
that isolated environment; system locale and mounts are unchanged.

`windows-make-processes.patch` is applied only to a newly prepared Windows
disassembly tree, after the existing maintained patches. It enables the Windows
Make branch, closes a decoded JPEG before renaming it, passes assembler arguments
directly, writes POSIX Make paths, and keeps GNU strip/objcopy input paths relative
to their existing working directory. It changes no compiler flags or library
ordering.

The duplicate section-symbol condition is an exact backport of upstream
[asm-processor commit 6b9b060](https://github.com/simonlindholm/asm-processor/commit/6b9b0601021ab9ffb44a25636771edd49451a592).
It merges only symbols with the same section and value, preserving relocation
remapping and rejecting conflicting definitions. Anne's older pinned processor
is retained; it is not replaced by SnapPad's newer version.

The actual Mac Python baseline is retained, with two explicit Windows fixes:
Rabbitizer 1.16.2's unsigned Python return values and Splat 0.25.0's POSIX output
path serialization. The local wheels have distinct `+padmint.1` versions. These
candidate tools still need a maintained distribution path before a player recipe
can depend on them.

## Module boundary

The app owns the runtime, renderer, saves, Transfer Pak state and GB audio helpers.
The private module owns generated CPU code, overlay tables, and the four exact
maintained RSP implementations: audio, GB Tower, color GB Tower, and JPEG. Their
persistent contexts and manual dispatch adjustments are preserved rather than
regenerated. A versioned getter validates the source identity and every required
callback before game startup. The existing static app path remains the default.

`scripts/module_sources.py` exports pinned Git objects plus Anne's maintained
patches into new task-owned folders. Its temporary index and object database keep
source caches unchanged. Prepared inventories reject changed, missing, extra or
linked files. Source export alone is not evidence that the full player route is
ready.

## Recorded validation and remaining gates

On Windows 11 ARM64, the actual original Make build reproduced the supported
33,554,432-byte ROM exactly: MD5 `ed1378bc12115f71209a77844965ba50` and SHA-256
`502f6082a6436012a8b61419435dec1388869a90ed870e87e2d7bee88f831519`.
The x64 IDO/MSYS/GNU tools ran under Windows emulation; LLVM preprocessing and the
MSVC-built N64Recomp generator were native ARM64. No Mac-built game objects were
copied into that build. Failed intermediate stages were preserved and the final
graph resumed after the focused fixes; this was not a single cold invocation.

Fresh Windows and Mac extraction produced the same 1,530 generated inputs and
metadata after line-ending normalization. Fresh CPU generation produced the same
1,006 files semantically: only line endings and the ordering of two complete
functions differed. All 50,169 declarations and the full overlay table matched.
Public Unicode-path CPU/RSP probes also passed.

The complete module/app import audit, final source/input ledger, repeatable full
orchestrator and packaged PadMint route remain acceptance gates. Device gameplay,
GB Tower behavior and Transfer Pak operation have not been tested by these build
checks. Neither Windows architecture is advertised by the recipe yet.


On 31 October 2026 the module/app import audit passed on an Apple Silicon Mac.
The private module was built with `cmake/game-module` from the existing
supported-ROM CPU generation, PadMint's LLVM 22.1.8 and its open-source iOS SDK
(1,011 compile units). The empty shell was built from the pinned game source
with `private-module-shell.patch` applied only for that build. The shell
contains no generated `func_8…` code. Its `recomp_entrypoint` is the loader's
forwarding stub, and all 103 declared runtime exports are present. PadMint
0.5.27 accepted the pair: 102 module imports resolve to the app, 13 are known
runtime names and 2 are standard C++ names. The module's minimum is iOS 16,
matching the shell. Insertion added only `AnnePadGame.dylib` and left every
shell entry unchanged. This used the Mac's generated CPU source, not a Windows
generation, and no device launch was attempted. A repeatable full orchestrator,
the final ledger and the Windows module compile remain open.

The shell and module now have repeatable entry points:
`scripts/build-module-shell.sh [output.ipa]` applies and verifies the maintained
patches, builds only rt64's `file_to_c` host tool, applies the shell patch for
that build only, rejects ROM files or `func_8…` code in the shell, and writes a
deterministic unsigned IPA. `scripts/build-game-module.py` compiles the module
with PadMint's toolchain and requires `_annepad_get_game_module` to be its only
export. Run from scratch on 31 October, they reproduced the audit above: shell
in 7 min 26 s, module in 10 min 27 s with 12 jobs, the same import counts, iOS 16,
and insertion adding only the module to the 8-entry shell. Turning these into one
PadMint recipe still needs the generation step for Windows.
