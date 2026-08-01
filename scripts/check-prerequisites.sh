#!/usr/bin/env bash

set -euo pipefail
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source "$script_dir/lib/common.sh"

required=(git jq cmake ninja python3 make xcrun xcodebuild md5 shasum)
missing=()

for command_name in "${required[@]}"; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        missing+=("$command_name")
    fi
done

if ((${#missing[@]})); then
    printf 'Missing required host commands:' >&2
    printf ' %s' "${missing[@]}" >&2
    printf '\n' >&2
    exit 1
fi

printf 'git: %s\n' "$(git --version)"
printf 'cmake: %s\n' "$(cmake --version | sed -n '1p')"
printf 'ninja: %s\n' "$(ninja --version)"
printf 'python: %s\n' "$(python3 --version)"
printf 'xcode: %s\n' "$(xcodebuild -version | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
printf 'macOS SDK: %s\n' "$(xcrun --sdk macosx --show-sdk-version)"
printf 'iPhoneOS SDK: %s\n' "$(xcrun --sdk iphoneos --show-sdk-version)"
printf 'iPhoneSimulator SDK: %s\n' "$(xcrun --sdk iphonesimulator --show-sdk-version)"

if command -v mips-linux-gnu-ld >/dev/null 2>&1; then
    printf 'MIPS linker: %s\n' "$(command -v mips-linux-gnu-ld)"
elif command -v mips64-elf-ld >/dev/null 2>&1; then
    printf 'MIPS linker: %s\n' "$(command -v mips64-elf-ld)"
else
    printf 'MIPS linker: missing (required for the pret disassembly build)\n' >&2
    exit 2
fi

note "Host prerequisite check passed."
