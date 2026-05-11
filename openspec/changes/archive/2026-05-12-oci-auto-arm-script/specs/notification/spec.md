## ADDED Requirements

### Requirement: Success Notification
The script SHALL notify the user upon the successful provisioning of an instance.

#### Scenario: Terminal notification
- **WHEN** the instance creation loop successfully completes
- **THEN** the script outputs a prominent success message to the terminal and triggers an audible alert (e.g., `echo -a '\a'`)
