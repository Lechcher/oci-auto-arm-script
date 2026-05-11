## 1. CLI Options and Configuration

- [x] 1.1 Add `--no-install-oci-cli` CLI option and `OCI_AUTO_INSTALL_CLI=false` environment opt-out.
- [x] 1.2 Update help text to describe OCI CLI auto-install behavior, supported OSes, and opt-out.

## 2. OCI CLI Detection

- [x] 2.1 Replace the current hard fail when `oci` is missing with an `ensure_oci_cli` function.
- [x] 2.2 Detect an existing `oci` command on `PATH` and continue without installing.
- [x] 2.3 Validate the discovered `oci` command with `oci --version` or equivalent lightweight check.

## 3. OS-Specific Installation

- [x] 3.1 Detect OS using `uname -s`.
- [x] 3.2 Implement macOS install path: use `brew install oci-cli` when Homebrew exists.
- [x] 3.3 Implement macOS fallback: use Oracle's official curl/bash installer when Homebrew is unavailable and `curl` exists.
- [x] 3.4 Implement Linux install path: use Oracle's official curl/bash installer from `https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh`.
- [x] 3.5 Fail with clear manual install guidance for unsupported OSes or missing installer prerequisites.
- [x] 3.6 After install, re-check common OCI CLI install paths and update current-process `PATH` when needed.

## 4. Provisioning Flow Integration

- [x] 4.1 Call `ensure_oci_cli` before any OCI CLI lookup or launch command.
- [x] 4.2 Ensure existing OCI configuration is not modified and `oci setup config` is not run.
- [x] 4.3 Continue the existing default/raw provisioning flow after successful install.

## 5. Verification

- [x] 5.1 Run shell syntax validation for `auto_provision.sh`.
- [x] 5.2 Verify help output documents auto-install and opt-out.
- [x] 5.3 Verify script continues when OCI CLI is already installed.
- [x] 5.4 Verify opt-out path fails clearly when `oci` is unavailable.
- [x] 5.5 If safe on current machine, verify installer selection for detected OS without altering OCI config.
