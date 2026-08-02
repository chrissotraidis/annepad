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
- Required automated tests include byte-order normalization, hashes, paths,
  atomic saves, config migration, touch geometry/state, normalized input
  merging, and lifecycle transition idempotence. The repository currently has
  policy/build/audit automation, but no Apple touch/lifecycle unit-test target;
  those tests remain an open gate and must not be reported as passing.

Gate 2 passed 2026-07-31 under the iPhoneSimulator 26.5 SDK for arm64. The audit
found only static AOT/runtime archives, no LiveRecomp/sljit target or artifact,
and no forbidden dynamic-loading/JIT undefined symbol. Archive hashes are
recorded in `STATUS.md`; optimization/performance remains a packaging gate.

Gate 3 passed 2026-07-31 on an iPad Pro 11-inch (M4) Simulator running iOS
18.5. The ROM-free arm64 app installed and launched with the private normalized
ROM only in its writable data container, initialized Metal, and rendered live
opening/title frames. Durable Computer Use evidence is
`evidence/m3-ios-simulator-first-frame.png`. The original 180° Simulator warning
is no longer reproducible. On 2026-08-02, a clean iPhone 16 Pro Simulator passed
relaunches from portrait and both supported landscape origins. The portrait
origin selected landscape automatically; the Metal surface and overlay stayed
upright and aligned; Start responded after each relaunch; and one saved control
resize survived rotation into the opposite landscape before reset. This closes
the local Simulator orientation gate, not physical-iPad acceptance.

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

The 2026-08-01 HarkinianPad-derived correction also builds and installs on that
iPad Simulator. Its low-grip layout, pressed feedback, Start navigation,
editor resize/reset/done path, and a short Home/relaunch cycle were observed.
Independent per-button tap lifetimes have deterministic host coverage for quick
taps, shoulder chords, overlapping A+R, Z cancellation, and lifecycle clearing.
A corrected-overlay rerun selected Squirtle/Pikachu/Bulbasaur, resolved all six
rentals against Psyduck/Oddish/Meowth through the explicit `LOSE`, and returned
to the main selection menu using touch only. Durable evidence is
`evidence/m5-ios-touch-rental-battle-corrected-result.png` (SHA-256
`1b931d2d684884fdac983086a4ddb4a439c7d868d1ba1e4a7da9d07bb449b0f3`).
The revised non-latching Z path and physical-device acceptance remain open.
The source-consistent Release app containing that change built and installed on
the iPad Pro 11-inch (M4), iOS 18.5 Simulator on 2026-08-02. It rendered two
advancing attract frames and retained PID 69075 through a 12-second live sample;
the 380,988,632-byte executable SHA-256 is
`19bcd1cfef6f0fbaaac31acb046128baa748f87e5e231853de4a4c960b57b540`.
Three initial Computer Use attachment attempts timed out. A later sanctioned
UI session attached on 2026-08-02 to the dedicated iPhone 16 Pro, iOS 18.5
Simulator and drove the clean app through title -> Game Pak Check -> main
selection -> Battle Now one-player setup using visible START, A, and D-left
touch controls. PID 52349 remained alive and no AnnePad crash report was found.
This passes ordinary current-iPhone touch routing. A follow-up Gallery run used
three separate Z taps to cycle the lower Pokémon display through gold
nameplate, blue nameplate, hidden, and back to gold; L opened the background
selection menu; and R entered the telephoto close-up. PID 53536 remained alive
with no crash report. Quick-Z and independent L/R routing therefore pass on the
current iPhone Simulator build. A subsequent touch-only Battle Now run selected
Pikachu/Squirtle/Bulbasaur and reached Pikachu versus Meowth. On move selection,
a held R visibly revealed Thunderbolt/Quick Attack/Swift/Thunder Wave with PP
and type data; release hid them again; L returned to strategy selection. Raw
held/released captures are retained under ignored `logs/iphone-current/`.
Pre-battle R-plus-selection and simultaneous chord cancellation remain open.

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
was not exposed by the installed Xcode UI. On 2026-08-02, Device > Lock produced
real UIKit deactivation/background events on the current clean iPhone 16 Pro
Simulator build. Unlock returned to the same PID 60409 and an upright live
surface; both 131,072-byte save copies retained SHA-256
`85781ca6...c7a`; and one Start press reached Game Pak Check with no repeated or
stuck input four seconds later. Physical audio route, interruption, lock/unlock,
termination, and real-speaker acceptance remain open.

Gate 9's local unsigned-package sub-gate and the isolated verifier's internal
checks passed 2026-08-02. The release app is arm64 iPhoneOS 16.0, links only
Apple system libraries, and passed profile,
privacy, metadata, icon, forbidden-runtime, local-path, ROM/save/artwork,
signature, provisioning, and targeted release-diagnostic audits. Unsigned
linking omits the nondeterministic Mach-O UUID; signed linking retains it. The
validation-only audio capture/synthetic, `aspMain` replay/capture/oracle, Ares
worker, TCP debug-server/port, turbo, environment-autoboot, and unavailable-
transport surfaces are compiled out. The app audit rejects their markers using
process substitution so `pipefail` cannot turn an expected `strings` SIGPIPE
into a false negative. Repeated local packages for the current descriptor-
batched/clear-state-cache candidate produced identical 8-file canonical
manifests with SHA-256
`bd6f14bea0db2342903a91448c8bfc24cc020879a446415ee145c3eb2dfd51fa`;
the 378,198,984-byte executable hashes to `1c2bd2e9...6850`. A no-hardlink
isolated clone of source commit `0cc91b61...142b` passed the full fail-closed
verifier and reproduced both values exactly. Private source publication passes.
Signing, install/retest, physical hardware, and public-license
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

On 2026-08-02, the current clean Release app was installed over the dedicated
iPhone 16 Pro, iOS 18.5 Simulator used for native ROM setup. The installation
migrated its data-container UUID but retained the private 32 MiB ROM and matching
131,072-byte primary/backup saves. The app visibly advanced from a battle-attract
scene to the title, stayed alive for 45 seconds, then passed explicit termination
and a 25-second title relaunch. The post-migration container stayed stable and
both save SHA-256 values remained `b5a41c37...2260`. This passes current iPhone
install/render/termination/relaunch persistence. A subsequent real app switch to
Simulator Settings emitted UIKit deactivation/background events while AnnePad
kept PID 51134. Foregrounding AnnePad returned the same PID to a live rendered
title; the primary save modification time advanced while its exact hash remained
unchanged, proving background flush plus foreground continuity. Touch input,
real-speaker audio, and physical-device acceptance remain open.

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

On 2026-08-01, a temporary counter immediately after RT64's Metal swap-chain
present call measured both profiles on iPad Pro 11-inch (M4), iOS 18.5. The
`-O0` validation title/attract path briefly reached 28-30 presents/s but commonly
reported 3-17. The complete `-O2` Release core materially improved title/menu
stretches to roughly 28-30, but the extended full-resolution battle/attract run
still missed the target. Across 80 one-second windows reporting a 30 Hz VI rate,
Release averaged 21.83 presents/s (4.44 minimum, 30.75 maximum), and 34 windows
were below 20. The clean Release app then passed A/Start navigation,
editor resize/reset/done, and Home/resume.

A bounded RT64 descriptor-state cache was then measured on the same Simulator.
Across 117 30 Hz VI windows spanning intro, menus, and rental-battle setup, it
averaged 23.40 presents/s (12.74 minimum, 30.83 maximum); 20 windows were below
20 and 22 were at least 28. The diagnostic-free app rebuilt, rendered the
animated intro at full size, and accepted Start touch into Game Pak Check.
Because the scene mix was not frame-identical and a fresh sample still showed
changing descriptor/XPC work, treat this as directional evidence, not a final
benchmark or performance sign-off.

On 2026-08-02, the exact diagnostic-free Release Simulator executable
`19bcd1cf...b540` was relaunched on the iPad Pro 11-inch (M4). It advanced from
the transient launch card to the animated title path and stayed alive for 45
seconds; start/end screenshots differed and no AnnePad crash report was present
in the preceding three days. The Metal HUD environment did not render a usable
overlay in this Simulator, and a 15-second Game Performance Overview trace hung
during finalization and was discarded. The present-window measurements above
were the current Simulator FPS evidence before the source probe below.

A narrow environment-gated counter was then placed immediately after RT64's
actual Metal present submission in the descriptor-batched source. After eight
startup windows were discarded, 90 automatic title/attract windows averaged
29.96 presents/s (27.66 minimum, 31.09 maximum); zero were below 20, one was
below 28, and 89 were at least 28. The probe was removed, maintained-source
verification passed, and the official Release Simulator build produced a clean
380,988,632-byte executable with no probe marker. That relink hashes to
`4206a896...3ef2`, visibly reaches the animated title, and survived 20 seconds.
The differing hash from the prior same-size source-verified relink means
Simulator executable byte reproducibility is not claimed. This accepts the
automatic title/attract cadence.

The same temporary probe was reintroduced after the current touch-control proof
and measured from the first selected move through two complete animated Battle
Now turns and the return to the third decision. The 154 one-second windows
averaged 29.47 presents/s (29.96 median, 4.32 minimum, 31.94 maximum); two were
below 20, ten were below 28, and 144 were at least 28. The probe was
removed, maintained-source verification passed, and the diagnostic-free Release
app rebuilt to the prior 380,988,632-byte `4206a896...3ef2` executable, with no
probe marker, then visibly relaunched. This accepts sustained controlled
Simulator battle cadence, not physical-iPad performance or thermals.

A follow-up tested whether those two low-present windows were visible stalls.
Matched 20-second, 1 ms `sample` captures covered battle entry and the steady
strategy screen. Entry added bounded RT64 shader-pipeline and texture creation,
but not a sampled one-second CPU hotspot. A raw Simulator recording then covered
38.625 seconds of attack, faint, and replacement activity. The committed
`scripts/analyze-simulator-video.swift` decoded 1,151 frames (29.799 recorded
frames/s) and found three near-unchanged runs: 0.268, 0.260, and 0.267 seconds.
Frames extracted at those timestamps show two black scene cuts and the
fainted-Pokémon hold. No quarter-second-or-longer moving-scene freeze was found.
This resolves the low-present windows as transition pacing, not an additional
shared-renderer optimization target.

A fresh internal-resolution test used RT64's actual manual resolution
multiplier rather than shrinking the Metal drawable. The 1x run remained
full-screen but visibly pixelated and did not improve cadence over the default
3x path; this rejects resolution/fill rate as the leading Simulator hypothesis.
The same audit found a per-clear native Metal depth-state allocation/leak and
replaced it with a cached state. The candidate renders correctly and removes
that state-creation call from sampling, but its non-frame-identical intro run is
not a proven FPS improvement.

The Release-only hook classification now compiles 96 reverse-engineering probes
and their arguments out while retaining the six functional fragment/audio
hooks. The clean runtime window contained zero targeted loader, fragment, pool,
geometry, segment-map, or input-probe lines. A temporary 29-window title/attract
counter then averaged 23.31 presents/s (4.15–30.56), with five windows below 20
and seven at or above 28. The near-identical mean to the preceding 23.40 result
shows that diagnostic output was not the leading cadence cost. The temporary
counter was removed and the clean app rebuilt before source verification.

`MTL_HUD_ENABLED` did not expose useful Simulator metrics, and an attached Game
Performance trace failed to finish a valid document. A five-second live process
sample instead identified synchronous `MTLSimDriver` descriptor/XPC work as the
dominant non-idle sampled path. A Simulator-only half-resolution experiment was
rejected because Computer Use showed the game surface incorrectly occupying only
the upper-left quarter. All temporary probes were removed, full-resolution
Release was rebuilt, and source verification passed. Do not infer physical-iPad
performance from this Simulator driver result; repeat the heavy scene on device.

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
