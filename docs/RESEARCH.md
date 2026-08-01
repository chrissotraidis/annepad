# Research and review

Research snapshot: 2026-07-31. Exact commits are in
`REPOSITORY-INVENTORY.md`; conclusions may change only through a recorded
decision and new runtime evidence.

## Executive conclusion

Use `mstan/PokemonStadiumRecomp` as the game-specific foundation. It is the only
investigated project already combining Pokémon Stadium-specific AOT output,
runtime fixes, rendering fixes, Transfer Pak/GB Tower work, saves, and a known
working desktop release. No fork is both newer and technically superior.

Do not treat its current checkout as reproducible or mobile-ready. Its setup
script clones the wrong N64Recomp remote relative to its documentation, warns
rather than enforcing its pin, does not materialize the runtime/renderer graph,
and the release publishes no dependency manifest. The base CMake also assumes
x86 (`-march=nehalem`), desktop windowing, a desktop launcher, and portions of a
Windows audio path.

For Apple architecture, adapt the proven BearBirdPad pipeline: pinned fetch-only
sources, host generation tools, generated source outside git, source patches
with forward/reverse checks, Metal through RT64, a native UIKit/SDL shell,
normalized controller/touch input, private user files, lifecycle handling, and
audited deterministic packaging. Use HarkinianPad only for interaction patterns
that remain independently implementable under its stated rights.

## Game-core candidates

### mstan/PokemonStadiumRecomp — selected provisionally

Strengths:

- Current static-recomp desktop port for the exact supported US 1.0 revision.
- Has upstreamed game fixes for framebuffer presentation, YUV decode, timing,
  saves, controller behavior, Transfer Pak, GB Tower, and battle flow.
- Uses a game-specific fork family (`mstan/N64Recomp`,
  `mstan/N64ModernRuntime`, `mstan/rt64`) rather than an emulator wrapper.
- v0.4.6 is a useful behavioral reference even though its binary is Windows-only.

Risks:

- Only Windows release artifacts; upstream macOS/Linux source claims are not
  backed by published binaries.
- Exact N64ModernRuntime, RT64, and small-library commits for v0.4.6 are absent.
- Documentation and open issues disagree on some validated/fixed behaviors.
- Current runtime always links dynamic recompilation infrastructure; iOS must
  make interpreter-only fallback a compile-time property, not an environment
  toggle.
- Desktop launcher requires OpenGL/ImGui and is unsuitable for iOS setup.

### Fork review

The three public forks are stale. `LucioXerus/PokemonStadiumRecomp` adds a
vendored dependency tree in one divergent commit but is 43 upstream commits
behind and predates the current launcher and fixes. It may help identify old
dependency layout only; it is rejected as a base. No open pull request contains
a superior Apple or portability implementation.

### Decompilation input

The selected repository pins `pret/pokestadium` at `756f7e3`. It verifies the
same ROM MD5 and provides the split/configuration inputs for AOT generation.
Its README targets Debian/Ubuntu and expects GNU MIPS binutils. On macOS this
will require either a pinned cross-binutils toolchain or a contained Linux build
step. The checkout lacks a repository-level license, so it is a local build
input, not a redistributable AnnePad component, pending clarification.

## Runtime and code generation

The Pokémon Stadium checkout pins mstan/N64Recomp commit `2b949c5` for host AOT
generation. The inferred N64ModernRuntime commit separately pins N64Recomp
`9483814` for its runtime and LiveRecomp build interface. These revisions serve
different roles and cannot be collapsed without a compatibility proof.
The generator commit lives on mstan's `work/pokemon-snap` branch rather than its default branch. Its
optional Ares submodule references a commit no longer fetchable from the listed
remote, so recursive submodule initialization is not reproducible. The required
ELFIO, fmt, Rabbitizer, sljit, and tomlplusplus submodules are fetchable; the
optional Ares bridge must be excluded from the host-tool build.

N64ModernRuntime provides the scheduler, memory, audio, input, overlays, and
game integration. Its current fork adds interpreter and dynamic fragment tiers.
The default CMake links N64Recomp and LiveRecomp and `overlays.cpp` includes TCC
recompilation support. On iOS:

- Base game functions must remain ahead-of-time native code.
- Runtime-loaded executable code, TCC, sljit JIT, dynamic libraries, and plugins
  must be excluded by the build graph.
- An interpreter may remain only as a statically linked compatibility fallback
  for exceptional overlay fragments, with tests proving base gameplay does not
  depend on general emulation.
- Generated AOT source must be reproducible locally and ignored by git.

## Renderer review

`mstan/rt64` current main already contains a direct Metal RHI and several
`TARGET_OS_IPHONE` branches in Metal code, plus Stadium-specific fixes. However,
its Apple window wrapper unconditionally imports AppKit and assumes NSWindow;
its CMake sets a macOS deployment target for all Apple builds. It requires a
UIKit/CAMetalLayer window bridge, iOS cross-compile rules, host-built shader
tools, and simulator/device validation.

Two viable strategies remain:

1. Adapt mstan's direct-Metal RT64 to UIKit. This keeps the smallest delta from
   the known Stadium renderer and minimizes game-regression risk.
2. Port the Stadium-specific delta onto official RT64/Plume, using BearBirdPad's
   proven iOS patch family. This has the stronger mobile base but a much larger
   renderer-era change and greater behavioral risk.

Milestone 1 will first build mstan's renderer on native arm64 macOS. A contained
spike will then compare iOS compile surface and first-frame viability before
Decision D-006 closes the choice. Direct Metal is preferred; MoltenVK is a
fallback only if measured evidence shows the direct path cannot meet the gate.
MoltenVK would add Vulkan translation, binary size, shader, lifecycle, and
licensing complexity without removing the need for UIKit integration.

Runtime shader compilation must not rely on unavailable iOS developer tools.
The build must compile and package Metal shader libraries on the Mac using
host-built DXC/SPIRV-Cross helpers and the selected Apple SDK. No app runtime
may invoke `xcrun`, `metal`, or download shaders.

## Apple reference review

### BearBirdPad — primary static-recomp reference

BearBirdPad proves the closest architecture: host N64Recomp tools generate AOT
sources; an iOS-gated N64ModernRuntime and RT64/Plume build into a native Metal
app; UIKit handles document import; SDL carries normalized input; patches are
maintained against exact pins; and an unsigned IPA is assembled and audited.
It has physical iPad and iPhone evidence. Its code-mod JIT is compiled/gated out
for iOS while base gameplay remains AOT.

Reusable approach, subject to GPL obligations:

- Fetch-only source graph and lock verification.
- Separate host and target build phases.
- RT64/Plume Apple cross-compilation and offline shader pipeline.
- UIKit shell, Files document picker, lifecycle, touch/config bridge, save path,
  package audit, and reproducibility gates.

Game-specific Banjo code and assets are not reusable.

### HarkinianPad — secondary UX/platform reference

HarkinianPad is an OoT native-source port, not a static recompilation project.
It nevertheless proves Metal/UIKit/SDL integration, document import, persistent
customizable multitouch profiles, high-DPI display handling, saves, lifecycle,
and package auditing on current iPad hardware. AnnePad should reproduce the
design principles—normalized touch input, phone/tablet profiles, safe-area-aware
overlays, and explicit lifecycle state—without copying rights-restricted code
or artwork unless permission is recorded.

### Other mobile references

BanjoRecomp-Android confirms that an N64ModernRuntime port can use mobile SDL,
Vulkan, controllers, and app-private saves, but it lacks touch and Apple paths.
BearBirdPad supersedes it for implementation guidance.

## Desktop assumptions to replace

- Win32 executable/resource layout and WASAPI-specific hosting.
- Cocoa/AppKit-only window and display discovery.
- x86 compiler flags and assumptions about executable memory.
- OpenGL ImGui launcher and unrestricted filesystem dialogs.
- Mutable files beside the executable and current-working-directory paths.
- Runtime shader/tool invocation, dynamic plugins, and loaded code mods.
- Keyboard-first controls, hover/right-click semantics, and fixed desktop DPI.

## Mobile product decisions from research

- Replace the desktop launcher with a small native first-run/import screen. It
  validates the ROM, reports supported revision, and proceeds to gameplay.
- Store imported ROM and generated private runtime material under Application
  Support; saves/config under Application Support with atomic writes and
  backup/recovery; user exports use the document picker/share sheet.
- Feed touch and GameController/SDL controllers into one normalized N64 input
  state. Touch UI never calls game logic directly.
- Start with rental battle, menus, rendering, audio, saves, and lifecycle.
  Defer customization polish, texture packs, Transfer Pak, and GB Tower.
- Transfer Pak can use user-imported GB/GBC ROM and save files inside the app
  sandbox. GB Tower is feasible only if its interpreter/runtime path is static,
  sandboxed, and legal; neither feature is a base-release gate.
- Statically link every runtime component on iOS and make optional desktop
  plugins unavailable at compile time.

## Review outcome

The early assumption that HarkinianPad would be the principal technical base
was rejected: BearBirdPad is materially closer because it already proves the
same static-recomp runtime family on iOS. The assumption that the upstream
release commit alone was a reproducible pin was also rejected because its
runtime and renderer revisions are undocumented. Research therefore supports a
locked fetch/patch model and a macOS proof gate before any polished mobile UI.
