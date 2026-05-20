#!/usr/bin/env bash
# audit.sh - Runs npm audit for all plugins to check for security violations.
# Mirrors the targets defined in audit.xml.
#
# Usage: audit.sh
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

CAPSTONE="${CAPSTONE:-$(cd "${BUILD_DIR}/.." && pwd)}"
load_common_properties "$BUILD_DIR"

ARTIFACTS_DIR="${BUILD_DIR}/artifacts/audit"

# Resolve plugin directory.
if [[ "${plugins:-}" == ../* ]]; then
    PLUGIN_DIR="$(cd "${BUILD_DIR}/${plugins}" 2>/dev/null && pwd)" || \
        PLUGIN_DIR="${CAPSTONE}/zlux-app-server/defaults/plugins"
elif [ -n "${plugins:-}" ]; then
    PLUGIN_DIR="${plugins}"
else
    PLUGIN_DIR="${CAPSTONE}/zlux-app-server/defaults/plugins"
fi

mkdir -p "$ARTIFACTS_DIR"

# -------------------------------------------------------------------------
# Generate an npm audit report for a single directory.
# -------------------------------------------------------------------------
generate_audit_report() {
    local location="$1"
    local plugin_id="$2"

    if [ ! -f "${location}/package.json" ]; then
        return 0
    fi

    local safe_id
    safe_id="$(echo "$plugin_id" | tr '/' '_' | tr ' ' '_')"
    local log_file="${ARTIFACTS_DIR}/${safe_id}_audit.log"

    echo "Running npm audit in ${location} -> ${log_file}"
    (cd "$location" && npm audit 2>&1) > "$log_file" || true
}

# -------------------------------------------------------------------------
# Audit target: run npm audit on each plugin and its subdirectories.
# -------------------------------------------------------------------------
do_audit() {
    _do_audit_plugin() {
        local plugin_location="$1"
        local plugin_id="$2"
        local plugin_path="${CAPSTONE}/zlux-app-server/lib/${plugin_location}"

        generate_audit_report "$plugin_path" "$plugin_id"

        if [ -d "$plugin_path" ]; then
            for subfolder in "${plugin_path}"/*/; do
                [ -d "$subfolder" ] || continue
                local sub_id
                sub_id="${plugin_id}_$(basename "$subfolder")"
                generate_audit_report "$subfolder" "$sub_id"
            done
        fi
    }

    traverse_plugins "$PLUGIN_DIR" _do_audit_plugin
}

echo "==> Running audit for all plugins. Reports will be written to ${ARTIFACTS_DIR}"
do_audit
echo "Audit complete."
