## ADDED Requirements

### Requirement: Instance Creation Loop
The script SHALL repeatedly execute the provided OCI CLI command until the instance is successfully created or a non-capacity related error occurs.

#### Scenario: Out of capacity error handling
- **WHEN** the OCI CLI returns an `InternalError` indicating "Out of host capacity"
- **THEN** the script pauses for a designated interval and retries the command

#### Scenario: Fatal error handling
- **WHEN** the OCI CLI returns a non-capacity error (e.g., authorization failure, invalid parameters)
- **THEN** the script logs the error and terminates without retrying

#### Scenario: Successful creation
- **WHEN** the OCI CLI successfully provisions the instance
- **THEN** the script logs the success and exits the retry loop

### Requirement: Rate Limiting
The script SHALL implement a delay between consecutive OCI CLI execution attempts to prevent API rate limiting or account bans.

#### Scenario: Delay between attempts
- **WHEN** a capacity error triggers a retry
- **THEN** the script waits for a random duration (e.g., between 30 and 60 seconds) before the next attempt
