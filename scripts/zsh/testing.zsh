#!/usr/bin/env zsh
# testing.zsh - Creates a testing distribution of zlux.
# Mirrors the targets defined in testing.xml.
# Runs both deploy and build into a dist directory.
#
# Usage: testing.zsh [target]
# Targets: setup-dist (default), publishVersion
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v2.0 which accompanies this
# distribution, and is available at https://www.eclipse.org/legal/epl-v20.html
#
# SPDX-License-Identifier: EPL-2.0
#
# Copyright Contributors to the Zowe Project.

emulate -L zsh
setopt ERR_EXIT PIPE_FAIL

SCRIPT_DIR="${0:A:h}"
BUILD_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${SCRIPT_DIR}/common.zsh"

CAPSTONE="${CAPSTONE:-$(cd "${BUILD_DIR}/.." && pwd)}"
load_common_properties "$BUILD_DIR"
load_version_properties "$BUILD_DIR"

# sed pre-joins backslash-continuation lines so the while loop only
# ever sees complete key=value pairs.
if [[ -f "${BUILD_DIR}/core-plugins.properties" ]]; then
    while IFS='=' read -r key value; do
        [[ "$key" =~ ^[[:space:]]*'#' ]] && continue
        [[ -z "${key// }" ]] && continue
        key="${key//[[:space:]]/}"
        value="${value//[[:space:]]/}"
        export "$key"="$value"
    done < <(sed ':a; /\\$/{N; s/\\\n[[:space:]]*//; ta}' "${BUILD_DIR}/core-plugins.properties")
fi

VERSION_DATE="$(date +%Y%m%d)"
PRODUCT_MAJOR_VERSION="${PRODUCT_MAJOR_VERSION:-0}"
PRODUCT_MINOR_VERSION="${PRODUCT_MINOR_VERSION:-8}"
PRODUCT_REVISION="${PRODUCT_REVISION:-4}"
VERSION_STRING="${PRODUCT_MAJOR_VERSION}.${PRODUCT_MINOR_VERSION}.${PRODUCT_REVISION}+${VERSION_DATE}"
DIST_DIR="${CAPSTONE}/../dist"

setup_dist() {
    echo "==> setup-dist (testing): creating testing distribution in ${DIST_DIR} ..."

    rm -rf "$DIST_DIR"
    mkdir -p "$DIST_DIR"

    # Copy capstone contents into dist so that dist mirrors the capstone layout
    # (e.g. dist/zlux-build/, dist/zlux-app-server/, ...) and dist_build_dir resolves correctly.
    if is_zos || ! is_windows; then
        cp -pR "${CAPSTONE}/"*(.) "${DIST_DIR}/" 2>/dev/null || true
        cp -pR "${CAPSTONE}/"*(/) "${DIST_DIR}/" 2>/dev/null || true
    else
        cp -R "${CAPSTONE}/" "${DIST_DIR}/"
    fi

    if [[ -n "${CORE_PLUGINS:-}" ]]; then
        echo "$CORE_PLUGINS" | tr ',' '\n' | while IFS= read -r plugin_rel; do
            plugin_rel="${plugin_rel// /}"
            [[ -z "$plugin_rel" ]] && continue
            local target_file="${DIST_DIR}/${plugin_rel}"
            if [[ -f "$target_file" ]]; then
                echo "Replacing version token in ${target_file}"
                sed -i.bak \
                    "s/0\\.0\\.0-zlux\\.version\\.replacement/${VERSION_STRING}/g" \
                    "$target_file"
                rm -f "${target_file}.bak"
            fi
        done
    fi

    local dist_build_dir="${DIST_DIR}/zlux-build"

    # testing.xml runs deploy AND build (unlike production.xml which skips deploy).
    echo "==> Running deploy in ${dist_build_dir} ..."
    CAPSTONE="${DIST_DIR}" zsh "${dist_build_dir}/scripts/zsh/deploy.zsh"

    echo "==> Running build in ${dist_build_dir} ..."
    CAPSTONE="${DIST_DIR}" zsh "${dist_build_dir}/scripts/zsh/build_ng2.zsh" buildng2

    echo "setup-dist (testing) complete. Distribution is at ${DIST_DIR}"
}

publish_version() {
    if [[ -z "${VERSION_DATE:-}" ]]; then
        echo "ERROR: VERSION_DATE is not set." >&2
        exit 1
    fi
    echo "PRODUCT_FULL_VERSION=${VERSION_STRING}" > "${BUILD_DIR}/fullVersion.properties"
    echo "Published version: ${VERSION_STRING}"
}

TARGET="${1:-setup-dist}"

case "$TARGET" in
    setup-dist|setupDist) setup_dist      ;;
    publishVersion)       publish_version ;;
    *)
        echo "ERROR: Unknown target '${TARGET}'" >&2
        exit 1
        ;;
esac
