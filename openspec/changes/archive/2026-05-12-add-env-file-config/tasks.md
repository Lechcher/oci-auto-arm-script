## 1. Dotenv Loading

- [x] 1.1 Add `--env-file PATH` CLI option and `ENV_FILE` environment input.
- [x] 1.2 Add early argument pre-scan so `--env-file` can be loaded before normal option defaults are assigned.
- [x] 1.3 Implement conservative dotenv parser for simple `KEY=value` lines, optional quotes, blank lines, and comments without using `source`.
- [x] 1.4 Load `.env` by default when present and no alternate env file is selected.
- [x] 1.5 Continue without error when default `.env` is absent.
- [x] 1.6 Fail clearly when an explicitly selected env file does not exist or is unreadable.

## 2. Configuration Precedence

- [x] 2.1 Apply dotenv values only when matching process environment variables are unset.
- [x] 2.2 Preserve existing CLI flag precedence over process environment and dotenv values.
- [x] 2.3 Verify dotenv values can populate OCI profile, OCI config file, compartment ID, SSH key paths, artifact root, auth method, retry delays, install behavior, and resource override inputs.
- [x] 2.4 Ensure principal auth behavior remains unchanged when dotenv contains API-key-oriented fields.

## 3. Template and Safety Files

- [x] 3.1 Add committed `.env.example` with placeholder values for all supported configuration keys.
- [x] 3.2 Ensure `.env.example` contains no real OCIDs, fingerprints, private key contents, tenancy IDs, or user IDs.
- [x] 3.3 Add or verify source-control ignore coverage for `.env`, `.env.local`, and `.env.*.local` when source-control metadata is present.
- [x] 3.4 Print a warning when dotenv source-control ignore coverage cannot be verified.

## 4. Help and Error Output

- [x] 4.1 Update help output to document `.env`, `.env.example`, `--env-file`, and configuration precedence.
- [x] 4.2 Ensure dotenv parser warnings include file path and line number but never print secret values.
- [x] 4.3 Ensure normal successful dotenv loading does not print dotenv contents.

## 5. Verification

- [x] 5.1 Run shell syntax validation for `auto_provision.sh`.
- [x] 5.2 Verify help output documents dotenv configuration and precedence.
- [x] 5.3 Verify default `.env` values are used when no process environment or CLI flag overrides them.
- [x] 5.4 Verify process environment overrides dotenv values.
- [x] 5.5 Verify CLI flags override process environment and dotenv values.
- [x] 5.6 Verify `--env-file PATH` selects an alternate dotenv file.
- [x] 5.7 Verify unsupported dotenv syntax does not execute shell code or print secret values.
- [x] 5.8 Verify `.env.example` exists and contains placeholder values only.
- [x] 5.9 Verify `.env` ignore behavior or warning path.
