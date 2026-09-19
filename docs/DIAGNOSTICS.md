# Sharing a crash diagnostic

Preview 4 / build 4 adds a local diagnostic report. It is an investigation build
for [issue #2](https://github.com/chrissotraidis/annepad/issues/2), not a confirmed
fix for the Brock-gym battle crash.

1. Update the existing AnnePad installation. Do not uninstall it or remove game
   data. Keep the same bundle/signing identity when re-signing.
2. Reproduce the crash once, then relaunch AnnePad.
3. Open the in-game utility menu and choose **Share Diagnostics**. The same
   action is available on the ROM setup screen.
4. Save or attach **AnnePad-Diagnostics.txt** to your existing issue. Also state
   which rental Pokémon or Transfer Pak team you selected and whether the first
   Pokémon appeared before the crash. Do not send ROMs, saves or Transfer Pak data.

Export immediately after the relaunch: the report contains the current and
previous session, rather than an unlimited history. Nothing uploads automatically.

The report contains version/build, executable UUID, OS version, session start,
fixed lifecycle events, periodic app memory footprint/available memory, and
best-effort fatal-signal details. Known runtime failure addresses are extracted
as numbers; raw runtime logs, guest memory dumps, file paths, account information,
ROMs, saves and device identifiers are excluded. Diagnostic text stays bounded
at approximately 64 KiB per session; an export has at most two sessions.

A memory kill (SIGKILL/jetsam) cannot be caught by an app signal handler. A report
without a fatal signal is not proof of a memory kill: suspension or a normal
system termination can also end a session without a final event. If the report
cannot distinguish the failure, the maintainer may ask for the matching AnnePad
`.ips` or JetsamEvent entry from iOS Analytics Data, with personal/device
identifiers removed. Existing iOS crash reporting is not replaced or suppressed.

## Maintainer validation

`./scripts/test-ios-diagnostics.sh ISOLATED_BOOTED_SIMULATOR_UUID` compiles the
same diagnostic implementation used by the app. It induces SIGABRT, verifies
normal signal termination, restarts the probe, verifies previous-session
recovery, forces journal wraparound, checks that private fixture text is absent,
and exercises report generation and creation of UIActivityViewController.
The test does not inject faults into a user's installed app or save container.

Retain the exact unsigned binary and its UUID with each diagnostic release.
The report's executable UUID identifies the matching binary; PC/LR offsets are
relative to that image's runtime load address. For PCs in system libraries or
when a full stack is needed, use the system `.ips` and matching symbols instead
of interpreting those offsets as game code. Physical-device and reporter
reproduction remain separate from the synthetic signal test.
