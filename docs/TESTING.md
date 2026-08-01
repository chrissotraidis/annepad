# Testing strategy

Every result records date, git commit, dependency-lock digest, target, SDK/OS,
device, configuration, command, and evidence path. Build success is never
reported as runtime success; Simulator evidence is never reported as device
evidence.

## Automated gates

### Repository and input safety

- Reject tracked/packaged ROM, save, cartridge, generated asset/source, signing,
  credential, archive, and unexpected binary extensions.
- Check ignored local ROMs never appear in `git ls-files` or package manifests.
- Validate only exact US 1.0 normalized size/MD5; test wrong byte order,
  revision, length, corruption, unreadable input, and atomic import failure.
- Scan source, logs, binaries, and packages for workspace/home absolute paths and
  secrets. Report filenames and rule names, never secret values.

### Source reproducibility

- Fetch exact lock commits with push disabled and reject dirty/mismatched trees.
- Apply every maintained patch forward; reverse-check it after application.
- Build host tools twice from fresh directories and record tool hashes.
- Generate AOT output twice from the same local ROM and compare sorted paths,
  sizes, and content hashes without archiving the output.
- Verify generated source and ROM-derived assets remain ignored/untracked.

### Compile/link/static analysis

- macOS debug/release and iOS Simulator/device compile matrix.
- Warnings-as-errors for AnnePad-owned code where third-party code permits.
- Architecture and SDK checks for every Mach-O.
- Forbidden symbol/dependency scan for TCC, LiveRecomp, sljit JIT execution,
  `dlopen`, writable+executable memory, desktop AppKit in iOS, and simulator
  frameworks in device builds.
- Unit tests for byte-order normalization, hashes, paths, atomic saves, config
  migration, touch geometry/state, normalized input merging, and lifecycle
  transition idempotence.

Gate 2 passed 2026-07-31 under the iPhoneSimulator 26.5 SDK for arm64. The audit
found only static AOT/runtime archives, no LiveRecomp/sljit target or artifact,
and no forbidden dynamic-loading/JIT undefined symbol. Archive hashes are
recorded in `STATUS.md`; optimization/performance remains a packaging gate.

Gate 3 passed 2026-07-31 on an iPad Pro 11-inch (M4) Simulator running iOS
18.5. The ROM-free arm64 app installed and launched with the private normalized
ROM only in its writable data container, initialized Metal, and rendered live
opening/title frames. Durable Computer Use evidence is
`evidence/m3-ios-simulator-first-frame.png`. Cold-launch orientation is not yet
accepted: the first landscape can be 180° from the Simulator chrome until the
device rotates to the opposite supported landscape.

The Simulator Home/background and icon relaunch smoke also returned to an
upright live frame. It proves a basic app transition only; the full lifecycle
matrix remains Gate 7 work.

Gate 4 compile proof passed 2026-07-31 under the iPhoneOS 26.5 SDK: the complete
ROM-free unsigned app is arm64, declares `platform IOS` with minimum iOS 16.0,
links the native Metal/audio/GameController framework surface, and contains no
ROM-format file. Runtime/controller acceptance is still open because no physical
iPhone/iPad, signing identity, or provisioning profile is available on this Mac.

Gate 5 Simulator touch proof passed 2026-07-31 on iPad Pro 11-inch (M4), iOS
18.5. The native overlay's complete N64 control surface, concurrent touch
ownership, edit operations, and tablet preference persistence were exercised.
A full rental battle used touch only from team selection through the explicit
result; the exact team was Squirtle/Pikachu/Bulbasaur against
Oddish/Magnemite/Meowth. Durable evidence is
`evidence/m5-ios-touch-rental-battle-result.png`. This does not close the
physical-hardware touch gate.

Gate 6 native ROM setup passed 2026-07-31 on an iPhone 16 Pro Simulator, iOS
18.5. Remove cleared the private normalized/runtime copies and config; cold
relaunch showed the legal setup screen upright; the native document picker
accepted a local `.v64`; normalization produced the exact supported 32 MiB MD5;
the private copy received file protection and backup exclusion; gameplay then
started. Durable evidence is `evidence/m6-ios-native-rom-setup.png`.

Gate 7 save/lifecycle software proof passed its Simulator portions 2026-07-31.
Home/background emitted the flush marker, icon relaunch emitted foreground
resume and returned to live rendering, and a second background produced exact
131,072-byte primary/backup saves. With the app terminated, the isolated
Simulator primary was replaced by a 3,100-byte invalid file; relaunch logged
backup recovery, restored identical valid primary/backup hashes, and quarantined
the injected input as `.corrupt`. Durable visible evidence is
`evidence/m7-ios-resume-after-background.png`. The source also handles low-memory
events without discarding game state. An actual Simulator memory-warning command
was not exposed by the installed Xcode UI, and physical audio route,
interruption, lock/unlock, termination, and real-speaker acceptance remain open.

Gate 9's local unsigned-package sub-gate and the isolated verifier's internal
checks passed 2026-08-01. The release app is arm64 iPhoneOS 16.0, links only
Apple system libraries, and passed profile,
privacy, metadata, icon, forbidden-runtime, local-path, ROM/save/artwork,
signature, provisioning, and targeted release-diagnostic audits. Unsigned
linking omits the nondeterministic Mach-O UUID; signed linking retains it. The
validation-only audio capture/synthetic, `aspMain` replay/capture/oracle, Ares
worker, TCP debug-server/port, turbo, environment-autoboot, and unavailable-
transport surfaces are compiled out. The app audit rejects their markers using
process substitution so `pipefail` cannot turn an expected `strings` SIGPIPE
into a false negative. Repeated local packages for source commit
`ee4f1af8...77f2` produced identical 8-file canonical manifests with SHA-256
`b0f62f11d11bff4f9a6f15770da65b41fea6f7efc3686eca0dc18238a3c562b0`;
the 378,173,192-byte executable hashes to `6453dac1...b27a`. The previous
`915b171b...a9ae` snapshot passed the full fail-closed isolated verifier; the
current hardened digest still needs that rerun. Private source publication
passes. Signing, install/retest, physical hardware, and public-license
acceptance remain open.

### Runtime smoke automation

- macOS: start, wait for first frame, validate ROM, navigate deterministic test
  input to a stable menu, request clean shutdown, check logs/crash output.
- Simulator: boot/install/launch, first frame, screenshot, background/foreground,
  terminate/relaunch, collect `.xcresult` and system logs.
- Package: expand IPA, enumerate files, Mach-O/load commands/entitlements/privacy,
  licenses, forbidden extensions, local paths, architecture, and canonical
  sorted uncompressed-content digest.

Automation that cannot see or hear gameplay is a smoke gate only.

## Manual macOS gate

On native arm64, validate cold start, menus, rental selection, one complete
battle and exit, rendering, audible audio, controller/keyboard input, save,
relaunch, fullscreen/window transitions if exposed, and clean shutdown. Capture
screen recording or timestamped screenshots plus a concise observation log.

Passed 2026-07-31 for the native arm64 release bundle: team selection through
the explicit full-battle result, Metal rendering, CoreAudio, keyboard input,
save creation, relaunch to title, and native-menu exit 0. Durable result image:
`evidence/m1-macos-rental-battle-result.png`. Physical-controller and
real-speaker subjective acceptance remain device-era gates and are not implied
by this pass.

## Simulator matrix

At minimum:

- One current iPhone portrait/landscape-capable model.
- One current iPad model with resize/orientation coverage.
- Supported minimum iOS runtime and current runtime when installed.

Test import errors, first frame, menus, battle entry, debug/controller input,
touch cancellation, safe areas, high DPI, background/foreground, termination,
relaunch, and save/config persistence. Simulator audio is functional evidence,
not real-speaker acceptance.

## Physical-device matrix

Record model identifier and OS without publishing device UDID.

- iPhone: signed install, real-speaker audio, physical controller, full touch
  rental battle, safe areas/orientation, lock/unlock, interruptions, save/relaunch.
- iPad: same gates, plus tablet touch layout, multitasking/resize where supported,
  external keyboard/controller coexistence, and sustained battle performance.
- At least one test on the minimum supported OS if hardware is available.

Physical controller and touch are separate gates. A complete touch battle must
not use keyboard/controller assistance after team selection begins.

## Touch scenarios

- One finger stick; one button; stick + one/two buttons; button chord; rapid
  handoff; multiple fingers crossing; touch leaves view; system gesture cancel;
  app resigns active while pressed.
- 8-way stick and C-button intent; deadzone and maximum; diagonal direction;
  D-pad and analog exclusivity/merge rules.
- Edit mode move/resize/opacity/hide/reset; overlapping controls; safe-area clamp;
  phone/tablet profile persistence and migration.
- No stuck input after cancellation, backgrounding, setup overlay, or controller
  connection change.

## Saves/files/lifecycle scenarios

- Fresh save, overwrite, relaunch, app update, export/import where supported.
- Fault injection before/after temp write and replacement; corrupted primary
  with good backup; corrupted both; full disk/permission error.
- Repeated inactive/background/foreground, lock/unlock, home gesture, file picker,
  audio interruption/route change, memory warning, renderer surface loss, force
  termination, and cold recovery.

## Performance evidence

Record frame-time percentiles, audio underruns, resident/high-water memory,
thermal state, device/OS, resolution/internal scale, and game scene. Do not hide
short stalls in averages. Initial acceptance is stable full-speed battle and
responsive input without sustained thermal collapse; numeric budgets are set
after the first physical baseline.

## Failure report template

```text
Gate / expected:
Observed:
Commit + lock digest:
Target / device / OS:
Exact command or interaction:
First failing timestamp/state:
Evidence paths:
Last known good:
Next falsifiable hypothesis:
```
