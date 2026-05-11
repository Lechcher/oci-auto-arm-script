#!/usr/bin/env bash

set -u

DEFAULT_REGION="ap-mumbai-1"
DEFAULT_AD="AD-1"
DEFAULT_FD="FD-2"
DEFAULT_INSTANCE_NAME="arm-server"
DEFAULT_VNIC_NAME="arm-server"
DEFAULT_SHAPE="VM.Standard.A1.Flex"
DEFAULT_OCPUS="4"
DEFAULT_MEMORY_GB="24"
DEFAULT_VCN_NAME="Linux-Server-vcn-1"
DEFAULT_SUBNET_NAME="Linux-Server-subnet-1"
DEFAULT_IMAGE_NAME="Canonical Ubuntu 24.04 Minimal aarch64"
DEFAULT_SSH_USER="ubuntu"
DEFAULT_SSH_INFO_FILE="ssh-info.txt"
DEFAULT_ARTIFACT_ROOT=".oci-arm-runs"
OCI_CLI_INSTALL_URL="https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh"

usage() {
  cat <<'USAGE'
Usage:
  Default mode:
    ./auto_provision.sh --compartment-id OCID --ssh-public-key-file ~/.ssh/id_rsa.pub --ssh-private-key-file ~/.ssh/id_rsa

  Raw command mode:
    ./auto_provision.sh [options] -- oci compute instance launch ...

Options:
  --compartment-id OCID        Required for default mode. Env: OCI_COMPARTMENT_ID
  --ssh-public-key-file PATH   Required unless --ssh-public-key is used. Env: SSH_PUBLIC_KEY_FILE
  --ssh-public-key KEY         Required unless --ssh-public-key-file is used. Env: SSH_PUBLIC_KEY
  --ssh-private-key-file PATH  Used for printed SSH command. Env: SSH_PRIVATE_KEY_FILE
  --ssh-user USER              SSH user. Default: ubuntu. Env: SSH_USER
  --ssh-info-file PATH         Output SSH info file. Default: ssh-info.txt. Env: SSH_INFO_FILE
  --env-file PATH              Load config from dotenv file. Default: .env when present. Env: ENV_FILE
  --profile NAME               OCI CLI profile for api-key auth. Env: OCI_PROFILE
  --oci-config-file PATH       OCI CLI config file for api-key auth. Env: OCI_CLI_CONFIG_FILE
  --auth-method METHOD         api-key, instance-principal, or resource-principal. Default: api-key. Env: OCI_AUTH_METHOD
  --artifact-root PATH         Project run artifact directory. Default: .oci-arm-runs. Env: OCI_ARTIFACT_ROOT
  --copy-ssh-private-key       Copy SSH private key into run artifact directory. Env: COPY_SSH_PRIVATE_KEY=true
  --overwrite-artifacts        Allow overwriting secret-bearing artifact files. Env: OVERWRITE_ARTIFACTS=true
  --image-id OCID              Override image lookup. Env: OCI_IMAGE_ID
  --vcn-id OCID                Override VCN lookup. Env: OCI_VCN_ID
  --subnet-id OCID             Override subnet lookup. Env: OCI_SUBNET_ID
  --availability-domain NAME   Override full availability domain value. Env: OCI_AVAILABILITY_DOMAIN
  --no-install-oci-cli         Disable OCI CLI auto-install. Env: OCI_AUTO_INSTALL_CLI=false
  --min-delay SECONDS          Minimum retry delay. Default: 30
  --max-delay SECONDS          Maximum retry delay. Default: 60
  -h, --help                   Show this help.

OCI CLI bootstrap:
  If oci is missing, the script can install OCI CLI automatically before provisioning.
  macOS uses Homebrew when available, otherwise Oracle's official installer.
  Linux uses Oracle's official installer from https://github.com/oracle/oci-cli.
  Unsupported OSes or missing installer prerequisites print manual install guidance.
  The script does not run 'oci setup config' or modify existing OCI config files.
  Set OCI_AUTO_INSTALL_CLI=false or pass --no-install-oci-cli to disable auto-install.

OCI authentication for scripts:
  api-key mode uses existing ~/.oci/config, key_file, and optional --profile.
  Use --oci-config-file for project-local API key config without modifying ~/.oci/config.
  instance-principal mode uses --auth instance_principal and must run on OCI Compute.
  resource-principal mode uses --auth resource_principal in supported OCI environments.
  The script validates auth with 'oci os ns get' before provisioning.
  Do not use browser login for scripts: 'oci session authenticate' is not run.
  The script does not write ~/.oci/config, private keys, fingerprints, tenancy OCIDs, or user OCIDs.

Project artifacts:
  Default mode writes run artifacts under .oci-arm-runs by default.
  Artifacts include raw instance JSON, run summary, and SSH command when available.
  SSH private key material is only copied with --copy-ssh-private-key and is written mode 0600.
  Do not commit .oci-arm-runs, OCI config files, or private keys to source control.

Dotenv configuration:
  Copy .env.example to .env for local settings. Do not commit .env.
  Supported .env lines use KEY=value syntax with optional single or double quotes.
  Precedence: CLI flags > exported environment > .env values > built-in defaults.
  The script never prints .env values and never executes .env shell code.

Default launch values:
  region: ap-mumbai-1
  AD: AD-1
  FD: FD-2
  instance name: arm-server
  shape: VM.Standard.A1.Flex
  shape configuration: 4 OCPU / 24 GB
  VNIC name: arm-server
  VCN: Linux-Server-vcn-1
  subnet: Linux-Server-subnet-1
  image: Canonical Ubuntu 24.04 Minimal aarch64

The script retries only OCI capacity errors. Other OCI CLI errors stop execution.
USAGE
}

fatal() {
  echo "Error: $*" >&2
  exit 2
}

require_value() {
  local name=$1
  local value=$2

  [[ -n "$value" ]] || fatal "$name is required."
}

trim_dotenv_value() {
  local value=$1

  value=${value#${value%%[![:space:]]*}}
  value=${value%${value##*[![:space:]]}}
  printf '%s' "$value"
}

strip_dotenv_comment() {
  local value=$1
  local result=""
  local char
  local prev=""
  local quote=""
  local i

  for ((i = 0; i < ${#value}; i++)); do
    char=${value:i:1}
    if [[ -z "$quote" && "$char" == "#" && ( -z "$prev" || "$prev" == [[:space:]] ) ]]; then
      break
    fi
    if [[ "$char" == "'" && "$quote" != '"' ]]; then
      if [[ "$quote" == "'" ]]; then
        quote=""
      elif [[ -z "$quote" ]]; then
        quote="'"
      fi
    elif [[ "$char" == '"' && "$quote" != "'" ]]; then
      if [[ "$quote" == '"' ]]; then
        quote=""
      elif [[ -z "$quote" ]]; then
        quote='"'
      fi
    fi
    result+="$char"
    prev="$char"
  done

  trim_dotenv_value "$result"
}

parse_dotenv_value() {
  local raw=$1
  local value

  value=$(strip_dotenv_comment "$raw")
  if [[ "$value" == "\""*"\"" && ${#value} -ge 2 ]]; then
    value=${value:1:${#value}-2}
    value=${value//\\n/$'\n'}
    value=${value//\\r/$'\r'}
    value=${value//\\t/$'\t'}
    value=${value//\\\"/\"}
    value=${value//\\\\/\\}
  elif [[ "$value" == "'"*"'" && ${#value} -ge 2 ]]; then
    value=${value:1:${#value}-2}
  fi

  printf '%s' "$value"
}

is_supported_env_key() {
  case "$1" in
    OCI_REGION|OCI_PROFILE|OCI_CLI_CONFIG_FILE|OCI_AUTH_METHOD|OCI_COMPARTMENT_ID|\
    SSH_PUBLIC_KEY_FILE|SSH_PUBLIC_KEY|SSH_PRIVATE_KEY_FILE|SSH_USER|SSH_INFO_FILE|\
    OCI_ARTIFACT_ROOT|COPY_SSH_PRIVATE_KEY|OVERWRITE_ARTIFACTS|OCI_IMAGE_ID|\
    OCI_VCN_ID|OCI_SUBNET_ID|OCI_AVAILABILITY_DOMAIN|OCI_AUTO_INSTALL_CLI|\
    OCI_LAUNCH_CMD|MIN_DELAY|MAX_DELAY|ENV_FILE)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

load_dotenv_file() {
  local file=$1
  local explicit=$2
  local line
  local trimmed
  local key
  local raw_value
  local value
  local line_no=0

  if [[ ! -e "$file" ]]; then
    if [[ "$explicit" == true ]]; then
      fatal "env file not found: $file"
    fi
    return 0
  fi

  [[ -r "$file" ]] || fatal "env file is not readable: $file"

  while IFS= read -r line || [[ -n "$line" ]]; do
    line_no=$((line_no + 1))
    trimmed=$(trim_dotenv_value "$line")
    [[ -z "$trimmed" || "$trimmed" == \#* ]] && continue

    if [[ "$trimmed" == export[[:space:]]* ]]; then
      trimmed=$(trim_dotenv_value "${trimmed#export}")
    fi

    if [[ "$trimmed" != *=* ]]; then
      echo "Warning: ignoring unsupported dotenv syntax at ${file}:${line_no}" >&2
      continue
    fi

    key=$(trim_dotenv_value "${trimmed%%=*}")
    raw_value=${trimmed#*=}
    if ! [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
      echo "Warning: ignoring invalid dotenv key at ${file}:${line_no}" >&2
      continue
    fi

    if ! is_supported_env_key "$key"; then
      echo "Warning: ignoring unsupported dotenv key at ${file}:${line_no}" >&2
      continue
    fi

    if [[ -n ${!key+x} ]]; then
      continue
    fi

    value=$(parse_dotenv_value "$raw_value")
    printf -v "$key" '%s' "$value"
    export "$key"
  done < "$file"
}

pre_scan_env_file() {
  local selected=${ENV_FILE:-}
  local explicit=false

  if [[ -n "$selected" ]]; then
    explicit=true
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --env-file)
        [[ $# -ge 2 ]] || fatal "missing value for --env-file"
        selected="$2"
        explicit=true
        shift 2
        ;;
      --)
        break
        ;;
      *)
        shift
        ;;
    esac
  done

  if [[ -n "$selected" ]]; then
    env_file="$selected"
    load_dotenv_file "$env_file" true
  else
    env_file=".env"
    load_dotenv_file "$env_file" false
  fi
}

normalize_auth_method() {
  case "$1" in
    api-key|api_key|apiKey|API_KEY)
      printf '%s\n' "api-key"
      ;;
    instance-principal|instance_principal|INSTANCE_PRINCIPAL)
      printf '%s\n' "instance-principal"
      ;;
    resource-principal|resource_principal|RESOURCE_PRINCIPAL)
      printf '%s\n' "resource-principal"
      ;;
    *)
      return 1
      ;;
  esac
}

oci_auth_arg() {
  case "$auth_method" in
    api-key)
      return 0
      ;;
    instance-principal)
      printf '%s\n' "instance_principal"
      ;;
    resource-principal)
      printf '%s\n' "resource_principal"
      ;;
  esac
}

print_api_key_auth_guidance() {
  local config_display=${oci_config_file:-~/.oci/config}

  printf '%s\n' \
    "API key auth requires existing OCI CLI config:" \
    "  ${config_display} with user, fingerprint, tenancy, region, and key_file" \
    "  chmod 700 ~/.oci" \
    "  chmod 600 ${config_display}" \
    "  chmod 600 <private-key-file>" \
    "Use --profile NAME or OCI_PROFILE for non-DEFAULT profiles." \
    "Use --oci-config-file PATH or OCI_CLI_CONFIG_FILE for project-local config." >&2
}

print_instance_principal_guidance() {
  printf '%s\n' \
    "Instance principal auth requires:" \
    "  running on OCI Compute" \
    "  instance included in a dynamic group" \
    "  IAM policy granting required permissions" >&2
}

print_resource_principal_guidance() {
  printf '%s\n' \
    "Resource principal auth requires a supported OCI environment such as Functions, OKE, or Cloud Shell" \
    "with environment-provided identity and IAM permissions." >&2
}

print_auth_failure_guidance() {
  local output=$1
  local normalized

  normalized=$(printf '%s' "$output" | tr '[:upper:]' '[:lower:]')
  printf '%s\n' "OCI CLI authentication validation failed." >&2

  case "$auth_method" in
    instance-principal)
      print_instance_principal_guidance
      ;;
    resource-principal)
      print_resource_principal_guidance
      ;;
    api-key)
      if [[ "$normalized" == *"could not find config file"* ]] || [[ "$normalized" == *"config file"*"not found"* ]]; then
        if [[ -n "$oci_config_file" ]]; then
          printf '%s\n' "Selected OCI config file was not found: $oci_config_file" >&2
        fi
        print_api_key_auth_guidance
      elif [[ "$normalized" == *"private key"*"not found"* ]] || [[ "$normalized" == *"key_file"* ]] || [[ "$normalized" == *"no such file"* ]]; then
        printf '%s\n' "Check key_file path in OCI config and private key permissions." >&2
        print_api_key_auth_guidance
      elif [[ "$normalized" == *"fingerprint"* ]] || [[ "$normalized" == *"notauthenticated"* ]] || [[ "$normalized" == *"not authenticated"* ]]; then
        printf '%s\n' "Check user OCID, tenancy OCID, fingerprint, region, and uploaded API public key match." >&2
        print_api_key_auth_guidance
      elif [[ "$normalized" == *"permission denied"* ]] || [[ "$normalized" == *"notauthorized"* ]] || [[ "$normalized" == *"not authorized"* ]]; then
        printf '%s\n' "Check IAM policies for required tenancy/compartment permissions." >&2
      else
        print_api_key_auth_guidance
      fi
      ;;
  esac
}

validate_oci_auth() {
  local output
  local status

  output=$(oci_base os ns get 2>&1)
  status=$?
  if (( status == 0 )); then
    return 0
  fi

  printf '%s\n' "$output" >&2
  print_auth_failure_guidance "$output"
  exit 127
}

oci_cli_available() {
  command -v oci >/dev/null 2>&1 && oci --version >/dev/null 2>&1
}

manual_oci_cli_install_guidance() {
  printf '%s\n' \
    "OCI CLI is required before provisioning." \
    "Install OCI CLI manually, then configure credentials if needed:" \
    "  https://github.com/oracle/oci-cli" \
    "" \
    "This script does not run 'oci setup config' or modify OCI configuration files." >&2
}

add_oci_cli_path_if_present() {
  local candidate_dir

  for candidate_dir in \
    "$HOME/bin" \
    "$HOME/lib/oracle-cli/bin" \
    "/opt/homebrew/bin" \
    "/usr/local/bin"; do
    if [[ -x "$candidate_dir/oci" ]]; then
      case ":$PATH:" in
        *":$candidate_dir:"*) ;;
        *) PATH="$candidate_dir:$PATH" ;;
      esac
    fi
  done
}

run_oracle_oci_cli_installer() {
  command -v curl >/dev/null 2>&1 || return 1
  echo "Installing OCI CLI with Oracle official installer: $OCI_CLI_INSTALL_URL"
  bash -c "$(curl -L "$OCI_CLI_INSTALL_URL")"
}

install_oci_cli_for_os() {
  local os_name

  os_name=$(uname -s 2>/dev/null || printf 'unknown')
  case "$os_name" in
    Darwin)
      if command -v brew >/dev/null 2>&1; then
        echo "Installing OCI CLI with Homebrew: brew install oci-cli"
        brew install oci-cli
      elif command -v curl >/dev/null 2>&1; then
        run_oracle_oci_cli_installer
      else
        return 1
      fi
      ;;
    Linux)
      run_oracle_oci_cli_installer
      ;;
    *)
      return 1
      ;;
  esac
}

ensure_oci_cli() {
  if oci_cli_available; then
    return 0
  fi

  if [[ "$auto_install_oci_cli" == false ]]; then
    echo "Error: OCI CLI not found and auto-install is disabled." >&2
    manual_oci_cli_install_guidance
    exit 127
  fi

  add_oci_cli_path_if_present
  if oci_cli_available; then
    return 0
  fi

  echo "OCI CLI not found. Attempting automatic install..."
  if ! install_oci_cli_for_os; then
    echo "Error: OCI CLI automatic install is not available on this system or prerequisites are missing." >&2
    manual_oci_cli_install_guidance
    exit 127
  fi

  add_oci_cli_path_if_present
  if ! oci_cli_available; then
    echo "Error: OCI CLI install completed, but 'oci' is not executable in this shell." >&2
    echo "Reopen your shell or add the OCI CLI install directory to PATH, then rerun this script." >&2
    manual_oci_cli_install_guidance
    exit 127
  fi
}

oci_base() {
  local cmd=(oci --region "$region")
  local auth_arg

  if [[ "$auth_method" == "api-key" && -n "$profile" ]]; then
    cmd+=(--profile "$profile")
  fi

  if [[ "$auth_method" == "api-key" && -n "$oci_config_file" ]]; then
    cmd+=(--config-file "$oci_config_file")
  fi

  auth_arg=$(oci_auth_arg)
  if [[ -n "$auth_arg" ]]; then
    cmd+=(--auth "$auth_arg")
  fi

  "${cmd[@]}" "$@"
}

oci_text() {
  oci_base "$@" --raw-output 2>/dev/null | sed '/^$/d' | head -n 1
}

lookup_required() {
  local description=$1
  shift
  local value

  value=$(oci_text "$@") || true
  [[ -n "$value" && "$value" != "null" ]] || fatal "could not resolve $description."
  printf '%s\n' "$value"
}

read_ssh_public_key() {
  if [[ -n "$ssh_public_key" ]]; then
    printf '%s\n' "$ssh_public_key"
    return
  fi

  require_value "SSH public key file" "$ssh_public_key_file"
  [[ -r "$ssh_public_key_file" ]] || fatal "SSH public key file is not readable: $ssh_public_key_file"
  IFS= read -r ssh_public_key < "$ssh_public_key_file"
  require_value "SSH public key" "$ssh_public_key"
  printf '%s\n' "$ssh_public_key"
}

resolve_availability_domain() {
  if [[ -n "$availability_domain" ]]; then
    printf '%s\n' "$availability_domain"
    return
  fi

  lookup_required "availability domain $DEFAULT_AD" iam availability-domain list \
    --compartment-id "$compartment_id" \
    --query "data[?ends_with(name, '\`${DEFAULT_AD}\`')].name | [0]"
}

resolve_vcn_id() {
  if [[ -n "$vcn_id" ]]; then
    printf '%s\n' "$vcn_id"
    return
  fi

  lookup_required "VCN $DEFAULT_VCN_NAME" network vcn list \
    --compartment-id "$compartment_id" \
    --display-name "$DEFAULT_VCN_NAME" \
    --query 'data[0].id'
}

resolve_subnet_id() {
  if [[ -n "$subnet_id" ]]; then
    printf '%s\n' "$subnet_id"
    return
  fi

  lookup_required "subnet $DEFAULT_SUBNET_NAME" network subnet list \
    --compartment-id "$compartment_id" \
    --vcn-id "$resolved_vcn_id" \
    --display-name "$DEFAULT_SUBNET_NAME" \
    --query 'data[0].id'
}

resolve_image_id() {
  if [[ -n "$image_id" ]]; then
    printf '%s\n' "$image_id"
    return
  fi

  lookup_required "image $DEFAULT_IMAGE_NAME" compute image list \
    --compartment-id "$compartment_id" \
    --operating-system "Canonical Ubuntu" \
    --shape "$DEFAULT_SHAPE" \
    --query "data[?\"display-name\" == '\`${DEFAULT_IMAGE_NAME}\`'].id | [0]"
}

build_default_launch_cmd() {
  require_value "compartment ID" "$compartment_id"
  ssh_public_key=$(read_ssh_public_key)

  resolved_ad=$(resolve_availability_domain)
  resolved_vcn_id=$(resolve_vcn_id)
  resolved_subnet_id=$(resolve_subnet_id)
  resolved_image_id=$(resolve_image_id)

  launch_cmd=(oci --region "$region")
  if [[ "$auth_method" == "api-key" && -n "$profile" ]]; then
    launch_cmd+=(--profile "$profile")
  fi
  if [[ "$auth_method" == "api-key" && -n "$oci_config_file" ]]; then
    launch_cmd+=(--config-file "$oci_config_file")
  fi
  auth_arg=$(oci_auth_arg)
  if [[ -n "$auth_arg" ]]; then
    launch_cmd+=(--auth "$auth_arg")
  fi

  launch_cmd+=(compute instance launch)
  launch_cmd+=(--compartment-id "$compartment_id")
  launch_cmd+=(--availability-domain "$resolved_ad")
  launch_cmd+=(--fault-domain "$DEFAULT_FD")
  launch_cmd+=(--display-name "$DEFAULT_INSTANCE_NAME")
  launch_cmd+=(--shape "$DEFAULT_SHAPE")
  launch_cmd+=(--shape-config "{\"ocpus\": ${DEFAULT_OCPUS}, \"memoryInGBs\": ${DEFAULT_MEMORY_GB}}")
  launch_cmd+=(--image-id "$resolved_image_id")
  launch_cmd+=(--create-vnic-details "{\"assignPublicIp\": true, \"displayName\": \"${DEFAULT_VNIC_NAME}\", \"hostnameLabel\": \"${DEFAULT_INSTANCE_NAME}\", \"subnetId\": \"${resolved_subnet_id}\"}")
  launch_cmd+=(--metadata "{\"ssh_authorized_keys\": \"${ssh_public_key}\"}")
}

is_capacity_error() {
  local output=$1
  local normalized

  normalized=$(printf '%s' "$output" | tr '[:upper:]' '[:lower:]')

  [[ "$normalized" == *"out of host capacity"* ]] || \
    [[ "$normalized" == *"out of capacity"* ]] || \
    ([[ "$normalized" == *"internalerror"* ]] && [[ "$normalized" == *"500"* ]] && [[ "$normalized" == *"capacity"* ]])
}

random_delay() {
  local spread=$((max_delay - min_delay + 1))

  if (( spread <= 1 )); then
    printf '%s\n' "$min_delay"
  else
    printf '%s\n' $((min_delay + RANDOM % spread))
  fi
}

extract_instance_id() {
  local output=$1

  printf '%s\n' "$output" | sed -n 's/.*"id"[[:space:]]*:[[:space:]]*"\(ocid1\.instance[^"[:space:]]*\)".*/\1/p' | head -n 1
}

resolve_public_ip() {
  local instance_id=$1
  local vnic_id
  local public_ip

  vnic_id=$(lookup_required "primary VNIC attachment" compute vnic-attachment list \
    --compartment-id "$compartment_id" \
    --instance-id "$instance_id" \
    --query 'data[0]."vnic-id"')

  public_ip=$(lookup_required "public IP for primary VNIC" network vnic get \
    --vnic-id "$vnic_id" \
    --query 'data."public-ip"')

  printf '%s\n' "$public_ip"
}

json_escape() {
  local value=$1

  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//$'\n'/\\n}
  value=${value//$'\r'/\\r}
  value=${value//$'\t'/\\t}
  printf '%s' "$value"
}

ensure_artifact_ignore() {
  local ignore_entry=$1

  if [[ ! -d .git ]]; then
    echo "Warning: source-control ignore not verified. Do not commit artifact path: $artifact_root" >&2
    return 0
  fi

  if [[ -f .gitignore ]] && grep -Fxq "$ignore_entry" .gitignore; then
    return 0
  fi

  if [[ -e .gitignore && ! -w .gitignore ]]; then
    echo "Warning: .gitignore is not writable. Do not commit artifact path: $artifact_root" >&2
    return 0
  fi

  printf '\n%s\n' "$ignore_entry" >> .gitignore
  echo "Added artifact path to .gitignore: $ignore_entry"
}

ensure_ignore_entry() {
  local ignore_entry=$1

  if [[ ! -d .git ]]; then
    return 1
  fi

  if [[ -f .gitignore ]] && grep -Fxq "$ignore_entry" .gitignore; then
    return 0
  fi

  if [[ -e .gitignore && ! -w .gitignore ]]; then
    return 1
  fi

  printf '%s\n' "$ignore_entry" >> .gitignore
}

ensure_dotenv_ignore() {
  local ok=true
  local entry

  if [[ ! -d .git ]]; then
    echo "Warning: source-control ignore not verified. Do not commit .env or local dotenv files." >&2
    return 0
  fi

  for entry in ".env" ".env.local" ".env.*.local"; do
    if ! ensure_ignore_entry "$entry"; then
      ok=false
    fi
  done

  if [[ "$ok" != true ]]; then
    echo "Warning: dotenv ignore rules could not be verified. Do not commit .env or local dotenv files." >&2
  fi
}

prepare_run_artifact_dir() {
  local instance_id=$1
  local timestamp=$2
  local short_id="unknown"
  local safe_timestamp

  safe_timestamp=${timestamp//:/}
  safe_timestamp=${safe_timestamp//+/-}
  if [[ -n "$instance_id" && "$instance_id" != "null" ]]; then
    short_id=${instance_id##*.}
    short_id=${short_id:0:12}
  fi

  mkdir -p "$artifact_root" || fatal "could not create artifact root: $artifact_root"
  ensure_artifact_ignore "${artifact_root%/}/"

  run_artifact_dir="${artifact_root%/}/${safe_timestamp}-${short_id}"
  if [[ -e "$run_artifact_dir" && "$overwrite_artifacts" != true ]]; then
    fatal "run artifact directory already exists: $run_artifact_dir"
  fi
  mkdir -p "$run_artifact_dir" || fatal "could not create run artifact directory: $run_artifact_dir"
}

copy_private_key_artifact() {
  local destination

  [[ "$copy_ssh_private_key" == true ]] || return 0
  require_value "SSH private key file" "$ssh_private_key_file"
  [[ -r "$ssh_private_key_file" ]] || fatal "SSH private key file is not readable: $ssh_private_key_file"

  destination="$run_artifact_dir/ssh_private_key"
  if [[ -e "$destination" && "$overwrite_artifacts" != true ]]; then
    fatal "SSH private key artifact already exists: $destination"
  fi

  cp "$ssh_private_key_file" "$destination" || fatal "could not copy SSH private key artifact"
  chmod 600 "$destination" || fatal "could not set SSH private key artifact permissions to 0600"
  ssh_private_key_artifact="$destination"
}

write_run_artifacts() {
  local instance_id=$1
  local public_ip=$2
  local timestamp
  local ssh_command=""
  local ssh_command_key
  local profile_display=${profile:-}
  local config_display=${oci_config_file:-}

  timestamp=$(date -u +%Y%m%dT%H%M%SZ)
  prepare_run_artifact_dir "$instance_id" "$timestamp"
  printf '%s\n' "$output" > "$run_artifact_dir/instance.json"

  copy_private_key_artifact
  ssh_command_key=${ssh_private_key_artifact:-$ssh_private_key_file}
  if [[ -n "$public_ip" && "$public_ip" != "null" && -n "$ssh_command_key" ]]; then
    ssh_command="ssh -i ${ssh_command_key} ${ssh_user}@${public_ip}"
    printf '%s\n' "$ssh_command" > "$run_artifact_dir/ssh-command.txt"
  fi

  cat > "$run_artifact_dir/summary.txt" <<INFO
Timestamp: ${timestamp}
Instance name: ${DEFAULT_INSTANCE_NAME}
Instance OCID: ${instance_id}
Region: ${region}
Public IP: ${public_ip}
SSH user: ${ssh_user}
Private key path: ${ssh_private_key_file}
Private key artifact: ${ssh_private_key_artifact:-}
SSH command: ${ssh_command}
OCI auth method: ${auth_method}
OCI profile: ${profile_display}
OCI config file: ${config_display}
INFO

  cat > "$run_artifact_dir/summary.env" <<INFO
RUN_TIMESTAMP="$(json_escape "$timestamp")"
INSTANCE_NAME="$(json_escape "$DEFAULT_INSTANCE_NAME")"
INSTANCE_OCID="$(json_escape "$instance_id")"
OCI_REGION="$(json_escape "$region")"
PUBLIC_IP="$(json_escape "$public_ip")"
SSH_USER="$(json_escape "$ssh_user")"
SSH_PRIVATE_KEY_FILE="$(json_escape "$ssh_private_key_file")"
SSH_PRIVATE_KEY_ARTIFACT="$(json_escape "${ssh_private_key_artifact:-}")"
SSH_COMMAND="$(json_escape "$ssh_command")"
OCI_AUTH_METHOD="$(json_escape "$auth_method")"
OCI_PROFILE="$(json_escape "$profile_display")"
OCI_CLI_CONFIG_FILE="$(json_escape "$config_display")"
INFO

  echo "Run artifacts saved to: $run_artifact_dir"
  if [[ -n "$ssh_command" ]]; then
    echo "SSH command saved to: $run_artifact_dir/ssh-command.txt"
  fi
}

write_ssh_info() {
  local instance_id=$1
  local public_ip=$2
  local ssh_command

  ssh_command="ssh -i ${ssh_private_key_file} ${ssh_user}@${public_ip}"

  cat > "$ssh_info_file" <<INFO
Instance name: ${DEFAULT_INSTANCE_NAME}
Instance OCID: ${instance_id}
Public IP: ${public_ip}
SSH user: ${ssh_user}
Private key: ${ssh_private_key_file}
SSH command: ${ssh_command}
INFO

  echo "SSH information saved to: $ssh_info_file"
  echo "SSH command: $ssh_command"
}

env_file=""
pre_scan_env_file "$@"

min_delay=${MIN_DELAY:-30}
max_delay=${MAX_DELAY:-60}
region=${OCI_REGION:-$DEFAULT_REGION}
profile=${OCI_PROFILE:-}
oci_config_file=${OCI_CLI_CONFIG_FILE:-}
auth_method=${OCI_AUTH_METHOD:-api-key}
compartment_id=${OCI_COMPARTMENT_ID:-}
ssh_public_key_file=${SSH_PUBLIC_KEY_FILE:-}
ssh_public_key=${SSH_PUBLIC_KEY:-}
ssh_private_key_file=${SSH_PRIVATE_KEY_FILE:-}
ssh_user=${SSH_USER:-$DEFAULT_SSH_USER}
ssh_info_file=${SSH_INFO_FILE:-$DEFAULT_SSH_INFO_FILE}
artifact_root=${OCI_ARTIFACT_ROOT:-$DEFAULT_ARTIFACT_ROOT}
copy_ssh_private_key=false
overwrite_artifacts=false
image_id=${OCI_IMAGE_ID:-}
vcn_id=${OCI_VCN_ID:-}
subnet_id=${OCI_SUBNET_ID:-}
availability_domain=${OCI_AVAILABILITY_DOMAIN:-}
auto_install_oci_cli=true
raw_mode=false
declare -a launch_cmd=()
run_artifact_dir=""
ssh_private_key_artifact=""

case "${OCI_AUTO_INSTALL_CLI:-true}" in
  false|FALSE|False|0|no|NO|No)
    auto_install_oci_cli=false
    ;;
esac

case "${COPY_SSH_PRIVATE_KEY:-false}" in
  true|TRUE|True|1|yes|YES|Yes)
    copy_ssh_private_key=true
    ;;
esac

case "${OVERWRITE_ARTIFACTS:-false}" in
  true|TRUE|True|1|yes|YES|Yes)
    overwrite_artifacts=true
    ;;
esac

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env-file)
      [[ $# -ge 2 ]] || fatal "missing value for --env-file"
      env_file="$2"
      shift 2
      ;;
    --compartment-id)
      [[ $# -ge 2 ]] || fatal "missing value for --compartment-id"
      compartment_id="$2"
      shift 2
      ;;
    --ssh-public-key-file)
      [[ $# -ge 2 ]] || fatal "missing value for --ssh-public-key-file"
      ssh_public_key_file="$2"
      shift 2
      ;;
    --ssh-public-key)
      [[ $# -ge 2 ]] || fatal "missing value for --ssh-public-key"
      ssh_public_key="$2"
      shift 2
      ;;
    --ssh-private-key-file)
      [[ $# -ge 2 ]] || fatal "missing value for --ssh-private-key-file"
      ssh_private_key_file="$2"
      shift 2
      ;;
    --ssh-user)
      [[ $# -ge 2 ]] || fatal "missing value for --ssh-user"
      ssh_user="$2"
      shift 2
      ;;
    --ssh-info-file)
      [[ $# -ge 2 ]] || fatal "missing value for --ssh-info-file"
      ssh_info_file="$2"
      shift 2
      ;;
    --profile)
      [[ $# -ge 2 ]] || fatal "missing value for --profile"
      profile="$2"
      shift 2
      ;;
    --oci-config-file)
      [[ $# -ge 2 ]] || fatal "missing value for --oci-config-file"
      oci_config_file="$2"
      shift 2
      ;;
    --auth-method)
      [[ $# -ge 2 ]] || fatal "missing value for --auth-method"
      auth_method="$2"
      shift 2
      ;;
    --artifact-root)
      [[ $# -ge 2 ]] || fatal "missing value for --artifact-root"
      artifact_root="$2"
      shift 2
      ;;
    --copy-ssh-private-key)
      copy_ssh_private_key=true
      shift
      ;;
    --overwrite-artifacts)
      overwrite_artifacts=true
      shift
      ;;
    --image-id)
      [[ $# -ge 2 ]] || fatal "missing value for --image-id"
      image_id="$2"
      shift 2
      ;;
    --vcn-id)
      [[ $# -ge 2 ]] || fatal "missing value for --vcn-id"
      vcn_id="$2"
      shift 2
      ;;
    --subnet-id)
      [[ $# -ge 2 ]] || fatal "missing value for --subnet-id"
      subnet_id="$2"
      shift 2
      ;;
    --availability-domain)
      [[ $# -ge 2 ]] || fatal "missing value for --availability-domain"
      availability_domain="$2"
      shift 2
      ;;
    --no-install-oci-cli)
      auto_install_oci_cli=false
      shift
      ;;
    --min-delay)
      [[ $# -ge 2 ]] || fatal "missing value for --min-delay"
      min_delay="$2"
      shift 2
      ;;
    --max-delay)
      [[ $# -ge 2 ]] || fatal "missing value for --max-delay"
      max_delay="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      launch_cmd=("$@")
      raw_mode=true
      break
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

requested_auth_method=$auth_method
auth_method=$(normalize_auth_method "$requested_auth_method") || fatal "unsupported auth method: $requested_auth_method. Use api-key, instance-principal, or resource-principal."

ensure_dotenv_ignore
ensure_oci_cli
validate_oci_auth

if ! [[ "$min_delay" =~ ^[0-9]+$ && "$max_delay" =~ ^[0-9]+$ ]]; then
  fatal "delays must be non-negative integers"
fi

if (( min_delay > max_delay )); then
  fatal "--min-delay cannot be greater than --max-delay"
fi

if [[ ${#launch_cmd[@]} -eq 0 && -n "${OCI_LAUNCH_CMD:-}" ]]; then
  launch_cmd=(bash -c "$OCI_LAUNCH_CMD")
  raw_mode=true
fi

if [[ ${#launch_cmd[@]} -eq 0 ]]; then
  build_default_launch_cmd
fi

attempt=1
instance_id=""
output=""

while true; do
  echo "Attempt ${attempt}: launching OCI instance..."
  output=$("${launch_cmd[@]}" 2>&1)
  status=$?

  if (( status == 0 )); then
    echo "$output"
    instance_id=$(extract_instance_id "$output")
    echo
    echo "SUCCESS: OCI instance provisioned."
    printf '\a\n'
    break
  fi

  if is_capacity_error "$output"; then
    delay=$(random_delay)
    echo "$output" >&2
    echo "Capacity unavailable. Retrying in ${delay} seconds..." >&2
    sleep "$delay"
    attempt=$((attempt + 1))
    continue
  fi

  echo "$output" >&2
  echo "Fatal OCI CLI error. Not retrying." >&2
  exit "$status"
done

if [[ "$raw_mode" == true ]]; then
  exit 0
fi

if [[ -z "$instance_id" || "$instance_id" == "null" ]]; then
  echo "Warning: instance created, but instance OCID could not be parsed. SSH info not generated." >&2
  exit 0
fi

sleep 10
public_ip=$(resolve_public_ip "$instance_id") || public_ip=""

if [[ -z "$public_ip" || "$public_ip" == "null" ]]; then
  echo "Warning: instance created, but no public IP was found. SSH command not generated." >&2
  write_run_artifacts "$instance_id" ""
  exit 0
fi

write_run_artifacts "$instance_id" "$public_ip"

if [[ -z "$ssh_private_key_file" ]]; then
  echo "Warning: instance created, but SSH private key path was not provided. SSH command not generated." >&2
  exit 0
fi

write_ssh_info "$instance_id" "$public_ip"
