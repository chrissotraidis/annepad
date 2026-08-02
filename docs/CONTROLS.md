# Pokémon Stadium controls

Updated: 2026-08-02 09:08 CDT

This is the game-specific input contract for AnnePad's touch design. It covers
Pokémon Stadium (US) 1.0, not the superficially similar controls of Zelda or
later Pokémon games.

## Core battle and menu behavior

| Input | Stadium behavior relevant to touch |
| --- | --- |
| D-pad | Primary cursor and list navigation. |
| Control Stick | Used where the game requests analogue input, especially some Kids Club games. |
| A | Confirm; battle; select assigned Pokémon; several minigame actions. |
| B | Cancel; choose/change an assigned Pokémon in battle. |
| C buttons | Choose assigned moves or Pokémon; mode-specific actions. |
| L | Page/list navigation; hold during battle to reveal hidden Pokémon and move assignments. |
| R | Page/list navigation; hold R while pressing a Pokémon's assigned button to inspect its data. |
| Z | Cancel/reset/cycle-style press; held Z only accelerates a generic list scroll helper. |
| Start | Start/pause or battle forfeit where the current mode allows it. |

The original instruction booklet documents the R-plus-selection inspection
chord and holding L to check hidden battle assignments. An exhaustive audit of
controller-bit `0x2000` in the pinned decomp found only three Z reads: one
`buttonDown` read that accelerates a generic list helper, one `buttonPressed`
read that cycles a three-state display, and one `buttonPressed` read that resets
mode state. No Z-plus-button gameplay chord was found. Kids Club uses the
D-pad/stick, A/B, or alternating L/R depending on the minigame; persistent Z is
not part of its normal controls.

Sources:

- [Pokémon Stadium instruction booklet](https://manualzz.com/doc/24022192/nintendo-64-game-pak-pok%C3%A9mon-stadium-instruction-booklet)
- `ref/harkinianpad/docs/customizable-touch-controls.md`
- `external/sources/PokemonStadiumRecomp/disasm/src/controller.h`
- `external/sources/PokemonStadiumRecomp/disasm/src/2E460.c`
- `external/sources/PokemonStadiumRecomp/disasm/src/fragments/15/fragment15_14CA70.c`
- `external/sources/PokemonStadiumRecomp/disasm/src/fragments/19/fragment19.c`
- `external/sources/PokemonStadiumRecomp/disasm/src/fragments/62/fragment62_2F74E0.c`

## HarkinianPad adaptation boundary

AnnePad uses HarkinianPad as the requested starting point for its low-grip
iPhone/iPad geometry, safe-area-normalized layouts, per-control customization,
multitouch ownership, visible pressed state, and cancellation on lifecycle or
management transitions. It keeps AnnePad's direct analogue N64 snapshot bridge
instead of HarkinianPad's synthetic-key path so stick magnitude is preserved.

The 0.5-second persistent Z toggle is the one intentionally rejected mechanism.
It solves a Zelda-specific targeting ergonomics problem, while Stadium needs a
normal Z press/hold/release and practical access to its L/R inspection actions.

## AnnePad touch consequences

- Preserve true simultaneous multitouch. R plus a Pokémon button is a real
  chord and must not be reduced to synthetic single-key events.
- Give L and R longer short-tap retention than ordinary face buttons so a
  touchscreen user can enter an inspection chord sequentially without making
  the shoulder remain toggled indefinitely.
- Z follows normal finger-down/finger-up semantics. A very short tap is retained
  for several runtime polls. A finger may keep Z held for the one list-speed
  path, but release clears it instead of toggling a persistent latch.
- Clear every held and retained input when editing controls, opening ROM
  management, cancelling touches, or leaving the foreground.
- Keep the full N64 surface available because menus, battle, Kids Club, GB
  Tower, and utility screens use different subsets.

## Acceptance

Simulator acceptance must cover quick Z cancel/reset, held L inspection,
R-plus-selection inspection, ordinary release, cancellation, and
background/foreground clearing. Physical iPhone/iPad acceptance must repeat
those checks with real multitouch ergonomics before release.
