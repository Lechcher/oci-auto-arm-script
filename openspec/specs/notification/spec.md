# notification Specification

## Purpose

Define success notification and SSH connection output behavior after an OCI instance is provisioned.

## Requirements

### Requirement: Success Notification

The script SHALL notify the user upon the successful provisioning of an instance and provide SSH connection details when public IP discovery succeeds.

#### Scenario: Terminal notification

- **WHEN** the instance creation loop successfully completes
- **THEN** the script outputs a prominent success message to the terminal and triggers an audible alert (e.g., `printf '\a'`)

#### Scenario: SSH command output

- **WHEN** the instance is successfully created and public IP discovery succeeds
- **THEN** the script prints an SSH command using the configured SSH username, private key path, and public IP address

#### Scenario: SSH information file

- **WHEN** the instance is successfully created and public IP discovery succeeds
- **THEN** the script saves SSH information including instance name, instance OCID, public IP, SSH username, private key path, and SSH command to a file
