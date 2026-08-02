# Blockers and risks

Resolved entries are never deleted.

## B-001 — Exact upstream v0.4.6 graph is not published

- Status: active, non-blocking for reconstruction
- Evidence: the release has one Windows ZIP; setup pins N64Recomp but does not
  pin/materialize N64ModernRuntime or RT64. It also exposes stale standalone
  concurrentqueue/SlotMap include paths despite the runtime owning its queue. Release
  dates suggest runtime `d4bf882` and RT64 `821a867`, but that is inference.
- Attempts: inspected setup, CMake, submodules, branches, forks, release archive,
  release metadata, issues, PRs, and companion repository histories.
- Next hypothesis: assemble the pre-release fork heads, compile, and compare
  hashes/log signatures/behavior to the release docs. Record deviations.

## B-002 — Official Windows baseline cannot execute locally

- Status: active environment gap
- Evidence: the only release binary is Windows x64; no Wine, CrossOver, Whisky,
  or VM product is installed on this Apple Silicon Mac.
- Attempts: enumerated commands and common application bundles; inspected the
  release ZIP without execution.
- Next hypothesis: first reproduce source-generation and native macOS behavior.
  If exact Windows execution remains needed, use a lawful Windows arm64/x64
  environment or obtain user authorization for a hosted runner. Compilation
  alone will not close the runtime gate.

## B-003 — N64Recomp recursive submodule is broken

- Status: active, contained
- Evidence: exact pin `2b949c5` references an optional Ares commit unavailable
  from the declared remote; required tool submodules initialize individually.
- Attempts: fresh recursive initialization failed; ELFIO, fmt, Rabbitizer,
  sljit, and tomlplusplus were initialized selectively.
- Next hypothesis: build only the N64Recomp/RSPRecomp targets and exclude the
  Ares bridge explicitly. If CMake still enters it, patch the host build with a
  narrowly scoped option and preserve the error log.

## B-004 — Upstream component licenses are incomplete

- Status: active release blocker; not a private local-build blocker
- Evidence: no repository-level license exists in the pinned `pret/pokestadium`
  checkout; `mstan/recomp-ui` states only bundled third-party licenses.
- Attempts: inspected root files and searched license/SPDX/copyright notices.
- Next hypothesis: seek upstream license clarification or remove/replace each
  component from redistributed source/binaries. Do not assume parent GPL covers
  separately copyrighted submodule content.

## B-005 — Renderer lineage is unproven on iOS

- Status: resolved 2026-07-31
- Evidence: mstan direct Metal contains iPhone conditionals but Apple windowing
  imports AppKit and CMake forces macOS. Official RT64/Plume has a proven iOS
  path in BearBirdPad but a much larger delta from Stadium's renderer.
- Attempts: compared fork branches, merge base, Stadium-specific commit delta,
  Apple code, CMake, shader tooling, and BearBirdPad patches.
- Resolution: the selected Stadium RT64 lineage now cross-builds its Metal
  shaders and native backend for iPhoneSimulator, links into the ROM-free app,
  and renders a visible live frame on an iPad Pro 11-inch (M4), iOS 18.5.

## B-006 — Runtime dynamic-code surface is incompatible with target policy

- Status: resolved 2026-07-31
- Evidence: current N64ModernRuntime links N64Recomp/LiveRecomp and includes TCC
  overlay recompilation. Runtime environment toggles do not remove code paths.
- Attempts: inspected CMake, overlay implementation, fragment-tier docs, and
  BearBirdPad iOS gates.
- Resolution: added a compile-time strict profile that excludes LiveRecomp,
  sljit, TCC fragment recompilation, and dynamic plugin loading. The full AOT
  game/runtime archives compile for arm64 iPhoneSimulator and pass build-graph,
  artifact, architecture, SDK, and forbidden-symbol audits.

## B-007 — Physical devices and signing are not yet enumerated

- Status: active external-resource gate; device compilation is unblocked
- Evidence: `xcrun xctrace list devices` reports only the Mac under physical
  devices; `security find-identity -v -p codesigning` reports zero valid
  identities; no provisioning profile is installed.
- Attempts: enumerated hardware, identities, and profiles without modifying the
  user's account. Independently cross-built the strict core and complete ROM-free
  unsigned app for arm64 iPhoneOS.
- Next hypothesis: when a lawful local signing identity/profile and physical
  iPhone/iPad are attached, sign/install this bundle and execute the separate
  controller, audio, orientation, lifecycle, and sustained-battle gates.

## B-016 — Optimized Simulator remains slow in heavy battle scenes

- Status: active performance acceptance gap; optimized build complete
- Evidence: `apple/core/CMakeLists.txt` intentionally compiles validation AOT at
  `-O0`, and the old Simulator script could only select that profile. A temporary
  counter at RT64's Metal present call measured the iPad title/attract path at
  3-17 presents/s in many one-second windows, with brief 28-30 presents/s peaks.
  The user's visible slowdown is therefore real for the tested artifact.
- Correction: Simulator release cores are now supported in a separate
  `build-ios-core-simulator-release/` tree, and the normal Simulator app command
  defaults to that `-O2` product. Validation remains available explicitly for
  fast SDK/static-policy checks and is no longer presented as a playability build.
- Release result: the complete `-O2` arm64 Simulator core passed its static
  audit and the ROM-free Release app built, installed over private ROM/save
  state, rendered at full resolution, accepted A/Start touch input, kept the
  editor functional, and resumed after Home. Title/menu stretches commonly held
  28-30 presents/s. In the extended battle/attract run, however, the 80 windows
  reporting a 30 Hz VI rate averaged 21.83 presents/s; 34 were below 20, with a
  4.44 minimum and 30.75 maximum. This is improved but not performance-accepted.
- Optimization result: RT64 now avoids re-encoding a Metal argument-buffer entry
  when resource, sampler, offset, and descriptor type are unchanged. A follow-up
  intro/menu/rental-setup run measured 117 30 Hz VI windows at 23.40 presents/s
  mean, 12.74 minimum, and 30.83 maximum; 20 were below 20 and 22 reached at
  least 28. Full-size rendering and Start touch still passed after removing the
  probe. The gain is real but insufficient for closing this blocker.
- Diagnosis: a live process sample found synchronous `MTLSimDriver` descriptor
  encoding and XPC waits dominating the non-idle sampled work. A half-resolution
  experiment improved cadence but incorrectly reduced the visible game surface
  to the upper-left quarter and was rejected. Both temporary experiments were
  removed; full-resolution source verification passes. A post-cache sample still
  showed changing descriptor calls and their synchronous XPC waits as the main
  Simulator cost, so a broader batching rewrite is not justified without
  physical-device evidence.
- Fresh audit: changing RT64's internal resolution multiplier from the default
  3x to 1x kept the output full-screen and made it visibly more pixelated, but
  did not improve the measured intro cadence. The earlier upper-left-quarter
  result changed drawable size and tested the wrong knob. Fill rate is not the
  leading current Simulator hypothesis.
- Fresh audit: RT64 also created and leaked a native depth-stencil object on
  every depth-backed color clear. A cached state removes that allocation and
  samples cleanly, but the non-frame-identical follow-up does not prove a
  material FPS gain. Changing descriptor/XPC traffic remains dominant.
- Release-surface result: 96 diagnostic-only hooks and their argument
  evaluation now compile out of the shipping AOT core while fragment/audio
  correctness hooks remain. The clean follow-up had zero targeted loader,
  fragment, pool, geometry, or input-probe lines. Its 29 title/attract windows
  averaged 23.31 presents/s (4.15–30.56), effectively unchanged from the prior
  23.40 mixed-scene result. Logging is therefore no longer a shipping-surface
  blocker and was not the leading FPS cause.
- Descriptor-batching result: contiguous dirty resources now use bulk Metal
  argument-encoder calls immediately before draw/dispatch, while clean sets
  return without scanning. In the exact-source 12-second attract sample, the
  workload thread spent 3,928 of 6,849 samples waiting on its command fence and
  265 waiting on its mutex; the old repeated single-entry setter hotspot was no
  longer present. This is not a frame-identical FPS or physical-device sign-off.
- Gate: measure the same heavy scene on a physical iPad before changing shared
  renderer behavior for a Simulator-specific driver cost. If hardware also
  misses the 30 Hz target, capture device GPU/frame-time evidence and optimize
  the smallest proven RT64 path. Physical sustained-battle, thermal, and audio
  evidence remains required.

## B-015 — Touch overlay physical acceptance remains open

- Status: active physical-device acceptance gap
- Evidence: direct comparison with HarkinianPad commit
  `4db21e4be0f0be52948438de5d8c755d191897ae` found that the retained AnnePad
  build used one hand-drawn full-screen view and generic geometry. It reused
  safe-area normalization, separate profiles, cancellation, and normalized
  input concepts, but not HarkinianPad's accepted low-grip layouts or pressed
  feedback. The goal names HarkinianPad as the preferred touch
  starting point unless a materially better implementation is proven; no such
  proof was recorded.
- Current correction: working source now adapts HarkinianPad's physically
  accepted phone/tablet positions, pressed visuals, customization, and
  cancellation on editor/ROM/lifecycle changes.
  AnnePad keeps its direct analog N64 snapshot bridge because the reference's
  synthetic keyboard path would discard analog magnitude.
- Game-specific correction: the official battle instructions and decompiled
  input reads show held L/R inspection chords but edge-triggered Z actions.
  HarkinianPad's Zelda-oriented persistent Z latch was therefore removed;
  touching Z still holds it normally until release and retains very short taps
  across runtime polls.
- Input correction: quick taps now use independent atomic poll lifetimes per
  N64 button. Deterministic host tests prove exact quick-tap expiry, the longer
  shoulder chord window, overlapping A+R without cross-extension, explicit Z
  clearing, and lifecycle cancellation.
- Partial proof: the corrected candidate builds and installs on the iPad
  Simulator; Start navigation, visible pressed feedback, editor resize/reset,
  Done, and one Home/relaunch cycle passed. Two portrait-origin cold boots
  rotated to landscape without manual intervention. The second reproduced
  transient stale overlay bounds; replacing frame/autoresizing attachment with
  four host-edge constraints kept every control in place across three timed
  startup screenshots.
- Follow-up proof: the corrected overlay completed a full touch-only rental
  battle using Squirtle/Pikachu/Bulbasaur against Psyduck/Oddish/Meowth, reached
  the explicit `LOSE`, and returned to the main selection menu without a crash.
  Evidence SHA-256 is
  `1b931d2d684884fdac983086a4ddb4a439c7d868d1ba1e4a7da9d07bb449b0f3`.
- Gate: smoke the non-latching Z path in UIKit, then repeat ergonomics,
  held-L inspection, R-plus-selection inspection, and stuck-input acceptance
  on physical iPhone and iPad before resolving this blocker.
- Local limitation: the Simulator UI-control bridge timed out on three
  attachment attempts after the exact app launched, so this gesture gate was
  not inferred from screenshots or process survival. A 2026-08-02 refresh also
  confirmed that this Xcode's `simctl io` supports display capture/configuration
  but no touch injection, and `idb`, Maestro, and AppleSimulatorUtils are absent.

## B-014 — iOS platform and dynamic-code separation is not yet compiled

- Status: resolved 2026-07-31
- Evidence: the macOS arm64 app now completes a full rental battle, but the
  current target still links desktop launcher/platform code and runtime
  dynamic-code facilities. No iPhoneSimulator archive exists yet.
- Attempts: introduced narrow macOS platform/window/input seams and proved the
  direct-Metal runtime under a native app bundle.
- Resolution: `apple/core` now builds the complete AOT game plus target-neutral
  runtime under the iPhoneSimulator SDK, and `audit-ios-core.sh` proves the
  required static archives and strict policy. UIKit/RT64 first-frame work moves
  to the next milestone rather than remaining part of this blocker.

## B-008 — Pinned n64splat has contradictory line-ending metadata

- Status: active upstream defect, contained
- Evidence: `src/splat/segtypes/n64/i1.py` is committed as CRLF while the
  repository's `.gitattributes` declares every file `text eol=lf`. Git 2.36
  reports a filtered modification immediately after an exact checkout.
- Attempts: compared status, filtered/unfiltered object IDs, committed bytes,
  and worktree bytes. The raw worktree object exactly matches the committed blob.
- Next hypothesis: keep a narrow raw-object verification exception for this one
  path and reject all other modifications; propose an upstream normalization
  separately rather than mutating the selected pin.

## B-009 — Pinned fmt does not allow its consteval mode to be overridden

- Status: resolved 2026-07-31
- Evidence: fmt 10.2.2 at the generator pin fails in `format.cc`/`os.cc` under
  AppleClang 21 with non-constant `FMT_STRING` evaluation. Passing
  `FMT_USE_CONSTEVAL=0` alone is ineffective because that release redefines it.
- Attempts: clean native arm64 build; compile-definition-only retry; comparison
  with current upstream fmt `base.h`.
- Resolution: maintain the upstream-style three-line guard that honors a supplied
  `FMT_USE_CONSTEVAL`, then pass `FMT_USE_CONSTEVAL=0` only to the host tool build.
  The patch is forward/reverse checked and does not change recompiler behavior.

## B-010 — Decomp extraction bypasses its virtual environment

- Status: resolved 2026-07-31
- Evidence: `make venv` successfully installed `crunch64` under `.venv`, but
  `tools/extract_assets.sh` executes helper files whose env shebang resolved the
  host `python3`; hundreds of helpers then failed `import crunch64`.
- Attempts: confirmed imports fail under host Python and pass under the created
  venv; inspected Makefile and extraction script execution.
- Resolution: run decomp make targets with `.venv/bin` first in `PATH`, preserving
  the upstream files and keeping Python dependencies isolated.

## B-011 — Decomp host syntax checker rejects incomplete WIP types

- Status: resolved 2026-07-31
- Evidence: after successful extraction, the optional host Clang syntax pass
  rejected known pointer/integer mismatches in WIP decomp source `src/11BA0.c`.
  This is not the IDO/MIPS compiler and does not produce the matching ROM object.
- Attempts: verified the Makefile separates `CC_CHECK` from the pinned IDO
  compiler and exposes `RUN_CC_CHECK=0` specifically for this check.
- Resolution: disable only the optional host warning/syntax pass for the matching
  ROM build. The authoritative acceptance remains the final rebuilt ROM MD5.

## B-012 — Apple archiver silently drops MIPS objects

- Status: resolved 2026-07-31
- Evidence: `/usr/bin/ar` produced a 96-byte archive containing only
  `__.SYMDEF SORTED`; the same two-object probe with `mips-linux-gnu-ar`
  preserved both members. The incomplete archive caused unresolved libultra
  symbols during the ROM link.
- Resolution: maintain a one-line decomp patch selecting `$(CROSS)ar`. The
  rebuilt archive contains all 380 ordered members and links successfully.

## B-013 — Native macOS IDO mishandles one EUC-JP escape boundary

- Status: resolved 2026-07-31
- Evidence: the initial rebuild differed in only 293 bytes, all within the
  Japanese string block beginning at `D_8438DC80`; `\n` immediately following
  Japanese text became a backslash glyph plus literal `n`.
- Resolution: split that one source literal into adjacent Japanese, escape, and
  Japanese C strings. The native compiler then emits the intended bytes and the
  complete rebuilt ROM matches MD5 `ed1378bc12115f71209a77844965ba50`.

## Resolved blockers

### B-R015 — Project baseline was not committed or backed up

- Status: resolved 2026-08-01
- Evidence: the audited 71-file baseline was committed to `main` at
  `136d145287d3374b93a3dfe0275a46980df85b9c` and pushed to the private GitHub
  repository; local `HEAD` and `origin/main` matched after a fresh fetch.
- Reproducibility evidence: isolated snapshot
  `915b171bfcf666533d39b8bcece2ce2107a3a9ae` passes the fail-closed verifier;
  its `e6b2ab11...f363` executable and `24dc9caa...d9e6` canonical IPA manifest
  matched the then-retained local candidate exactly. The later hardened
  `ee4f1af8...77f2` candidate has independent local two-pass package proof and
  still needs its own full isolated rerun.
- Safety: ROMs, generated source, build trees, saves, IPAs, logs, and signing
  material remain ignored and were not published. Public release and licensing
  are still separate open gates.

### B-R001 — ROM revision uncertainty

- Status: resolved 2026-07-31
- Evidence: streaming byte-swap of the user `.v64` input produced 33,554,432
  bytes and normalized MD5 `ed1378bc12115f71209a77844965ba50`, exactly the
  documented Pokémon Stadium (US) 1.0 input.
- Resolution: support this revision only and keep both source and normalized
  data ignored/local.
