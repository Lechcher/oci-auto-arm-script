## Why

`auto_provision.sh` can install and call OCI CLI, but it does not guide or validate script-safe authentication before provisioning. Users need a clear automation path that avoids browser session login and supports API key config, instance principal, and resource principal modes without hard-coding secrets.

## What Changes

- Add script-oriented OCI CLI authentication handling and guidance.
- Support API key authentication through existing `~/.oci/config` and profile selection.
- Support instance principal and resource principal modes through an auth option passed to OCI CLI.
- Add preflight authentication checks before default or raw provisioning runs.
- Print targeted troubleshooting guidance for missing config, private key, fingerprint mismatch, permissions, and authentication failures.
- Explicitly discourage `oci session authenticate` for automation.
- Preserve secret safety by not writing OCI config, private keys, or credentials from the script.

## Capabilities

### New Capabilities

### Modified Capabilities
- `auto-provisioning`: Add script-safe OCI CLI authentication selection and preflight validation before provisioning.

## Impact

- **Script:** Updates `auto_provision.sh` option parsing, OCI command construction, and startup validation.
- **User inputs:** Adds authentication mode selection and documentation while preserving existing `--profile` behavior.
- **Security:** Avoids browser login flows and avoids storing secrets in the repository or script.
- **OCI behavior:** Supports API key config for local/non-OCI hosts, instance principal for OCI compute, and resource principal for supported OCI-managed environments.
