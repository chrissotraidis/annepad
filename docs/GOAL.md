# AnnePad goal

AnnePad is complete when a clean checkout can reproducibly build a native
iPhone and iPad port of Pokémon Stadium (US) 1.0 from a legally obtained ROM
supplied by the user. The game must use ahead-of-time static recompilation and
a native Apple runtime; an emulator wrapper is not acceptable.

The project name is **AnnePad**. The objective's occasional `AniPad` spelling
is treated as a typo.

## Success criteria

- The user supplies and validates the exact supported ROM; no ROM or extracted
  copyrighted game asset is committed or shipped.
- Exact source inputs are pinned, fetched without push access, patchable, and
  documented. Generated recompiled source stays local and ignored.
- A native arm64 macOS build completes a rental-Pokémon battle before the iOS
  platform work is accepted.
- The same game core builds for iOS Simulator and signed physical iPhone and
  iPad targets without runtime-loaded executable code, plugins, or an emulator.
- Rendering, audio, normalized controller input, saves, configuration, ROM
  setup, background/foreground transitions, interruption handling, and file
  access work on real hardware.
- Customizable multitouch controls support simultaneous stick and button input.
  A complete rental-Pokémon battle is played on physical hardware using touch.
- Physical controllers are validated separately from touch on iPhone and iPad.
- The build is reproducible from a clean checkout plus the user's local ROM and
  documented toolchain. Automated audits reject prohibited files.
- A signed device build and deterministic unsigned IPA are produced. The IPA
  passes payload, binary, license, privacy, and forbidden-asset audits.
- Status, build, test, legal, release, decision, history, and worklog documents
  match the evidence at release time.

## Exclusions

- No bundled or downloaded Pokémon Stadium ROM, save, Transfer Pak cartridge
  image, firmware, keys, or prohibited extracted game assets.
- No emulator frontend, libretro core, virtual machine, JIT required for base
  gameplay, or executable-code download.
- No claim of App Store eligibility or approval without a separate legal and
  policy review. Sideloading success is not App Store proof.
- Texture packs, mods, Transfer Pak, and GB Tower are deferred until the base
  rental-battle loop is stable. Their omission does not justify weakening the
  base-game acceptance gates.
- Simulator success is not physical-device success, and a successful build is
  not gameplay validation.
