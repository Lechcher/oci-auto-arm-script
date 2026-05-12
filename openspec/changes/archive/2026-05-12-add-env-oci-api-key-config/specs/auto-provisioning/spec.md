## ADDED Requirements

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

## MODIFIED Requirements

### Requirement: Dotenv Example Template

The project SHALL provide a committed `.env.example` file documenting supported configuration keys with placeholder values only, including both existing script inputs and dotenv-based OCI API key config fields.

#### Scenario: Example contains supported keys

- **WHEN** a user opens `.env.example`
- **THEN** it includes placeholder entries for OCI auth method, OCI profile, optional OCI config file path, OCI API key user OCID, fingerprint, tenancy OCID, key file path, compartment ID, SSH key paths, artifact root, retry delays, and other supported script environment inputs

#### Scenario: Example contains no real secrets

- **WHEN** `.env.example` is committed or displayed
- **THEN** it MUST NOT contain real OCIDs, private key contents, fingerprints, tenancy IDs, user IDs, or other real secret values
