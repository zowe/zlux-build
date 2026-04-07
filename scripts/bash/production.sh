#!/usr/bin/env bash
# production.sh - Creates a production distribution of zlux.
# Mirrors the targets defined in production.xml.
#
# Usage: production.sh [target]
# Targets: setup-dist (default), publishVersion
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
load_version_properties "$BUILD_DIR"

# Load core-plugins.properties.
if [ -f "${BUILD_DIR}/core-plugins.properties" ]; then
    while IFS='=' read -r key value; do
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${key// }" ]] && continue
        key="${key//[[:space:]]/}"
        # Strip trailing backslash-continuation from multi-line values.
        value="${value%\\}"
        value="${value// /}"
        export "$key"="${!key:-}${value}"
    done < "${BUILD_DIR}/core-plugins.properties"
fi

# Build version date (yyyyMMdd).
VERSION_DATE="$(date +%Y%m%d)"

PRODUCT_MAJOR_VERSION="${PRODUCT_MAJOR_VERSION:-0}"
PRODUCT_MINOR_VERSION="${PRODUCT_MINOR_VERSION:-8}"
PRODUCT_REVISION="${PRODUCT_REVISION:-4}"

VERSION_STRING="${PRODUCT_MAJOR_VERSION}.${PRODUCT_MINOR_VERSION}.${PRODUCT_REVISION}+${VERSION_DATE}"

DIST_DIR="${CAPSTONE}/../dist"

# -------------------------------------------------------------------------
# Target: setup-dist
# Copies all capstone sources to a dist directory, replaces version tokens,
# and runs the build (without deploy, unlike testing.xml).
# -------------------------------------------------------------------------
setup_dist() {
    echo "==> setup-dist: creating production distribution in ${DIST_DIR} ..."

    rm -rf "$DIST_DIR"
    mkdir -p "$DIST_DIR"

    # Copy everything from the capstone parent directory into dist.
    if is_zos || ! is_windows; then
        cp -pR "${CAPSTONE}/../"* "${DIST_DIR}/" 2>/dev/null || true
        # Also copy hidden entries (dotfiles) at the top level.
        cp -pR "${CAPSTONE}/../".[!.]* "${DIST_DIR}/" 2>/dev/null || true
    else
        cp -R "${CAPSTONE}/../" "${DIST_DIR}/"
    fi

    # Replace version placeholder tokens in CORE_PLUGINS files.
    if [ -n "${CORE_PLUGINS:-}" ]; then
        # CORE_PLUGINS is a comma-separated (possibly multi-line) list of
        # relative paths within the capstone directory.
        echo "$CORE_PLUGINS" | tr ',' '\n' | while IFS= read -r plugin_rel; do
            plugin_rel="${plugin_rel// /}"
            [ -z "$plugin_rel" ] && continue
            local target_file="${DIST_DIR}/${plugin_rel}"
            if [ -f "$target_file" ]; then
                echo "Replacing version token in ${target_file}"
                sed -i.bak \
                    "s/0\\.0\\.0-zlux\\.version\\.replacement/${VERSION_STRING}/g" \
                    "$target_file"
                rm -f "${target_file}.bak"
            fi
        done
    fi

    # Run the build (without deploy) from the dist copy.
    local dist_build_dir="${DIST_DIR}/zlux-build"
    echo "==> Running build in ${dist_build_dir} ..."
    CAPSTONE="${DIST_DIR}" bash "${dist_build_dir}/scripts/bash/build_ng2.sh" buildng2

    echo "==> Running removeSource in ${dist_build_dir} ..."
    CAPSTONE="${DIST_DIR}" bash "${dist_build_dir}/scripts/bash/build_ng2.sh" removeSource

    echo "setup-dist complete. Distribution is at ${DIST_DIR}"
}

# -------------------------------------------------------------------------
# Target: publishVersion
# Writes the full version string to fullVersion.properties.
# -------------------------------------------------------------------------
publish_version() {
    if [ -z "${VERSION_DATE:-}" ]; then
        echo "ERROR: VERSION_DATE is not set." >&2
        exit 1
    fi
    echo "PRODUCT_FULL_VERSION=${VERSION_STRING}" > "${BUILD_DIR}/fullVersion.properties"
    echo "Published version: ${VERSION_STRING}"
}

# -------------------------------------------------------------------------
# Dispatch
# -------------------------------------------------------------------------
TARGET="${1:-setup-dist}"

case "$TARGET" in
    setup-dist|setupDist) setup_dist      ;;
    publishVersion)       publish_version ;;
    *)
        echo "ERROR: Unknown target '${TARGET}'" >&2
        exit 1
        ;;
esac
