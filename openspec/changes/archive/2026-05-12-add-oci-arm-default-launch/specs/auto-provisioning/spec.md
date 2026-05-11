## MODIFIED Requirements

### Requirement: Instance Creation Loop
The script SHALL repeatedly execute an OCI ARM instance launch until the instance is successfully created or a non-capacity related error occurs. The script SHALL support both a default launch mode and a raw command mode.

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

## ADDED Requirements

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
