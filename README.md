# AnnePad

AnnePad is an experimental native iPhone, iPad, and Apple Silicon port of
Pokémon Stadium built from static recompilation. It is not an emulator wrapper,
contains no game ROM, and requires a legally obtained Pokémon Stadium (US) 1.0
ROM supplied by the user.

The native macOS build completes a full rental battle. iPhone and iPad Simulator
builds render through Metal, use native customizable multitouch controls, import
and validate the user's ROM through a document picker, and recover atomic saves
across background/relaunch. The arm64 iPhoneOS app and audited,
reproducible-content IPA build unsigned and reproduce from an isolated clean
source snapshot. Signed
physical iPhone/iPad, controller, real-speaker audio, hardware lifecycle, and
hardware touch-battle gates remain open because this Mac currently has no
attached device or signing identity.

Start with:

- [`docs/STATUS.md`](docs/STATUS.md) for passing and open gates.
- [`docs/BUILDING.md`](docs/BUILDING.md) for exact reproducible commands.
- [`docs/TESTING.md`](docs/TESTING.md) for runtime acceptance criteria.
- [`docs/LEGAL-AND-ASSET-BOUNDARIES.md`](docs/LEGAL-AND-ASSET-BOUNDARIES.md)
  before handling any ROM, generated source, screenshot, or package.
- [`docs/RELEASE-CHECKLIST.md`](docs/RELEASE-CHECKLIST.md) before distributing
  anything.

AnnePad is independent and is not affiliated with or endorsed by Nintendo,
Creatures, or GAME FREAK. Pokémon and Pokémon Stadium are trademarks of their
respective owners. This repository's upstream licensing gaps block public
redistribution until resolved; see the legal document and blocker B-004.
