## Why

The `auto_provision.sh` script has grown to over 800 lines with complex logic spanning dotenv parsing, dependency installation, OCI resource resolution, JSON parsing, and retry loops. It needs inline comments to help developers and users understand the structure, function behaviors, and flow without reverse-engineering the code.

## What Changes

- Add block comments explaining the purpose of major script sections (e.g., config defaults, helper functions, OCI CLI install, resource lookups, retry loop).
- Add function-level comments describing inputs, outputs, and side effects for complex operations (like the dotenv parser and artifact writer).
- Add inline comments for non-obvious Bash idioms or string manipulations.

## Capabilities

### New Capabilities
None.

### Modified Capabilities
None (this is a documentation/maintenance change only; no behavior changes).

## Impact

- Affects `auto_provision.sh` readability and maintainability.
- No changes to script execution logic, arguments, or output behaviors.
