# Legal and asset boundaries

This is an engineering policy, not legal advice.

## Allowed in git

- AnnePad-authored source, scripts, configuration, tests, documentation, and
  original artwork created for the app.
- Small patch files against precisely pinned open-source dependencies when the
  applicable licenses permit modification and redistribution.
- Commit hashes, expected file sizes, cryptographic hashes, and instructions
  used to validate user-supplied material.
- License texts and attribution required by redistributed dependencies.

## Never allowed in git, app bundles, IPAs, releases, CI artifacts, or logs

- Pokémon Stadium ROMs in any byte order or revision.
- Extracted ROM segments, generated source that embeds ROM data, textures,
  models, audio, video, fonts, box art, save data, or Transfer Pak cartridge
  images unless a file-by-file audit establishes independent redistribution
  rights.
- Nintendo firmware, keys, SDK files, private symbols, or proprietary tools.
- Provisioning profiles, certificates, private keys, credentials, tokens,
  personal identifiers, or device diagnostics containing private data.

Derived recompiled C/C++ is generated locally from the user's ROM, kept under
ignored paths, and treated as prohibited release material until a documented
legal review says otherwise. A source build may consume it locally; packaging
must prove it did not enter the shipped resources as a separable asset.

The native iOS target deliberately does not copy the desktop launcher's
`assets/` directory. In particular, its fonts, cartridge icons, and box art are
absent from the app and IPA. The package audit fails if that directory, box-art
paths, ROM/save extensions, provisioning data, signatures, or credentials
appear. The only authored visual package input is the original AnnePad app icon.

## User ROM flow

AnnePad supports only Pokémon Stadium (US) 1.0, 33,554,432 bytes, normalized
big-endian MD5 `ed1378bc12115f71209a77844965ba50`. The app or build scripts may
normalize `.v64`/`.n64` byte order in a private local location, then validate
size and digest before use. Unsupported or modified inputs fail closed with a
clear message. The original and normalized files remain local.

## Upstream licensing state

- PokémonStadiumRecomp and N64ModernRuntime declare GPL-3.0.
- N64Recomp and mstan/RT64 declare MIT.
- BearBirdPad declares GPL-3.0-or-later and is suitable as an architectural and
  implementation reference when its license obligations are preserved.
- The local HarkinianPad checkout marks project-owned material all rights
  reserved. It may guide design, but code or artwork must not be copied into a
  public AnnePad release without explicit permission and attribution terms.
- The pinned `pret/pokestadium` checkout has no repository-level license.
- The pinned `mstan/recomp-ui` checkout licenses bundled third-party code but
  does not state a license for the launcher itself.

The last two items block public source or binary redistribution of those
components. They may be inspected and used as local build inputs while their
status is resolved. A public release must either obtain clear permission,
replace the component, or contain no redistributed portion of it.

The iOS bundle contains `ThirdPartyNotices.txt` with the major linked runtime
components, license identifiers, source locations, source-offer requirement,
trademark disclaimer, and no-warranty notice. This improves a private sideload
candidate but does not resolve the missing `pret/pokestadium` and `recomp-ui`
licenses or substitute for a file-by-file distribution review.

The current unsigned IPA audit passes the technical boundary: no ROM, save,
separable generated source/assets, desktop launcher media, signing material,
credential, unexpected dynamic library, or developer-machine path is present.
That technical result does not close the unresolved license/rights gate.

## Screenshots and test evidence

Private local screenshots may document engineering tests. Public screenshots,
videos, store art, and repositories require a separate rights review and must
not reveal ROM paths, account names, device identifiers, or signing details.

## Sideloading and App Store

A locally signed or unsigned IPA proves packaging only. App Store distribution
adds review-guideline, intellectual-property, privacy-manifest, encryption,
entitlement, executable-code, and licensing requirements. AnnePad must compile
out runtime JIT/codegen and dynamic plugins on iOS regardless of distribution
channel. No store submission is authorized by this project plan.
