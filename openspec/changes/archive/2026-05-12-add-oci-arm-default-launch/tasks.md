## 1. Configuration

- [x] 1.1 Add default launch constants for region `ap-mumbai-1`, AD `AD-1`, FD `FD-2`, instance/VNIC name `arm-server`, shape `VM.Standard.A1.Flex`, 4 OCPUs, 24 GB memory, VCN `Linux-Server-vcn-1`, subnet `Linux-Server-subnet-1`, and image `Canonical Ubuntu 24.04 Minimal aarch64`.
- [x] 1.2 Add CLI/env inputs for required values: compartment ID, SSH public key path or literal SSH public key, SSH private key path, SSH username, output SSH info file, OCI profile, and optional OCID overrides.
- [x] 1.3 Update usage/help text to document default mode and raw command mode.

## 2. OCI Resource Lookup

- [x] 2.1 Resolve the full availability domain name for `AD-1` in region `ap-mumbai-1`.
- [x] 2.2 Resolve VCN OCID by display name `Linux-Server-vcn-1` within the compartment.
- [x] 2.3 Resolve subnet OCID by display name `Linux-Server-subnet-1` within the resolved VCN.
- [x] 2.4 Resolve image OCID for `Canonical Ubuntu 24.04 Minimal aarch64`, unless an image OCID override is supplied.
- [x] 2.5 Fail fast with clear fatal errors when required inputs or resource lookups are missing.

## 3. Launch Flow

- [x] 3.1 Build default `oci compute instance launch` arguments from resolved values.
- [x] 3.2 Include shape config with `ocpus: 4` and `memoryInGBs: 24`.
- [x] 3.3 Include fault domain `FD-2` and display name `arm-server`.
- [x] 3.4 Preserve existing raw command mode after `--`.
- [x] 3.5 Preserve capacity retry behavior and fatal error exit behavior.
- [x] 3.6 Capture instance OCID from successful launch output.

## 4. Post-Create SSH Output

- [x] 4.1 Query VNIC attachments for the created instance and resolve the primary VNIC.
- [x] 4.2 Retrieve public IP from the primary VNIC.
- [x] 4.3 Save SSH information to the configured output file.
- [x] 4.4 Print the SSH command to terminal using username, private key path, and public IP.
- [x] 4.5 Print a clear warning if no public IP is available.

## 5. Verification

- [x] 5.1 Run shell syntax validation for `auto_provision.sh`.
- [x] 5.2 Verify help output documents default and raw command modes.
- [x] 5.3 Verify fatal validation path when compartment ID or SSH key input is missing.
- [x] 5.4 Verify raw command mode still handles non-capacity fatal errors.
- [ ] 5.5 If valid OCI credentials/resources are available, run default mode and verify capacity retry or successful SSH info output.
