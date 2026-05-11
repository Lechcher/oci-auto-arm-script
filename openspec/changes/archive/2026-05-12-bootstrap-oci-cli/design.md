## Context

`auto_provision.sh` depends on OCI CLI but currently exits if `oci` is missing. The OCI CLI repository documents platform-specific install methods: `brew install oci-cli` on macOS, Oracle's curl/bash installer on Linux, package-manager options for some Linux distributions, and PowerShell installer for Windows.

## Goals / Non-Goals

**Goals:**
- Check for working `oci` before provisioning.
- Detect OS using `uname -s` for the shell script environment.
- Install OCI CLI automatically when missing on supported macOS and Linux systems.
- Continue the existing script flow after installation succeeds.
- Print clear manual install guidance if auto-install cannot run safely.

**Non-Goals:**
- Running `oci setup config` or modifying user OCI credentials/config files.
- Supporting Windows execution inside the bash script beyond clear guidance.
- Installing Homebrew itself.
- Using `sudo` automatically unless the selected package manager/install method explicitly requires user-managed elevation.

## Decisions

- **Install entrypoint:** Replace the hard fail in `auto_provision.sh` with `ensure_oci_cli`, called before any OCI command is used. Existing behavior remains when `oci` is already installed.
- **macOS path:** Prefer Homebrew when `brew` exists, using `brew install oci-cli`, matching OCI CLI README. If Homebrew is absent, fall back to Oracle's official curl/bash installer when `curl` exists. This avoids silently installing Homebrew.
- **Linux path:** Use Oracle's official installer via `bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"`, matching README. If `curl` is missing, fail with manual instructions.
- **Post-install validation:** After installation, re-check `command -v oci` and run `oci --version` when available. Continue only if command is discoverable in the current shell PATH.
- **User control:** Add `--no-install-oci-cli` / `OCI_AUTO_INSTALL_CLI=false` to preserve fail-fast behavior for users who do not want automatic installers.

## Risks / Trade-offs

- [Risk] Installer modifies shell profile or PATH but current process cannot see new PATH. -> Mitigation: Re-check common install locations such as `$HOME/bin/oci` and `$HOME/lib/oracle-cli/bin/oci`, and show clear re-open-shell guidance if still unavailable.
- [Risk] Auto-install via remote script has supply-chain risk. -> Mitigation: Use Oracle's official GitHub URL already referenced by user, expose opt-out flag, and print install command before running it.
- [Risk] macOS Homebrew unavailable. -> Mitigation: Fall back to official installer or fail with manual instructions.
- [Risk] Unsupported OS. -> Mitigation: Fail clearly with link to https://github.com/oracle/oci-cli and manual install instructions.
