## ADDED Requirements

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
