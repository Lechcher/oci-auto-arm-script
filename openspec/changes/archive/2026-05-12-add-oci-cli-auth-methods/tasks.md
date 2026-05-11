## 1. CLI Options and Help

- [x] 1.1 Add `--auth-method api-key|instance-principal|resource-principal` CLI option and `OCI_AUTH_METHOD` environment input with `api-key` as default.
- [x] 1.2 Validate auth method values and fail fast for unsupported values.
- [x] 1.3 Update help text to document API key config, instance principal, resource principal, and why `oci session authenticate` is not used for scripts.
- [x] 1.4 Keep `--profile` / `OCI_PROFILE` documented for API key profiles.

## 2. OCI Command Construction

- [x] 2.1 Add helper logic that maps `api-key` to no `--auth`, `instance-principal` to `--auth instance_principal`, and `resource-principal` to `--auth resource_principal`.
- [x] 2.2 Apply selected auth options to script-built OCI helper commands such as resource lookup and public IP lookup.
- [x] 2.3 Apply selected auth options to the default `oci compute instance launch` command.
- [x] 2.4 Preserve raw command execution exactly as provided after `--` while still running preflight auth with the selected method.

## 3. Authentication Preflight

- [x] 3.1 Add `validate_oci_auth` after OCI CLI bootstrap and before default command construction or launch retry logic.
- [x] 3.2 Run lightweight preflight command `oci os ns get` with selected region/profile/auth options.
- [x] 3.3 Stop before provisioning when authentication validation fails.
- [x] 3.4 Ensure validation does not run `oci setup config`, `oci session authenticate`, or write OCI config/key files.

## 4. Troubleshooting Guidance

- [x] 4.1 Classify missing OCI config errors and print API key config guidance.
- [x] 4.2 Classify missing private key path errors and print key file/path/permission guidance.
- [x] 4.3 Classify fingerprint mismatch and `NotAuthenticated` errors and print credential verification guidance.
- [x] 4.4 Classify permission denied errors and print IAM policy guidance.
- [x] 4.5 Print instance principal guidance when selected auth fails.
- [x] 4.6 Print resource principal guidance when selected auth fails.

## 5. Verification

- [x] 5.1 Run shell syntax validation for `auto_provision.sh`.
- [x] 5.2 Verify help output documents auth methods and automation-safe login guidance.
- [x] 5.3 Verify invalid `--auth-method` fails before provisioning.
- [x] 5.4 Verify raw command mode preserves the user command after preflight.
- [x] 5.5 Verify no implementation path invokes `oci setup config` or `oci session authenticate`.
- [ ] 5.6 If valid credentials are available, verify API key preflight succeeds with `--profile DEFAULT`.
- [ ] 5.7 If running on OCI Compute with IAM configured, verify instance principal preflight succeeds.
