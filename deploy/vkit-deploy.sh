#!/usr/bin/env bash

if [[ "$OSTYPE" == "darwin"* ]]; then
    SHELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
else
    SHELL_DIR="$(cd "$(dirname "${BASH_SOURCE:-$0}")" && pwd)"
fi

echo -e "\nDeploy...\n"

if [ -z "$VKIT_PLATFORM" ] || [ -z "$VKIT_PREBUILT_DIR" ]; then
    echo -e "Error: Unknown platform!\n"
    exit 1
fi

mkdir -p "$VKIT_PREBUILT_DIR"

. "$SHELL_DIR/functions/do_copy.sh"
. "$SHELL_DIR/functions/do_fileset.sh"
. "$SHELL_DIR/functions/do_packup.sh"

do_copy
do_fileset
do_packup

echo -e "\nDone.\n"
