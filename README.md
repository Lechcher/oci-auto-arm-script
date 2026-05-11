# OCI Auto ARM Instance Script

A reliable, retry-aware Bash script to automatically provision an Oracle Cloud Infrastructure (OCI) ARM instance (`VM.Standard.A1.Flex`) when capacity becomes available.

Oracle Cloud's Always Free ARM instances frequently return "Out of host capacity" errors in popular regions. This script automates the retry process, handling authentication, OCI CLI installation, instance provisioning, and SSH info extraction.

## Prerequisites

- `bash`
- `curl` (for automated OCI CLI installation)
- An active Oracle Cloud Infrastructure account
- Required OCI configuration (user OCID, tenancy OCID, fingerprint, and region)
- An SSH key pair

## Quick Start

The simplest way to use the script is via the `.env` file configuration and default launch mode.

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```
2. Fill in the required fields in `.env`, such as `OCI_COMPARTMENT_ID` and your SSH key paths.
3. Run the script:
   ```bash
   ./auto_provision.sh
   ```

Alternatively, you can provide all required values via CLI flags:

```bash
./auto_provision.sh \
  --compartment-id ocid1.compartment.oc1..example \
  --ssh-public-key-file ~/.ssh/id_rsa.pub \
  --ssh-private-key-file ~/.ssh/id_rsa
```

## Launch Modes

### Default Launch Mode
When run without a trailing `--`, the script builds a default `oci compute instance launch` command aiming for an Always Free ARM instance (`VM.Standard.A1.Flex` with 4 OCPUs, 24 GB RAM). It automatically looks up the necessary `image-id`, `vcn-id`, and `subnet-id` based on default names.

### Raw Command Mode
If you need full control over the exact `oci compute instance launch` command, pass it after `--`:

```bash
./auto_provision.sh --auth-method api-key -- oci compute instance launch \
  --compartment-id ocid1.compartment.oc1..example \
  --availability-domain AD-1 \
  --shape VM.Standard.A1.Flex \
  ...
```
In raw command mode, the script manages the retry loop but executes your command exactly as provided.

## OCI CLI Auto-Bootstrap

If the `oci` command is not available on your system, the script will attempt to install it automatically:
- **macOS**: Uses Homebrew (`brew install oci-cli`) if available, falling back to the official Oracle script.
- **Linux**: Uses the official Oracle curl/bash installer.

The script *never* runs `oci setup config` or modifies existing credential files. You can disable this behavior by passing `--no-install-oci-cli` or setting `OCI_AUTO_INSTALL_CLI=false` in `.env`.

## Authentication Modes

The script supports three non-interactive authentication methods, specified via `--auth-method` or `OCI_AUTH_METHOD`:

1. **`api-key` (Default)**: Uses standard OCI CLI config (`~/.oci/config` or the path passed to `--oci-config-file`). Requires valid `user`, `fingerprint`, `tenancy`, `region`, and `key_file`.
2. **`instance-principal`**: For running the script on an existing OCI Compute instance. Requires the instance to be in a dynamic group with appropriate IAM policies.
3. **`resource-principal`**: For running in supported OCI environments like Cloud Shell, OKE, or Functions.

*Note: Browser-based login (`oci session authenticate`) is not supported for automation.*

## Project Artifacts & Security

When an instance is successfully created in default launch mode, the script generates a unique project-local artifact directory (by default under `.oci-arm-runs/`).

This directory includes:
- `instance.json`: Raw OCI CLI JSON output.
- `summary.txt` / `summary.env`: Convenient details including the instance OCID and public IP.
- `ssh-command.txt`: A copy-pasteable SSH command if the instance got a public IP.

**Secret Safety**: 
- Artifact directories contain sensitive output. Keep `.oci-arm-runs/` out of source control (the script attempts to add it to `.gitignore` automatically).
- The script never prints your private key contents or OCI config secrets to the console.
- If `--copy-ssh-private-key` is used, the private key is copied with restrictive `0600` permissions.

## Configuration & Flags

All flags can be set via the `.env` file or environment variables.

| CLI Flag | Env Var / `.env` Key | Description |
|---|---|---|
| `--env-file PATH` | `ENV_FILE` | Alternate `.env` file to load. |
| `--auth-method METHOD` | `OCI_AUTH_METHOD` | `api-key`, `instance-principal`, or `resource-principal`. |
| `--profile NAME` | `OCI_PROFILE` | Profile name in the OCI config file. |
| `--oci-config-file PATH` | `OCI_CLI_CONFIG_FILE` | Custom path to the OCI config file for `api-key` auth. |
| `--compartment-id OCID` | `OCI_COMPARTMENT_ID` | Required. The target compartment OCID. |
| `--ssh-public-key-file PATH` | `SSH_PUBLIC_KEY_FILE` | Path to public key (e.g. `~/.ssh/id_rsa.pub`). |
| `--ssh-private-key-file PATH` | `SSH_PRIVATE_KEY_FILE` | Path to private key (used for artifact/info generation). |
| `--artifact-root PATH` | `OCI_ARTIFACT_ROOT` | Directory for run artifacts (default: `.oci-arm-runs`). |
| `--copy-ssh-private-key` | `COPY_SSH_PRIVATE_KEY` | Copy the SSH private key into the artifact directory. |
| `--overwrite-artifacts` | `OVERWRITE_ARTIFACTS` | Allow overwriting existing secret-bearing artifacts. |
| `--min-delay SECONDS` | `MIN_DELAY` | Minimum seconds between retries (default: 30). |
| `--max-delay SECONDS` | `MAX_DELAY` | Maximum seconds between retries (default: 60). |
| `--no-install-oci-cli` | `OCI_AUTO_INSTALL_CLI` | Disable automatic OCI CLI installation. |

*(For full flag details, including resource overrides like `--image-id` and `--vcn-id`, run `./auto_provision.sh --help`)*
