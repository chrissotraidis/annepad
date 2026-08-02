# Performance and completion audit

Updated: 2026-08-02 03:40 CDT

## Bottom line

AnnePad does not have one generic “slow game” problem. The current evidence
separates four different concerns:

1. The iPad Simulator misses the game's 30 Hz presentation cadence in some
   scenes, with synchronous Simulator Metal argument-buffer/XPC work dominating
   sampled non-idle time.
2. Release previously executed several upstream reverse-engineering probes.
   Ninety-six diagnostic hook sites are now compiled out while the six
   separately classified correctness hooks remain active.
3. Gameplay correctness has touch-only battle proof. The latest exact-source
   Simulator app builds, renders, advances, and remains alive; release
   completion is gated by revised-control acceptance and physical iPad signing,
   touch ergonomics, lifecycle, audio, controller, sustained-performance,
   orientation, and thermal tests.
4. The retained Simulator process is stable enough to finish a touch-only
   battle and remain alive for hours, but occasional Simulator CoreAudio
   overloads and incomplete cold-orientation acceptance are separate concerns.
   Neither should be mislabeled as a game crash or as renderer FPS.

The macOS static recompilation has completed a full rental battle. The native
iOS build renders, advances, accepts touch, saves, resumes, and packages, but it
is not yet physically proven or release-ready.

## Ranked findings

### 1. Simulator Metal submission is the leading measured frame-time cost

- The optimized game reports a 30 Hz VI rate while the Simulator often presents
  fewer frames.
- A bounded batching follow-up coalesces contiguous dirty Metal argument-buffer
  entries immediately before draw/dispatch and bypasses clean descriptor sets.
  The exact-source 12-second attract sample recorded 6,849 samples on the RT64
  workload thread, including 3,928 waiting on its command fence and 265 waiting
  on its mutex. Bulk `setBuffers`/`setTextures` calls replaced the old repeated
  single-entry setter hotspot. Because the scene is not frame-identical and no
  present counter was retained, this is directional throughput evidence rather
  than FPS acceptance.
- A five-second process sample repeatedly found synchronous
  `MTLSimArgumentEncoder` calls and `MTLSimDriver` XPC replies in the RT64
  workload thread.
- RT64 also waits after submitting the present command list. That serialization
  is shared renderer behavior and is not safe to remove without proving resource
  lifetime and cross-backend ordering.
- A controlled internal-resolution experiment contradicted the earlier
  drawable-size hypothesis. Changing RT64's internal multiplier from 3x to 1x
  kept the output full-screen but visibly pixelated it and did not improve the
  measured intro cadence. Pixel fill is therefore not the leading Simulator
  bottleneck.
- Physical Apple GPUs do not use the Simulator's host XPC driver path. A
  physical iPad trace is required before treating this as a device blocker or
  making a broad shared-renderer rewrite.

### 2. Release diagnostics were real shipping noise, not the FPS root cause

- A normal Release title/attract run produced 1,001 stderr lines and 74,440
  bytes in the observed window. Excluding the temporary 163-line present
  counter, 838 lines came from retained probes such as `[pers]`, `[aload]`,
  `[frag36]`, `[cri]`, pool, fragment, and geometry tracing.
- These probes live mainly in upstream `extras.c` and are called from explicit
  `game.toml` hooks. Ninety-six diagnostic-only call sites now compile to
  nothing in the shipping AOT core, including their argument evaluation.
- Fragment registration/cleanup, GB audio, fragment input/resolve, and audio-UAF
  voice protection remain active. The Release core audit fails unless its only
  `pkmnstadium_*` references are the three expected parts of that functional
  surface.
- The clean follow-up emitted 95 stderr lines and 8,243 bytes in the observed
  window, with zero `[pers]`, `[aload]`, `[frag36]`, `[cri]`, pool, geometry,
  segment-map, or asset-load probe lines.
- A temporary 29-window title/attract counter averaged 23.31 presents/s (4.15
  minimum, 30.56 maximum), with five windows below 20 and seven at or above 28.
  That is effectively unchanged from the preceding 23.40 mixed-scene result,
  so retained logging was not the leading FPS bottleneck. The counter was
  removed and the clean app rebuilt before this result was recorded.
- The audit also exposed a stale-build defect: Simulator/device app entry points
  previously audited an existing AOT archive instead of rebuilding it. Both now
  always invoke the incremental core build, so regenerated game sources cannot
  silently link against an old archive.

### 3. Metal color clears created and leaked native state

- RT64 created a new depth-stencil state every time `clearColor` targeted a
  framebuffer with depth, and the object was never released.
- A bounded candidate now creates one “depth compare always, writes disabled”
  state with the renderer interface, reuses it for color clears, and releases
  both cached clear states at teardown.
- The Release Simulator build succeeds, renders the full-size animated title,
  and no longer samples `newDepthStencilState` in that clear path.
- The non-frame-identical intro measurement did not prove a material FPS gain.
  Keep this as a correctness/leak fix, not a claimed performance breakthrough.

### 4. The corrected touch layer is HarkinianPad-derived and battle-proven

- The current overlay adapts HarkinianPad's accepted phone/tablet grip geometry,
  safe-area behavior, customization model, pressed visuals, and cancellation
  rules.
- AnnePad intentionally uses a direct normalized N64 snapshot instead of
  HarkinianPad's synthetic keyboard events so analog stick magnitude is not
  discarded.
- HarkinianPad's persistent Z latch is intentionally not retained. The original
  Stadium battle instructions document R+Pokémon inspection and held L move
  inspection, while Z is a cancel/reset-style press. Decompiled input paths
  likewise use `buttonPressed` for Z, with only generic list scrolling reading
  held Z. Persistent Z could suppress the next press edge or leak into another
  screen; normal finger-down/finger-up Z behavior remains.
- Quick taps now have independent atomic poll lifetimes per N64 button, so a
  later shoulder/Z tap cannot extend A/B/Start or another button. Host tests
  cover exact quick-tap expiry, the longer shoulder chord window, overlapping
  A+R, Z cancellation, and lifecycle clearing.
- Start navigation and editor/lifecycle smokes pass in Simulator. A full
  touch-only Battle Now rerun selected Squirtle/Pikachu/Bulbasaur, resolved all
  six rentals through an explicit `LOSE`, and returned to the main selection
  menu. The revised non-latching Z path and physical-device ergonomics remain
  to be smoke-tested.

### 5. Current evidence does not reproduce an AnnePad crash

- The corrected-overlay rental battle reached its explicit result, returned to
  the main selection menu, and observed no crash or stuck input.
- A follow-up live check found the same Simulator process still alive and
  rendering after approximately two hours. No AnnePad report was present in
  the host DiagnosticReports or that Simulator's CrashReporter directory.
- The Simulator log does contain occasional CoreAudio
  `IOWorkLoop: skipping cycle due to overload` entries. That is a real audio
  scheduling symptom under the measured Simulator load, not evidence of a
  process crash. Real-speaker/audio-underrun acceptance remains a physical-iPad
  gate.
- The current live Simulator window is correctly landscape with the complete
  overlay visible. Cold orientation still needs the planned repeated-boot
  matrix; a raw framebuffer whose pixels are stored in portrait order is not
  itself evidence that the visible app is sideways.
- The 2026-08-02 source-consistent Release app built and installed cleanly,
  rendered two visibly different attract frames, and retained PID 69075 through
  a 12-second live sample. The executable hash is
  `19bcd1cfef6f0fbaaac31acb046128baa748f87e5e231853de4a4c960b57b540`.

### 6. The remaining finish line is mostly acceptance work

In priority order:

1. Smoke the game-specific non-latching Z path, held-L inspection, and
   R-plus-selection inspection with the corrected overlay.
2. On an attached signed iPad, resolve cold orientation and run the same heavy
   scene while collecting frame-time,
   memory, thermal, audio, lifecycle, and controller evidence.
3. Resolve upstream licensing and store/distribution requirements before any
   public release.

## Decision rules

- Do not lower visual quality again unless a frame-identical measurement shows
  that fill rate is material.
- Do not remove RT64 command-fence waits based only on Simulator symptoms.
- Do not describe Simulator launch, unsigned compilation, or a historical
  battle with the old overlay as physical-iPad acceptance.
- Prefer small patches that can be forward/reverse verified and independently
  removed.
