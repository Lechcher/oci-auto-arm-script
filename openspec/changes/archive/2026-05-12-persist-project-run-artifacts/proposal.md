## Why

Provisioning currently depends on user-home OCI configuration and writes only minimal SSH connection output. The project needs a repeatable, project-local run directory so instance details, SSH material references, and OCI profile configuration used for login are captured with each provisioning run.

## What Changes

- Add project-local artifact output for each provisioning run, including instance export information and SSH connection details.
- Add support for writing or copying run-specific SSH private key material into the project artifact directory when explicitly requested, with restrictive permissions and secret-safe defaults.
- Add first-class OCI CLI config/profile inputs so users can keep login configuration inside the project instead of relying only on `~/.oci/config`.
- Add clear output paths and guidance so future reruns, SSH login, and troubleshooting use files from the project directory.
- Preserve existing default behavior unless project-local artifact/config options are provided.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `auto-provisioning`: Add requirements for project-local run artifacts, exported instance information, SSH private key artifact handling, and OCI CLI config/profile selection.

## Impact

- Affects `auto_provision.sh` CLI options, environment inputs, auth preflight, default provisioning output, SSH info generation, and file permission handling.
- Adds project-local files or directories for generated run artifacts, likely under a predictable ignored output path such as `.oci-arm-runs/`.
- Requires careful secret handling to avoid printing private keys, committing credential files, or overwriting existing project artifacts unintentionally.
