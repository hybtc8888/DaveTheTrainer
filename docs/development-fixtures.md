# Development Fixtures

Reverse-engineering fixtures are local-only development inputs.

Do not commit:

- Extracted `GameAssembly.dylib` files.
- `nm`, `otool`, `dwarfdump`, or disassembly outputs.
- Memory dumps.
- Save files.
- `.codex/` or `.agents/` local environment files.
- Local app bundles, zips, logs, or signing artifacts.

Discovery work should produce reviewed manifest entries and tests, not player-runtime scanning fallback.
