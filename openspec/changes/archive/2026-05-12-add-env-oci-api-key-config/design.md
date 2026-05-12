## Context

The script already loads supported values from `.env`, supports API key auth by delegating to OCI CLI config files, and can use `OCI_CLI_CONFIG_FILE` to select a project-local config. Users who copy Oracle's API key configuration preview still need to create a separate OCI config file and set `key_file`, while their other inputs live in `.env`.

This change lets `.env` provide the OCI API key config fields directly for local automation while keeping the current OCI CLI config file path as a compatible option.

## Goals / Non-Goals

**Goals:**

- Let users configure API key auth from `.env` without manually editing `.oci/config` or `~/.oci/config`.
- Keep private key material out of `.env`; store only `key_file` path.
- Preserve existing `OCI_CLI_CONFIG_FILE`, `OCI_PROFILE`, and principal auth behavior.
- Avoid printing or committing secret-bearing `.env` values.
- Document safe placeholder values in `.env.example`.

**Non-Goals:**

- Generate OCI API keys or upload public keys to Oracle.
- Store private key contents in `.env`.
- Replace OCI CLI authentication internals.
- Remove support for standard OCI config files.

## Decisions

- **Use dotenv fields as source of an OCI CLI-compatible config.** The script should convert `.env` values such as user OCID, fingerprint, tenancy OCID, region, and key file path into a form OCI CLI can consume for `api-key` auth. Alternative considered: ask users to paste multiline `[DEFAULT]` config text into `.env`. Rejected because dotenv parsing is safer and simpler with explicit single-value keys.

- **Keep private key as path only.** `.env` should contain `OCI_KEY_FILE=/path/to/private_key.pem`, not private key contents. Alternative considered: support a multiline private key variable. Rejected because it increases leak risk and dotenv parser complexity.

- **Prefer explicit env-derived config when complete.** If all required OCI API key fields are present, API key auth can use those fields without requiring `OCI_CLI_CONFIG_FILE`. If fields are incomplete, existing `OCI_CLI_CONFIG_FILE` / `~/.oci/config` behavior and guidance remains available. This keeps compatibility while reducing setup friction.

- **Ignore API-key-specific env fields for principal auth.** Instance principal and resource principal modes should not validate or use API key config values. This preserves current separation between auth modes.

- **Treat generated/intermediate config as sensitive artifact.** If implementation writes a temporary config file, it must be protected with restrictive permissions, placed in an ignored local path, and never printed. Alternative considered: pass values only through OCI CLI env vars. OCI CLI primarily expects config file/profile semantics, so a generated config may be more reliable.

## Risks / Trade-offs

- [Risk] `.env` now may contain real user OCIDs, tenancy OCIDs, and fingerprints. → Mitigation: keep `.env` ignored, update `.env.example` with placeholders only, and never print values.
- [Risk] Users may paste private key contents into `.env`. → Mitigation: document `OCI_KEY_FILE` as a path only and reject/guide values that look like private key blocks.
- [Risk] Generated config files could leak if committed. → Mitigation: write only under ignored local artifact/config paths and ensure source-control ignore rules cover them.
- [Risk] Conflicting config sources may confuse users. → Mitigation: define precedence: CLI flags/process env/dotenv values override built-in defaults; complete env-derived API key config takes precedence over config-file fallback unless explicit config-file behavior is chosen.
