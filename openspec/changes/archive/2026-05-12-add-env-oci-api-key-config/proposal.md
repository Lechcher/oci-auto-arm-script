## Why

Users currently need to maintain OCI API key configuration in `~/.oci/config` or a project-local `.oci/config` file, while the rest of the script configuration already lives in `.env`. Allowing OCI API key config fields in `.env` makes one-file local setup easier while preserving secret-safety guidance and source-control protections.

## What Changes

- Add support for OCI API key config values in `.env`, including user OCID, fingerprint, tenancy OCID, region, and private key file path.
- Allow the script to materialize or otherwise pass those `.env` values to OCI CLI for `api-key` auth without requiring users to hand-write `.oci/config` or `~/.oci/config`.
- Update `.env.example` with placeholder OCI API key config fields and warnings to avoid committing real values.
- Keep existing `OCI_CLI_CONFIG_FILE` / `--oci-config-file` behavior available for users who prefer OCI config files.
- Ensure principal auth modes ignore API-key-specific `.env` fields.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `auto-provisioning`: API key authentication and dotenv configuration requirements change to support OCI API key config fields directly from `.env`.

## Impact

- Affected code: `auto_provision.sh`, `.env.example`, README authentication/configuration documentation.
- Affected specs: `openspec/specs/auto-provisioning/spec.md`.
- Security impact: `.env` may contain sensitive OCI identifiers and fingerprint values; `.env` must remain ignored, values must not be printed, and private key contents must still not be stored in `.env`.
- Compatibility: Existing `~/.oci/config`, `.oci/config`, `OCI_CLI_CONFIG_FILE`, and profile workflows should keep working.
