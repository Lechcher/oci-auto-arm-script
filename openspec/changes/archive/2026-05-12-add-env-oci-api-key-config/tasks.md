## 1. Dotenv Inputs

- [x] 1.1 Add supported dotenv/environment keys for OCI API key user OCID, fingerprint, tenancy OCID, and key file path.
- [x] 1.2 Ensure dotenv loading allowlist accepts the new OCI API key config keys without executing shell code.
- [x] 1.3 Define and apply config-source precedence between CLI flags, process environment, dotenv values, and built-in defaults.

## 2. API Key Config Materialization

- [x] 2.1 Detect when `api-key` auth has a complete dotenv-derived OCI API key config.
- [x] 2.2 Validate required dotenv API key fields and fail with safe missing-field guidance when incomplete.
- [x] 2.3 Reject or warn on dotenv values that appear to contain private key contents instead of a key file path.
- [x] 2.4 Generate or provide an OCI CLI-compatible config from dotenv values for preflight, resource lookup, launch, and post-launch discovery.
- [x] 2.5 Protect any generated intermediate config file with restrictive permissions and keep it under a source-control-ignored local path.
- [x] 2.6 Preserve existing `OCI_CLI_CONFIG_FILE`, `--oci-config-file`, and `OCI_PROFILE` workflows when dotenv-derived config is not used.

## 3. Auth Mode Isolation and Secret Safety

- [x] 3.1 Ensure instance-principal and resource-principal modes ignore all API-key-specific dotenv fields.
- [x] 3.2 Ensure logs and errors never print dotenv OCI API key values or generated config contents.
- [x] 3.3 Ensure `.env`, `.env.local`, `.env.*.local`, and any generated config path are ignored by source control when possible.

## 4. Documentation and Examples

- [x] 4.1 Update `.env.example` with placeholder OCI API key config fields and key-file-path-only guidance.
- [x] 4.2 Update README authentication/configuration docs to explain `.env`-based API key setup and existing config-file fallback.
- [x] 4.3 Keep examples free of real OCIDs, real fingerprints, private key contents, and user-specific secrets.

## 5. Validation

- [x] 5.1 Add or update stubbed OCI CLI tests to verify complete dotenv API key config is used for preflight and script-built OCI CLI calls.
- [x] 5.2 Verify incomplete dotenv API key config fails before provisioning and prints only safe guidance.
- [x] 5.3 Verify principal auth modes do not use or require dotenv API key config fields.
- [x] 5.4 Verify existing project-local config file and profile behavior still works.
- [x] 5.5 Run OpenSpec validation for `add-env-oci-api-key-config`.
