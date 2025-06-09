#!/bin/env bash

# Global Style Variables 
red='\033[0;31m'
yellow='\033[1;33m'
green='\033[0;32m'
blue='\033[0;34m'
cyan='\033[0;36m'
nc='\033[0m' # No Color
bold='\033[1m'

gen_separator() {
    local separator=${1:-'='}
    local _cols
    # Check if stdout is connected to a terminal
    if [ -t 1 ]; then
        _cols=$(stty size | cut -d' ' -f2)
    else
        # Fallback to a default width if not in a terminal
        _cols=80
    fi
    printf '%*s\n' "$_cols" '' | tr ' ' "${separator}"
}
pretty_echo() {
    local type=$1
    shift
    local message="$@"

    local label_width=12

    case "${type,,}" in
        "error")
            printf "${red}${bold}[ERROR]${nc}%-$((label_width-7))s%s\n" " " "${message}"
            ;;
        "warning")
            printf "${yellow}${bold}[WARNING]${nc}%-$((label_width-9))s%s\n" " " "${message}"
            ;;
        "info")
            printf "${blue}${bold}[INFO]${nc}%-$((label_width-6))s%s\n" " " "${message}"
            ;;
        "success")
            printf "${green}${bold}[SUCCESS]${nc}%-$((label_width-9))s%s\n" " " "${message}"
            ;;
        "debug")
            printf "${cyan}${bold}[DEBUG]${nc}%-$((label_width-7))s%s\n" " " "${message}"
            ;;
        "clean")
            printf "${message}\n"
            ;;
        *)
            printf "${red}${bold}[ERROR]${nc}%-$((label_width-7))s%s\n" " " "Unknown message type in pretty print: ${type}!"
            exit 1
            ;;
    esac
}

pretty_clean() {
    pretty_echo "clean" "$@"
}

pretty_info() {
    pretty_echo "info" "$@"
}

pretty_error() {
    pretty_echo "error" "$@"
}

pretty_warn() {
    pretty_echo "warning" "$@"
}

pretty_success() {
    pretty_echo "success" "$@"
}

pretty_debug() {
    pretty_echo "debug" "$@"
}
