# Decisions

Decisions are append-only. Superseded decisions remain with a pointer to their
replacement.

## D-001 — Canonical product name

- Date: 2026-07-31
- Status: accepted
- Decision: use **AnnePad** consistently; treat `AniPad` as an objective typo.
- Evidence: repository name and objective title both use AnnePad.

## D-002 — Game-core foundation

- Date: 2026-07-31
- Status: accepted, pending Milestone 0 reproduction
- Decision: base the port on `mstan/PokemonStadiumRecomp` v0.4.6 source.
- Evidence: it is the only reviewed current Stadium-specific static recomp port;
  forks are stale and no PR/branch provides a better Apple base.
- Revisit if: source reconstruction cannot reproduce upstream behavior or a
  newly discovered branch has demonstrably better correctness.

## D-003 — Source integration model

- Date: 2026-07-31
- Status: accepted
- Decision: use a machine-readable lock plus fetch-only clones and maintained
  patch files. Do not vendor upstream trees or rely on mutable submodule heads.
- Evidence: upstream setup does not enforce all pins; an optional N64Recomp
  submodule is broken; BearBirdPad/HarkinianPad proved fetch + patch auditing.
- Containment: upstream sources and generated outputs live in ignored paths.

## D-004 — Apple reference hierarchy

- Date: 2026-07-31
- Status: accepted
- Decision: BearBirdPad is the primary static-recomp implementation reference;
  HarkinianPad is a secondary interaction/platform reference.
- Evidence: BearBirdPad already ports the same runtime/renderer family to real
  iPhone/iPad hardware; HarkinianPad uses a different native-source game core.

## D-005 — Mobile setup

- Date: 2026-07-31
- Status: accepted
- Decision: replace the desktop ImGui/OpenGL launcher on iOS with a small native
  ROM import/validation setup flow. Keep desktop launcher behavior only where it
  helps reproduce upstream.
- Evidence: iOS file access and lifecycle require UIKit; the current launcher's
  project license is unclear and its desktop feature surface is unnecessary.

## D-006 — Renderer lineage

- Date: 2026-07-31
- Status: open gate
- Candidates: adapt mstan direct Metal, or forward-port Stadium fixes to
  official RT64/Plume using BearBirdPad's iOS work.
- Current preference: mstan direct Metal, because it minimizes game delta.
- Close only after: arm64 macOS rental battle and a measured iOS first-frame
  compile/runtime spike for the smallest candidate.

## D-007 — No runtime code generation on iOS

- Date: 2026-07-31
- Status: accepted
- Decision: base gameplay is AOT; compile out TCC, LiveRecomp, sljit target JIT,
  dynamic code mods, plugins, and executable-code download from iOS targets.
- Evidence: iOS execution/packaging constraints and the project prohibition on
  emulator/JIT shortcuts. An interpreter fallback requires a separate inventory
  and must never become the base execution engine.

## D-008 — Metal first, MoltenVK only by evidence

- Date: 2026-07-31
- Status: accepted
- Decision: direct Metal is the default. MoltenVK is a contained fallback, not
  an initial dependency.
- Evidence: both mstan RT64 and BearBirdPad demonstrate Metal-capable paths;
  MoltenVK would add another translation and lifecycle layer.

## D-009 — One normalized input path

- Date: 2026-07-31
- Status: accepted; touch implementation corrected 2026-08-01
- Decision: touch, GameController/SDL, and desktop keyboard feed the same N64
  input snapshot; UI does not invoke game logic. HarkinianPad is the preferred
  starting point for touch geometry, feedback, customization, and cancellation
  behavior, adapted to this direct analog bridge rather than converted into
  synthetic keyboard events.
- Evidence: the first AnnePad overlay proved a full Simulator touch battle but
  did not justify its visual/state-machine divergence from HarkinianPad. The
  corrected candidate uses the reference's accepted phone/tablet grip geometry,
  pressed feedback, customization, and lifecycle release behavior while
  preserving analog stick values and normalized N64 button masks. A later
  game-specific control audit rejected HarkinianPad's persistent Z latch:
  Stadium's identified Z actions are edge-triggered except for generic held-Z
  scroll acceleration. Live US 1.0 battle proof identifies L as cancel and
  held R as the assignment-reveal action; the manual also documents R plus a
  Pokémon's assigned button for pre-battle data inspection.

## D-010 — Public redistribution remains gated

- Date: 2026-07-31
- Status: accepted
- Decision: local engineering may continue with user inputs and inspected
  upstreams, but no public source/binary release may redistribute unlicensed
  decomp or launcher content.
- Evidence: no top-level license found in the exact decomp or launcher checkouts.

## D-011 — Contain AppleClang/fmt compatibility in a maintained host patch

- Date: 2026-07-31
- Status: accepted
- Decision: backport fmt's upstream guard for a user-provided
  `FMT_USE_CONSTEVAL` value and disable consteval only for the native host tools.
- Evidence: the exact pin fails under AppleClang 21; current upstream fmt honors
  the override; changing the compiler, generator commit, or dependency version
  would create a larger and less attributable baseline delta.

## D-012 — Preserve byte-identical macOS decomp output with two narrow patches

- Date: 2026-07-31
- Status: accepted
- Decision: use the configured MIPS cross-archiver and split the single
  Japanese/newline/Japanese literal at a C string boundary.
- Evidence: Apple `ar` discarded every MIPS member; native IDO misencoded only
  that multibyte escape boundary. With both changes, the complete reconstructed
  ROM exactly matches the required MD5.
- Containment: both patches are forward/reverse checked and source verification
  rejects any additional tracked modification.

## D-013 — Keep Cocoa event ownership on the main thread

- Date: 2026-07-31
- Status: accepted
- Decision: pump SDL window, keyboard, and controller events from the macOS main
  thread and pass normalized snapshots inward; the recompiled game thread never
  calls AppKit event APIs.
- Evidence: direct game-thread polling raised AppKit's
  `nextEventMatchingMask` main-thread exception. The main-thread seam completed
  the full rental battle without recurrence and aligns with the future UIKit
  ownership model.

## D-014 — Use a real SDL Metal view for the desktop proof target

- Date: 2026-07-31
- Status: accepted for macOS; input to D-006
- Decision: request `SDL_WINDOW_METAL`, create the SDL Metal view, and pass its
  CAMetalLayer to the direct-Metal RT64 backend.
- Evidence: a null native view produced a live black window; the explicit Metal
  layer immediately produced correct title, menu, and full-battle rendering.
- Revisit if: the iOS static-archive/first-frame spike proves the official
  RT64/Plume lineage materially smaller or safer.

## D-015 — Compile dynamic-code facilities out of mobile targets

- Date: 2026-07-31
- Status: accepted
- Decision: `N64MODERN_NO_DYNAMIC_CODE` removes LiveRecomp/sljit targets and
  makes runtime code/plugin requests fail closed; mobile builds do not merely
  disable those facilities with environment variables.
- Evidence: the complete arm64 iPhoneSimulator core builds without those targets
  or artifacts, and its archive audit finds no `dlopen`/`dlsym` or Apple JIT
  cache-control dependency.
- Boundary: the remaining `_mprotect` reference changes reserved RDRAM pages
  from inaccessible to read/write; it never requests executable permission.

## D-016 — Serialize and atomically rotate game saves

- Date: 2026-07-31
- Status: accepted
- Decision: serialize snapshot writes behind one mutex, mark dirty state
  atomically, rotate one last-known-good backup, replace the primary atomically,
  and flush on background, termination, normal quit, and save-path changes.
- Evidence: backgrounding created exact-size primary/backup saves; an isolated
  deliberately invalid primary was quarantined and restored from a valid backup
  on next Simulator launch.
- Boundary: physical forced-termination, update, low-storage, lock, and audio
  interruption tests remain required; the Simulator recovery proof does not
  waive them.

## D-017 — Keep desktop launcher media out of iOS packages

- Date: 2026-07-31
- Status: accepted
- Decision: do not copy the upstream desktop `assets/` tree into iOS. Use only
  original AnnePad app artwork plus native metadata/privacy/notices resources.
- Evidence: the native iOS launcher is UIKit and never reads the desktop fonts,
  cartridge art, or box art; the app audit rejects any stale copy.
- Containment: device builds recreate the exact app product before linking so
  removed resources cannot survive incremental builds.

## D-018 — Separate validation and release AOT products

- Date: 2026-07-31
- Status: accepted
- Decision: retain the practical `-O0` SDK/static-policy core as `validation`,
  but require a separately built `-O2` core and an `Info.plist` `release` marker
  for IPA assembly.
- Evidence: the complete validation core is large and deliberately optimized for
  compile turnaround, not shipment. Package scripts fail closed if handed that
  app, and audit both optimization profile and final device binary.
- Revisit if: measured physical-device performance or build feasibility requires
  a different release optimization level; any change needs binary/runtime and
  canonical-package evidence.

## D-019 — Close the renderer lineage gate on direct Metal

- Date: 2026-07-31
- Status: accepted; closes D-006
- Decision: retain the pinned mstan RT64 direct-Metal lineage with narrow
  maintained iOS patches rather than forward-porting Stadium changes into the
  larger Plume branch.
- Evidence: it completed a native macOS rental battle and rendered sustained
  live Simulator gameplay through Metal, including the touch-only battle and
  background/foreground return.
- Revisit if: physical-device performance, correctness, or maintainability
  evidence demonstrates a release-severity limitation that Plume fixes.
