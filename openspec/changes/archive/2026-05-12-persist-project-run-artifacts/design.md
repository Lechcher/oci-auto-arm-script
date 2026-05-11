## Context

The script now provisions OCI ARM instances and validates non-interactive OCI CLI authentication, but operational state remains split between terminal output, `ssh-info.txt`, user-home OCI config, and user-provided SSH key paths. This makes later SSH access, troubleshooting, and reruns harder because the project directory does not contain a complete record of what was created and which project-local inputs were used.

The user wants everything needed for ongoing use to live inside the project: exported instance information, SSH access files, and OCI config profile login material. This overlaps with secret handling, so the design must preserve safe defaults and avoid accidentally printing or overwriting private credentials.

## Goals / Non-Goals

**Goals:**

- Create a predictable project-local run artifact directory for generated provisioning outputs.
- Export instance details after successful provisioning in machine-readable and human-readable forms.
- Support project-local OCI CLI config files and profile selection for API key auth.
- Support explicit private SSH key artifact handling with restrictive file permissions.
- Keep generated secret-bearing files out of source control by documenting and enforcing an ignored artifact path.

**Non-Goals:**

- Generate OCI API keys, upload public API keys, or create real OCI credentials.
- Run browser login or `oci session authenticate` for automation.
- Automatically run `oci setup config` or overwrite user-home `~/.oci/config`.
- Guarantee that project-local private keys are safe to commit; they must be treated as local secrets.

## Decisions

- **Artifact root:** Use a project-local default such as `.oci-arm-runs/` for generated outputs. Alternative considered: write outputs beside `auto_provision.sh` with flat filenames. Directory-based output is safer because multiple runs can coexist and `.gitignore` can exclude one path.
- **Run identity:** Create one run directory per provisioning attempt using timestamp plus short instance OCID when available. Alternative considered: reuse a fixed `latest/` directory only. Per-run directories preserve history; a `latest` pointer/file can still help humans find the newest run.
- **Instance export format:** Write `instance.json` containing raw OCI launch output and a small `summary.env` or `summary.txt` containing useful values such as instance OCID, display name, region, public IP, SSH user, SSH command, OCI profile, and config path. Alternative considered: only write text. JSON preserves machine-readable data for later tooling.
- **OCI config selection:** Add first-class options for project-local OCI config path and profile, mapping to OCI CLI config behavior without modifying credentials. API key auth can use `OCI_CLI_CONFIG_FILE` or equivalent command environment when invoking `oci`. Alternative considered: require users to export env vars manually. First-class script options make runs repeatable and discoverable in help output.
- **Private SSH key handling:** Default to recording the private key path in artifact metadata, not copying key material. If explicit copy/write is requested, store it under the run directory with mode `0600` and never print contents. Alternative considered: always copy the key into the project. Explicit opt-in reduces accidental secret duplication.
- **Overwrite behavior:** Never overwrite existing config, key, or run artifacts unless an explicit force flag is provided. Alternative considered: overwrite `latest` files every run. Non-overwrite protects credentials and forensic output.
- **Source control safety:** Ensure generated artifact root is ignored by Git when repository metadata exists, or print a warning if ignore updates are not possible. Alternative considered: rely only on user discipline. Secrets near project code need stronger guardrails.

## Risks / Trade-offs

- [Risk] Project-local private keys are easier to accidentally commit. -> Mitigation: default to path references, require explicit opt-in for copying key material, set `0600`, and ignore artifact root.
- [Risk] OCI CLI config files contain sensitive tenancy/user/key references. -> Mitigation: do not generate secrets, do not print file contents, and keep project-local config under ignored paths.
- [Risk] Users may confuse OCI API key config with SSH private key. -> Mitigation: label artifacts clearly: `oci-config`, `ssh-private-key`, `instance.json`, and `ssh-command.txt`.
- [Risk] Multiple auth modes have different config needs. -> Mitigation: apply project-local config/profile only to `api-key`; principal auth continues using OCI-provided identity.
- [Risk] Current workspace is not a Git repository according to environment details. -> Mitigation: script can still create/use ignored artifact root guidance; Git ignore updates happen only when applicable.
