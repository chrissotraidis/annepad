# Project history

## 2026-08-02 — Exact current package reproduces from published main

- Ran the full no-hardlink verifier from published commit
  `f5b0048b7bd9b38a262f9ef0f516e2a3dae3dfd5` with the legal external US 1.0
  ROM path and the expected release manifest.
- Reconstructed the matching ROM, regenerated 1,006 AOT files, built native
  macOS plus Simulator/device static cores, built and audited the unsigned
  device app, packaged the IPA, and passed repository checks in isolation.
- The clean 378,195,736-byte executable reproduced SHA-256 `86be9fe4...4689d`;
  the clean package reproduced canonical manifest SHA-256
  `d5c26978...c8f5` byte-for-byte. Physical signed-device gates remain open.

## 2026-08-02 — Re-audited Z and Stadium's real button chords

- Investigated a 2000 player-guide claim that Z + C-Up + C-Right can force an
  attack to miss. The official manual and curated cheat list do not corroborate
  it, and the exact US 1.0 decompilation has no `0x2009` combination or gameplay
  condition combining Z with another button.
- Confirmed the real holds/chords are R + assigned Pokémon button for data,
  Start while holding L + R for stick recentering, held A in Rock Harden, and
  alternating L/R in Dig! Dig! Dig! Normal press/hold and bounded shoulder grace
  cover these without persistent Z state.
- Added a host regression proving independent retained touches can still
  deliver simultaneous Z + C-Up + C-Right if needed.

## 2026-08-02 — Release audio observability removed from the hot path

- Found that Release still computed validation-only synthesized-PCM metrics and
  locked a diagnostic ring once per game audio buffer, despite shipping without
  the debug server that consumes it.
- Made both audio rings validation-only and pinned the measured bridge/smoothing
  defaults for Release, removing 819,200 bytes of static ring storage and the
  per-buffer metric/mutex work while preserving functional audio protections.
- Rebuilt and visibly smoke-tested Simulator, audited the unsigned device app,
  and reproduced the new `d5c26978...c8f5` eight-file package manifest twice.

## 2026-08-02 — Visible battle-transition audit closes the Simulator hitch

- Compared matched battle-entry and steady-state 20-second CPU samples; entry
  adds bounded pipeline/texture creation but no one-second CPU hotspot.
- Recorded a 38.625-second attack/faint/switch segment at 1,151 frames
  (29.799 recorded frames/s) and added a reproducible pixel-difference analyzer.
- The only three 0.260–0.268-second near-unchanged runs were intentional black
  cuts or the fainted-Pokémon hold. No moving-scene freeze was found; physical
  iPad performance remains the honest open gate.

## 2026-08-02 — Controlled battle reaches near-30 Hz cadence

- Measured 154 one-second windows from the first selected move through two
  complete animated Battle Now turns and the return to a third decision.
- Recorded 29.47 presents/s mean, 29.96 median, 4.32 minimum, and 31.94 maximum;
  two windows were below 20, ten below 28, and 144 at least 28.
- Removed the temporary probe, passed source verification, rebuilt the clean
  `4206a896...3ef2` Release app, and visibly relaunched it. A later visible-frame
  audit resolved the low-present transition windows; physical-iPad performance
  remains open.

## 2026-08-02 — Held-R battle inspection and L cancel pass

- Used touch only to select Pikachu/Squirtle/Bulbasaur and reach a Battle Now
  Pikachu-versus-Meowth decision screen on the current iPhone Simulator build.
- Held R revealed Pikachu's four moves with PP/type data; releasing R hid the
  assignments again; L returned from move selection to strategy selection.
- Corrected the earlier control interpretation: live US 1.0 labels L Cancel and
  R Check. Pre-battle R-plus-selection and physical multitouch remain open.

## 2026-08-02 — Current iPhone Z/L/R actions are distinct and live

- Reached Gallery through the visible current iPhone overlay and selected a
  rental Bulbasaur without controller or keyboard input.
- Three separate Z taps cycled the lower display through gold nameplate, blue
  nameplate, hidden, and back to gold; L opened the background selector; R
  entered the telephoto close-up.
- Kept held-R battle inspection, simultaneous R-plus-selection, and physical
  multitouch acceptance open while closing quick-Z and independent L/R routing.

## 2026-08-02 — Current iPhone touch routing reaches Battle Now

- Attached a sanctioned UI-control session to the dedicated iPhone 16 Pro,
  iOS 18.5 Simulator after three earlier bridge timeouts.
- Used the visible START, A, and D-left overlay controls to advance from title
  through Game Pak Check and the main selection into Battle Now one-player
  setup; PID 52349 stayed alive and no AnnePad crash report was present.
- Closed ordinary current-iPhone touch routing while keeping action-specific
  quick-Z, held-R, R-plus-selection, and physical-device acceptance open.

## 2026-08-02 — iPhone background/foreground preserves process and save

- Backgrounded AnnePad by foregrounding Simulator Settings and recorded real
  UIKit deactivation/background events while the AnnePad PID stayed alive.
- Returned to the same PID and a live rendered title/phone overlay; the save
  modification time advanced while its exact content hash remained unchanged.
- Closed current iPhone background/foreground continuity while keeping touch,
  real-speaker, signing, and physical-hardware acceptance open.

## 2026-08-02 — iPhone Simulator lock/unlock preserves live state

- Locked the current clean iPhone 16 Pro Simulator through its visible Device
  menu and observed UIKit deactivate/background events without losing AnnePad's
  PID.
- Unlock returned to the same process and upright live surface with identical
  primary/backup save hashes. A fresh Start reached Game Pak Check and did not
  repeat, closing current Simulator lock/unlock and stuck-input recovery.
- Kept physical-device lock/unlock, audio interruption/route, speaker, signing,
  and hardware acceptance open.

## 2026-08-02 — Current iPhone install and relaunch preserve state

- Installed the clean Release app over the dedicated iPhone 16 Pro Simulator's
  existing private ROM/save container and visibly advanced from battle attract
  to the title screen.
- Terminated and relaunched the app; the migrated container, private ROM size,
  and exact primary/backup save hashes remained intact with no crash report.
- Kept touch, background/foreground, real-speaker, and physical-device iPhone
  acceptance open rather than inferring them from launch/relaunch persistence.

## 2026-08-02 — Descriptor-batched Simulator path reaches target cadence

- Measured 90 post-startup automatic title/attract windows at 29.96 presents/s
  mean, 27.66 minimum, and 31.09 maximum; none were below 20 and one was below 28.
- Removed the temporary present probe, passed maintained-source verification,
  rebuilt the official clean Release Simulator app, and visibly relaunched it.
- Accepted the automatic Simulator title/attract cadence while keeping a
  controlled rental-battle measurement and physical-iPad acceptance open at
  that checkpoint; the controlled measurement passed later the same day.

## 2026-08-02 — Current optimized package reproduced from clean source

- Rebuilt the current descriptor-batched, Stadium-specific-control source in a
  no-hardlink clone at `0cc91b61...142b`.
- Passed fresh fetch, AOT generation, native macOS, Simulator validation,
  optimized iPhoneOS, app/package audits, and repository tests.
- Reproduced the 378,198,984-byte device executable SHA-256 `1c2bd2e9...6850`
  and canonical eight-file IPA manifest `bd6f14be...51fa` exactly.
- Extended `ANNEPAD_BUILD_JOBS` to host-tool and native macOS builds after the
  clean verifier exposed ten-worker memory pressure on the 16 GB build Mac.

## 2026-08-02 — Stadium-specific controls and Metal descriptor batching

- Audited the original Stadium manual and decompiled controller paths instead
  of carrying over HarkinianPad's Zelda-specific Z toggle. The documented
  battle inspection holds R while L cancels; Z remains held only while touched, with brief tap
  retention for reliable runtime polling and no persistent latch.
- Added a bounded RT64 Metal descriptor cache that coalesces contiguous dirty
  resource bindings immediately before draw or dispatch. A matched Simulator
  sample removed the prior repeated descriptor-setter hotspot and increased
  renderer wait-for-work time. The exact-source Release app then built,
  installed, rendered advancing attract scenes, and remained alive through a
  12-second sample. Direct revised-control UI acceptance remains open because
  the local Simulator UI-control bridge timed out.

## 2026-08-02 — Exact-source unsigned package reproduced

- Rebuilt the complete locked source graph from a no-hardlink isolated clone of
  source commit `15a79de423458683370c6fb9bd0a7fa18288979d`.
- Passed fresh fetch, AOT generation, native macOS, Simulator, optimized
  iPhoneOS, app, package, touch-latch, and repository verification.
- Reproduced the 378,199,272-byte unsigned executable SHA-256
  `8d1f440f...4494` and canonical eight-file IPA manifest
  `fcb2832e...b590` exactly. Physical signing and iPad acceptance remain open.

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

## 2026-08-01 — Touch tap lifetimes made independent and testable

- Replaced the shared tap countdown with one atomic lifetime per N64 button, so
  overlapping shoulder/Z taps cannot prolong unrelated buttons.
- Added host tests for six-poll taps, the 45-poll shoulder grace window,
  overlapping A+R, Z clearing, and lifecycle cancellation.
- Rebuilt and launched Release on the iPad Simulator; quick Start input returned
  from attract mode and advanced into Game Pak Check.

## 2026-08-01 — Corrected touch overlay completes rental battle

- Used only the HarkinianPad-derived on-screen controls to select
  Squirtle/Pikachu/Bulbasaur and play a complete Battle Now match against
  Psyduck/Oddish/Meowth.
- Resolved all six rentals, reached the explicit `LOSE` result, and returned to
  the main selection menu without a crash.
- Preserved a correctly oriented Simulator screenshot at
  `docs/evidence/m5-ios-touch-rental-battle-corrected-result.png`; timed UIKit Z
  latch and physical-device acceptance remain open.
