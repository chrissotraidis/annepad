# Repository and dependency inventory

Snapshot: 2026-07-31. `Selected` means part of the provisional implementation
graph; `reference` means read-only research; `rejected` means not a foundation.

| Project | Commit / version | Role | License observed | Disposition |
| --- | --- | --- | --- | --- |
| `mstan/PokemonStadiumRecomp` | `de27b7b8481630d41fc7fb913dbd02572d421efd` (`v0.4.6`) | Stadium game integration | GPL-3.0 | Selected |
| `pret/pokestadium` | `756f7e332ee3837ead17197276cebc071108e8c6` | ROM split/symbol inputs | No repo-level license found | Selected local-only |
| `mstan/recomp-ui` | `4ed61d0dd826bb81f17d3b23e412b974114bf83f` | Desktop preboot launcher | Project license not stated | Desktop reference only |
| `mstan/N64Recomp` | `2b949c5c3f1c41dd76023e7626a6302a4a262a8a` | Host AOT generator | MIT | Selected generator pin |
| `mstan/N64Recomp` | `94838144bb970ca6b415636924339e90bafa9ebd` | NMR runtime/LiveRecomp interface | MIT | Selected NMR gitlink |
| `mstan/N64ModernRuntime` | `d4bf8828514c567df42ff049e1e90505bdcdb734` | Runtime candidate | GPL-3.0 | Provisional inferred pin |
| `mstan/rt64` | `821a8676963a1b486ca693ebaf8dd606f6c31c64` | Renderer candidate | MIT | Provisional inferred pin |
| `chrissotraidis/bearbirdpad` | `0451d3fae492bb9c474e90596cba7efce820b349` | Static-recomp iOS reference | GPL-3.0-or-later | Primary reference |
| local `ref/harkinianpad` | `4db21e4be0f0be52948438de5d8c755d191897ae` | Native iOS UX/platform reference | Project work all rights reserved; third party mixed | Design reference |
| `Manurocker95/BanjoRecomp-Android` | `2966e05…` | Android runtime reference | Repository license inspected locally | Secondary reference |
| official `N64Recomp/N64Recomp` | current default branch inspected | Canonical AOT tool history | MIT | Upstream reference |
| official `N64Recomp/N64ModernRuntime` | current default branch inspected | Canonical runtime | GPL-3.0 | Upstream reference |
| official `rt64/rt64` | `6f1c2d9…` comparison point | RT64/Plume Apple renderer | MIT/mixed dependencies | Alternative candidate |
| `LucioXerus/PokemonStadiumRecomp` | ahead 1 / behind 43 at review | Old vendored graph | Inherits upstream | Rejected as base |
| `Raafas/PokemonStadiumRecomp` | behind 5 | Fork | Inherits upstream | Rejected as stale |
| `Manurocker95/PokemonStadiumRecomp` | behind 43 | Fork | Inherits upstream | Rejected as stale |

## Pokémon Stadium branches and issues

The upstream default branch and release branches were inspected, along with
branches for audio, Transfer Pak, widescreen, UI, and game fixes. No branch is a
strictly better Apple-ready base. All open pull requests were checked; none
provides the port.

Issues #1–#21 were reviewed through GitHub metadata. Current open reports cover
startup/antivirus behavior, Linux, audio, L-button mapping, a Starmie crash,
GB Tower, fullscreen, launcher CPU use, menu graphics, and a CRT-driver crash.
README/issue status is inconsistent in places, so AnnePad will retest rather
than inherit claims.

## Known release inputs

The v0.4.6 release contains one Windows x64 ZIP and no source dependency
manifest. The artifact observed during research was 116,252,237 bytes with
SHA-256 `ecc5422b1608ec92bf49d676fe3d8f2d315b61df9dc2bbfe6b0e72a2892620c2`.
It includes the executable, DLLs, assets, notices, and docs but cannot identify
the exact runtime/renderer commits used.

The N64ModernRuntime and RT64 commits in the table were the respective fork
heads before the v0.4.6 release and are therefore reasonable reconstruction
starting points, not proven release inputs. Milestone 0 must record any API or
behavior mismatch and must not relabel inference as provenance.

The graph intentionally contains two N64Recomp revisions. PokémonStadiumRecomp's
`n64recomp.pin` selects `2b949c5` for host generation, while the inferred NMR
commit's gitlink selects `9483814` for the runtime/LiveRecomp library interface.
They must not be collapsed until a tested source update proves compatibility.

## N64Recomp subdependencies at the generator pin

| Dependency | Commit | State |
| --- | --- | --- |
| ELFIO | `ad8b641f9682b6091ba8b9f7c8152255c1a2c803` | Fetchable |
| fmt | `8e728044f673774160f43b44a07c6b185352310f` | Fetchable |
| Rabbitizer | `e0d8003047938e2ec3697eaf8d61a84d11d17b43` | Fetchable |
| sljit | `f6326087b3404efb07c6d3deed97b3c3b8098c0c` | Fetchable; target JIT forbidden on iOS |
| tomlplusplus | `1f7884e59165e517462f922e7b6de131bd9844f3` | Fetchable |
| optional Ares bridge | gitlink expected `ef10a9a…` by fresh recursive fetch | Broken upstream reference; exclude |

## Toolchain observed

- macOS on Apple Silicon, zsh, git 2.36.1.
- Xcode 26.6 (17F113); iOS 18.5 and 26.5 SDK/Simulator runtimes.
- CMake 4.4.0 and Ninja 1.13.2.
- No Wine, CrossOver, Whisky, UTM, Parallels, or VMware runtime found.
- The decomp README expects Python >3.7, GNU make, and
  `binutils-mips-linux-gnu`; exact local provisioning remains a Milestone 0 task.

## Local-only inputs

The `research/` directory contains ignored clones and release material. The
`ref/` directory contains the ignored user ROM and HarkinianPad checkout. Their
presence is not a clean-checkout dependency; fetch scripts and documented local
input paths will replace them.
