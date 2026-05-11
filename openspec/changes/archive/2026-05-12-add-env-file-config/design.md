## Context

The script now accepts many configuration inputs: OCI auth method, profile, config file path, compartment ID, SSH key paths, artifact root, retry delays, resource overrides, and installation behavior. Passing all values as CLI flags is noisy, while exporting them manually in a shell is easy to forget. Users also need a safe template they can copy without risking real credentials in source control.

The project should use a local `.env` file for machine-specific configuration and a committed `.env.example` for documentation. The `.env` file may contain sensitive values such as OCIDs and private key paths, so it must be treated as local-only and ignored by Git.

## Goals / Non-Goals

**Goals:**

- Load supported script configuration from a project-local `.env` file by default.
- Support `--env-file PATH` and `ENV_FILE` for alternate dotenv paths.
- Keep deterministic precedence: CLI flags override process environment, process environment overrides `.env`, and `.env` overrides built-in defaults.
- Provide `.env.example` with placeholder values only.
- Add source-control safety for `.env` and common local env variants.
- Avoid printing `.env` contents or sensitive values.

**Non-Goals:**

- Store real OCI credentials, real OCIDs, real private key contents, or real SSH keys in `.env.example`.
- Parse complex shell syntax, command substitution, multiline secrets, or `export` statements beyond simple dotenv assignments.
- Replace OCI CLI config files; `.env` points to config/profile inputs but does not contain OCI private key contents.
- Load `.env` in raw command subprocesses beyond environment variables intentionally exported by the script.

## Decisions

- **Default file:** Load `.env` from the project working directory when present. Alternative considered: require explicit `--env-file`. Default loading is friendlier for repeated provisioning.
- **Alternate file selection:** Support `ENV_FILE` from the process environment and `--env-file PATH` from CLI. Because CLI args are parsed after startup, `--env-file` requires a lightweight pre-scan before normal config initialization. Alternative considered: only `ENV_FILE`; CLI support is more discoverable.
- **Precedence:** Use CLI > process env > dotenv > defaults. Alternative considered: dotenv overrides process env. Preserving externally exported env is safer for CI and shells.
- **Parser scope:** Implement a conservative Bash dotenv parser for `KEY=value`, optional single/double quotes, blank lines, and comments. Reject or ignore unsupported lines with a warning that does not print values. Alternative considered: `source .env`; rejected because it can execute arbitrary shell code.
- **Export behavior:** Load variables into shell variables used by the script rather than printing or dumping environment. Alternative considered: print loaded configuration for debugging; rejected because paths and OCIDs can be sensitive.
- **Template:** Commit `.env.example` with placeholder values for all supported env inputs. Alternative considered: generate it at runtime; committed template is easier to review and copy.
- **Ignore behavior:** Ensure `.env`, `.env.local`, `.env.*.local`, and selected local OCI artifact paths are ignored when `.git` exists. Alternative considered: only document ignore rules; local secret files near source code need active guardrails.

## Risks / Trade-offs

- [Risk] Dotenv parser could mishandle unusual quoting. -> Mitigation: support only simple documented syntax and warn on unsupported lines.
- [Risk] Users may place real private key contents in `.env`. -> Mitigation: `.env.example` uses paths only and help text says not to store key material.
- [Risk] Auto-loading `.env` could surprise CI or scripted callers. -> Mitigation: process env and CLI override `.env`; allow disabling or selecting another file via `ENV_FILE`/`--env-file` design if implementation includes empty path behavior.
- [Risk] `.env` ignore updates cannot run outside Git repositories. -> Mitigation: print clear warning when source-control protection cannot be verified.
