#! /usr/bin/env bash

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
