# Release checklist

No public release is allowed while any required item is unchecked. Optional
features may ship disabled/absent, but their incomplete state must be explicit.

## Source and legal

- [ ] Release commit is clean, reviewed, and tagged from the intended branch.
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
- [ ] Build logs contain no local absolute paths, tokens, or user identifiers.

## Gameplay gates

- [x] Native arm64 macOS completes a rental-Pokémon battle with rendering,
      audible audio, input, save/relaunch, and clean exit.
- [ ] iPhone and iPad Simulator launch, import, render, accept input, persist,
      background/foreground, and relaunch.
      Current iPhone install/render/termination/relaunch persistence and iPad
      import/touch/background/relaunch have separate passing evidence. Current
      iPhone background/foreground also passes with same-PID render/save
      continuity, and visible START/A/D-left input reaches Battle Now setup.
      Action-specific Z/L/R and the remaining per-form-factor matrix stay open.
- [ ] Signed physical iPhone and iPad builds install and run.
- [ ] Physical controllers pass on iPhone and iPad.
- [ ] Customizable touch controls complete a full rental-Pokémon battle on real
      hardware without controller/keyboard assistance.
- [ ] Real-speaker audio, interruption/route changes, lifecycle, lock/unlock,
      save integrity, and update/relaunch pass on physical hardware.
- [ ] Known crashes/correctness regressions have no open release-severity item.

## App and IPA audit

- [ ] Release configuration has no debug menus, test ROM paths, verbose private
      logs, assertions that expose data, or unsupported feature toggles.
      Audio capture/synthetic, `aspMain` replay/capture/oracle, Ares worker,
      TCP debug server/port, turbo, and environment-autoboot surfaces are
      absent; retained `extras.c`/`game.toml` reverse-engineering probes and
      remaining upstream render/audio configuration and trace toggles remain
      under audit.
- [x] Device Mach-O is arm64, has expected load commands/frameworks, contains no
      Simulator slice, unexpected dylib, JIT/TCC/LiveRecomp/code-mod loader,
      writable-executable entitlement, or runtime tool dependency.
- [x] Bundle identifier, version/build, icons, launch UI, orientations, minimum
      OS, device families, privacy manifest, usage strings, and entitlements are
      correct and internally consistent.
- [x] IPA manifest contains only expected files and every third-party notice.
- [x] Unsigned IPA has no embedded provisioning profile/signing secret.
- [x] Canonical sorted uncompressed-content digest and full audit report are
      recorded and reproduced from an isolated no-hardlink checkout
      (`bd6f14be...51fa`); physical install/retest remains open.

## Documentation and handoff

- [x] Goal, architecture, plan, status, blockers, decisions, testing, building,
      legal, release, history, and worklog documents reflect the release.
- [x] Limitations, unsupported ROM revisions, optional-feature state, device/OS
      test matrix, performance data, and unresolved external gates are honest.
- [x] Exact signed-device handoff commands and unsigned IPA location/digests are
      recorded without exposing signing identity details.
- [ ] Rollback/recovery procedure and last known good tag are documented.

## App Store-specific additional gate

- [ ] Separate legal counsel/rights authorization and current Apple review-policy
      assessment are complete.
- [ ] Privacy nutrition labels, encryption/export compliance, accessibility,
      metadata, support URL, account/data declarations, and store assets pass.

Local sideload/IPA completion does not check these App Store boxes automatically.
