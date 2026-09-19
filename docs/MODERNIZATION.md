# Source maintenance and issue #2 — 19 September 2026

Status: **diagnostic build 4 qualified; full source migration and issue resolution remain follow-up**.
This is an engineering evidence record, not a rights clearance or a claim that
the reported crash has been fixed.

## Verified baseline

- Repository: `chrissotraidis/annepad`; clean `main` and freshly fetched
  `origin/main`: `65b8eb7ddfd6c067832600d684597d73ca6491ae`.
- Starting public release: [Preview 3](https://github.com/chrissotraidis/annepad/releases/tag/v0.1.0-preview.3),
  iOS/iPadOS 0.1.0 build 3. No macOS binary is published in that release.
- The anonymously downloaded IPA matches SHA-256
  `aaff759f17f127e2bbfe2125f01f0f1effdf0640f76d332444f818fc6cadd85d`.
  The identical retained package passes the app/IPA audit; content-manifest hash:
  `1c1b9db69aeb69b54be7f615a6f113552405b1b9a2c54c16a1e3df481fb142c6`.
- Its four assets are the IPA, audit, content manifest and SHA256SUMS.
  There is no complete nested source archive. A GitHub wrapper archive is not
  sufficient to supply the modified dependency graph.
- [mstan/PokemonStadiumRecomp](https://github.com/mstan/PokemonStadiumRecomp)
  is archived. The only commit after the selected game revision is the
  end-of-maintenance README notice, `c99ed8effd71f9dcea6ede78f606512daa57ea2a`.
  No upstream version was upgraded.

## Effective source and implementation order

Normal macOS, Simulator and iPhoneOS builds actively invoke
`scripts/apply-patches.sh`. Its 23 patch files modify these components:

| Component | Exact upstream baseline | Maintenance scope |
|---|---|---|
| PokemonStadiumRecomp | `de27b7b8481630d41fc7fb913dbd02572d421efd` | Apple integration, release profile, controller and audio changes |
| N64ModernRuntime | `d4bf8828514c567df42ff049e1e90505bdcdb734` | Static mobile profile, audio, save lifecycle, Transfer Pak validation |
| Runtime N64Recomp | `94838144bb970ca6b415636924339e90bafa9ebd` | Exclude dynamic-code targets |
| RT64 | `821a8676963a1b486ca693ebaf8dd606f6c31c64` | Apple Metal integration and resource handling |
| fmt, both generator/runtime copies | `8e728044f673774160f43b44a07c6b185352310f` | Honor consteval override |
| nativefiledialog-extended | `17b6e8ce219c0677f94b63636abb9296b28841ca` | iOS null backend |
| hlsl++ | `6f5274c66132e8f951c400103d897582b8f21491` | Apple scalar declaration |
| pret/pokestadium | `756f7e332ee3837ead17197276cebc071108e8c6` | Private matching-ROM build compatibility |

The generator remains `2b949c5c3f1c41dd76023e7626a6302a4a262a8a`.
All other baseline pins remain in `dependencies.lock.json`.

1. Preserve the complete working product and prove restoration. **Done:** a
   private full-checkout copy, including Git history, nested working sources,
   generated inputs, packages and local build products, was restored separately.
   A SHA-256/mode/symlink manifest matched all 159,345 files and links. Both
   copies are on the same physical disk, so this is not disaster recovery.
2. Preserve prepared changes as ordinary component commits with their original
   parents. **Staged privately:** nine component commits, including both fmt
   copies, match 3,244 baseline tracked files byte-for-byte. Only nested gitlinks
   change. Commit identities and original-to-prepared mapping are retained in
   the private handoff. This is not a public fork graph or completed migration.
3. Resolve the specific source-delivery boundary below, then publish permitted
   maintained components, select immutable pins and change normal bootstrap.
   Keep the existing preparation mechanism until every supported platform and
   generated output has been compared. **Pending.**
4. Qualify the issue fix independently, build clean release commits, deliver
   matching permitted source/notices/provenance, and verify anonymous downloads.
   **Diagnostic build 4 qualified; battle-fix acceptance remains pending.**

Source verification now compares the entire prepared runtime and renderer
against their ordered patch stacks using a temporary Git index. Previously,
reverse-patch applicability and a changed-filename list could accept an extra
edit elsewhere in a patched file. The comparison preserves the real index,
working files, generated inputs and submodules. Existing separate checks still
verify the game stack, nested dependencies and expected new files.

## Publication boundary

The existing [legal/asset policy](LEGAL-AND-ASSET-BOUNDARIES.md) explicitly keeps
`pret/pokestadium`, the separately copyrighted desktop launcher, and derived
game source subject to unresolved distribution review. General release
authorization does not supply these missing rights.

The iOS target uses AnnePad's `recompui_stub.cpp` and excludes
`recomp_ui.cmake`, desktop launcher sources and launcher assets. This narrows
the launcher issue for iOS; it does not clear desktop distribution or the
game-derived source boundary. The game CMake target directly compiles
`rsp/aspMain.cpp`, `rsp/gbTowerMain.cpp`, `rsp/gbTowerColorMain.cpp` and
`rsp/njpgdspMain.cpp`. The core compiles private generated game C files.
The upstream Git history also contains `aspmain_combined.bin` and Ghidra RSP
binary captures. Republishing an unchanged full history as a fork would include
those files; a fork badge would not resolve their treatment under this policy.

Required decision: establish permitted delivery for the linked translated game
and RSP sources, including corresponding-source requirements, and for any
redistributed disassembly content. Complete source-delivery compliance and a finished public migration cannot
be declared while that decision remains open. The diagnostic update retains
the existing preview source pins and translated-code boundary; it does not
resolve this question or expand the source redistribution scope. No upstream contact was made.

## Issue #2 investigation

[Report](https://github.com/chrissotraidis/annepad/issues/2): iPhone 12 Pro Max,
iOS 16.6.1, TrollStore; first Brock-gym trainer battle crashes/restarts the app.
The report does not identify the installed build, selected team, or exception.

An isolated copy of the retained macOS build 3 was tested with a separate data
directory. Its executable SHA-256 is
`62e660f3da3d0272464800631e9443d67603dcf32733831e5055c5ce008a4146`.
Route: Pokémon Stadium → Gym Leader Castle → Battle → Brock → Rental Only.
Selecting Bulbasaur, Ivysaur and Venusaur succeeded; opening Charmander then
stalled gameplay before battle entry. The private log records a lookup miss at
`0x801E40B8`, followed by audio-state errors. A three-second thread sample shows
the game thread in nested geometry dispatch and an unhandled-lookup trampoline.
This is a captured local failure, **not proof of the reporter's crash cause**;
the retained desktop executable is not the iOS shipping artifact.

The retained mobile Release Simulator executable (SHA-256
`f10a4d6b171fc6153253c464baedbee923fbf5edf324d658e76e6f9c62b28d68`)
installed and launched in a newly created isolated iPhone 12 Pro Max simulator
running iOS 26.5. It remained live after startup. This machine's Xcode 27
installation has simctl/runtime support but no Simulator.app, preventing the
interactive battle path through the available UI tooling. This does not test
iOS 16.6.1, TrollStore, physical-device memory pressure or battle acceptance.

## Diagnostic build 4

The owner's explicit follow-up authorized continued investigation, a diagnostic
IPA, and a response on issue #2. Build 4 adds **Share Diagnostics** to the
utility menu and ROM setup screen. It records bounded current/previous sessions,
version/build and executable UUID, lifecycle events, memory footprint/available
memory, fatal-signal details where catchable, and numeric guest failure addresses.
It does not enable gameplay traces or dynamic code, upload automatically, or
export raw runtime logs, guest memory, paths, ROMs, saves or device identifiers.
See [the reporting guide](DIAGNOSTICS.md).

This is a diagnostic update, not a confirmed fix for the reported battle crash.
The next input is the reporter's exported report, selected team and point of
failure. A system crash report may still be needed for jetsam or a full stack.
The original component pins, save paths, bundle ID and iOS 16 deployment floor
are unchanged. No speculative gameplay change was made.

`scripts/package-build-recipe.py` archives the clean wrapper source, dependency
lock, patch series, recursive gitlinks, prepared-file hashes and available
license texts. Restore the archive and check `MANIFEST.sha256` before using its
build instructions. It explicitly requires fetching dependencies and supplying
private game inputs; it is **not** a complete/offline corresponding-source kit.
No claim of complete source delivery or legal clearance is made.

## Validation and rollback

- Baseline and strengthened source verifiers pass.
- Touch latch, controller slot/lifecycle and repository policy checks pass.
- New regression: an extra edit accepted by reverse-patch checking is rejected
  by exact-tree verification; the original index and source remain unchanged.
- Existing Preview 3 unsigned package audit and anonymous hash comparison pass.
- Unsigned arm64 device Release build 4 and strict app audit pass; same bundle
  ID, version 0.1.0, minimum iOS 16, Apple-only dynamic dependencies.
- Simulator probe compiles the exact diagnostic implementation: real SIGABRT
  termination, recovery after relaunch, bounded journals, numeric-only export,
  share-controller construction and stale-error clearing all pass.
- No new physical install, reporter-device reproduction or fixed battle is claimed.

The production dependency checkouts and existing release tags remain unchanged.
Rollback of this wrapper change is an ordinary revert of the review commit;
the prepared component commits exist only in a private restored checkout. The
private handoff includes backup locations, manifests and non-destructive
restoration commands. Do not overwrite an active checkout or uninstall a
device app to roll back. Reinstall a preserved signed app only after verifying
the same bundle/signing identity and backing up the full durable container.
