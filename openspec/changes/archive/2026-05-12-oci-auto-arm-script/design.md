## Context

Users want to provision OCI Always Free ARM instances, but they are frequently out of capacity. Manual retries via the web console are tedious. The OCI CLI provides a way to script this, but requires parsing error output to differentiate between permanent errors (like bad configuration) and temporary errors (out of capacity).

## Goals / Non-Goals

**Goals:**
- Automate OCI CLI `compute instance launch` command.
- Accurately detect "Out of host capacity" (InternalError) vs other errors.
- Loop with configurable delays.
- Alert user on success.

**Non-Goals:**
- Automating the initial OCI CLI installation and configuration.
- Managing network resources (VCNs, Subnets) - assumes these are pre-configured.

## Decisions

- **Language:** Bash script. *Rationale:* OCI CLI is a command-line tool. Bash is ubiquitous on Unix-like systems, easy to loop, and requires no extra dependencies beyond `jq` (often used with OCI CLI) or basic text processing tools like `grep`. *Alternative:* Python - more robust, but requires setting up the OCI Python SDK or wrapping subprocess calls. Bash is simpler for a single-purpose wrapper.
- **Parsing Errors:** Rely on capturing stderr from the `oci compute instance launch` command. Search for specific OCI error codes related to capacity.
- **Delay:** Implement a random delay (e.g., 30-90 seconds) between attempts to avoid hitting rate limits.
- **Configuration:** Use environment variables or command-line arguments for instance configuration (shape, compartment-id, subnet-id, ssh-key, etc.) to keep the script generic, or instruct the user to generate the exact command from the OCI web console. *Decision:* Instruct user to generate the base command from the OCI Web Console (which provides a convenient "Save as local script" or "copy command" feature) and wrap *that* command.

## Risks / Trade-offs

- [Risk] Account ban due to API spam. -> Mitigation: Implement mandatory minimum sleep delays and jitter.
- [Risk] Missing dependencies. -> Mitigation: Check for `oci` command existence at start.
- [Risk] Changing OCI error messages. -> Mitigation: Target the generic 500 error code for capacity, but log unexpected errors and exit to prevent looping on bad configs.
