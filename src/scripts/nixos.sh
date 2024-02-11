#! /usr/bin/env bash

set -o errexit

reset=$(tput sgr0)
# shellcheck disable=SC2034
null=/dev/null
declare -A tool_log_colors=(
    [DEFAULT]=$(tput setaf 2)
)
declare -A log_level_colors=(
    [ERROR]=$(tput setaf 1)
    [WARNING]=$(tput setaf 5)
    [INFO]=$(tput setaf 4)
)
declare -A exit_status_codes=(
    [SUCCESS]=0
    [FAILURE]=1
    [INVALID]=2
)

function logfx() {
    local "$@"
    local file="${file:-null}" tool="${tool:-DEFAULT}" level="${level:-INFO}" prefix=

    # Catch invalid function calls
    if [[ ! -v tool_log_colors[$tool] ]]; then
        message="'$tool' is not a valid tool among: ${!tool_log_colors[*]}"
        logfx level=ERROR exit_status=INVALID <<< "$message"
    fi
    if [[ ! -v log_level_colors[$level] ]]; then
        message="'$level' is not a valid log level among: ${!log_level_colors[*]}"
        logfx level=ERROR exit_status=INVALID <<< "$message"
    fi
    if [[ -v exit_status && ! -v exit_status_codes[$exit_status] ]]; then
        message="'$exit_status' is not a valid exit status among: ${!exit_status_codes[*]}"
        logfx level=ERROR exit_status=INVALID <<< "$message"
    fi

    # Build the logging prefix
    if [[ $level != INFO ]]; then
        prefix="${log_level_colors[$level]}$level$reset $prefix"
    fi
    prefix="${tool_log_colors[$tool]}$tool$reset $prefix"

    # Log stdout
    tee -a "${!file}" | sed "s/^/$prefix /"

    # Exit the program if specified
    if [[ -v exit_status ]]; then
        exit "${exit_status_codes[$exit_status]}"
    fi
}

contains() {
    if [[ $# -lt 2 ]]; then
        logfx log_level=ERROR exit_status=INVALID <<< "You must pass a value and an array to 'contains'"
    fi
    value="$1"
    array=("${@:1}")
    local is_contained=1

    for element in "${array[@]}"; do
        if [[ $element == "$value" ]]; then
            is_contained=0
            break
        fi
    done
    return "$is_contained"
}

readarray -t devices < <(nix flake show --json | jq '.nixosConfigurations | keys[]' -r)
devices_str="$(IFS="|"; echo "${devices[*]}")"
cmd="test"

usage="Usage: nixos
       -d|--device DEVICE     (Required) The device to deploy a nixos configuration for (options: ${devices_str})
       [-c|--cmd CMD]         The nixos-rebuild command to run on the device (default: $cmd)
       [--remote]             The device is a remote device
       [...]                  Extra arguments passed to nixos-rebuild
"

# Parse and validate arguments
if [[ $# -eq 0 ]]; then
    logfx exit_status=SUCCESS <<< "$usage"
fi
extra_args=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--device)
            device="$2"
            if ! contains "$device" "${devices[@]}"; then
                logfx log_level=ERROR exit_status=FAILURE <<< "$1 is not an available device among: ${devices_str}"
            fi
            shift 1
            ;;
        -c|--cmd)
            cmd="$2"
            shift 1
            ;;
        --remote)
            # We override the ControlPath because otherwise Nix will create too long of a Unix domain socket name
            # if the name of the device is more than 5 characters... This path is managed by nix and will be deleted
            # when the connection to the remote host ends when the program halts.
            export NIX_SSHOPTS="-o ControlPath=/tmp/%C"
            extra_args+=(--build-host "$device" --target-host "$device" --fast --use-remote-sudo)
            ;;
        *)
            extra_args+=("$1")
            ;;
    esac
    shift 1
done
if [[ -z $device ]]; then
    logfx log_level=ERROR exit_status=FAILURE <<< "No device specified. Options: ${devices_str}"
fi

\nixos-rebuild "$cmd" --flake ".#$device" "${extra_args[@]}"
