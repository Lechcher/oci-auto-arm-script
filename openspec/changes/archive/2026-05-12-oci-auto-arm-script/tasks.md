## 1. Setup

- [x] 1.1 Create `auto_provision.sh` script file with bash shebang.
- [x] 1.2 Add usage instructions and parameter parsing (expecting the raw `oci compute instance launch` command as input or as a configured variable within the script).

## 2. Core Implementation

- [x] 2.1 Implement the main `while` loop for executing the OCI command.
- [x] 2.2 Capture standard error and standard output of the command.
- [x] 2.3 Add logic to check for "Out of host capacity" (InternalError/500) in the output.
- [x] 2.4 Add logic to break the loop and exit if a non-capacity related error occurs.
- [x] 2.5 Implement the randomized sleep delay (e.g., 30-60 seconds) between loop iterations when capacity errors occur.

## 3. Notification

- [x] 3.1 Add logic to break the loop upon successful execution.
- [x] 3.2 Implement terminal notification (echo success message and system beep) on success.

## 4. Verification

- [x] 4.1 Test script with a deliberately invalid command to verify fatal error handling.
- [ ] 4.2 Run script with a valid command and verify it handles capacity errors, sleeps, and retries.
