# Performance and completion audit

Updated: 2026-08-01 16:14 CDT

## Bottom line

AnnePad does not have one generic “slow game” problem. The current evidence
separates three different concerns:

1. The iPad Simulator misses the game's 30 Hz presentation cadence in some
   scenes, with synchronous Simulator Metal argument-buffer/XPC work dominating
   sampled non-idle time.
2. Release previously executed several upstream reverse-engineering probes.
   Ninety-six diagnostic hook sites are now compiled out while the six
   separately classified correctness hooks remain active.
3. Gameplay completion is gated less by compilation than by deterministic
   touch acceptance, a full battle with the corrected overlay, and physical
   iPad signing, lifecycle, audio, controller, sustained-performance, and
   thermal tests.

The macOS static recompilation has completed a full rental battle. The native
iOS build renders, advances, accepts touch, saves, resumes, and packages, but it
is not yet physically proven or release-ready.

## Ranked findings

### 1. Simulator Metal submission is the leading measured frame-time cost

- The optimized game reports a 30 Hz VI rate while the Simulator often presents
  fewer frames.
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

### 4. The corrected touch layer is HarkinianPad-derived but not accepted yet

- The current overlay adapts HarkinianPad's accepted phone/tablet grip geometry,
  safe-area behavior, customization model, pressed/latched visuals, 0.5-second
  Z latch, haptic confirmation, and cancellation rules.
- AnnePad intentionally uses a direct normalized N64 snapshot instead of
  HarkinianPad's synthetic keyboard events so analog stick magnitude is not
  discarded.
- Quick taps are retained across runtime polls. The present implementation uses
  one shared poll window for all tap bits, so overlapping taps can extend one
  another and a producer/consumer boundary still needs deterministic coverage.
- Start navigation and editor/lifecycle smokes pass in Simulator. A full
  touch-only battle after the HarkinianPad-derived replacement has not been
  completed.

### 5. The remaining finish line is mostly acceptance work

In priority order:

1. Add deterministic tap/Z/cancellation coverage and complete a touch-only
   rental battle with the corrected overlay.
2. Rebuild and reproduce the exact current unsigned device package from a clean
   checkout.
3. On an attached signed iPad, run the same heavy scene and collect frame-time,
   memory, thermal, audio, lifecycle, and controller evidence.
4. Resolve upstream licensing and store/distribution requirements before any
   public release.

## Decision rules

- Do not lower visual quality again unless a frame-identical measurement shows
  that fill rate is material.
- Do not remove RT64 command-fence waits based only on Simulator symptoms.
- Do not describe Simulator launch, unsigned compilation, or a historical
  battle with the old overlay as physical-iPad acceptance.
- Prefer small patches that can be forward/reverse verified and independently
  removed.
