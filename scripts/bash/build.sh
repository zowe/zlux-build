#!/usr/bin/env bash
# build.sh - Main build entry point for zlux-build.
# Mirrors the targets defined in build.xml.
#
# Usage: build.sh [target]
# Targets: buildAll, production, testing, getVersion, deploy, audit,
#          cleanDeploy, devClean, build, bootstrapBuild, removeSource, help
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

# Source common utilities.
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

CAPSTONE="$(cd "${BUILD_DIR}/.." && pwd)"
load_common_properties "$BUILD_DIR"
load_version_properties "$BUILD_DIR"

# Ordered list of targets for the interactive menu.
TARGETS=(
    buildAll
    build
    bootstrapBuild
    deploy
    cleanDeploy
    devClean
    production
    testing
    getVersion
    audit
    removeSource
    help
)

TARGET_DESCRIPTIONS=(
    "Run deploy then build (default)"
    "Build all ng2/Angular components"
    "Build only server framework and bootstrap"
    "Deploy plugin definitions and server config"
    "Remove instance and site deploy directories"
    "Remove instance plugins and user/group data"
    "Build a production distribution into ../dist/"
    "Build a testing distribution (deploy + build) into ../dist/"
    "Write version string to fullVersion.properties"
    "Run npm audit on all plugins"
    "Remove source files not needed for production"
    "Show this help message"
)

show_help() {
    echo "Available targets:"
    local i
    for i in "${!TARGETS[@]}"; do
        printf "  %-18s %s\n" "${TARGETS[$i]}" "${TARGET_DESCRIPTIONS[$i]}"
    done
}

prompt_target() {
    echo ""
    echo "zlux-build — available targets:"
    echo "-----------------------------------"
    local i
    for i in "${!TARGETS[@]}"; do
        printf "  %2d) %-18s %s\n" "$(( i + 1 ))" "${TARGETS[$i]}" "${TARGET_DESCRIPTIONS[$i]}"
    done
    echo ""
    # Default to 1 (buildAll).
    local choice
    read -r -p "Enter target number or name [1 = buildAll]: " choice || true
    choice="${choice:-1}"

    # Accept a number.
    if [[ "$choice" =~ ^[0-9]+$ ]]; then
        local idx=$(( choice - 1 ))
        if (( idx >= 0 && idx < ${#TARGETS[@]} )); then
            echo "${TARGETS[$idx]}"
            return
        else
            echo "ERROR: Number '${choice}' is out of range." >&2
            exit 1
        fi
    fi

    # Accept a name.
    echo "$choice"
}

# If no argument was given and we are attached to a terminal, ask interactively.
# If stdin is not a tty (e.g. piped in CI), fall back to buildAll silently.
if [ $# -eq 0 ]; then
    if [ -t 0 ]; then
        TARGET=$(prompt_target)
    else
        TARGET="buildAll"
    fi
else
    TARGET="$1"
fi

case "$TARGET" in
    buildAll)
        echo "==> Running deploy ..."
        bash "${SCRIPT_DIR}/deploy.sh"
        echo "==> Running build ..."
        bash "${SCRIPT_DIR}/build_ng2.sh" buildng2
        ;;
    production)
        bash "${SCRIPT_DIR}/production.sh"
        ;;
    testing)
        bash "${SCRIPT_DIR}/testing.sh"
        ;;
    getVersion)
        bash "${SCRIPT_DIR}/production.sh" publishVersion
        ;;
    deploy)
        bash "${SCRIPT_DIR}/deploy.sh"
        ;;
    audit)
        bash "${SCRIPT_DIR}/audit.sh"
        ;;
    cleanDeploy)
        bash "${SCRIPT_DIR}/deploy.sh" cleanDeploy
        ;;
    devClean)
        bash "${SCRIPT_DIR}/deploy.sh" devClean
        ;;
    build)
        bash "${SCRIPT_DIR}/build_ng2.sh" buildng2
        ;;
    bootstrapBuild)
        bash "${SCRIPT_DIR}/build_ng2.sh" bootstrapBuild
        ;;
    removeSource)
        bash "${SCRIPT_DIR}/build_ng2.sh" removeSource
        ;;
    help|-h|--help)
        show_help
        ;;
    *)
        echo "ERROR: Unknown target '${TARGET}'" >&2
        show_help >&2
        exit 1
        ;;
esac
