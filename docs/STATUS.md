# Status

Updated: 2026-08-01 14:19 CDT

## Current state

Research, locked source reconstruction, host-tool compilation, matching ROM
reconstruction, AOT generation, the native macOS runtime gate, and the static
iOS core-separation and iPad Simulator first-frame gates are complete. A
ROM-free unsigned arm64 iPhoneOS app and release-optimized unsigned IPA now
build, pass their static artifact audits, and reproduce from an isolated clean
source snapshot. Native first-run ROM setup, touch-only battle completion, and
atomic save/lifecycle recovery have Simulator evidence. A live rerun on
2026-08-01 found the retained build process stable and frame-advancing across a
short sample and one background/foreground cycle, but also confirmed that its
touch overlay was a bespoke approximation rather than an adaptation of the
preferred HarkinianPad mechanism. The corrected HarkinianPad-derived low-grip
layout now builds, installs, accepts touch navigation, survives a short
background/foreground cycle, and keeps the editor functional on the iPad
Simulator. The retained `-O0` validation build was confirmed too slow for
playability. The separate `-O2` Simulator core and Release app are now complete,
audited, installed, and smoke-tested. They bring title/menu scenes close to the
game's 30 Hz cadence, but an extended full-resolution attract/battle capture
still averaged 21.83 presents/s across 80 one-second windows where the game
reported a 30 Hz VI rate, including 34 windows below 20 presents/s. Release is
materially better, but Simulator performance is not accepted. Physical-device
runtime acceptance remains externally gated.
AnnePad now builds as a native arm64 `.app`, renders through Metal, outputs
CoreAudio, accepts keyboard input through the normalized N64 path, persists its
game save, and has completed a full rental battle through an explicit result.

The leading game foundation is `mstan/PokemonStadiumRecomp` at
`de27b7b8481630d41fc7fb913dbd02572d421efd`. The leading Apple architecture
reference is BearBirdPad; HarkinianPad is the preferred touch/Apple interaction
reference while remaining secondary for the static-recomp architecture. The
selected direct-Metal RT64 lineage now has
both macOS runtime proof and a native iOS Simulator frame under maintained
patches.

## Proven

- The user-supplied 32 MiB `.v64` file normalizes to Pokémon Stadium (US) 1.0
  MD5 `ed1378bc12115f71209a77844965ba50`.
- The Mac has Xcode 26.6, CMake 4.4.0, Ninja 1.13.2, Apple Silicon, iOS 18.5 and
  26.5 Simulator runtimes, and available iPhone/iPad simulators.
- The upstream game code, disassembly, runtime, renderer, N64Recomp pin, Apple
  reference ports, release metadata, forks, branches, and issue history were
  inspected at exact commits recorded in `REPOSITORY-INVENTORY.md`.
- BearBirdPad demonstrates the required high-level static-recomp Apple pipeline:
  host code generation, Metal renderer, native iOS shell, user ROM import,
  touch, saves, lifecycle, and deterministic IPA packaging.
- HarkinianPad demonstrates a reusable normalized touch/file/lifecycle design,
  although it is not a static-recomp codebase.
- Exact source revisions are materialized with disabled push URLs and verified
  against `dependencies.lock.json`.
- Native arm64 `N64Recomp` and `RSPRecomp` host tools build and pass architecture
  checks.
- The pinned decomp rebuilds a byte-identical ROM with MD5
  `ed1378bc12115f71209a77844965ba50` on macOS.
- N64Recomp generated 1,006 AOT files. The relative-path manifest SHA-256 is
  `cfb9d1e10d30a43ed2b3f9be439842e2bb7a6ae557ee75f38a9c24fdbfda57d2`.
- `./scripts/build-macos.sh` produces
  `build-macos/AnnePad.app/Contents/MacOS/AnnePad`, a Mach-O arm64 executable
  with SHA-256
  `0eb8b5fbb009b4dc46b13525b0a5d13b8ce9373879ff849d73981d75831941e7`.
- The native bundle uses a real SDL Metal view/CAMetalLayer and keeps macOS
  event/controller polling on the Cocoa main thread.
- A full Battle Now rental match was played from team selection through all six
  knockouts and the explicit `LOSE`/`WIN` result screen. Evidence:
  `evidence/m1-macos-rental-battle-result.png` (SHA-256
  `05f87fae577307221ec12392ddb67ebe1587820fd424c5c82d0ee4c273a07f4d`).
- The run exercised rendered menus and battle animations, CoreAudio at 48 kHz,
  held and short-tap keyboard input, in-battle switching, and result-state
  transitions without a crash.
- `build-macos/saves/pokestadium.us.1.0.bin` and its backup were created, the
  app relaunched to a correct title frame, and App-menu Quit returned exit 0.
- `./scripts/build-ios-core.sh simulator` and `./scripts/build-ios-core.sh
  device` produce arm64 archives for the complete AOT game, `librecomp`,
  `ultramodern`, and the AnnePad core profile under their respective Apple SDKs.
- The strict mobile build graph contains no LiveRecomp or sljit target/artifact
  and its undefined-symbol audit rejects `dlopen`, `dlclose`, `dlsym`, and Apple
  JIT cache-control entry points. The 933 MiB AOT archive SHA-256 is
  `6113f6032877a0e65b7f3ed430de94c9c0322e6ac8c540c260ebbe979cd75305`.
- `./scripts/build-ios-simulator.sh validation` produces a ROM-free native arm64
  iPhoneSimulator app. Its earlier executable SHA-256 is
  `d78061dc29b2e0d91185224e7934d436f7e29c96c6ca53b57d663fc3966c4301`.
- The app was installed on an iPad Pro 11-inch (M4) Simulator running iOS 18.5.
  A private normalized ROM was supplied only through the app data container;
  Metal initialized and rendered the live opening/title sequence. Computer Use
  evidence: `evidence/m3-ios-simulator-first-frame.png` (SHA-256
  `d4cef5ac2512b97e51418db0eb0189387e5d57d854e65c71a7b288dcb672b30a`).
- Home/background followed by tapping AnnePad again returned to an upright live
  frame in the Simulator. This is a smoke check, not the later adverse-lifecycle
  acceptance gate.
- `./scripts/build-ios-device.sh` produces
  `build-ios-app-device/Release/AnnePad.app`, a ROM-free, unsigned, 816 MiB
  native iPhoneOS bundle. Its executable is Mach-O arm64 with `platform IOS`,
  minimum iOS 16.0, SDK 26.5, and SHA-256
  `d97a33ba3159d5caac45c5cb9a5d62fb7b479374d2a060ee45e5589c22be2c29`.
  It links only Apple system frameworks/libraries, including Metal, audio, and
  weak GameController/CoreHaptics; no ROM-format file exists in the bundle.
- The iPhoneOS static core passed the no-dynamic-code archive audit. Its hashes
  are `11e404d5...` (AnnePad core), `16b541c4...` (validation AOT game),
  `e36cdd1b...` (`librecomp`), and `a78f39c6...` (`ultramodern`).
- The retained native UIKit touch layer exposes all N64 controls, handles
  independent simultaneous touches, and supports
  move/resize/opacity/hide/reset with separate phone/tablet persistence. A full
  three-on-three rental battle was
  completed using touch only from team selection through the explicit `LOSE`
  result. Evidence: `evidence/m5-ios-touch-rental-battle-result.png` (SHA-256
  `5054e4799b43b0b825eaa3094b89cae31fc39aa32fc70081df7017522fda3572`).
  That proof does not accept its ergonomics. The corrected candidate replaces
  its generic defaults with HarkinianPad-derived, physically accepted low-grip
  phone/tablet geometry, adds pressed-state feedback and a lifecycle-safe
  hold-to-latch Z control, and keeps AnnePad's direct analog N64 input bridge.
  It builds and runs on the iPad Simulator; touch navigation, editor/reset, and
  one background/foreground cycle passed. A timed Z-latch and sustained-battle
  rerun plus physical-device acceptance remain required.
- A temporary source-local counter at RT64's actual Metal swap-chain present
  call measured the validation candidate on the iPad Pro 11-inch (M4), iOS
  18.5. In the title/attract path it reached the scene's observed 30 Hz ceiling
  briefly but commonly delivered 3-17 presents/s, with other one-second samples
  in the high teens and twenties. The probe was removed after collection and
  the locked source tree again passes verification. This proves that the user's
  visible slowdown was real for this artifact; it does not establish release
  device performance because the measured AOT core was deliberately `-O0`.
- Simulator release builds are now first-class: `build-ios-core.sh simulator
  release` produces a separate `-O2` core, and `build-ios-simulator.sh` defaults
  to that optimized product. The complete arm64 iPhoneSimulator release core
  passed the no-dynamic-code audit. Archive SHA-256 values are
  `739c584e9288ab997b39e235ee138f8ed65f4b1c40a47fdc3321c4b54a0b41ca`
  (AnnePad core),
  `c3e38dfc6e8b454ed4ba9c70d0c4b9797da44cf789a70400e79eace04507c784`
  (AOT game),
  `f3f964d4006be20857d402083b94b54a7ab16dabc0bef7a7be2da5d31d575a76`
  (`librecomp`), and
  `2fe6acd7e4f91add2b19bd467d16138b5fabbc14609cdf9da327b3bb1589f440`
  (`ultramodern`). The clean Release Simulator executable is arm64,
  `platform IOSSIMULATOR`, minimum iOS 16.0, profile-marked `release`, ROM-free,
  and hashes to
  `e56f2415e079ad7bd5baf20db3f39c15b69506bb9670ec038e1e041546f33af8`.
- The optimized app installed over the existing private ROM/save state and
  visibly rendered full-resolution title, menu, and battle-attract scenes.
  A/Start touch navigation, editor resize/reset/done, and Home/resume passed.
  A temporary present counter was then removed and exact-source verification
  passed. A live five-second process sample identified synchronous
  `MTLSimDriver` descriptor/XPC work as the dominant non-idle sampled path;
  that is Simulator evidence and does not predict physical iPad performance.
- On an iPhone 16 Pro Simulator, a cold launch with no ROM presents an upright
  native setup screen. The document picker imported the user's local `.v64`,
  normalized and validated it to the exact 32 MiB supported image, stored it
  privately with backup exclusion/file protection, and launched the game.
  Remove and replacement flows were also exercised. Evidence:
  `evidence/m6-ios-native-rom-setup.png` (SHA-256
  `7cd68193c5849d0d4f60631f35d0a9554bf51f9682c57a22dc60e930350ac01f`).
- Save commits now serialize snapshots, rotate a backup, atomically replace the
  primary, flush on background/termination and before file swaps, validate exact
  sizes, quarantine corrupt primaries, and restore valid backups. Simulator
  background/foreground returned to a live upright frame; deliberate corruption
  of the isolated Simulator primary recovered from backup and preserved the
  3,100-byte corrupt input as `.corrupt`. Evidence:
  `evidence/m7-ios-resume-after-background.png` (SHA-256
  `5d213cbd88c7e8441d5c788ff1ab137b13c4f41a423e1e36681b0671d31ac03f`).
- Recovery primary and backup were each exactly 131,072 bytes with SHA-256
  `b5a41c3758763bbec72769fab4a2533bf2db0b6312d93d25a695f9e4b9e02260`;
  the quarantined injected file hashed to
  `aff563c400119e53f69fd4e91d55c956b60bc9851cd7ac9bbc67efa107fdca4e`.
- The release bundle now includes original AnnePad icons, an Apple privacy
  manifest, and third-party notices, while excluding the unused desktop
  launcher fonts, cartridge art, and box art. The current validation-profile
  executable is arm64 iPhoneOS, unsigned, ROM-free, and hashes to
  `9e89d4bd1a75a2d7b2760616cdee3bd4f10166532fe46e1f8cd6f4989b8d400d`.
- The separate `-O2` release core passed its no-dynamic-code audit. Its four
  archive SHA-256 values are `3c416883...` (AnnePad core), `628606e5...`
  (AOT game), `8535ef7c...` (`librecomp`), and `8325b873...`
  (`ultramodern`).
- `./scripts/package-ios.sh` produced the audited ROM-free unsigned candidate.
  Its arm64 iPhoneOS executable is 378,173,192 bytes, has no linker UUID, and
  has SHA-256
  `6453dac196bbda1631ce499fb019118df6f07cf6cf083ca485b9c788187eb27a`.
  Unsigned builds deliberately link with `-reproducible,-no_uuid`; signed
  builds retain the normal UUID for symbolication. Release builds compile out
  validation-only audio capture/synthetic hooks, `aspMain` capture/replay and
  reference-oracle sources, Ares worker, debug server/port, turbo override,
  environment autoboot, and the unavailable-transport log. The app audit
  rejects their markers and avoids `pipefail`/SIGPIPE false negatives.
- Two local package passes produced different raw ZIP hashes, as expected from
  archive timestamps, but the exact same 8-file sorted path/size/content
  manifest. Its SHA-256 is
  `b0f62f11d11bff4f9a6f15770da65b41fea6f7efc3686eca0dc18238a3c562b0`.
  This hardened candidate is committed at
  `ee4f1af807d4c9f7281668a37765d1a1760e77f2`; its full isolated clean-checkout
  rerun remains open. The preceding fail-closed clean pass used temporary
  source commit `915b171bfcf666533d39b8bcece2ce2107a3a9ae` and dependency-lock SHA-256
  `aff563c400119e53f69fd4e91d55c956b60bc9851cd7ac9bbc67efa107fdca4e`.
  That predecessor passed every fetch, generation, native macOS, Simulator,
  optimized device, app, package, and repository audit, then matched its
  retained expected manifest (`24dc9caa...d9e6`) byte-for-byte.
  The bundle contains only the executable, compiled icons/catalog, metadata,
  privacy manifest, and notices; it has no ROM, save, desktop artwork,
  provisioning profile, signature, unexpected dylib, or local developer path.
- The audited 71-file source/document baseline and later release-hardening
  checkpoint (`ee4f1af8...77f2`) are committed on `main` and backed up to the
  private GitHub repository. Local `HEAD` and `origin/main` are compared after
  each push; ignored ROM, generated, build, artifact, log, and signing material
  is not published.

## Not yet proven

- The official Windows v0.4.6 executable has not run on this Mac; no compatible
  Windows runtime is installed.
- The exact dependency graph used to build upstream v0.4.6 is not published.
- Physical controller proof and signed iPhone/iPad installation do not exist.
  Simulator touch/lifecycle proof and unsigned iPhoneOS compilation do not imply
  physical-device runtime success.
- Real-speaker audio, lock/unlock, interruptions/routes, thermal performance,
  and a touch-only battle on physical hardware remain open.
- Optimized iOS Simulator frame pacing is measured and remains below acceptance
  in heavy scenes. Across 80 one-second 30 Hz VI windows, Release averaged
  21.83 presents/s (4.44 minimum, 30.75 maximum), with 34 windows below 20.
  Static title/menu stretches often held 28-30, while battle/transition stretches
  commonly fell into the teens and low twenties. Physical iPad measurement is
  required before deciding whether this is Simulator-only overhead or a device
  release blocker.
- `xctrace` reports no attached physical iPhone or iPad, the keychain has zero
  valid code-signing identities, and no provisioning profile is installed.
- App Store compatibility and redistribution of unlicensed upstream components
  are not established.
- High-cost replay, capture, oracle, debug-server, turbo, and autoboot release
  surfaces are removed. Gameplay/render/audio configuration and lower-level
  trace toggles remain in the upstream static core; the broader release-
  configuration checklist remains open until those surfaces are classified or
  compiled out.

## Known regressions

An upright cold-launch/setup flow was re-proven on the iPhone Simulator, but a
fresh iPad Simulator boot can initially stretch the landscape-only app into a
portrait surface until the Simulator is rotated once. That cold-start iPad
orientation remains open. The desktop window close action returns from gameplay
to the launcher by design; App-menu Quit exits cleanly. Physical-device
orientation remains untested.

## Current targets

- Host tools: macOS arm64 command-line executables.
- Reference runtime: macOS arm64 native app bundle (passing).
- Passing runtime target: arm64 iOS Simulator on iPad Pro 11-inch (M4), iOS 18.5.
- Compiling target: arm64 iPhoneOS unsigned app (passing).
- Packaging target: release-optimized arm64 iPhoneOS app and audited unsigned
  IPA (passing and reproduced exactly from the isolated clean snapshot).
- External targets: signed physical iPhone/iPad runtime and controllers.

## Next concrete task

Fix the cold iPad orientation and add deterministic touch-state coverage for the
Z latch/cancellation semantics, then rebuild the device Release package and rerun
the fail-closed clean verifier. When lawful signing assets and hardware are
available, measure the same heavy battle on a physical iPad before changing the
renderer for a Simulator-specific bottleneck, and execute the signed controller,
speaker, lifecycle, thermal, and hardware touch-battle matrix. Keep public
redistribution blocked on license review.
