## Why

`auto_provision.sh` currently fails immediately when `oci` is missing, forcing users to manually discover and install the OCI CLI before using the script. The script should bootstrap this dependency by detecting the machine OS, installing OCI CLI when absent, then continuing with provisioning.

## What Changes

- Detect whether `oci` is already installed and usable.
- Detect machine OS and architecture before choosing an install path.
- Install OCI CLI automatically when missing, using the supported Oracle installer from https://github.com/oracle/oci-cli where practical.
- Prefer safe platform-native behavior for macOS and Linux; fail with clear instructions on unsupported platforms.
- Continue with the existing provisioning flow after OCI CLI installation succeeds.
- Do not overwrite existing OCI configuration or run `oci setup config` automatically.

## Capabilities

### New Capabilities

### Modified Capabilities
- `auto-provisioning`: Add OCI CLI bootstrap behavior before default or raw provisioning runs.

## Impact

- **Script:** Updates `auto_provision.sh` startup flow.
- **Dependencies:** May invoke `bash`, `curl`, and Python tooling used by Oracle's OCI CLI installer.
- **Systems:** Affects macOS and Linux environments; unsupported OSes receive manual install guidance.
- **User experience:** Reduces setup friction while preserving existing OCI config safety.
