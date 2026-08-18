# Release checklist

No public release is allowed while any required item is unchecked. Optional
features may ship disabled/absent, but their incomplete state must be explicit.

## Source and legal

- [x] Release commit is clean, reviewed, and tagged from the intended branch as
      `annepad-local-acceptance-2026-08-02`. This is a local-acceptance tag, not
      a public or signed-device release tag.
- [ ] Dependency lock, patch series, license inventory, and source offer satisfy
      every redistributed component's terms.
- [ ] `pret/pokestadium` and `recomp-ui` licensing is clarified, or their
      unlicensed material is absent from redistributed source and binaries.
- [x] Repository/package audits find no ROM, save, extracted game asset/source,
      cartridge image, firmware, signing secret, credential, or private data.
- [ ] Public screenshots/media have a documented rights and privacy review.
- [x] Release language requires a legally obtained user ROM and does not imply
      Nintendo affiliation or endorsement.

## Reproducible build

- [x] Fresh isolated checkout on the documented host fetches every exact source
      pin and passes the full verifier.
- [x] All patches apply and reverse-check; no source tree is dirty unexpectedly.
- [x] Host tools, AOT output manifest, macOS app, iOS app, and unsigned IPA build
      through the documented commands.
- [x] A second clean build matches required content/manifests; differences are
      understood and documented.
- [x] Retained release evidence contains no local absolute paths, credentials,
      tokens, or private user identifiers. Raw compiler console output is local,
      ignored, and not a release artifact; the intended public bundle identifier
      is recorded in the audit.

## Gameplay gates

- [x] Native arm64 macOS completes a rental-Pokémon battle with rendering,
      audible audio, input, save/relaunch, and clean exit.
- [x] iPhone and iPad Simulator launch, import, render, accept input, persist,
      background/foreground, and relaunch.
      Current iPhone install/render/termination/relaunch persistence and iPad
      import/touch/background/relaunch have separate passing evidence. Current
      iPhone background/foreground also passes with same-PID render/save
      continuity; current iPhone Simulator lock/unlock also returns to the same
      PID, preserves matching saves, and accepts a fresh Start without repeated
      input. Visible START/A/D-left input reaches Battle Now setup. Gallery
      visibly proves quick-Z cycling plus independent L and R actions. Battle
      visibly proves held-R reveal/release and L cancel. The final side-rail
      controls, native utility menu, editor, and ROM-manager route pass on both
      form-factor Simulators. Pre-battle
      R-plus-selection remains a physical-multitouch gate. A final 180-second
      Release soak on both form factors kept the same PID alive through 90
      seconds foreground, a Settings background interval, and 90 seconds after
      restoration, with no new AnnePad crash report.
- [ ] Signed physical iPhone build installs and runs.
- [x] Signed physical iPad build 0.1.0 (3) installs in place and reaches game
      boot. The 2026-08-18 pass found the existing game data and saves,
      initialized audio, Metal, and recomp fragments, and logged startup plus
      foreground controller reconciliation. Pre/post readback preserved the
      material ROMs, saves, Transfer Pak data, launcher configuration, and
      AnnePad preferences; only the obsolete data-container path in `rom.cfg`
      was migrated to the current container.
- [ ] Physical controllers pass on iPhone and iPad.
- [ ] Customizable touch controls complete a full rental-Pokémon battle on real
      hardware without controller/keyboard assistance.
- [ ] Real-speaker audio, interruption/route changes, lifecycle, lock/unlock,
      save integrity, and update/relaunch pass on physical hardware.
- [x] Known local crashes/correctness regressions have no open release-severity
      item. The reproduced over-8,192-pixel Metal target abort is guarded, its
      60-second reproduction path passes, and the later two-form-factor soak
      produced no new crash. Physical-device-only regressions remain separate
      unchecked gates above.

## App and IPA audit

- [x] Release configuration has no debug menus, test ROM paths, verbose private
      logs, assertions that expose data, or unsupported feature toggles.
      Audio capture/synthetic, `aspMain` replay/capture/oracle, Ares worker,
      TCP debug server/port, turbo, and environment-autoboot surfaces are
      absent. The two audio diagnostic rings and their A/B environment switches
      are validation-only. Runtime/scheduler trace rings and recorders are also
      compiled out of Release and rejected by audit. The iOS renderer path uses
      a native stub with fixed fullscreen/no-supersampling/no-MSAA defaults and
      disables RT64 configuration-file loading; it exposes no settings or debug
      menu.
- [x] Device Mach-O is arm64, has expected load commands/frameworks, contains no
      Simulator slice, unexpected dylib, JIT/TCC/LiveRecomp/code-mod loader,
      writable-executable entitlement, or runtime tool dependency.
- [x] Bundle identifier, version/build, icons, launch UI, orientations, minimum
      OS, device families, privacy manifest, usage strings, and entitlements are
      correct and internally consistent.
- [x] IPA manifest contains only expected files and every third-party notice.
- [x] Unsigned IPA has no embedded provisioning profile/signing secret.
- [x] Canonical sorted uncompressed-content digest and full audit report are
      recorded for Preview 3. Two package passes from the same audited app are
      byte-identical at IPA SHA-256
      `aaff759f17f127e2bbfe2125f01f0f1effdf0640f76d332444f818fc6cadd85d`;
      their canonical manifest is also identical at SHA-256
      `1c1b9db69aeb69b54be7f615a6f113552405b1b9a2c54c16a1e3df481fb142c6`.

## Documentation and handoff

- [x] Goal, architecture, plan, status, blockers, decisions, testing, building,
      legal, release, history, and worklog documents reflect the release.
- [x] Limitations, unsupported ROM revisions, optional-feature state, device/OS
      test matrix, performance data, and unresolved external gates are honest.
- [x] Exact signed-device handoff commands and unsigned IPA location/digests are
      recorded without exposing signing identity details.
- [x] Rollback/recovery procedure and last known good local-acceptance tag are
      documented.

## App Store-specific additional gate

- [ ] Separate legal counsel/rights authorization and current Apple review-policy
      assessment are complete.
- [ ] Privacy nutrition labels, encryption/export compliance, accessibility,
      metadata, support URL, account/data declarations, and store assets pass.

Local sideload/IPA completion does not check these App Store boxes automatically.
