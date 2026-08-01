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

## B-015 — Project baseline is not committed or backed up

- Status: active repository-state gate
- Evidence: AnnePad has no commit at `HEAD`; all intended project files are
  currently untracked and no project source has been pushed to GitHub.
- Technical gate: resolved. A committed isolated snapshot at
  `915b171bfcf666533d39b8bcece2ce2107a3a9ae` passed the complete no-hardlink
  clean verifier and its `e6b2ab11...f363` executable plus
  `24dc9caa...d9e6` canonical IPA manifest match the retained local candidate
  exactly. The remaining gate is repository publication, not reproducibility.
- Next action: review, commit, and publish the intended source baseline only
  when explicitly authorized. Do not include the ROM, generated source, build
  trees, saves, IPA, logs, or signing material.

## Resolved blockers

### B-R001 — ROM revision uncertainty

- Status: resolved 2026-07-31
- Evidence: streaming byte-swap of the user `.v64` input produced 33,554,432
  bytes and normalized MD5 `ed1378bc12115f71209a77844965ba50`, exactly the
  documented Pokémon Stadium (US) 1.0 input.
- Resolution: support this revision only and keep both source and normalized
  data ignored/local.
