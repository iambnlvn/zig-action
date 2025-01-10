#!/bin/bash

COLOR_ERROR='\033[0;31m'
COLOR_SUCCESS='\033[0;32m'
COLOR_WARN='\033[0;33m'
COLOR_CLEAR=$(tput sgr0)

# Utility functions for progress messages
printProgressSuccess() {
    echo -e "\r${COLOR_SUCCESS} ✔ ${1} ${COLOR_CLEAR}"
}

printProgessWarn() {
    echo -en "\r${COLOR_WARN} • ${1} ${COLOR_CLEAR}"
}

printProgressFailure() {
    echo -e "\r${COLOR_ERROR} ✕ ${1} ${COLOR_CLEAR}"
}
getAvailableVersions() {
    curl -sL https://ziglang.org/download/index.json | jq -cr 'keys[]' | sort -V
}
# if [[ $# -lt 2 ]]; then
#     printUsage
#     printProgressFailure "Error: Missing arguments"
#     exit 1
# fi

printUsage() {
    echo -e "\nUsage: install.sh [version] [flavour]"
    echo -e "\nAvailable Versions:\n"
    echo "${VERSIONS}" | tr " " "\n" | sed "s/^/\t/"
    echo -e "\nAvailable Flavours:\n"
    echo "${FLAVOURS}" | tr " " "\n" | sed "s/^/\t/"
    echo ""
}


VERSIONS=$(getAvailableVersions)
printUsage