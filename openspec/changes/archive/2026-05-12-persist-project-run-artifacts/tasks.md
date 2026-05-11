## 1. CLI Options and Paths

- [x] 1.1 Add project artifact root option and environment input, with default `.oci-arm-runs`.
- [x] 1.2 Add project OCI config file option and environment input for API key auth.
- [x] 1.3 Keep existing profile option and ensure profile is recorded in project artifacts when used.
- [x] 1.4 Add explicit SSH private key copy option and overwrite/force guard for secret-bearing artifacts.
- [x] 1.5 Update help output to explain project-local artifacts, config path behavior, secret warnings, and source-control expectations.

## 2. OCI Config Integration

- [x] 2.1 Apply project OCI config file path to API key auth preflight without modifying the config file.
- [x] 2.2 Apply project OCI config file path to script-built OCI resource lookup, launch, and public IP discovery commands.
- [x] 2.3 Ensure instance-principal and resource-principal modes do not require or use API key config/profile inputs as authentication requirements.
- [x] 2.4 Improve auth failure guidance to mention selected project config path when config validation fails.

## 3. Run Artifact Generation

- [x] 3.1 Create a unique project-local run directory for each successful default provisioning run.
- [x] 3.2 Write raw OCI instance launch response to a machine-readable file in the run directory.
- [x] 3.3 Write human-readable run summary with instance OCID, display name, region, public IP when available, SSH user, SSH command, OCI profile, OCI config path, and timestamp.
- [x] 3.4 Write SSH command file in the run directory when public IP discovery succeeds.
- [x] 3.5 Preserve existing `--ssh-info-file` behavior or map it clearly to the new project artifact behavior without breaking existing callers.

## 4. SSH Private Key Artifact Handling

- [x] 4.1 Record SSH private key path in run metadata by default without copying private key contents.
- [x] 4.2 Copy SSH private key into the run directory only when explicitly requested.
- [x] 4.3 Set copied private key file permissions to `0600` and fail if permissions cannot be set.
- [x] 4.4 Refuse to overwrite existing private key artifacts unless explicit overwrite behavior is provided.
- [x] 4.5 Ensure private key contents are never printed in success, error, or debug output.

## 5. Source-Control Safety

- [x] 5.1 Add or verify ignore coverage for the project artifact root when source-control metadata is present.
- [x] 5.2 Print a warning when ignore coverage cannot be applied or verified.
- [x] 5.3 Ensure generated config/key/artifact paths are reported without exposing secret file contents.

## 6. Verification

- [x] 6.1 Run shell syntax validation for `auto_provision.sh`.
- [x] 6.2 Verify help output documents project artifact root, project OCI config file, profile, and SSH private key copy behavior.
- [x] 6.3 Verify API key preflight uses project config path in stubbed OCI CLI calls.
- [x] 6.4 Verify principal auth modes do not require project config path.
- [x] 6.5 Verify successful stubbed launch writes expected project run artifact files.
- [x] 6.6 Verify private key copy requires explicit opt-in, writes mode `0600`, and refuses accidental overwrite.
- [x] 6.7 Verify secret contents are not printed to stdout or stderr during artifact generation.
