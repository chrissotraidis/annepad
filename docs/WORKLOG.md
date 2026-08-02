# Worklog

Append entries in chronological order. Keep raw logs and private artifacts under
ignored `logs/` or `artifacts/`; this file records sanitized durable evidence.

## 2026-07-31 12:00–12:38 CDT — Objective intake and research review

- Goal: establish the real upstream state, validate local prerequisites, inspect
  the required HarkinianPad reference, and write a proof-based port plan.
- Changed: `.gitignore`, `ref/README.md`, all initial `docs/` source-of-truth
  files, and the dependency lock.
- Commands: inspected the objective in bounded chunks; enumerated git/workspace
  state and Xcode/Simulator/toolchain; cloned/read upstream candidates and
  submodules under ignored `research/`; queried GitHub repository/release/
  issue/branch/fork metadata; inspected CMake/source/license/patch histories;
  validated the local ROM by streaming byte-order normalization and hashing.
- Result: research and self-review produced a concrete architecture and ordered
  implementation plan. No game implementation was changed.
- Evidence: exact commits and tool versions in `REPOSITORY-INVENTORY.md`;
  conclusions in `RESEARCH.md`; decisions D-001–D-010; blockers B-001–B-007.
  User ROM source MD5 was `3a7324ce816d5891dea074055690750a`; normalized
  output MD5 was `ed1378bc12115f71209a77844965ba50`, SHA-256
  `502f6082a6436012a8b61419435dec1388869a90ed870e87e2d7bee88f831519`.
- Remaining issue: exact upstream v0.4.6 dependency graph and executable Windows
  runtime evidence are unavailable; macOS port and every iOS gate remain open.
- Next action: implement the locked source fetch/verification path, provision the
  host generation prerequisites, reproduce AOT output, and start Milestone 0.

## 2026-07-31 12:38–13:09 CDT — Locked source graph and AOT generation

- Goal: turn the research baseline into a reproducible, private-input static
  recompilation pipeline.
- Changed: source fetch/verify, ROM normalization, host-tool build, patch
  application, generation, and repository-policy scripts; three maintained
  compatibility patches; status/history/blocker records.
- Resolved: AppleClang/fmt consteval incompatibility, venv bypass during asset
  extraction, optional host syntax-check failures, Apple `ar` discarding MIPS
  members, and a native-IDO EUC-JP escape-state mismatch.
- Evidence: both host tools are arm64; the reconstructed ROM MD5 is
  `ed1378bc12115f71209a77844965ba50`; 1,006 generated files have manifest hash
  `cfb9d1e10d30a43ed2b3f9be439842e2bb7a6ae557ee75f38a9c24fdbfda57d2`;
  source and repository verification scripts pass.
- Remaining issue: the official Windows runtime is still unavailable locally,
  and the native macOS runtime/battle gate has not started.
- Next action: configure the generated game with its pinned runtime and renderer
  for arm64 macOS, then launch and play the complete rental-battle gate.

## 2026-07-31 13:09–14:51 CDT — Native arm64 macOS rental battle

- Goal: build the generated game/runtime/renderer as a native Apple Silicon app
  and complete the Milestone 1 interaction gate rather than stopping at compile.
- Changed: maintained Apple compatibility, non-Windows platform, main-thread
  input, Metal-window, native-bundle, and latched-keyboard-tap patches; macOS
  build/run scripts; source verification; result evidence.
- Resolved: Apple API/compiler differences, Linux-only debug/platform symbols,
  AppKit event polling from the game thread, a null Metal layer that rendered a
  black window, raw-executable app identity, and missed short keyboard taps.
- Evidence: `AnnePad.app` contains a Mach-O arm64 binary with SHA-256
  `0eb8b5fbb009b4dc46b13525b0a5d13b8ce9373879ff849d73981d75831941e7`;
  runtime selected CoreAudio at 48 kHz and a real SDL Metal view; a complete
  three-on-three Battle Now match reached the explicit result screen at
  `evidence/m1-macos-rental-battle-result.png`.
- Interaction: selected a rental team, issued moves, switched twice after
  knockouts, resolved every opposing and player rental, then observed the final
  `LOSE`/`WIN` state. The app remained live, returned to its launcher on window
  close, relaunched to the title screen with its save present, and exited 0 via
  the native application menu.
- Verification: all maintained patches pass forward/reverse checks;
  `verify-sources.sh`, `test-repository.sh`, and `build-macos.sh` pass.
- Next action: retain this runtime as the regression target while separating
  platform services and compiling iOS no-dynamic-code static archives.

## 2026-07-31 14:51–15:47 CDT — Static iOS core separation

- Goal: prove that the complete generated game and target-neutral runtime can
  compile for arm64 iPhoneSimulator without runtime code generation or dynamic
  plugin loading.
- Changed: strict N64ModernRuntime/N64Recomp compile profiles, an Apple core
  target and audit, maintained RT64/iOS preparation patches, and initial native
  app-shell/build inputs. Consolidated overlapping game patches into one
  forward/reverse-verifiable Apple platform patch.
- Evidence: `build-ios-core.sh` built and audited the 933 MiB AOT archive plus
  AnnePad/librecomp/ultramodern archives. No LiveRecomp/sljit build entry or
  forbidden dynamic-loading/JIT symbol was present. Required archive hashes are
  recorded in `STATUS.md`.
- Regression: the default strict option remains off and the macOS target still
  builds after the runtime changes; the complete rental-battle result remains
  the behavioral baseline.
- Next action: build/install the ROM-free iOS Simulator bundle, inject the
  private ROM into its container, and visually prove the first native frame.

## 2026-07-31 15:48–16:14 CDT — Native iOS Simulator first frame

- Goal: link the audited AOT/runtime core into a ROM-free native iOS app and
  prove the selected Metal renderer through visible Simulator output.
- Changed: pinned a static Metal-only SDL2 build, added the native UIKit/SDL app
  shell and iOS CMake target, cross-built RT64 shaders with host tools, added an
  iOS null file-dialog backend, and allowed the host-backed Simulator Metal
  device while preserving physical-device family checks.
- Evidence: the arm64 iPhoneSimulator app built and installed on an iPad Pro
  11-inch (M4), iOS 18.5. The private ROM remained outside the bundle in the app
  data container. Metal rendered live opening/title/game imagery; evidence and
  executable hashes are recorded in `STATUS.md`.
- Regression: source patch forward/reverse verification and the strict core
  audit still pass. Cold launch can begin 180° from the Simulator chrome and is
  carried into the next orientation gate rather than hidden.
- Next action: enumerate physical hardware/signing, build the device target,
  and prove controllers on iPhone and iPad.

## 2026-07-31 16:14–17:27 CDT — Unsigned iPhoneOS compile proof

- Goal: resolve the device-target build surface independently from the external
  hardware/signing gate.
- Changed: parameterized the strict core build/audit for Simulator versus
  iPhoneOS, added a pinned static Metal-only SDL device build, and added the
  ROM-free unsigned `build-ios-device.sh` path.
- Evidence: all four arm64 iPhoneOS core archives passed the no-dynamic-code
  audit. Xcode then built `build-ios-app-device/Release/AnnePad.app`; its
  executable declares iOS 16.0/SDK 26.5 and hashes to
  `d97a33ba3159d5caac45c5cb9a5d62fb7b479374d2a060ee45e5589c22be2c29`.
  The 816 MiB bundle contains no ROM and is intentionally unsigned.
- External gate: `xctrace` reports only the Mac as a physical device; the
  keychain has zero valid signing identities and there are zero provisioning
  profiles. No account or signing state was changed.
- Regression: Simulator core audit, maintained patch verification, repository
  tests, and source cleanliness checks remain the next post-doc verification.
- Next action: keep hardware/controller acceptance open and begin the normalized
  customizable touch layer in Simulator.

## 2026-07-31 17:27–19:03 CDT — Customizable multitouch rental battle

- Goal: prove the complete base-game loop through native touch without a
  keyboard or controller.
- Changed: added a UIKit overlay with every N64 control, independent touch
  ownership, analog geometry, cancellation/background reset, and edit controls
  for position, size, opacity, visibility, reset, and phone/tablet persistence.
- Runtime fixes: hardened audio DMA recovery for stale exact and high-level
  handlers and added a structural guard encountered during sustained battle.
- Evidence: played Squirtle/Pikachu/Bulbasaur against
  Oddish/Magnemite/Meowth through all knockouts and the explicit `LOSE` result
  using touch only. Durable result SHA-256 is recorded in `STATUS.md`.
- Gate boundary: this passes Simulator touch behavior, not physical-device
  ergonomics, safe-area, audio, thermal, or full-battle acceptance.

## 2026-07-31 19:03–19:43 CDT — Native first-run ROM setup

- Goal: replace private-container provisioning with a legal native first-run
  import and management flow.
- Changed: added native setup and manager controllers, document-picker import,
  z64/v64/n64 normalization, exact size/MD5 rejection, atomic private storage,
  file protection, backup exclusion, replace/remove, and setup-state config.
- Evidence: on an iPhone 16 Pro Simulator, remove cleared all app copies, cold
  launch showed an upright landscape setup screen, the picker imported the
  private `.v64`, the normalized private file matched exactly, and gameplay
  started. The temporary local transfer server was stopped afterward.
- Boundary: no ROM content entered git, the app bundle, evidence metadata, or
  documentation.

## 2026-07-31 19:43–20:23 CDT — Atomic saves and lifecycle recovery

- Goal: make persistence survive backgrounding and recover deterministically
  from an interrupted/corrupt primary.
- Changed: serialized save snapshots; platform-correct atomic replacement;
  primary/backup rotation; flush before background, termination, quit, and save
  swaps; exact-size validation; corrupt quarantine; valid-backup restoration;
  and foreground audio resume. Added a maintained runtime patch with
  forward/reverse verification.
- Evidence: Simulator background/foreground returned to a live frame; exact
  131,072-byte primary/backup files were created; an isolated deliberately
  corrupted primary recovered from backup, and the invalid input remained in a
  `.corrupt` quarantine. Hashes and screenshot are recorded in `STATUS.md`.
- Remaining: physical audio route/interruption, lock/unlock, speaker, update,
  forced-termination, and hardware persistence acceptance.

## 2026-07-31 20:23–20:47 CDT — Release surface and IPA audit implementation

- Goal: remove unused launcher media and create a release-profile package that
  cannot inherit compatibility-build or stale-bundle content.
- Changed: added original app artwork/asset catalog, launch declaration, privacy
  manifest, third-party notices, build-profile marker, `-O2` AOT release mode,
  app/IPA audits, canonical uncompressed-content manifest, packaging script, and
  committed-HEAD clean-checkout verifier. Device builds now recreate only the
  known app product before linking so removed resources cannot persist.
- Evidence so far: the validation-profile arm64 iPhoneOS app passes architecture,
  platform, dependency, privacy, icon, signature/profile, ROM/save, and asset
  audits. The release-profile AOT build is in progress; IPA completion is not
  claimed in this entry.

## 2026-07-31 20:47–21:44 CDT — Release-profile unsigned IPA reproduced

- Goal: finish the optimized static core, assemble the unsigned device payload,
  audit it, and independently reproduce its canonical uncompressed content.
- Changed: added source-prefix mapping to the device app compile, declared the
  `mach_absolute_time` timer use as privacy category System Boot Time reason
  `35F9.1`, and required that declaration in the app audit.
- Evidence: the four `-O2` arm64 iPhoneOS core archives passed the no-dynamic-
  code audit; Xcode built the 378,470,288-byte release executable with SHA-256
  `03413dd80f0b83ed8e5287c92f8a5ed29fd948f26ae8ffd1e361dbc56e27c7db`.
  The app audit found only Apple system dependencies and no signature/profile,
  ROM/save, desktop art, prohibited runtime marker, or developer path.
- Package result: the primary 84,685,766-byte IPA hashes to
  `4febac64e0850b82f8765671629f7c40060cf4485cb9b4021452f8d05bf06ed0`.
  A second archive has the same size and a different raw ZIP hash, but `cmp`
  proved both 8-file canonical manifests identical; their manifest SHA-256 is
  `763940c56bd642eb9b704210dae88e39b020f25601c93201fffe592873ede46c`.
- Recovery: the first package invocation reached the completed core but its
  long-lived Bash process encountered the device script while that file was
  being rewritten. Fresh Bash and Zsh syntax checks passed, and rerunning from
  the cached audited core completed without changing the script again.
- External/repository gates: the clean-checkout verifier failed closed because
  AnnePad has no committed `HEAD`; no physical device, signing identity, or
  profile exists. Signed install, hardware runtime, and public release remain
  open.

## 2026-07-31 21:44–2026-08-01 02:39 CDT — Clean-checkout package reproduced

- Goal: run the complete verifier from an isolated committed source snapshot,
  compare it with the working release output, and close any deterministic-build
  defect without publishing private or generated material.
- First pass: fresh fetch, host-tool/AOT reconstruction, macOS build, Simulator
  and device static-core builds, release app, package audits, and repository
  policy all passed. Every bundled resource matched the working candidate, but
  the app binary differed because Apple `ld` emitted a fresh Mach-O UUID.
- Root cause and change: minimal repeated-link probes reproduced the random UUID
  difference. Unsigned device builds now pass `-Wl,-no_uuid`, and the app audit
  requires UUID absence for unsigned products while retaining the normal UUID
  requirement for signed products.
- Local proof: the rebuilt 378,470,288-byte executable has SHA-256
  `5658a61da4479fbf1d388f866f0ef89c2131634b1121097a818785b1ef0cab51`.
  Two package passes had different raw ZIP hashes but identical 8-file canonical
  manifest SHA-256
  `9d7881b1cc72d6fdfdd9a39443f233e2c1379cd2a92c6527f27bc46821d1dfab`.
- Independent proof: temporary snapshot commit
  `83c327fe925f9ac992ed3263814983f9d261a6b2`, with dependency-lock SHA-256
  `aff563c400119e53f69fd4e91d55c956b60bc9851cd7ac9bbc67efa107fdca4e`,
  passed the complete clean verifier. Its binary hash and canonical manifest
  exactly match the local release. Sanitized reports are under ignored
  `logs/clean-checkout-latest/`.
- Remaining gates: the working repository still has no commit and has not been
  backed up to GitHub. Physical devices, signing/profile assets, controller,
  real-speaker audio, lifecycle/performance, hardware touch-battle, and public
  license review also remain open.

## 2026-08-01 — Fail-closed release reproduction restored

- Goal: resolve the later 483-byte cross-checkout executable delta introduced
  during release-diagnostic hardening and prevent an internally consistent but
  externally different package from being reported as reproduced.
- Diagnosis: repeated local links were stable only after Apple `ld` received
  both `-reproducible` and `-no_uuid`; removing the UUID alone did not constrain
  all link-layout decisions for the hardened binary.
- Verifier change: `verify-clean-checkout.sh` now requires an absolute
  `--expected-manifest` input and uses `cmp` plus a readable diff to fail on any
  canonical package difference.
- Local proof: repeated relinks produced the same 378,469,952-byte executable
  SHA-256 `e6b2ab11cee127b5f2cb89f7318b1e03138e31d3f93e6fb98184f90e119ef363`.
  The audited retained IPA manifest hashes to
  `24dc9caa60851e6a204c6435ff7a9054b84dccac4ff8a3999b999024cfe7d9e6`.
- Independent proof: temporary snapshot commit
  `915b171bfcf666533d39b8bcece2ce2107a3a9ae` rebuilt exact sources and AOT,
  native macOS, Simulator, optimized device core/app, and the unsigned IPA.
  Every audit passed and the expected manifest comparison was byte-identical;
  sanitized evidence is under ignored `logs/clean-checkout-latest/`.
- Remaining: publish the audited source baseline, then keep signed physical
  iPhone/iPad, controller, speaker/audio-route, lifecycle/performance,
  hardware touch-battle, and licensing gates open until directly tested.

## 2026-08-01 — Private GitHub baseline published

- Authorization and scope: after explicit user approval, reviewed the 71-file
  intended baseline and confirmed the GitHub repository is private and empty.
  The staged index passed repository policy and contained no forbidden ROM,
  save, generated, IPA, signing, credential, or build material.
- Publication: created root commit
  `136d145287d3374b93a3dfe0275a46980df85b9c` directly on `main`. A pull request
  was not possible or useful because the remote had no base commit or branch.
- Transport recovery: the first image-bearing HTTPS push returned HTTP 400;
  the remote still had zero heads. Retrying the same push with a 15 MiB HTTP
  post buffer succeeded, then a fetch and SHA comparison proved local `HEAD`
  and `origin/main` identical.
- Boundary: this is a private source backup, not a public or signed release.
  Physical iPhone/iPad, controller, real-speaker audio, lifecycle/performance,
  hardware touch-battle, signing, and licensing gates remain open.

## 2026-08-01 — Release-only diagnostics hardening

- Inventory: the release executable still contained high-cost offline replay,
  Ares reference-oracle, `aspMain` capture/spike hooks, debug-server, turbo, and
  environment-autoboot surfaces, including large diagnostic rings in the app
  target.
- Change: source commit `ee4f1af807d4c9f7281668a37765d1a1760e77f2`
  adds a maintained patch that compiles those surfaces out only for the iOS
  release profile. Validation builds retain them; native `aspMain`, touch,
  controller, ROM setup, renderer configuration, saves, and voluntary
  preemption remain intact.
- Audit correction: reproduced a false negative caused by `strings | rg -q`
  under `pipefail`, switched executable scans to process substitution, and
  proved the old `PSR_AUTOBOOT` marker failed before rebuilding. The rebuilt
  candidate contains none of the targeted markers and passes the expanded app
  and IPA audits.
- Evidence: binary size 378,173,192 bytes, SHA-256
  `6453dac196bbda1631ce499fb019118df6f07cf6cf083ca485b9c788187eb27a`,
  UUID absent. Two local packages had different raw ZIP hashes but identical
  eight-file canonical manifest SHA-256
  `b0f62f11d11bff4f9a6f15770da65b41fea6f7efc3686eca0dc18238a3c562b0`.
- Remaining: rerun the full fail-closed isolated verifier for this exact
  hardened digest. Physical signing/install, controller, real-speaker audio,
  lifecycle/performance, touch battle, and licensing remain open.

## 2026-08-01 — Live iPad rerun and HarkinianPad touch correction

- Goal: answer whether AnnePad still runs on this Mac's iPad Simulator and
  verify that the preferred `ref/harkinianpad` touch mechanism was actually
  used.
- Runtime evidence: booted the iPad Pro 11-inch (M4), iOS 18.5 Simulator;
  relaunched the retained ROM-free AnnePad install as PID `21296`; observed
  live Metal gameplay, the full touch surface, successful A input, and 48 kHz
  audio initialization. Six samples over roughly two minutes kept the same PID
  alive and produced changing framebuffer hashes. Home/background and relaunch
  returned on the same PID to an upright, advancing frame in the visible
  Simulator UI. A fresh boot can initially present the Simulator in portrait
  until it is rotated once; that cold-start orientation remains open.
- Touch audit: AnnePad had reused design principles but not HarkinianPad's
  proven control/state implementation. The working correction adapts the
  accepted low-grip phone/tablet defaults, pressed/latched feedback, Z
  hold-to-latch haptic, and cancellation rules while retaining direct analog
  normalized N64 input. The saved-layout keys move to `v2` so old generic
  geometry cannot mask the new defaults.
- Documentation correction: removed the unsupported statement that Apple
  touch/lifecycle unit tests already exist. The repo currently has policy,
  build, and artifact audits; a real touch/lifecycle unit-test target is open.
- Remaining: compile/install/playtest this corrected source, exercise the latch
  and editor, complete the current clean verifier, and repeat the full touch
  and stability gate on physical iPhone/iPad.

## 2026-08-01 — iPad frame pacing measured and build profile corrected

- Observation: the corrected HarkinianPad-derived candidate built, installed,
  reached the title and menus through touch, kept the editor operational, and
  survived a short Home/relaunch cycle. A fresh iPad boot can still require one
  Simulator rotate before the landscape surface is correct.
- Diagnosis: the app linked `build-ios-core-simulator/`, whose generated AOT is
  deliberately `-O0`. A temporary, environment-gated counter immediately after
  RT64's Metal swap-chain present measured many title/attract windows at 3-17
  presents/s, with brief high-twenties/30 Hz windows. That confirms the visible
  unevenness without confusing process survival for performance acceptance.
- Tool fallback: Metal HUD logging emitted no useful Simulator metrics and an
  attached Game Performance `xctrace` run did not finish a valid trace. The
  narrow source probe supplied the direct evidence and was removed afterward;
  exact-source verification passes again.
- Build correction: release-optimized Simulator cores are now supported in a
  separate ignored tree, and `build-ios-simulator.sh` defaults to that product.
  The retained `-O2` build completed 283 of 1,110 steps before this checkpoint;
  the remaining large AOT files require a multi-hour compile on this 16 GB Mac.
- Remaining: finish/install the optimized candidate, repeat frame pacing in the
  same title and an animated battle, verify timed Z latch/cancellation and cold
  iPad orientation, then rebuild/package and rerun the isolated verifier.

## 2026-08-01 — Optimized Simulator completed and measured

- Build: completed and audited the retained `-O2` arm64 iPhoneSimulator core,
  then built the profile-marked Release app. The clean executable hashes to
  `e56f2415e079ad7bd5baf20db3f39c15b69506bb9670ec038e1e041546f33af8`.
- Runtime: installed without erasing private ROM/save state and visibly proved
  full-resolution title, menu, and battle-attract rendering. A/Start navigation,
  editor resize/reset/done, and Home/resume passed on iPad Pro 11-inch (M4),
  iOS 18.5.
- Performance: title/menu stretches commonly held 28-30 presents/s, but 80
  one-second windows with a reported 30 Hz VI rate averaged 21.83 presents/s;
  34 were below 20. Release is improved, not accepted for heavy Simulator scenes.
- Diagnosis: live sampling pointed to synchronous `MTLSimDriver` descriptor/XPC
  overhead. A Simulator-only half-resolution experiment improved cadence but
  visibly shrank the game surface to the upper-left quarter, so it was reverted.
  The present counter and file sink were also removed; full-resolution Release
  rebuilt successfully and exact-source verification passes.
- Remaining: physical iPad battle/thermal measurement, cold iPad orientation,
  timed Z latch/cancellation coverage, new device package/clean verifier, and
  signed controller/speaker/lifecycle acceptance.

## 2026-08-01 — Cold iPad overlay geometry stabilized

- Reproduction: launched the clean Release app after two separate portrait-origin
  iPad Simulator shutdown/boot cycles. Both rotated into landscape without a
  manual toolbar rotation, but the second intermittently pushed controls off
  both edges while UIKit/SDL settled their view bounds.
- Fix: replaced the overlay's initial-frame/autoresizing attachment with four
  Auto Layout edge constraints to the live root host. This keeps the HarkinianPad-
  derived normalized geometry tied to the actual play surface through cold
  rotation and SDL view transitions.
- Proof: rebuilt and installed the optimized Release app, repeated the
  portrait-origin cold boot, and inspected startup at three timed intervals.
  The overlay stayed complete and correctly positioned throughout visible live
  gameplay. The ROM-free arm64 Simulator executable hashes to
  `ca173975eb88915f4e2c3e151087d4808a731caf6ad820c8970ca77faa817b9d`.
- Remaining: deterministic Z latch/cancellation coverage and physical-device
  orientation/ergonomics acceptance.

## 2026-08-01 — Device package rebuilt and stale-app guard closed

- Reproduction: the first package command audited and archived the previous
  `6453dac1...b27a` device binary because `package-ios.sh` rebuilt only when the
  Release app was missing or profile-invalid. Source changes alone did not
  invalidate that existing product.
- Fix: default packaging now always invokes the canonical device Release build.
  `--no-build` is the explicit existing-product path, and caller-supplied apps
  remain audit-only and are never replaced.
- Result: the rebuilt ROM-free unsigned arm64 iPhoneOS executable is
  378,174,464 bytes with SHA-256 `f6e5eacc...ddf2`, no UUID, signature, or
  provisioning profile, and Apple-system-only dynamic dependencies. Its package
  passed both app and IPA audits.
- Reproduction: the rebuild/package pass and a separate `--no-build` pass had
  different raw ZIP hashes but identical eight-file canonical manifest SHA-256
  `416db7aaad51bda6b46ca78801a35ec2eb5d0150d295da02ed690e2297c4b829`.
  A committed clean-checkout comparison remains open.

## 2026-08-01 — Identical Metal descriptors no longer re-encode

- Diagnosis: a second live sample confirmed that synchronous Simulator
  `MTLArgumentEncoder` descriptor calls and their XPC replies remain the largest
  non-idle rendering cost after the Release-profile correction.
- Fix: retained each descriptor entry's resource, sampler, buffer offset, and
  range type, and skipped the encoder call only when all four values were
  unchanged. The change is maintained in the RT64 patch rather than left in the
  ignored source checkout.
- Measurement: across 117 one-second windows reporting a 30 Hz VI rate during
  intro, menus, and rental-battle setup, the candidate averaged 23.40
  presents/s (12.74 minimum, 30.83 maximum); 20 windows were below 20 and 22
  reached at least 28. The earlier pre-cache run averaged 21.83 across 80 such
  windows, with 34 below 20. The scene mixes were not frame-identical, so this
  is directional evidence rather than a final benchmark.
- Runtime proof: removed the counter/file sink, rebuilt Release, installed it
  on iPad Pro 11-inch (M4), and visibly confirmed full-size animated rendering
  plus Start touch into Game Pak Check. The clean Simulator binary hashes to
  `3f0e291d...2dfe` and source verification passes.
- Package proof: rebuilt the ROM-free unsigned device app. Its 378,174,464-byte
  binary hashes to `4f55bc82...4586`. A normal package and separate
  `--no-build` pass produced raw ZIP hashes `6094e223...a1f5` and
  `dcf6fbd9...e096`, but the same canonical manifest
  `75bea9dbba5bfe65d7ee5ddf73b4d2d7eddb10d0282b2806873d88758c188ff7`.
- Remaining: performance acceptance stays open because changing descriptors
  still dominate the Simulator sample. Physical iPad measurement is required
  before a broader renderer rewrite; the isolated clean verifier also needs a
  rerun for this exact source digest.

## 2026-08-01 — Fresh performance and completion audit

- Reframed the work into separate cadence, shipping-surface, touch-acceptance,
  and physical-device gates instead of treating every symptom as generic FPS.
- Tested RT64's real internal-resolution multiplier. A 1x run remained
  full-screen but visibly pixelated and did not improve cadence over the default
  3x path, rejecting fill rate as the leading Simulator hypothesis.
- Found that depth-backed Metal color clears created a new depth-stencil state
  and never released it. Added one cached no-depth-write clear state, reused it,
  and released both cached clear states at teardown. Release builds and renders;
  the change is retained as a correctness/leak fix without claiming a measured
  FPS breakthrough.
- Found 838 non-counter Release diagnostic lines in the observed title/attract
  window. The probes are interleaved with load-bearing fragment, scheduler, and
  audio-UAF hooks, so the next slice will compile only diagnostic work out and
  then repeat timing.
- Confirmed the current touch layer adapts HarkinianPad grip layouts,
  customization, feedback, Z latch, and cancellation while intentionally using
  a direct analog N64 bridge. Quick-tap latching exists, but its shared poll
  window and cancellation edges still require deterministic tests and a full
  battle with the corrected overlay.
- Added `PERFORMANCE-AND-COMPLETION-AUDIT.md` as the ranked evidence and decision
  record.
- Clean proof: after removing the temporary counter, the Release Simulator app
  rebuilt, rendered full-size animation, and accepted Start into Game Pak Check;
  its executable hashes to `0e4b09eb...a50f`. The unsigned arm64 iPhoneOS app
  passed audit at 378,174,464 bytes with SHA-256 `cd205ee8...338a`. A normal
  package and separate `--no-build` pass produced raw ZIP hashes
  `c5ccb45d...8e5f` and `25d85e91...2ef1`, with identical canonical manifest
  `ef38239ac11403538c9bb5a5ba1542c53f80b7c84c2c570ce13a68879aaa0ccd`.

## 2026-08-01 — Release hook cleanup and source-consistent app rebuilds

- Classified explicit `game.toml` hooks instead of removing the diagnostic and
  correctness surfaces together. Release now erases 96 diagnostic calls and
  their arguments; fragment registration/cleanup, GB audio, fragment
  input/resolve, and audio-UAF voice protection remain.
- Added a Release core audit that permits only the three expected
  `pkmnstadium_*` references. The updated Simulator archive passed it.
- Found that app build scripts reused an existing AOT archive after generated
  source changed. Both Simulator and device entry points now always run the
  incremental core build before linking.
- Local proof rebuilt the 38 generated units containing changed hooks and
  refreshed the archive; the conservative full dependency rebuild remains the
  published path and the exact clean-checkout rerun remains open.
- The final clean iPad Pro 11-inch (M4), iOS 18.5 run rendered animated attract
  mode and accepted Start touch into Game Pak Check. Its executable is
  380,988,840 bytes with SHA-256
  `609ecfa0ca06f5c103d2a019a21a87187e728d7ba8275ac7d9b3e34448f19b9f`.
- Targeted reverse-engineering probe output fell to zero (95 total stderr lines,
  8,243 bytes). A temporary 29-window present counter averaged 23.31 presents/s
  (4.15–30.56; five below 20, seven at least 28), showing that diagnostics were
  not the leading FPS cause. The counter was removed before the final rebuild.

## 2026-08-01 — Independent touch tap lifetimes

- Replaced the overlay's shared tap countdown with 16 independent atomic
  counters, one per N64 button bit. A later R/L/Z tap can no longer extend an
  unrelated quick A/B/Start tap.
- Added a host-compiled test covering exact six-poll expiry, the 45-poll
  shoulder window, overlapping A+R without cross-extension, Z clearing, and
  lifecycle cancellation. It is part of `test-repository.sh`.
- The Release iOS Simulator target rebuilt successfully. On iPad Pro 11-inch
  (M4), iOS 18.5, quick Start taps returned from attract mode and advanced into
  Game Pak Check. The clean executable is 380,988,920 bytes with SHA-256
  `73d456b930fe0501840ffb544d7f05a61320cb3c30cd2a9faeb0675663fa077b`.
- Timed UIKit Z-latch and full corrected-overlay battle acceptance remain open.

## 2026-08-01 16:25–16:52 CDT — Corrected-overlay rental battle acceptance

- Goal: replace the historical bespoke-overlay battle proof with a complete
  run using the corrected HarkinianPad-derived touch layer.
- Runtime: on iPad Pro 11-inch (M4), iOS 18.5, used touch only to pass Game Pak
  Check, enter Battle Now, select Squirtle/Pikachu/Bulbasaur, issue battle moves,
  replace fainted rentals, and resolve Psyduck/Oddish/Meowth.
- Result: reached the explicit `LOSE` screen after all six rentals resolved and
  pressed A to return to the main selection menu. No crash or stuck input was
  observed. Long battle animations and transitions remained visibly uneven,
  consistent with the measured Simulator cadence blocker.
- Evidence: `docs/evidence/m5-ios-touch-rental-battle-corrected-result.png`
  hashes to
  `1b931d2d684884fdac983086a4ddb4a439c7d868d1ba1e4a7da9d07bb449b0f3`.
- Boundary: a desktop gesture-driver drag did not trigger the blue timed Z
  latch, so that UIKit gate is not claimed. Physical-device touch, controller,
  speaker, lifecycle, and performance acceptance also remain open.
- Next: build a duration-controlled Z UI test, then rebuild/reproduce the exact
  current unsigned device package and clean-checkout verifier.

## 2026-08-01 16:55–17:25 CDT — Memory-bounded device core rebuild

- Goal: rebuild the exact current optimized iPhoneOS core instead of packaging
  the older source-inconsistent archive.
- Observation: bare `cmake --build --parallel` launched eight optimizers for the
  2.60 GiB / 1,003-file generated C set on this 16 GB Mac. The system entered
  heavy compression and swap churn; individual compiler processes received
  roughly 15–40% CPU while progress dropped sharply.
- Changed: `build-ios-core.sh` now accepts a validated positive
  `ANNEPAD_BUILD_JOBS` limit, documented in `BUILDING.md`.
- Proof: `ANNEPAD_BUILD_JOBS=0` fails clearly, shell syntax passes, and a resumed
  `ANNEPAD_BUILD_JOBS=2` package build runs exactly two compiler workers at
  roughly 75–85% CPU each while preserving completed incremental objects.
- Remaining: the long optimized build is still running; app, package, and
  canonical-manifest evidence must not be claimed until it finishes and audits.

## 2026-08-01 17:25–2026-08-02 01:18 CDT — Reproducible unsigned device package

- Goal: finish the exact current device build, audit and reproduce its unsigned
  IPA, then prove that pushed source can rebuild the same candidate elsewhere.
- Local result: the optimized arm64 iPhoneOS app passed audit at 378,199,272
  bytes with executable SHA-256 `8d1f440fc89820b346321145382b8eb41e9fa0817a94ecc1d8054f2b32a94494`.
  Two package passes had timestamp-dependent raw ZIP hashes but the exact same
  eight-file canonical manifest SHA-256
  `fcb2832e27b0a082268c9838b4edf8b9dc1ece80c16b5755d7c68186c6b7b590`.
- Clean proof: with `ANNEPAD_BUILD_JOBS=2`, a no-hardlink isolated clone of
  source commit `15a79de423458683370c6fb9bd0a7fa18288979d` fetched locked dependencies,
  regenerated AOT, built native macOS, Simulator, optimized iPhoneOS, audited
  the app/IPA, ran touch-latch/repository tests, and reproduced the executable
  and canonical manifest exactly. Dependency-lock SHA-256 was
  `aff563c400119e53f69fd4e91d55c956b60bc9851cd7ac9bbc67efa107fdca4e`;
  sanitized ignored evidence is under `logs/clean-checkout-latest/`.
- Boundary: this proves source/package reproducibility, not signed installation
  or physical iPad FPS, controller, touch, speaker, lifecycle, or thermal
  acceptance. Timed UIKit Z-latch acceptance also remains open.

## 2026-08-02 02:00–02:16 CDT — Pokémon Stadium-specific Z control audit

- Question: determine whether HarkinianPad's 0.5-second persistent Z latch is
  useful for Pokémon Stadium holds or combinations rather than inheriting it
  solely from a Zelda-oriented reference port.
- Evidence: the original Stadium battle instructions use R plus a Pokémon
  button to inspect data and held L to reveal hidden Pokémon/move assignments.
  Z is a cancel/reset-style press. The decompiled game checks `buttonPressed`
  for its identified Z actions; only a generic list-navigation helper reads
  held Z to accelerate scrolling. No Z-plus-button gameplay chord was found.
- Decision: remove persistent Z toggling and its haptic/latched visuals. Z still
  follows ordinary touch-down/touch-up hold semantics, and the independent
  short-tap bridge still preserves taps across runtime polls.
- Proof so far: the focused host touch-tap test passes and source diff checks
  pass. The full source-consistent Release Simulator rebuild is in progress;
  UIKit runtime acceptance is not claimed yet.

## 2026-08-02 02:16–03:40 CDT — Exact-source Simulator rebuild and runtime proof

- Built the complete Release Simulator graph with the Stadium-specific
  non-latching Z change and contiguous Metal descriptor batching. The static
  core audit, maintained patch forward/reverse checks, dependency build, and
  Xcode app link passed.
- Installed the ROM-free app on the iPad Pro 11-inch (M4), iOS 18.5 Simulator.
  The preserved private user ROM booted into the animated attract path; two
  captures showed different rendered scenes and PID 69075 remained alive
  through a 12-second process sample.
- The 380,988,632-byte Simulator executable SHA-256 is
  `19bcd1cfef6f0fbaaac31acb046128baa748f87e5e231853de4a4c960b57b540`.
  The workload thread spent 3,928 of 6,849 samples waiting on its command fence
  and 265 on its mutex. Bulk argument-encoder calls replaced the earlier
  repeated single-entry setter hotspot; this is directional Simulator evidence,
  not measured FPS or physical-iPad acceptance.
- Three sanctioned Computer Use attachment attempts timed out. Direct UIKit Z
  press/release, held-L, and R-plus-selection acceptance therefore remains open
  rather than being inferred from the passing host test or visible overlay.

## 2026-08-02 03:40–08:24 CDT — Current package clean-checkout proof

- Ran the full fail-closed verifier from committed source
  `0cc91b6166126fc2156d30bba4114ffc3beb142b` in a no-hardlink clone with the
  private ROM supplied outside the clone and a four-job build limit.
- Passed fresh locked-source fetch, 1,006-file AOT generation, native macOS,
  Simulator validation core/app, optimized iPhoneOS core/app, app and IPA
  audits, repository tests, and exact expected-manifest comparison.
- Reproduced the 378,198,984-byte device executable SHA-256
  `1c2bd2e923f60f84127b97cb05a7b536f5acb245784233ebdb92de99421d6850`
  and eight-file canonical IPA manifest SHA-256
  `bd6f14bea0db2342903a91448c8bfc24cc020879a446415ee145c3eb2dfd51fa`.
  The isolated raw ZIP SHA-256 was
  `90fa70bf59264240365477fc443513d1ece7baafadc682b1054ebffb378b9f70`;
  timestamp-dependent raw ZIP bytes are not the reproducibility authority.
- The first native build still launched Ninja's default ten workers despite the
  requested package job cap, creating avoidable memory compression and swap.
  Centralized positive-integer validation and extended `ANNEPAD_BUILD_JOBS` to
  host-tool, native macOS, and iOS core builds; focused repository tests cover
  valid, zero, and non-numeric values.
- Boundary: this proves the current source and unsigned package, not signed
  installation, physical iPad performance, controller, touch, speaker,
  lifecycle, thermal, or orientation acceptance.

## 2026-08-02 08:24–08:36 CDT — Current runtime and external-gate refresh

- Confirmed local `HEAD` and `origin/main` at `cf73caa...869f`, with the bounded
  build and exact package evidence published to private GitHub `main`.
- Refreshed physical deployment prerequisites: `xctrace` listed only the Mac and
  Simulators, `devicectl` found no device, the keychain contained zero valid
  signing identities, and neither provisioning-profile location contained a
  profile.
- Relaunched the exact 380,988,632-byte Release Simulator executable
  `19bcd1cf...b540`. PID 46549 remained alive for 45 seconds and two captures
  advanced from the transient launch card to the Pokémon Stadium title path;
  no AnnePad crash report was found from the preceding three days.
- Attempted external frame measurement without changing source. The Metal HUD
  did not appear in the Simulator capture, and an attached 15-second Game
  Performance Overview trace hung during finalization and was discarded. The
  prior in-app present-window measurements remain the honest Simulator FPS
  evidence.
- Re-audited direct gesture options. This Xcode's `simctl io` has no touch
  injection, `idb`, Maestro, and AppleSimulatorUtils are absent, and the
  sanctioned UI-control bridge had already timed out three times. Direct revised
  Z/L/R UIKit acceptance remains open rather than inferred.

## 2026-08-02 08:36–08:47 CDT — Post-batching Simulator cadence measured

- Added a temporary environment-gated counter immediately after RT64's actual
  Metal present submission, rebuilt only `rt64_metal.cpp` plus the final Release
  Simulator link, and installed over the preserved private ROM/save container.
- After discarding eight startup windows, a machine-aggregated 90-window
  automatic title/attract run averaged 29.96 presents/s (27.66 minimum, 31.09
  maximum); zero windows were below 20, one was below 28, and 89 were at least
  28. This materially improves the earlier 23.31 title/attract mean.
- Removed the temporary probe and rebuilt through the official Release
  Simulator script. Maintained-source verification passed, the binary contains
  no probe marker, and the clean app visibly reached the animated title and kept
  PID 48916 alive for 20 seconds.
- The clean relink remains 380,988,632 bytes but hashes to
  `4206a896f85a74fa6eb50112acc0d6a93fda3185d5e61e524360ac457cad3ef2`
  rather than the prior same-size source-verified relink. Simulator executable
  byte reproducibility is not claimed; the UUID-free device executable and
  canonical IPA manifest remain the reproducibility authority.
- Determination: descriptor batching closes the automatic title/attract
  Simulator cadence symptom. A controlled rental-battle measurement and signed
  physical-iPad performance, thermal, audio, touch, and controller acceptance
  remain open.

## 2026-08-02 08:47–08:55 CDT — Current iPhone install and relaunch proof

- Booted the dedicated AnnePad iPhone 16 Pro, iOS 18.5 Simulator used for the
  earlier native setup gate. Before installation it retained the private 32 MiB
  ROM plus matching 131,072-byte primary and backup saves.
- Installed the current ROM-free Release app. CoreSimulator migrated the data-
  container UUID, but the private ROM and save contents remained intact. The app
  visibly advanced from a battle-attract scene at 10 seconds to the title at 45
  seconds while PID 50928 stayed alive.
- Explicitly terminated and relaunched the app. PID 51134 reached the rendered
  title and stayed alive for 25 seconds; the migrated container UUID remained
  stable, the private ROM remained 33,554,432 bytes, and both save SHA-256 values
  remained `b5a41c3758763bbec72769fab4a2533bf2db0b6312d93d25a695f9e4b9e02260`.
- No AnnePad crash report was present. This proves current iPhone
  install/render/termination/relaunch persistence, not touch input,
  background/foreground, real-speaker audio, signing, or physical hardware.
