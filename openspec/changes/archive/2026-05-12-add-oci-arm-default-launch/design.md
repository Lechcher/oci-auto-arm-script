## Context

`auto_provision.sh` currently wraps a user-provided OCI CLI launch command and retries capacity failures. The new requirement makes the script more opinionated: it should launch a specific ARM instance in Mumbai with known resource names, then produce SSH details after provisioning.

## Goals / Non-Goals

**Goals:**
- Add a default launch mode for `arm-server` in region `ap-mumbai-1`.
- Resolve compartment-independent resource details required by OCI CLI where possible from resource display names.
- Launch `VM.Standard.A1.Flex` with 4 OCPUs and 24 GB memory in `AD-1` and `FD-2`.
- Keep capacity retry behavior.
- Fetch public IP after create, save SSH details to file, and print SSH command.

**Non-Goals:**
- Creating VCN, subnet, security lists, keys, or OCI config.
- Guaranteeing capacity in OCI.
- Guessing missing compartment IDs or SSH private key path without user input/config.

## Decisions

- **Default mode over raw-command-only:** Add default launch behavior when no raw command is provided. Raw command mode remains via `--` for advanced use. Alternative was forcing users to pass a full command; that does not satisfy fixed default requirement.
- **Config inputs:** Require `--compartment-id` or `OCI_COMPARTMENT_ID`; require SSH public key path or literal key. OCI resource lookup needs compartment context, and SSH command output needs a private key path. Alternative was hardcoding OCIDs, but user supplied names rather than OCIDs.
- **Resource lookup:** Resolve VCN, subnet, and image by display-name through OCI CLI list commands, then extract OCIDs with `--query` and `--raw-output`. Alternative was requiring OCIDs, but name-based config better matches user request.
- **Availability domain:** Resolve full AD name by index/suffix for `AD-1`, because OCI CLI expects full AD value such as `<tenant>:AP-MUMBAI-1-AD-1`. Alternative was accepting literal AD string only; script can still support override if needed.
- **Post-create details:** Capture instance OCID from launch JSON, wait briefly for VNIC attachment, query primary VNIC public IP, then write SSH details to a file. Alternative was parsing console output; JSON query is safer.

## Risks / Trade-offs

- [Risk] Multiple resources share same display name. -> Mitigation: Use exact display-name filters where OCI CLI supports them and fail if required values cannot be resolved.
- [Risk] Image display name changes over time. -> Mitigation: Allow image OCID override while keeping default display-name lookup.
- [Risk] Public IP is absent if subnet does not assign public IP or VNIC launch option disables it. -> Mitigation: Fail post-create SSH output with clear message while leaving instance creation successful.
- [Risk] Compartment ID remains required. -> Mitigation: Document required `--compartment-id` / `OCI_COMPARTMENT_ID` input.
