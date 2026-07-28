# Contributing

Contributions must preserve the trainer product model:

- Player features are manifest-first.
- Player buttons do not run global memory scans.
- Unknown builds must be rejected before player writes. Use the explicit local
  compatibility report to collect evidence for a new exact profile.
- Multi-point patches are transactional.
- Writes require readback or behavior verification.
- Development discovery code must stay behind explicit diagnostics.

## Feature Workflow

1. Document the target in `DaveTrainerManifest`.
2. Add tests for unknown-build feature validation, target mismatch, write failure, verify failure, and success.
3. Implement the smallest validated patch or runtime object path.
4. Keep game-specific addresses and offsets in the Dave project, not in the generic skill.
5. Run `swift test` before publishing changes.

Do not add silent fallback, mock success, unverified runtime guessing, or unbounded compatibility paths.
