## Why

Users need a convenient way to configure OCI profile, compartment, SSH paths, and artifact settings without typing long commands or accidentally committing real secrets. A project `.env` file plus committed `.env.example` lets sensitive local values stay out of Git while documenting required configuration.

## What Changes

- Add support for loading configuration from a project-local `.env` file before CLI argument parsing.
- Add `--env-file PATH` and `ENV_FILE` so users can select a different dotenv file.
- Add `.env.example` with safe placeholder values for OCI profile, config path, compartment ID, SSH key paths, artifact root, auth method, and retry settings.
- Ensure `.env` and common secret-bearing local env variants are ignored by source control.
- Preserve precedence: explicit CLI flags override environment variables, and environment variables override `.env` file values.
- Avoid printing `.env` contents or secret values.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `auto-provisioning`: Add requirements for dotenv configuration loading, `.env.example` documentation, configuration precedence, and source-control safety for local environment files.

## Impact

- Affects `auto_provision.sh` startup configuration loading, help output, and source-control safety handling.
- Adds a committed `.env.example` template with placeholders only.
- Adds or updates ignore rules for `.env` and local secret env files when source-control metadata exists.
- Does not create real credentials, real OCI config, private keys, or secret values.
