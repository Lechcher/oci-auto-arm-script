## MODIFIED Requirements

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
- **THEN** the script validates OCI CLI authentication using existing `~/.oci/config`, key file, and optional profile before provisioning

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

## ADDED Requirements

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
