# Security

Report security issues privately to the project maintainer before public disclosure.

## Scope

- Privilege escalation or unsafe administrator flows.
- Memory write operations that can target unrelated processes.
- Release artifacts with broken signing or unexpected bundled files.
- Logs or diagnostics that expose private paths, save contents, secrets, or memory dumps.

## Secrets

Do not commit API keys, signing credentials, Apple notarization credentials, or local account identifiers.

Local reverse-engineering fixtures and extracted game binaries are not part of the public repository.
