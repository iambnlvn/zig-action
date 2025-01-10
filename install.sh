#!/bin/bash

# Define colors for output
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

# Available flavors
FLAVOURS="x86_64-linux x86_64-windows aarch64-linux x86-linux aarch64-windows x86-windows x86_64-macos aarch64-macos riscv64-linux powerpc64le-linux powerpc-linux bootstrap src"

# Display script usage
printUsage() {
    echo -e "\nUsage: install.sh [version] [flavour]"
    echo -e "\nAvailable Versions:\n"
    echo "${VERSIONS}" | tr " " "\n" | sed "s/^/\t/"
    echo -e "\nAvailable Flavours:\n"
    echo "${FLAVOURS}" | tr " " "\n" | sed "s/^/\t/"
    echo ""
}

# Check if an item exists in a space-separated list
hasItem() {
    local items="$1"
    local item="$2"
    for x in ${items}; do
        if [[ "${x}" == "${item}" ]]; then
            return 0
        fi
    done
    return 1 # Item not found
}


# Fetch Zig data
fetchZigData() {
    local url="https://ziglang.org/download/index.json"
    local retries=5
    local waitTime=2
    local logFile="fetch_errors.log"

    # Overwrite the log file if it exists
    > "$logFile"
    for ((i=1; i<=retries; i++)); do
        response=$(curl -sL "$url" 2>>"$logFile")
        if [[ $? -eq 0 && -n "$response" ]]; then
            echo "$response"
            return 0
        fi
        echo "Attempt $i failed. Retrying in $waitTime seconds..." | tee -a "$logFile"
        sleep $waitTime
    done

    echo "Failed to fetch Zig data after $retries attempts. Check $logFile for details."
    return 1
}

# Get available versions
getAvailableVersions() {
    echo "$zigData" | jq -cr 'keys[]' | sort -V
}

# Get flavor information 
getFlavour() {
    local version="$1"
    local flavour="$2"

    echo "$zigData" | jq -cr --arg version "${version}" --arg flavour "${flavour}" \
        '.[$version][$flavour]'
}

zigData=$(fetchZigData)
# Check if necessary commands are available
checkDeps() {
    if ! command -v curl &> /dev/null || ! command -v jq &> /dev/null || ! command -v sha256sum &> /dev/null; then
        echo "Missing dependencies detected. You need sudo privileges to install them"
        sudo -v
        if [[ $? -ne 0 ]]; then
            printProgressFailure "Error: Sudo privileges are required to install missing dependencies.\n"
            exit 1
        fi

        case "$(uname -s)" in
            Linux)
                if [[ -f /etc/os-release ]]; then
                    . /etc/os-release
                    case "$ID" in
                        ubuntu|debian)
                            sudo apt-get update
                            sudo apt-get install -y curl jq coreutils
                            ;;
                        fedora|centos|rhel)
                            sudo yum install -y curl jq coreutils
                            ;;
                        arch)
                            sudo pacman -Sy --noconfirm curl jq coreutils
                            ;;
                        *)
                            printProgressFailure "Error: Unsupported Linux distribution"
                            exit 1
                            ;;
                    esac
                fi
                ;;
            Darwin)
                brew install curl jq coreutils
                ;;
        esac
    fi
}

VERSIONS=$(getAvailableVersions)

# Start of the script
if command -v zig &> /dev/null; then
    printProgressSuccess "Zig is already installed. Skipping installation."
    exit 0
fi
if [[ $# -lt 2 ]]; then
    printUsage
    printProgressFailure "Error: Missing arguments"
    exit 1
fi

checkDeps

version="$1"
flavour="$2"

if ! hasItem "${VERSIONS}" "${version}"; then
    printUsage
    printProgressFailure "Error: Invalid version '${version}'"
    exit 1
fi

if ! hasItem "${FLAVOURS}" "${flavour}"; then
    printUsage
    printProgressFailure "Error: Invalid flavour '${flavour}'"
    exit 1
fi

printProgessWarn "Downloading flavour information for version '${version}' and flavour '${flavour}' ..."
res=$(getFlavour "${version}" "${flavour}")

if [[ -z "${res}" || "${res}" == "null" ]]; then
    printProgressFailure "Error: Failed to fetch download information for version '${version}' and flavour '${flavour}'"
    exit 1
fi

tarball=$(echo "${res}" | jq -cr '.tarball')
shasum=$(echo "${res}" | jq -cr '.shasum')
filename="${tarball##*/}"

if [[ -f "${filename}" ]]; then
    printProgessWarn "File '${filename}' already exists. Skipping download."
else
    printProgessWarn "Downloading tarball '${filename}'"
    curl -OL --progress-bar "${tarball}" || {
        printProgressFailure "Error: Failed to download tarball '${filename}'"
        exit 1
    }
    printProgressSuccess "Downloaded tarball '${filename}'"
fi

printProgessWarn "Verifying checksum"
fileChecksum=$(sha256sum "${filename}" | cut -d ' ' -f1)
if [[ "${shasum}" != "${fileChecksum}" ]]; then
    printProgressFailure "Error: Checksum mismatch for '${filename}'"
    exit 1
fi
printProgressSuccess "Checksum verified"

printProgessWarn "Installing Zig from '${filename}'"
tar -xf "${filename}" 2>> install_errors.log || {
    printProgressFailure "Error: Failed to extract tarball '${filename}' (see install_errors.log for details)"
    exit 1
}
printProgessWarn "Cleaning up"
if ! rm -f "${filename}"; then
    printProgressFailure "Error: Failed to remove tarball '${filename}'"
    exit 1
fi

filedir="${filename%.tar.xz}"
mkdir -p "${PWD}/bin"
ln -frs "${filedir}/zig" "${PWD}/bin/zig" || {
    printProgressFailure "Error: Failed to create symlink for Zig binary"
    exit 1
}
printProgressSuccess "Zig installed successfully"

printProgessWarn "Configuring Zig executable"
export PATH="${PWD}/bin:${PATH}"
if [[ -n "${GITHUB_PATH}" ]]; then
    echo "${PWD}/bin" >> "${GITHUB_PATH}"
fi
printProgressSuccess "Zig executable configured"

printProgressSuccess "Installation complete"
