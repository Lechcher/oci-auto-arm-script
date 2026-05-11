## MODIFIED Requirements

### Requirement: Instance Creation Loop
The script SHALL ensure the OCI CLI is installed and executable before repeatedly executing the provided OCI CLI command or default launch command until the instance is successfully created or a non-capacity related error occurs.

#### Scenario: OCI CLI already installed
- **WHEN** the script starts and `oci` is available on `PATH`
- **THEN** the script continues to the provisioning flow without installing OCI CLI

#### Scenario: OCI CLI missing on supported OS
- **WHEN** the script starts, `oci` is missing, and the OS is supported for automatic installation
- **THEN** the script installs OCI CLI using the OS-appropriate installer and continues to the provisioning flow after installation succeeds

#### Scenario: OCI CLI missing on unsupported OS
- **WHEN** the script starts, `oci` is missing, and the OS is unsupported for automatic installation
- **THEN** the script prints manual install guidance and exits without provisioning

#### Scenario: OCI CLI auto-install disabled
- **WHEN** the script starts, `oci` is missing, and auto-install is disabled
- **THEN** the script prints manual install guidance and exits without provisioning

#### Scenario: Out of capacity error handling
- **WHEN** the OCI CLI returns an `InternalError` indicating "Out of host capacity"
- **THEN** the script pauses for a designated interval and retries the command

#### Scenario: Fatal error handling
- **WHEN** the OCI CLI returns a non-capacity error (e.g., authorization failure, invalid parameters)
- **THEN** the script logs the error and terminates without retrying

#### Scenario: Successful creation
- **WHEN** the OCI CLI successfully provisions the instance
- **THEN** the script logs the success and exits the retry loop

## ADDED Requirements

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
