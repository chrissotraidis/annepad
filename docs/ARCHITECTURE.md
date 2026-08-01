# Architecture

This is the reviewed target architecture. Items marked provisional require the
named proof gate before they become permanent.

## System boundary

```text
User ROM -> validate/normalize -> host disassembly + N64Recomp
                                  |
                                  v
                         ignored AOT C/C++ source
                                  |
                   +--------------+--------------+
                   v                             v
          macOS native proof app        iOS static app binary
                                                 |
                       +-------------------------+------------------+
                       v              v          v          v       v
                    Metal/RT64      Audio      Input     Saves   Lifecycle
                                                   ^
                                           touch + controller
```

No ROM travels through source control or release packaging. No target-side JIT,
dynamic code download, emulator core, or plugin is part of the iOS app.

## Game core and recompiled code

`mstan/PokemonStadiumRecomp` supplies game-specific configuration, glue, fixes,
and generated-code interfaces. A host-only toolchain consumes the user's exact
Pokémon Stadium (US) 1.0 ROM and the pinned `pret/pokestadium` inputs to produce
ahead-of-time C/C++ under an ignored build/source directory. Generation records
tool commits and output hashes but never commits or archives generated content.

The base game executes as compiled arm64 machine code. A statically linked
interpreter may be retained only for exceptional runtime fragments after a code
inventory proves it is required; it must not become a general N64 emulator.

## Runtime

N64ModernRuntime supplies memory layout, events, scheduler, audio command flow,
input, saves, and overlay bookkeeping. The Apple target now has a compile-time
mobile profile that:

- excludes TCC, LiveRecomp, sljit target JIT, executable-memory allocation,
  loaded code mods, and dynamic plugins;
- rejects target-side LiveRecomp/sljit targets and fails closed for runtime code
  or dynamically loaded mod requests;
- will redirect all mutable paths to app-controlled storage;
- will expose lifecycle-safe pause/resume/flush entry points;
- preserves deterministic scheduler and timer behavior; and
- makes unsupported desktop-only behavior fail at build time.

The strict profile is proven in arm64 iPhoneSimulator and iPhoneOS archives,
including the separate `-O2` release product. Desktop builds keep diagnostics
needed to compare behavior but share core game logic with iOS.

## Renderer

Metal is the target API. The provisional renderer is mstan/RT64 direct Metal
because it contains the known Stadium fixes. The alternative is official
RT64/Plume with those fixes forward-ported. The decision gate is native macOS
gameplay plus an iOS first-frame spike.

Shader generation is a host build step: DXC/SPIR-V input is converted by pinned
host tools and compiled with the selected Xcode SDK into static Metal libraries.
The app does not compile or download shaders at runtime. A UIKit-owned view
provides CAMetalLayer, size, scale, orientation, safe-area, foreground, and
swapchain lifecycle state. MoltenVK is not in the default architecture.

## Apple app shell

A thin Objective-C++/Swift-free-by-default shell owns UIApplication lifecycle,
the setup view, document picker, scene/window/view, display configuration,
background tasks, audio session, and fatal-error presentation. SDL remains an
internal portability/input/audio integration layer where useful; UIKit, not
SDL's desktop window assumptions, owns the mobile presentation boundary.

The shell depends inward on narrow C/C++ interfaces. Game/runtime code does not
import UIKit. Platform implementations are selected by CMake target and compile
definitions, not runtime platform branching scattered through the core.

## Input and touch

All sources produce one normalized N64 controller state per player:

```text
UIKit multitouch ----+
GameController/SDL --+--> normalized stick/buttons --> runtime input snapshot
keyboard (macOS) ----+
```

The touch overlay tracks each finger independently, supports stick recentering,
8-way/C-button intent, simultaneous stick/buttons, cancellation, and safe-area
layout. Phone and tablet profiles store normalized positions, sizes, opacity,
visibility, and handedness. Edit/reset operations are explicit and reversible.
Touch never invokes game menu or battle functions directly.

## Audio

Runtime audio commands feed one platform-neutral mixer. On iOS an AVAudioSession
policy selects the appropriate playback category, observes interruptions and
route changes, and coordinates SDL/core audio start/stop without double-open.
Audio acceptance is based on real speaker/headphone/controller testing, not
buffer counters alone.

## ROM and setup flow

First launch shows a native setup screen with the supported revision and a
Files picker. A security-scoped import is copied into Application Support using
an atomic temporary file, normalized if needed, hashed, then committed only on
success. The UI distinguishes unsupported revision, malformed file, denied
access, low storage, and successful import. The desktop ImGui launcher is not
ported to mobile.

The installed ROM remains a user-owned private input. Reset/remove/export
operations are explicit and never delete saves implicitly.

## Saves and configuration

- `Application Support/AnnePad/ROM/`: private validated normalized ROM.
- `Application Support/AnnePad/Saves/`: game save and optional cartridge saves.
- `Application Support/AnnePad/Config/`: versioned app/runtime/touch settings.
- `Caches/AnnePad/`: reproducible temporary/generated caches only.
- `Documents/`: used only for user-visible exports when appropriate.

Writes use temp-file + fsync/close + atomic replacement where the platform
permits, with schema/version headers, sanity checks, and last-known-good backup.
The runtime receives explicit paths rather than using cwd/executable siblings.

## Lifecycle

State machine:

```text
setup -> launching -> active <-> inactive -> background -> active
                         |                       |
                         +---- flush/pause ------+
                         |
                       terminating
```

Transitions are idempotent. Entering inactive stops accepting gameplay touch;
background pauses scheduling/render submission, flushes saves/config, and
suspends audio. Foreground recreates drawable/swapchain state before resuming
the game and audio. Interruptions and file-picker presentation use the same
pause contract. Abrupt termination recovery is tested separately.

## Optional Stadium systems

Transfer Pak inputs are imported by the user, validated, copied into private
storage, and mapped to a selected controller port. Writes are atomic and
exportable. GB Tower is deferred; if enabled, its GB runtime must be static,
sandbox-compatible, and separately audited. Neither system may weaken ROM or
runtime-code restrictions.

## Packaging and build tooling

Pinned fetch scripts create read-only upstream worktrees with push URLs
disabled. AnnePad patches apply forward and prove reverse applicability. Build
phases are host tools, local generation, macOS runtime, iOS dependencies, Xcode
app, tests, signing, then deterministic unsigned IPA assembly.

The IPA audit enumerates every entry, Mach-O architecture/load command,
framework, entitlement, privacy manifest, license, executable bit, and forbidden
extension. It rejects ROM formats, saves, generated game assets/source, signing
secrets, unexpected dynamic libraries, simulator slices, and absolute local
paths. A canonical sorted uncompressed-content digest is the reproducibility
gate because ZIP timestamps are not stable across tools. The local unsigned
candidate passed this audit twice with identical canonical manifests; a clean
committed-checkout rebuild remains a separate gate.
