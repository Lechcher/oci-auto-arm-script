# auto-provisioning Specification

## Purpose

Define automated OCI ARM instance provisioning behavior, authentication modes, configuration loading, resource resolution, retry handling, and local run artifact safety.

## Requirements

### Requirement: Instance Creation Loop

The script SHALL ensure the OCI CLI is installed, executable, and authenticated with a script-safe authentication method before repeatedly executing an OCI ARM instance launch until the instance is successfully created or a non-capacity related error occurs. The script SHALL support both a default launch mode and a raw command mode.

#### Scenario: OCI CLI already installed

- **WHEN** the script starts and `oci` is available on `PATH`
- **THEN** the script continues to authentication validation without installing OCI CLI

#### Scenario: OCI CLI missing on supported OS

- **WHEN** the script starts, `oci` is missing, and the OS is supported for automatic installation
- **THEN** the script installs OCI CLI using the OS-appropriate installer and continues to authentication validation after installation succeeds

#### Scenario: OCI CLI missing on unsupported OS

- **WHEN** the script starts, `oci` is missing, and the OS is unsupported for automatic installation
- **THEN** the script prints manual install guidance and exits without provisioning

#### Scenario: OCI CLI auto-install disabled

- **WHEN** the script starts, `oci` is missing, and auto-install is disabled
- **THEN** the script prints manual install guidance and exits without provisioning

#### Scenario: API key authentication

- **WHEN** the selected authentication method is `api-key`
- **THEN** the script validates OCI CLI authentication using complete dotenv-derived OCI API key config when provided, or existing `~/.oci/config`, key file, and optional profile before provisioning

#### Scenario: Instance principal authentication

- **WHEN** the selected authentication method is `instance-principal`
- **THEN** the script validates OCI CLI authentication with `--auth instance_principal` before provisioning and uses that auth option for script-built OCI CLI calls

#### Scenario: Resource principal authentication

- **WHEN** the selected authentication method is `resource-principal`
- **THEN** the script validates OCI CLI authentication with `--auth resource_principal` before provisioning and uses that auth option for script-built OCI CLI calls

#### Scenario: Browser session authentication not used

- **WHEN** authentication validation runs
- **THEN** the script MUST NOT run `oci session authenticate` or require browser-style login

#### Scenario: Authentication failure

- **WHEN** OCI CLI authentication validation fails
- **THEN** the script prints targeted troubleshooting guidance and exits without launching or retrying provisioning

#### Scenario: Default launch configuration

- **WHEN** the script runs without a raw command after `--`
- **THEN** the script launches an OCI instance using region `ap-mumbai-1`, availability domain `AD-1`, fault domain `FD-2`, instance display name `arm-server`, shape `VM.Standard.A1.Flex`, 4 OCPUs, 24 GB memory, VNIC name `arm-server`, VCN `Linux-Server-vcn-1`, subnet `Linux-Server-subnet-1`, and image `Canonical Ubuntu 24.04 Minimal aarch64`

#### Scenario: Raw command mode

- **WHEN** the script receives a command after `--`
- **THEN** the script executes that command instead of building the default launch command

#### Scenario: Out of capacity error handling

- **WHEN** the OCI CLI returns an `InternalError` indicating "Out of host capacity"
- **THEN** the script pauses for a designated interval and retries the command

#### Scenario: Fatal error handling

- **WHEN** the OCI CLI returns a non-capacity error (e.g., authorization failure, invalid parameters, missing required IDs)
- **THEN** the script logs the error and terminates without retrying

#### Scenario: Successful creation

- **WHEN** the OCI CLI successfully provisions the instance
- **THEN** the script logs the success, records the instance OCID, and exits the retry loop

### Requirement: Rate Limiting

The script SHALL implement a delay between consecutive OCI CLI execution attempts to prevent API rate limiting or account bans.

#### Scenario: Delay between attempts

- **WHEN** a capacity error triggers a retry
- **THEN** the script waits for a random duration (e.g., between 30 and 60 seconds) before the next attempt

### Requirement: OCI CLI Bootstrap

The script SHALL detect machine OS and install OCI CLI when missing on supported platforms.

#### Scenario: macOS install path

- **WHEN** the script runs on macOS and `oci` is missing
- **THEN** the script installs OCI CLI using Homebrew if available, or Oracle's official installer if Homebrew is unavailable and `curl` is available

#### Scenario: Linux install path

- **WHEN** the script runs on Linux and `oci` is missing
- **THEN** the script installs OCI CLI using Oracle's official curl/bash installer from `https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh`

#### Scenario: Post-install validation

- **WHEN** OCI CLI installation completes
- **THEN** the script verifies `oci` is executable before continuing

#### Scenario: Existing OCI config safety

- **WHEN** OCI CLI is installed or found
- **THEN** the script MUST NOT run `oci setup config` or overwrite OCI configuration files

### Requirement: OCI Resource Resolution

The script SHALL resolve required OCI launch inputs from provided defaults or user-supplied overrides before launching the default ARM instance.

#### Scenario: Resolve networking resources

- **WHEN** default launch mode is used
- **THEN** the script resolves VCN `Linux-Server-vcn-1` and subnet `Linux-Server-subnet-1` in the target compartment before launch

#### Scenario: Resolve image

- **WHEN** default launch mode is used and no image OCID override is provided
- **THEN** the script resolves image `Canonical Ubuntu 24.04 Minimal aarch64` before launch

#### Scenario: Missing required input

- **WHEN** default launch mode lacks required values such as compartment ID or SSH public key
- **THEN** the script prints a clear error and exits without retrying

### Requirement: Public IP Discovery

The script SHALL retrieve the public IP address for the created instance after successful launch.

#### Scenario: Successful public IP retrieval

- **WHEN** an instance is successfully created with an attached public VNIC
- **THEN** the script retrieves the VNIC public IP address

#### Scenario: No public IP available

- **WHEN** the created instance has no public IP address
- **THEN** the script prints a clear warning and does not print an unusable SSH command

### Requirement: Project-Local Run Artifacts

The script SHALL support writing provisioning outputs into a project-local run artifact directory. The artifact directory SHALL include enough information to reconnect to and audit the created instance without relying only on terminal output.

#### Scenario: Successful run artifact export

- **WHEN** default launch mode successfully creates an instance
- **THEN** the script writes project-local artifacts containing the instance OCID, region, display name, public IP when available, SSH user, SSH command, OCI config path when selected, OCI profile when selected, and timestamp of the run

#### Scenario: Machine-readable instance export

- **WHEN** OCI CLI returns instance launch data
- **THEN** the script stores the raw instance launch response in a machine-readable file under the run artifact directory

#### Scenario: Human-readable SSH output

- **WHEN** public IP discovery succeeds
- **THEN** the script writes a human-readable SSH command file under the run artifact directory

### Requirement: Project-Local OCI Config Selection

The script SHALL allow API key authentication to use a project-local OCI CLI config file and profile without modifying user-home OCI configuration.

#### Scenario: Project config path selected

- **WHEN** the user provides a project-local OCI config file path for API key auth
- **THEN** the script uses that config file for OCI CLI preflight, resource lookup, launch, and post-launch discovery commands

#### Scenario: Project profile selected

- **WHEN** the user provides an OCI profile name for API key auth
- **THEN** the script passes that profile to OCI CLI commands that are constructed by the script

#### Scenario: Principal auth ignores API key config

- **WHEN** instance-principal or resource-principal auth is selected
- **THEN** the script MUST NOT require a project-local OCI config file or profile for authentication

### Requirement: SSH Private Key Artifact Handling

The script SHALL support project-local SSH private key artifact handling only when explicitly requested and SHALL protect private key material with restrictive permissions.

#### Scenario: Private key path recorded by default

- **WHEN** the user provides an SSH private key file for SSH command generation without requesting key copy
- **THEN** the script records the private key path in run metadata and does not copy private key material

#### Scenario: Private key copied explicitly

- **WHEN** the user explicitly requests copying the SSH private key into the project run artifact directory
- **THEN** the script copies the private key into the run artifact directory, sets file mode `0600`, and does not print the private key contents

#### Scenario: Existing private key artifact collision

- **WHEN** the target private key artifact already exists and overwrite was not explicitly requested
- **THEN** the script stops with a clear error instead of overwriting the file

### Requirement: Artifact Secret Safety

The script SHALL avoid exposing secret-bearing artifact contents and SHALL guide users to keep generated project-local artifacts out of source control.

#### Scenario: Secret contents not printed

- **WHEN** the script writes or references OCI config files or SSH private key files
- **THEN** the script prints paths and next steps but MUST NOT print private key contents or OCI config contents

#### Scenario: Artifact root source-control protection

- **WHEN** project-local run artifacts are enabled
- **THEN** the script ensures the artifact root is ignored by source control when possible or prints a clear warning that the path contains local secrets and must not be committed

### Requirement: Script-Safe OCI Authentication

The script SHALL support non-browser OCI CLI authentication methods appropriate for automation without writing secrets or OCI config files.

#### Scenario: API key config guidance

- **WHEN** API key authentication is selected and validation fails due to missing config or key material
- **THEN** the script prints guidance to create `~/.oci/config`, set file permissions to `600`, provide `user`, `fingerprint`, `tenancy`, `region`, and `key_file`, and retry

#### Scenario: Profile selection

- **WHEN** `--profile` or `OCI_PROFILE` is provided with API key authentication
- **THEN** the script uses that profile for OCI CLI preflight and script-built OCI CLI calls

#### Scenario: Instance principal guidance

- **WHEN** instance principal authentication is selected and validation fails
- **THEN** the script prints guidance that the script must run on OCI Compute with a dynamic group and IAM policy granting required permissions

#### Scenario: Resource principal guidance

- **WHEN** resource principal authentication is selected and validation fails
- **THEN** the script prints guidance that the script must run in a supported OCI resource-principal environment such as Functions, OKE, or Cloud Shell with environment-provided identity

#### Scenario: Secret safety

- **WHEN** authentication options are configured
- **THEN** the script MUST NOT request, print, write, or commit private keys, fingerprints, tenancy OCIDs, user OCIDs, or config contents

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

The project SHALL provide a committed `.env.example` file documenting supported configuration keys with placeholder values only, including both existing script inputs and dotenv-based OCI API key config fields.

#### Scenario: Example contains supported keys

- **WHEN** a user opens `.env.example`
- **THEN** it includes placeholder entries for OCI auth method, OCI profile, optional OCI config file path, OCI API key user OCID, fingerprint, tenancy OCID, key file path, compartment ID, SSH key paths, artifact root, retry delays, and other supported script environment inputs

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

### Requirement: Dotenv OCI API Key Config

The script SHALL allow API key authentication to be configured from supported dotenv keys without requiring users to manually create `~/.oci/config` or `.oci/config`. The dotenv-based configuration SHALL include OCI user OCID, fingerprint, tenancy OCID, region, and private key file path values.

#### Scenario: Complete dotenv API key config selected

- **WHEN** the selected authentication method is `api-key` and dotenv or environment values provide OCI user OCID, fingerprint, tenancy OCID, region, and key file path
- **THEN** the script uses those values for OCI CLI authentication validation and script-built OCI CLI calls without requiring a pre-existing OCI config file

#### Scenario: Private key path only

- **WHEN** dotenv-based OCI API key config is used
- **THEN** the script requires a private key file path and MUST NOT require or accept private key contents in dotenv values

#### Scenario: Incomplete dotenv API key config

- **WHEN** only some dotenv OCI API key config values are provided for `api-key` authentication
- **THEN** the script prints clear guidance about the missing fields and exits without printing provided secret-bearing values

#### Scenario: Principal auth ignores dotenv API key config

- **WHEN** instance-principal or resource-principal auth is selected and dotenv contains OCI API key config values
- **THEN** the script MUST NOT use those API key config values for authentication validation or script-built OCI CLI calls

### Requirement: Dotenv OCI API Key Secret Safety

The script SHALL protect OCI API key configuration values loaded from dotenv and any generated intermediate config used for OCI CLI authentication.

#### Scenario: Dotenv API key values not printed

- **WHEN** dotenv OCI API key config values are loaded, validated, or fail validation
- **THEN** the script MUST NOT print user OCIDs, tenancy OCIDs, fingerprints, private key paths with embedded secrets, or generated config contents

#### Scenario: Intermediate config protected

- **WHEN** the script writes an intermediate OCI CLI config file from dotenv API key values
- **THEN** it writes the file only to a source-control-ignored local path, applies restrictive file permissions, and does not print the file contents
