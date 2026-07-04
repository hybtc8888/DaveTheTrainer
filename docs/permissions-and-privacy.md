# Permissions And Privacy

DaveTheTrainer modifies a running macOS game process. macOS may require administrator authorization to attach to the game task and write memory.

## Permission Model

- The player GUI should not run arbitrary privileged commands.
- Elevation is only for attach/read/write work against the detected Dave game process.
- Unknown game builds may be attempted, but each feature must fail before writing
  when its own target validation cannot pass.
- Permission denial is reported directly to the player.

## Local Data

The app may read:

- The game bundle identity.
- The running game process identity.
- Build fingerprint files needed for manifest selection and feature validation.
- Local save files when the player uses backup features.

The app does not upload telemetry, memory dumps, save files, or diagnostics.

## Diagnostic Redaction

Public diagnostics must redact:

- Home directory paths.
- Raw memory addresses.
- Save file paths and Steam account directories.
- Unrelated process lists.
- Extracted game symbols and memory dumps.
