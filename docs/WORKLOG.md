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
