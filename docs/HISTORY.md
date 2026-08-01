# Project history

## 2026-08-01 — Fresh completion audit and Metal clear-state leak fix

- Ruled out RT64 internal resolution as the leading Simulator slowdown with a
  full-screen 1x experiment.
- Cached Metal color-clear depth state instead of allocating and leaking one
  object per depth-backed clear.
- Identified retained Release reverse-engineering probes as the next bounded
  cleanup and documented the remaining touch and physical-device gates.

## 2026-07-31 — Repository established

- Read and adopted the end-to-end AnnePad objective.
- Added repository guardrails that ignore ROMs in all common N64 byte orders,
  saves, cartridge images, signing materials, generated sources, local research,
  builds, logs, and packages.
- Validated the user's local Pokémon Stadium input as US 1.0 without adding it or
  normalized output to source control.

## 2026-07-31 — Independent research completed

- Inspected current PokémonStadiumRecomp game integration, releases, branches,
  issues, pull requests, forks, setup/build scripts, generated-source inputs,
  N64Recomp pin, N64ModernRuntime, RT64, launcher, and decomp checkout.
- Identified missing dependency provenance, a broken optional N64Recomp submodule,
  desktop/x86 assumptions, runtime dynamic-code surfaces, and incomplete
  component licensing.
- Inspected HarkinianPad as the requested native-iOS reference.
- Discovered and inspected BearBirdPad as the closer static-recomp iOS reference,
  including its source graph, host/target build, Metal renderer, UIKit shell,
  touch, lifecycle, save, device, and package proof gates.

## 2026-07-31 — Architecture review completed

- Selected PokémonStadiumRecomp v0.4.6 as the provisional game core.
- Selected a locked fetch + maintained patch integration model.
- Set BearBirdPad as primary Apple static-recomp reference and HarkinianPad as a
  secondary UX/platform reference.
- Required AOT base gameplay and compile-time removal of runtime code generation
  on iOS.
- Chose direct Metal as the default direction while leaving renderer lineage open
  until a native macOS battle and iOS first-frame spike provide evidence.
- Defined nine proof-gated milestones from upstream reproduction through audited
  packaging.

## 2026-07-31 — Reproducible AOT source baseline established

- Added locked, push-disabled source fetching and exact revision verification.
- Built native arm64 N64Recomp/RSPRecomp host tools with a maintained fmt
  compatibility patch.
- Rebuilt the Pokémon Stadium US 1.0 ROM byte-identically on macOS after narrow
  cross-archiver and EUC-JP escape fixes.
- Generated 1,006 private AOT source files and recorded a stable relative-path
  manifest without ROM paths or private input names.

## 2026-07-31 — Native macOS Milestone 1 passed

- Built a native arm64 `AnnePad.app` from the locked game, generated AOT source,
  runtime, and direct-Metal renderer.
- Added narrow maintained seams for non-Windows diagnostics, Apple APIs, Cocoa
  main-thread input, SDL Metal layer ownership, native bundle metadata, and
  reliable short keyboard taps.
- Played a complete three-on-three rental battle from team selection through an
  explicit result screen with rendered animations, audio, input, switching,
  save creation, relaunch, and a clean native-menu exit.

## 2026-07-31 — Static iOS core Milestone 2 passed

- Added a compile-time mobile profile that removes LiveRecomp/sljit targets,
  TCC fragment recompilation, dynamic plugins, and dynamic code loading.
- Compiled the complete generated game plus target-neutral runtime as arm64
  iPhoneSimulator static archives.
- Added an archive/build-graph/symbol audit and recorded passing hashes without
  committing or packaging generated source or ROM material.

## 2026-07-31 — Native iOS Simulator Milestone 3 passed

- Linked the complete AOT game and strict runtime into a ROM-free native arm64
  iPhoneSimulator application with UIKit, SDL, and direct Metal rendering.
- Installed on an iPad Pro 11-inch (M4) Simulator running iOS 18.5 and supplied
  the user-owned ROM only through the app's private data container.
- Captured a live upright rendered game frame through Computer Use. Physical
  device, controller, touch, lifecycle, and packaging gates remain open.

## 2026-07-31 — Unsigned iPhoneOS compile proof

- Cross-built and audited the complete strict static core for arm64 iPhoneOS.
- Built a ROM-free unsigned native iOS 16.0 AnnePad app with Metal, audio, and
  GameController framework linkage; recorded the final executable hash.
- Confirmed that this Mac has no attached iPhone/iPad, valid signing identity,
  or provisioning profile, so physical runtime/controller acceptance remains
  open rather than being inferred from compilation.

## 2026-07-31 — Touch, ROM setup, and persistence milestones

- Added a complete customizable native multitouch N64 overlay and finished a
  full rental battle using touch only in iPad Simulator.
- Added a legal first-run native document-picker flow that validates and stores
  only the user's supported ROM in private app storage, with replace/remove
  management and no ROM in the app bundle.
- Added serialized atomic save commits, backup rotation, corrupt quarantine and
  recovery, and lifecycle flush/resume behavior; proved background/foreground
  and deliberate primary-corruption recovery in Simulator.

## 2026-07-31 — Audited packaging surface started

- Removed the unused desktop launcher asset tree from iOS packaging, including
  box art and cartridge imagery.
- Added original AnnePad app icons, a launch declaration, Apple privacy manifest,
  third-party notices, release-profile AOT optimization, bundle/IPA audits,
  canonical content hashing, and a clean-checkout verifier.
- Kept public redistribution, clean committed checkout, physical devices,
  controllers, real-speaker audio, and signing as explicit open gates.

## 2026-07-31 — Reproducible unsigned IPA sub-gate passed

- Built and audited a separate `-O2` arm64 iPhoneOS core and release app.
- Produced a ROM-free unsigned IPA whose app links only Apple system libraries
  and contains original icons, metadata, privacy declarations, and notices.
- Repackaged the same audited app independently: raw ZIP hashes differed while
  the canonical sorted uncompressed path/size/content manifests were identical.
- Reproduced the committed-HEAD prerequisite failure for the clean-checkout
  verifier. Physical-device, signing, full clean-build, license, and public
  release gates remain open.

## 2026-08-01 — Clean-checkout reproduction passed

- Proved Apple linker UUID generation made otherwise identical unsigned Mach-O
  outputs differ, then disabled the UUID only for unsigned builds. Signed builds
  retain the normal UUID for crash symbolication.
- Rebuilt and packaged twice locally; both canonical manifests matched despite
  different raw archive hashes.
- Created an isolated committed source snapshot and passed the full fresh fetch,
  host-tool, AOT, macOS, Simulator, device, app-audit, package, and repository-
  policy verifier. Its 378,470,288-byte executable and 8-file canonical IPA
  manifest exactly match the local build.
- Kept the isolated snapshot distinct from publication: the working AnnePad
  repository still has no `HEAD` commit and is not backed up to GitHub.

## 2026-08-01 — Release linker reproduction hardened

- A later release-hardening build exposed a 483-byte cross-checkout executable
  delta even after removing the Mach-O UUID; every non-executable bundle file
  already matched.
- Added Apple's reproducible linker mode alongside `-no_uuid`, rebuilt the
  local candidate twice, and required the clean verifier to compare against an
  explicit expected canonical manifest rather than accepting internal
  self-consistency.
- Temporary snapshot commit `915b171bfcf666533d39b8bcece2ce2107a3a9ae`
  passed fresh fetch, AOT, macOS, Simulator, optimized iPhoneOS, app, IPA, and
  repository-policy gates. The 378,469,952-byte executable hashes to
  `e6b2ab11...f363`; the exact 8-file manifest hashes to `24dc9caa...d9e6` in
  both the retained and isolated builds.

## 2026-08-01 — Private main backup established

- Audited and staged the complete 71-file source, patch, documentation, and
  evidence scope while excluding ROMs, generated source, builds, artifacts,
  logs, and signing material.
- Created initial `main` commit `136d145287d3374b93a3dfe0275a46980df85b9c`
  and pushed it to the previously empty private GitHub repository.
- Fetched the new remote branch and proved local `HEAD` and `origin/main` are
  equal. The private backup does not clear public-license or release gates.

## 2026-08-01 — Release diagnostic surface narrowed

- Added a maintained, stack-verified release patch that omits the Ares worker,
  `aspMain` replay/reference sources, capture rings/hooks, TCP debug server,
  turbo override, and environment-autoboot path from iPhoneOS release builds.
- Preserved native iOS startup by making release autoboot a compile-time choice;
  validation builds retain their existing environment-controlled behavior.
- Fixed the executable string audit so `pipefail` cannot hide a marker match
  when `rg -q` closes `strings` early, then expanded the deny-list for every
  removed surface.
- Rebuilt with the release macro scoped only to the app target. The audited
  378,173,192-byte binary hashes to `6453dac1...b27a`; two local packages share
  canonical manifest `b0f62f11...562b0`. Full isolated reproduction of this
  new candidate remains open.

## 2026-08-01 — Optimized iPad Simulator profile proved

- Completed and audited the separate `-O2` arm64 Simulator core and Release app.
- Re-proved full-resolution title/menu/battle rendering, touch navigation,
  editor operation, and Home/resume on iPad Pro 11-inch (M4), iOS 18.5.
- Direct present measurement showed title/menu near 30 Hz but heavy battle
  pacing averaging about 22 presents/s during 30 Hz VI windows; Simulator
  performance remains open, with physical iPad evidence required.
- Rejected and reverted a visually incorrect half-resolution workaround, then
  rebuilt the clean full-resolution Release app and re-verified locked sources.

## 2026-08-01 — Cold iPad overlay bounds fixed

- Reproduced transient touch-control clipping during a portrait-origin cold boot.
- Constrained the touch overlay to all four edges of its live UIKit host instead
  of relying on its initial frame and autoresizing-mask conversion.
- Rebuilt Release and proved stable control geometry throughout a repeated cold
  boot; physical orientation acceptance remains open.

## 2026-08-01 — Packaging now rejects implicit stale app reuse

- Reproduced a default package pass archiving an existing pre-fix device app.
- Made default packaging rebuild the canonical Release app; retained
  `--no-build` as the explicit reuse path.
- Rebuilt and audited the touch-corrected unsigned IPA, then reproduced its
  canonical manifest in a separate no-build archive pass.

## 2026-08-01 — RT64 descriptor cache improves Simulator pacing

- Added maintained descriptor-state deduplication so identical Metal resource,
  sampler, offset, and type bindings do not repeat synchronous encoder work.
- Measured a directional improvement from 21.83 to 23.40 presents/s mean across
  30 Hz VI windows, while keeping the performance gate open.
- Rebuilt and visibly smoke-tested the diagnostic-free iPad Simulator app, then
  rebuilt and twice audited the ROM-free unsigned device package.

## 2026-08-01 — Release hook surface classified and stale core reuse closed

- Compiled 96 diagnostic-only game hooks and their argument evaluation out of
  Release while retaining the six fragment/audio correctness hooks.
- Reduced the observed clean runtime log to 95 lines / 8,243 bytes with zero
  targeted reverse-engineering probe lines.
- Measured 23.31 presents/s across 29 title/attract windows, confirming that log
  removal cleans the shipping surface but does not solve Simulator cadence.
- Made Simulator and device app builds always run the incremental AOT core build
  so regenerated sources cannot silently reuse an older archive.
