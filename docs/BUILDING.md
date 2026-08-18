# Building AnnePad

AnnePad has proven native arm64 macOS, strict iOS Simulator and iPhoneOS static
cores, native iPad Simulator runtime, and unsigned iPhoneOS app compilation.
`STATUS.md` is authoritative about runtime and device gates.

## Supported host

- Apple Silicon Mac.
- Xcode 26.6 (17F113) during the initial baseline.
- CMake 4.4.0, Ninja 1.13.2, git, Python >3.7.
- A pinned or documented MIPS GNU binutils provider for the decomp step.
- Enough storage for multiple ignored dependency, generated-source, and build
  trees. No source step needs administrator privileges.

## Inputs

1. A clean AnnePad checkout.
2. A legally obtained Pokémon Stadium (US) 1.0 ROM. `.z64`, `.v64`, and `.n64`
   byte orders may be accepted, but normalized input must be 33,554,432 bytes
   with MD5 `ed1378bc12115f71209a77844965ba50`.
3. Network access only for the explicit fetch phase. A verified source cache may
   be used offline later.
4. Local Apple signing only for physical-device builds; unsigned Simulator and
   IPA assembly do not require credentials.

Never place the ROM in a tracked path. `ref/` is local-only but scripts will
accept an explicit path so clean checkouts need not use that layout.

## Build phases

The following command names are the stable interface. Commands through the
validation-profile unsigned iPhoneOS app build pass. Packaging selects a
separate release-optimized core automatically. Signed device runtime remains an
external proof gate.

```sh
./scripts/check-prerequisites.sh
./scripts/fetch-sources.sh
./scripts/verify-sources.sh
./scripts/prepare-game.sh --rom /absolute/path/to/user-rom.v64
./scripts/build-host-tools.sh
./scripts/generate-game.sh --rom /absolute/path/to/user-rom.v64
./scripts/build-macos.sh
./scripts/run-macos.sh --rom /absolute/path/to/pokemon-stadium-us-1.0.z64
./scripts/build-ios-core.sh simulator release
./scripts/build-ios-dependencies.sh simulator
./scripts/build-ios-simulator.sh
./scripts/build-ios-device.sh validation
./scripts/test-repository.sh
./scripts/package-ios.sh
./scripts/audit-ipa.sh artifacts/AnnePad-0.1.0-unsigned.ipa
./scripts/verify-clean-checkout.sh \
  --rom /absolute/path/to/user-rom.v64 \
  --expected-manifest /absolute/path/to/AnnePad-0.1.0-unsigned.manifest.sha256
```

Scripts must resolve their repository root from their own location, quote all
paths, reject an unset/ambiguous destructive target, and write only to ignored
`external/`, `generated/`, `build-*`, `artifacts/`, or `logs/` directories.

## Source graph

`dependencies.lock.json` is authoritative. Fetching checks out detached exact
commits and removes/disables push URLs. It initializes only required submodules;
the unavailable optional Ares bridge at the selected N64Recomp pin is excluded.
No script follows a branch at build time. A source update is an explicit lock
change plus patch/build/runtime review.

## Host generation

The ROM is normalized into a private ignored work directory. The decomp split
and AOT generator run only on the host. Their outputs remain ignored and are
checked through path/size/content manifests, not committed or packaged.

## Apple builds

The passing macOS build is:

```sh
./scripts/build-macos.sh
./scripts/run-macos.sh --rom /absolute/path/to/pokemon-stadium-us-1.0.z64
```

It produces a native bundle at `build-macos/AnnePad.app`. The run command
validates the absolute ROM path, autoboots the ignored user input, and tees
sanitized runtime diagnostics to `logs/macos-latest.log`. Quit with **AnnePad >
Quit AnnePad** for the normal exit path. Closing the gameplay window returns to
the launcher.

Host shader/codegen tools are macOS executables. Target libraries use the
selected iPhoneSimulator or iPhoneOS SDK and never execute during cross-build.
Device output is arm64 only; Simulator output matches supported simulator
architectures. All iOS runtime components are statically linked except Apple
system frameworks and explicitly audited permitted libraries.

The passing core proofs are:

```sh
./scripts/build-ios-core.sh simulator validation
./scripts/build-ios-core.sh simulator release
./scripts/build-ios-core.sh device
./scripts/build-ios-device.sh validation
```

The validation core compiles private generated AOT source with `-O0` because
that gate proves SDK compatibility and static policy quickly; it is not a
playability or performance candidate. `build-ios-simulator.sh` defaults to the
release profile and produces separate `-O2` output under
`build-ios-core-simulator-release/` and `build-ios-app-simulator-release/`.
Pass `validation` explicitly only for the fast compile gate. Packaging likewise
invokes `build-ios-core.sh device release` and `build-ios-device.sh release`,
producing `-O2` output under `build-ios-core-device-release/` and
`build-ios-app-device-release/`. A profile marker in `Info.plist` prevents the
package script from accepting the validation app. `audit-ios-core.sh` checks
arm64 iPhoneSimulator or iPhoneOS load commands, required archives, the selected
optimization profile, build-graph exclusions, and forbidden dynamic-loading/JIT
symbols. Building either app does not claim installation or physical-device
runtime success.

Both app build entry points always invoke the corresponding incremental core
build, even when an archive already exists. This is intentional: generated AOT
sources can change while an older archive still passes static policy audits,
and linking that stale archive would produce a source-inconsistent app.

The optimized AOT compile can run several very large C translation units at
once. On an 8 GB Mac, limit core-build concurrency:

```sh
ANNEPAD_BUILD_JOBS=2 ./scripts/package-ios.sh
```

`ANNEPAD_BUILD_JOBS` must be a positive integer and bounds the native host-tool,
macOS, and static iOS core builds. Completed objects remain incremental when the
command is rerun. An unrestricted ten-worker clean build on that hardware
reached roughly 12 GB of swap and completed the largest generated units much
more slowly; this is build throughput, not game FPS.

The iOS bundle contains only native app resources: compiled original AnnePad
icons, `PrivacyInfo.xcprivacy`, `ThirdPartyNotices.txt`, metadata, and the
executable. The desktop launcher's fonts, cartridge icons, and box art are not
copied. Device builds recreate the known app product before linking so stale
resources removed from CMake cannot survive an incremental build.

## Signing

Project files use automatic/local signing settings without committing team IDs,
profiles, entitlements containing personal identifiers, or certificates. The
device build command accepts local overrides from ignored configuration. An
unsigned IPA contains `Payload/AnnePad.app` and no embedded mobileprovision.
`package-ios.sh` accepts output only under ignored `artifacts/`, rebuilds the
canonical device Release app by default, audits it, assembles the payload, and
calls `audit-ipa.sh`. Use `--no-build` only when deliberately repackaging the
existing audited app; a caller-supplied `--app` is never replaced. The audit
emits a full text report plus a sorted path/size/content-SHA manifest. The
SHA-256 of that manifest remains the content-level reproducibility gate.
Packaging normalizes staged entry times so repeated packages from the same
audited app should also have identical ZIP bytes and archive SHA-256.

When a lawful local development team and attached device are available, build,
verify, install, and launch without writing the team or device identifier into
the repository:

```sh
DEVELOPMENT_TEAM="your-local-team-id" \
  ./scripts/build-ios-device.sh release signed
./scripts/install-ios-device.sh --device "attached-device-name-or-id"
```

The signed product is isolated under
`build-ios-app-device-release-signed/Release/AnnePad.app`. The build audit
requires a valid signature; installation re-audits it before `devicectl` runs.
These commands are a reproducible handoff, not evidence that either physical
form factor has passed until the complete matrix in `TESTING.md` is observed.

## Clean build evidence

A reproducibility run starts from a fresh checkout or detached worktree plus an
empty output directory, fetches exact sources, consumes the user ROM, builds,
tests, packages, and audits. Record:

- AnnePad commit and dependency lock digest.
- Host and Xcode/SDK versions.
- Source/tree and patch verification results.
- Generated-source manifest digest (not contents).
- App binary UUID/content hashes and package canonical content digest.
- Test and audit summaries.

The packager normalizes ZIP entry timestamps, so repeated packages from the
same audited app should be byte-identical. Canonical sorted uncompressed
path+content hashing remains the independent content-level gate.
Unsigned packages retain the linker's normal hash-derived `LC_UUID` command so
they are accepted by loaders that require it, including LiveContainer.

`verify-clean-checkout.sh` deliberately requires a committed, clean AnnePad
`HEAD` and an expected canonical candidate manifest, then creates a local
no-hardlink clone and runs the complete fetch, generation, macOS build,
Simulator/device build, package, and audit sequence using an explicit ROM
outside the checkout. It fails if the clean package differs from that expected
manifest. The source baseline is committed and backed up to private GitHub
`main`; private inputs and generated output remain ignored and must never be
added to make a verifier pass.

## Passing local unsigned candidate

The 2026-08-18 Preview 3 build produced:

- `artifacts/AnnePad-0.1.0-preview.3-unsigned.ipa`: 85,343,107 bytes, SHA-256
  `aaff759f17f127e2bbfe2125f01f0f1effdf0640f76d332444f818fc6cadd85d`;
- `artifacts/AnnePad-0.1.0-preview.3-unsigned.audit.txt`: passing app/package
  report; and
- `artifacts/AnnePad-0.1.0-preview.3-unsigned.manifest.sha256`: sorted content
  records, SHA-256
  `1c1b9db69aeb69b54be7f615a6f113552405b1b9a2c54c16a1e3df481fb142c6`.

An independent second package pass from the same audited app matched both the
IPA bytes and manifest bytes exactly. The 382,638,528-byte unsigned arm64
iPhoneOS executable hashes to
`de308691a730b70073000eddbca42398551928d29f5545f6e3aae24f68f438a2`.
The app and IPA audits report iOS 16.0 minimum, Apple-system-only dynamic
dependencies, required notices/privacy manifest, and no ROM, save, log, private
path, credential, signature, or provisioning profile.

## Rollback and recovery

The local-acceptance tag is the source rollback point. Inspect it before use and
build it on a new branch; do not rewrite `main`:

```bash
git fetch origin --tags
git switch -c codex/rollback-annepad-local-acceptance \
  annepad-local-acceptance-2026-08-02
./scripts/verify-clean-checkout.sh \
  --rom /absolute/path/to/legal-user-rom.v64 \
  --expected-manifest /absolute/path/to/AnnePad-0.1.0-unsigned.manifest.sha256
```

For Simulator or signed-device recovery, install the known-good app over the
existing installation. Do not uninstall first: uninstalling removes the private
app container, including the user-imported ROM and saves. AnnePad's atomic save
path restores a valid backup and quarantines a corrupt primary automatically;
copy any important device container or save evidence before further testing.
Never commit the ROM, saves, signing material, IPA, or device container.

The tag means locally reproduced source/package plus Simulator acceptance. It
does not mean a signed physical-device build, public-distribution authorization,
or App Store acceptance.
