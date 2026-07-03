# Permissions And Privacy

DaveTheTrainer modifies a running macOS game process. macOS may require administrator authorization to attach to the game task and write memory.

## Permission Model

- The player GUI should not run arbitrary privileged commands.
- Elevation is only for attach/read/write work against the supported game process.
- Unsupported game builds must fail before writing memory.
- Permission denial is reported directly to the player.

## Local Data

The app may read:

- The game bundle identity.
- The running game process identity.
- Supported build files needed for manifest validation.
- Local save files when the player uses backup features.

The app does not upload telemetry, memory dumps, save files, or diagnostics.

## Diagnostic Redaction

Public diagnostics must redact:

- Home directory paths.
- Raw memory addresses.
- Save file paths and Steam account directories.
- Unrelated process lists.
- Extracted game symbols and memory dumps.
