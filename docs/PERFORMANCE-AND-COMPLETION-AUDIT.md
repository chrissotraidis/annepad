# Performance and completion audit

Updated: 2026-08-01 15:26 CDT

## Bottom line

AnnePad does not have one generic “slow game” problem. The current evidence
separates three different concerns:

1. The iPad Simulator misses the game's 30 Hz presentation cadence in some
   scenes, with synchronous Simulator Metal argument-buffer/XPC work dominating
   sampled non-idle time.
2. Release still executes and prints several upstream reverse-engineering
   probes. They are not the sampled primary renderer cost, but they are
   inappropriate for a shipping build and can distort timing evidence.
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

### 2. Release diagnostics are still active

- A normal Release title/attract run produced 1,001 stderr lines and 74,440
  bytes in the observed window. Excluding the temporary 163-line present
  counter, 838 lines came from retained probes such as `[pers]`, `[aload]`,
  `[frag36]`, `[cri]`, pool, fragment, and geometry tracing.
- These probes live mainly in upstream `extras.c` and are called from explicit
  `game.toml` hooks. Some nearby hooks are load-bearing correctness fixes, so a
  blanket removal would be unsafe.
- The next release-surface slice must compile diagnostic-only hooks/logging out
  while retaining fragment cleanup, audio UAF protection, scheduler preemption,
  and loud persistent errors for genuinely unhandled code.

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

1. Compile release-only reverse-engineering probes out and repeat the controlled
   Simulator measurement.
2. Add deterministic tap/Z/cancellation coverage and complete a touch-only
   rental battle with the corrected overlay.
3. Rebuild and reproduce the exact current unsigned device package from a clean
   checkout.
4. On an attached signed iPad, run the same heavy scene and collect frame-time,
   memory, thermal, audio, lifecycle, and controller evidence.
5. Resolve upstream licensing and store/distribution requirements before any
   public release.

## Decision rules

- Do not lower visual quality again unless a frame-identical measurement shows
  that fill rate is material.
- Do not remove RT64 command-fence waits based only on Simulator symptoms.
- Do not describe Simulator launch, unsigned compilation, or a historical
  battle with the old overlay as physical-iPad acceptance.
- Prefer small patches that can be forward/reverse verified and independently
  removed.
