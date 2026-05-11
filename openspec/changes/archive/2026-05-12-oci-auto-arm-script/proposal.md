## Why

Oracle Cloud Infrastructure (OCI) offers an Always Free tier that includes ARM-based compute instances. However, these instances are frequently out of capacity in many regions, making it difficult to provision them manually. This script automates the process of repeatedly attempting to create an instance via the OCI CLI until successful, saving users from manual, repetitive checking.

## What Changes

- Create a bash/python script that interfaces with the OCI CLI.
- Loop the instance creation command.
- Implement rate limiting/delays between attempts to avoid API bans.
- Add error handling to differentiate between "out of capacity" and actual configuration errors.
- Send a notification (e.g., terminal beep, webhook, or email) upon successful creation.

## Capabilities

### New Capabilities
- `auto-provisioning`: Script to repeatedly attempt OCI instance creation handling "Out of host capacity" errors.
- `notification`: Alert mechanism when the instance is successfully provisioned.

### Modified Capabilities

## Impact

- **Dependencies**: Requires OCI CLI to be installed and configured (`oci setup config`).
- **Systems**: Runs locally on the user's machine.
