#!/usr/bin/env bash
# copy_node.sh - Copies node_modules from nodeServer to lib/node_modules.
# Mirrors the targets defined in copy_node.xml.
#
# Usage: copy_node.sh
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v2.0 which accompanies this
# distribution, and is available at https://www.eclipse.org/legal/epl-v20.html
#
# SPDX-License-Identifier: EPL-2.0
#
# Copyright Contributors to the Zowe Project.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

# The ant copy_node.xml uses ${user.dir} which is the working directory
# at the time ant is invoked. We mimic that by defaulting to the current
# working directory.
USER_DIR="${USER_DIR:-${PWD}}"

SOURCE_DIR="${USER_DIR}/../nodeServer/node_modules"
DEST_DIR="${USER_DIR}/../lib/node_modules"

echo "==> copynode: copying node_modules from ${SOURCE_DIR} to ${DEST_DIR} ..."

if [ ! -d "$SOURCE_DIR" ]; then
    echo "ERROR: Source directory '${SOURCE_DIR}' does not exist." >&2
    exit 1
fi

mkdir -p "$DEST_DIR"

if is_zos || ! is_windows; then
    cp -pR "${SOURCE_DIR}/"* "${DEST_DIR}/"
else
    cp -R "${SOURCE_DIR}/" "${DEST_DIR}/"
fi

echo "copynode complete."
