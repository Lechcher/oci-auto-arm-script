## Why

`auto_provision.sh` currently requires users to provide a full OCI launch command and stops after generic success output. Users need a purpose-built flow for a known Always Free ARM target in `ap-mumbai-1`, including automatic capacity retries, public IP discovery, and ready-to-use SSH connection details.

## What Changes

- Add built-in launch defaults for region `ap-mumbai-1`, availability domain `AD-1`, fault domain `FD-2`, instance name `arm-server`, shape `VM.Standard.A1.Flex`, and shape config `4 OCPU / 24 GB`.
- Resolve OCI resources by display name where possible: VCN `Linux-Server-vcn-1`, subnet `Linux-Server-subnet-1`, VNIC name `arm-server`, and image `Canonical Ubuntu 24.04 Minimal aarch64`.
- Preserve auto-retry behavior when OCI capacity is unavailable.
- After successful creation, fetch public IP, save SSH information to a file, and print the SSH command.
- Keep the existing raw-command mode available for advanced users.

## Capabilities

### New Capabilities

### Modified Capabilities
- `auto-provisioning`: Add default OCI ARM launch configuration, resource-name lookup, fault-domain placement, and post-create public IP retrieval.
- `notification`: Expand success output to include saved SSH connection details and printed SSH command.

## Impact

- **Script:** Updates `auto_provision.sh` to support a default configured launch path and post-provision metadata lookup.
- **Dependencies:** Continues requiring OCI CLI. Uses shell utilities already expected on macOS/Linux.
- **User configuration:** Requires OCI CLI profile with permissions to inspect networking/images and launch compute instances in `ap-mumbai-1`.
