# Reviewed implementation plan

Reviewed: 2026-07-31. This plan follows observed repository state and the
required proof order. A milestone is complete only when its runtime gate and
evidence pass; compilation is never substituted for interaction.

## Working rules

- Keep upstream trees immutable and reproducible through exact fetch pins.
- Make the smallest proof-oriented patch, build, run, capture evidence, then
  update status/worklog before expanding scope.
- Preserve a known-good target while introducing the next platform layer.
- Do not begin polish or optional systems while the base rental-battle loop has
  an open correctness regression.
- Each failure retains the command, relevant log, target/SDK/commit, and next
  falsifiable hypothesis under ignored `logs/` plus a concise doc entry.

## Dependency chain

`M0 source truth -> M1 macOS game -> M2 platform seams -> M3 Simulator -> M4 devices -> M5 touch -> M6 setup -> M7 persistence/lifecycle -> M8 optional systems -> M9 release`

## Execution status

- M0–M3: passing for the locally available upstream/source, macOS, static-core,
  and Simulator gates. The unavailable official Windows runtime remains an
  explicitly separate environment gap.
- M4: unsigned arm64 iPhoneOS compile passes; signed physical iPhone/iPad,
  controller, audio, lifecycle, and performance acceptance remain externally
  blocked by absent devices and signing assets.
- M5: Simulator touch implementation and a complete touch-only rental battle
  pass; the physical-device success condition remains open.
- M6: Simulator first-run import/replace/remove and private storage pass; signed
  device storage acceptance remains open.
- M7: atomic save/backup/recovery and background/foreground pass in Simulator;
  physical interruption/route/lock/update/termination acceptance remains open.
- M8: intentionally absent from the base candidate.
- M9: release resources, optimized arm64 app, app/IPA audits, and two-pass
  canonical unsigned-IPA reproduction pass locally. The previous candidate's
  isolated committed snapshot passed the fail-closed full clean-checkout
  verifier. The current hardened candidate compiles out validation-only audio,
  replay/capture/oracle, debug-server, turbo, autoboot, and unavailable-
  transport surfaces and rejects them by audit; its isolated reproduction is
  the next software gate. Private repository publication passes. Signing,
  installation, physical retest, and public-license gates remain open until
  separately evidenced.

Progress past M4 uses independent Simulator sub-gates so the external hardware
block does not stall software hardening. It does not reorder or waive any M4–M7
physical success condition.

## Milestone 0 — Reproducible upstream baseline

- Goal: reconstruct the selected v0.4.6 source graph and run the supported
  upstream behavior, without changing game behavior.
- Dependencies: user ROM; locked game/decomp/N64Recomp/runtime/renderer inputs;
  host CMake/Ninja/Python/MIPS tools; upstream Windows runtime if obtainable.
- Systems affected: lock file, fetch/verify scripts, ignored source/output
  layout, host-generation scripts, baseline logs.
- Build target: upstream Windows target where executable; otherwise host tools
  and exact generated-source output as an explicitly incomplete sub-gate.
- Runtime test: launch v0.4.6, import/validate ROM, enter and leave a rental
  battle, exercise menus/audio/controller/save; record known issue behavior.
- Success: fresh fetches match pins, forward/reverse patches are clean, ROM
  generation is repeatable, and actual upstream execution evidence exists.
- Failure evidence: dependency tree, hashes, CMake cache, compiler versions,
  full failing command/log, release artifact metadata, and environment gap.
- Rollback/containment: all work occurs under ignored `external/`, `generated/`,
  and `build-*`; delete only those explicitly resolved directories if needed.
- Depends on: research review and legal policy only.

## Milestone 1 — Native macOS Apple Silicon build

- Goal: prove the exact game core as a native arm64 macOS app before iOS work.
- Dependencies: M0 source graph/AOT output; mstan NMR/RT64 candidate; SDL and
  host-built shader tools.
- Systems affected: macOS toolchain, portability patches, path/audio/window
  adapters, diagnostics, smoke runner.
- Build target: arm64 macOS 14+ debug and release app/CLI as appropriate.
- Runtime test: cold launch, ROM validation, title/menu navigation, rental team
  selection, one complete battle including win/loss exit, audible audio,
  controller input, save/relaunch persistence.
- Success: native arm64 Mach-O, no Rosetta, stable rendering/audio/input, full
  rental battle, clean exit, and reproducible build/run script.
- Failure evidence: crash report, unified log, renderer captures, runtime tier
  diagnostics, input trace, save hashes, and last successful game state.
- Rollback/containment: keep upstream behavior on a separate patch series;
  revert one patch family, never bulk-rewrite generated source.
- Depends on: M0.

## Milestone 2 — Apple core separation

- Goal: isolate portable game/runtime logic from macOS/iOS platform services and
  remove target-side dynamic-code assumptions.
- Dependencies: passing M1 runtime.
- Systems affected: platform interfaces, CMake targets/options, filesystem,
  clocks, threads, audio, window/renderer bootstrap, codegen tier selection.
- Build target: macOS arm64 remains green; iOS static libraries compile without
  linking an app.
- Runtime test: repeat the M1 battle on the refactored macOS target; compile and
  inspect iOS archives for forbidden symbols/dependencies.
- Success: UIKit/AppKit imports remain in platform files; runtime builds with
  iOS no-JIT profile; macOS behavior is unchanged; architecture audit passes.
- Failure evidence: dependency graph, undefined symbols, forbidden symbol scan,
  behavioral diff, scheduler/renderer logs.
- Rollback/containment: land seams one service at a time behind the existing
  macOS implementation; revert the last seam if its gate fails.
- Depends on: M1.

## Milestone 3 — iOS Simulator build

- Goal: produce the first native Simulator app and reach interactive gameplay.
- Dependencies: M2 static libraries; UIKit/CAMetalLayer bridge; simulator SDL,
  renderer/shader libraries; minimal debug input bridge.
- Systems affected: Xcode project/generator, app shell, scene/view/lifecycle,
  renderer surface, bundle resources, diagnostics.
- Build target: arm64 iOS Simulator on at least one iPhone and one iPad model.
- Runtime test: install/launch, import local test ROM through supported setup or
  a debug-only injection, reach title/menu, enter rental battle, background and
  foreground once, terminate/relaunch.
- Success: visible correct frames, responsive debug/controller input, audible
  simulator audio, no forbidden dynamic-code dependency, no launch crash.
- Failure evidence: `.xcresult`, Simulator/system logs, screenshots, shader and
  CAMetalLayer state, crash report, binary audit.
- Rollback/containment: keep the shell minimal and feature-gated; macOS remains
  the truth target while each iOS service comes online.
- Depends on: M2 and D-006 renderer choice.

## Milestone 4 — Physical iPhone and iPad

- Goal: prove signed deployment and base gameplay on real hardware.
- Dependencies: M3; available devices; valid local signing identity/profile.
- Systems affected: signing config, device architecture, orientation/safe area,
  audio session, display scale, thermal/memory diagnostics, controllers.
- Build target: signed arm64 iPhoneOS app for one iPhone and one iPad.
- Runtime test: install/launch/import, title/menu, rental battle interaction with
  a physical controller, real-speaker audio, rotation/resizing as supported,
  background/foreground, lock/unlock, relaunch.
- Success: both form factors render and run without JIT entitlement or crash;
  controllers/audio work; measured performance is recorded honestly.
- Failure evidence: device model/OS, signing/build log, device console/crash,
  screenshots/video, audio route, frame-time/memory/thermal sample.
- Rollback/containment: device-only fixes remain inside platform adapters and do
  not weaken simulator/macOS assertions.
- Depends on: M3.

## Milestone 5 — Touch controls

- Goal: complete a full rental-Pokémon battle with customizable multitouch.
- Dependencies: passing M4 base loop; normalized input API.
- Systems affected: UIKit overlay, touch state machine, layouts/profiles,
  configuration persistence, accessibility labels/haptics where appropriate.
- Build target: Simulator plus signed iPhone/iPad.
- Runtime test: simultaneous stick + A/B/C/Z/Start/L/R, menu navigation, team
  select, attack selection, battle completion, edit/move/resize/reset controls,
  interruption/cancellation, phone/tablet orientation and safe areas.
- Success: full physical-device touch battle; no stuck inputs; two-finger and
  rapid transitions work; layouts persist; controller path remains green.
- Failure evidence: timestamped touch-to-normalized-input trace, video, layout
  JSON, device/orientation, missed/stuck-event diagnostics.
- Rollback/containment: overlay can be disabled independently; normalized input
  path and controller remain the reference.
- Depends on: M4.

## Milestone 6 — Native setup flow

- Goal: make ROM onboarding safe and understandable without desktop UI.
- Dependencies: M5 playable app; validated ROM service and storage paths.
- Systems affected: setup screen, document picker, byte-order normalization,
  hashing, atomic import/replacement/removal, error UI.
- Build target: signed iPhone/iPad and Simulator.
- Runtime test: first run, cancel picker, correct `.z64`, correct `.v64`, wrong
  region/revision, corrupt/short file, denied access, replace ROM, low-storage
  simulation where practical, relaunch without re-pick.
- Success: supported ROM enters game; all invalid inputs fail closed; no source
  path leaks; imported file remains private; app never bundles a ROM.
- Failure evidence: sanitized validation result, size/digest class, filesystem
  error, UI screenshot, storage state.
- Rollback/containment: setup service is independent from game core; a debug-only
  local path remains available in non-release builds for diagnosis.
- Depends on: M5.

## Milestone 7 — Saves, files, lifecycle

- Goal: preserve progress/config correctly across normal and adverse lifecycle.
- Dependencies: M6 stable private storage; lifecycle state machine.
- Systems affected: save/config adapters, atomic writes/backups/migration,
  background tasks, audio interruptions, renderer recreation, file exports.
- Build target: all Apple targets, with device tests authoritative.
- Runtime test: create save, quit/relaunch, background/foreground repeatedly,
  lock/unlock, audio route/interruption, memory warning, forced termination at
  controlled write stages, corrupt primary/valid backup recovery, app update.
- Success: no save loss/corruption/stuck audio/black screen; touch clears on
  inactive; settings persist; recovery behavior is deterministic and documented.
- Failure evidence: pre/post hashes, transition trace, save journal/backup state,
  crash log, audio/renderer state.
- Rollback/containment: version formats and keep backups; stage lifecycle changes
  per subsystem with fault injection.
- Depends on: M6.

## Milestone 8 — Optional Stadium systems

- Goal: evaluate Transfer Pak first, then GB Tower, without risking base release.
- Dependencies: M7; separate legal review for user cartridge inputs; stable file
  import/export and controller-port model.
- Systems affected: GB/GBC ROM/save validation, port assignment, atomic cartridge
  writes, optional interpreter/runtime, UI.
- Build target: physical device plus macOS reference.
- Runtime test: import valid/invalid cartridge files, attach/detach, Stadium
  Transfer Pak feature, save round trip/export; GB Tower boot/gameplay only if
  static sandbox-compatible implementation exists.
- Success: base game unchanged when disabled; data persists safely; no runtime
  executable code; legal/package audit passes.
- Failure evidence: cartridge metadata/hashes, port state, interpreter tier,
  save diff, crash/performance logs.
- Rollback/containment: compile-time feature flags and separate storage namespace;
  omit entirely from release if any gate remains open.
- Depends on: M7.

## Milestone 9 — Packaging and release

- Goal: produce auditable signed device output and reproducible unsigned IPA.
- Dependencies: all required M0–M7 gates; optional M8 either complete or absent;
  resolved redistribution licenses for any public release.
- Systems affected: release configuration, icons/launch assets, privacy manifest,
  licenses/notices, packaging/audit scripts, clean-checkout verifier.
- Build target: archive, signed device install, unsigned `Payload/*.app` IPA.
- Runtime test: install packaged build, first-run import, full touch rental battle,
  controller smoke, save/relaunch, background/foreground, package re-install.
- Success: clean checkout reproduces canonical content digest; binary contains
  device arm64 only and expected load commands/frameworks; forbidden-file,
  entitlement, privacy, license, local-path, and secret audits pass; docs current.
- Failure evidence: archive/IPA manifests, content digests, Mach-O/load-command
  report, codesign report, audit failures, install/device logs.
- Rollback/containment: package only from a tagged verified tree and fresh output;
  never patch an archive by hand; failed candidates remain private artifacts.
- Depends on: M7 and every release checklist item.

## Principal risks

1. Missing upstream build provenance — close with reconstruction plus honest
   inference labels, then lock the first proven graph.
2. Renderer divergence — decide only after macOS battle and iOS first frame.
3. Runtime overlay/JIT dependency — inventory real gameplay tiers and compile out
   target code generation early.
4. Unlicensed source components — block public distribution until replaced or
   clarified; keep local build inputs outside AnnePad source.
5. Mobile lifecycle/save corruption — design atomic paths and fault tests before
   optional features.
6. Physical-device availability/signing — enumerate after Simulator gate and
   report as an external gate if unavailable, never as a pass.
