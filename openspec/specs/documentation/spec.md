# documentation Specification

## Purpose

Define project documentation requirements for README coverage and source code readability.

## Requirements

### Requirement: Centralized Documentation

The project SHALL include a `README.md` file in the repository root to document purpose, setup, and usage.

#### Scenario: User discovers project

- **WHEN** a user navigates to the project repository
- **THEN** they can read the `README.md` to understand what the `auto_provision.sh` script does and its prerequisites

#### Scenario: User needs to run the script

- **WHEN** a user wants to execute the script
- **THEN** the `README.md` provides copy-pasteable examples for default provisioning and explains required arguments

#### Scenario: User needs to configure authentication

- **WHEN** a user needs to authenticate in a specific environment (local vs OCI Compute)
- **THEN** the `README.md` explains the difference between `api-key`, `instance-principal`, and `resource-principal` modes

#### Scenario: User wants to locate outputs

- **WHEN** a user successfully provisions an instance
- **THEN** the `README.md` explains the structure and contents of the project-local `.oci-arm-runs` artifact directory

### Requirement: Code Readability

The script source code SHALL include comments explaining its structure and complex logic functions.

#### Scenario: Developer reads the code

- **WHEN** a developer opens `auto_provision.sh`
- **THEN** they see section headers separating configuration, CLI parsing, OCI helpers, and the main execution loop
