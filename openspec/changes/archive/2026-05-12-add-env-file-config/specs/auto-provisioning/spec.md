## ADDED Requirements

### Requirement: Dotenv Configuration Loading
The script SHALL support loading supported configuration variables from a project-local dotenv file without executing arbitrary shell code.

#### Scenario: Default dotenv loaded
- **WHEN** `.env` exists in the project directory and no alternate env file is selected
- **THEN** the script loads supported configuration values from `.env` before provisioning begins

#### Scenario: Alternate dotenv selected
- **WHEN** `--env-file PATH` or `ENV_FILE` is provided
- **THEN** the script loads supported configuration values from the selected dotenv file instead of the default `.env`

#### Scenario: Missing dotenv file
- **WHEN** no dotenv file exists and no env file is explicitly required
- **THEN** the script continues using process environment values, CLI flags, and built-in defaults

#### Scenario: Dotenv does not execute code
- **WHEN** a dotenv file contains shell syntax beyond simple key/value assignments
- **THEN** the script MUST NOT execute that content and MUST NOT expose any secret value from the file in output

### Requirement: Configuration Precedence
The script SHALL apply configuration precedence in a deterministic order so explicit user input wins over local defaults.

#### Scenario: CLI overrides environment and dotenv
- **WHEN** the same option is provided by CLI flag, process environment, and dotenv file
- **THEN** the script uses the CLI flag value

#### Scenario: Process environment overrides dotenv
- **WHEN** the same option is provided by process environment and dotenv file but not by CLI flag
- **THEN** the script uses the process environment value

#### Scenario: Dotenv overrides built-in defaults
- **WHEN** an option is provided only by dotenv file
- **THEN** the script uses the dotenv value instead of the built-in default

### Requirement: Dotenv Example Template
The project SHALL provide a committed `.env.example` file documenting supported configuration keys with placeholder values only.

#### Scenario: Example contains supported keys
- **WHEN** a user opens `.env.example`
- **THEN** it includes placeholder entries for OCI auth method, OCI profile, OCI config file path, compartment ID, SSH key paths, artifact root, retry delays, and other supported script environment inputs

#### Scenario: Example contains no real secrets
- **WHEN** `.env.example` is committed or displayed
- **THEN** it MUST NOT contain real OCIDs, private key contents, fingerprints, tenancy IDs, user IDs, or other real secret values

### Requirement: Dotenv Source-Control Safety
The script SHALL protect local dotenv files from accidental source-control commits when possible.

#### Scenario: Git ignore updated
- **WHEN** source-control metadata is present and ignore rules are writable
- **THEN** the script ensures `.env`, `.env.local`, and `.env.*.local` are ignored

#### Scenario: Git ignore cannot be verified
- **WHEN** source-control metadata is absent or ignore rules cannot be updated
- **THEN** the script prints a clear warning that local dotenv files may contain sensitive values and must not be committed

#### Scenario: Dotenv contents not printed
- **WHEN** dotenv loading succeeds or fails
- **THEN** the script prints file paths and safe guidance only, and MUST NOT print dotenv values
