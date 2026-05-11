## Context

`auto_provision.sh` now bootstraps OCI CLI and provisions ARM instances, but it assumes OCI CLI is already authenticated. For automation, browser-style login (`oci session authenticate`) is not appropriate because it requires an interactive sign-in flow and produces session credentials less suited for long-running scripts.

The script should guide users toward stable non-interactive authentication modes while avoiding secret creation or storage. Existing `--profile` behavior should remain the default API key path, and OCI principal auth should be selectable for scripts running inside OCI-managed environments.

## Goals / Non-Goals

**Goals:**
- Support script-safe authentication modes: API key config, instance principal, and resource principal.
- Validate authentication before provisioning starts with a lightweight OCI CLI command.
- Keep `--profile` support for `~/.oci/config` profiles.
- Pass `--auth instance_principal` or `--auth resource_principal` consistently to all OCI CLI calls when selected.
- Provide clear troubleshooting for common authentication/config failures.
- Avoid storing, generating, or committing credentials.

**Non-Goals:**
- Running `oci setup config` or `oci session authenticate` automatically.
- Creating API keys, uploading public keys, or writing `~/.oci/config`.
- Managing IAM policies, dynamic groups, or resource principal environment setup.
- Supporting browser login for automation.

## Decisions

- **Authentication option:** Add `--auth-method api-key|instance-principal|resource-principal` plus `OCI_AUTH_METHOD`. API key remains default because it matches local machine, private server, and simple CI scripting.
- **OCI CLI argument mapping:** API key mode uses normal OCI CLI config/profile behavior and does not add `--auth`. Instance principal mode adds `--auth instance_principal`. Resource principal mode adds `--auth resource_principal`.
- **Profile handling:** Keep `--profile` and `OCI_PROFILE` for API key mode. If a principal auth method is selected, do not require a profile; profile should not be presented as the primary authentication mechanism for principal auth.
- **Preflight check:** Run a lightweight command before provisioning: `oci os ns get` is preferred because it validates tenancy authentication without requiring a compartment ID. If it fails, print targeted guidance and stop before launch/retry logic.
- **Error guidance:** Classify common stderr text such as missing config file, private key not found, fingerprint mismatch, permission denied, and `NotAuthenticated`; print concise next steps without exposing secrets.
- **Secret safety:** Do not write config or key files. Help text can show required files/permissions and link users to setup steps, but implementation must not prompt for or persist secret values.

## Risks / Trade-offs

- [Risk] `oci os ns get` may fail due to IAM or Object Storage restrictions even when some Compute calls might work. -> Mitigation: keep guidance clear and allow users to resolve IAM/auth before provisioning.
- [Risk] Principal auth only works in specific OCI environments. -> Mitigation: document requirements and fail clearly when selected outside those environments.
- [Risk] Users may expect script to create `~/.oci/config`. -> Mitigation: explicitly state config/key setup remains manual for security.
- [Risk] Existing raw command users may already include their own `--auth`. -> Mitigation: only inject auth into script-built OCI helper commands and default launch command; for raw commands, run preflight using selected auth but execute the user command unchanged.
