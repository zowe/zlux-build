#!/usr/bin/env zsh
# build.zsh - Main build entry point for zlux-build.
# Mirrors the targets defined in build.xml.
#
# Usage: build.zsh [target]
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

emulate -L zsh
setopt ERR_EXIT PIPE_FAIL

SCRIPT_DIR="${0:A:h}"
BUILD_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${SCRIPT_DIR}/common.zsh"

CAPSTONE="${CAPSTONE:-$(cd "${BUILD_DIR}/.." && pwd)}"
load_common_properties "$BUILD_DIR"
load_version_properties "$BUILD_DIR"

typeset -a TARGETS TARGET_DESCRIPTIONS
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
    for i in {1..${#TARGETS}}; do
        printf "  %-18s %s\n" "${TARGETS[$i]}" "${TARGET_DESCRIPTIONS[$i]}"
    done
}

prompt_target() {
    echo ""
    echo "zlux-build — available targets:"
    echo "-----------------------------------"
    local i
    for i in {1..${#TARGETS}}; do
        printf "  %2d) %-18s %s\n" "$i" "${TARGETS[$i]}" "${TARGET_DESCRIPTIONS[$i]}"
    done
    echo ""
    local choice
    read "choice?Enter target number or name [1 = buildAll]: " || true
    choice="${choice:-1}"

    if [[ "$choice" =~ ^[0-9]+$ ]]; then
        if (( choice >= 1 && choice <= ${#TARGETS} )); then
            echo "${TARGETS[$choice]}"
            return
        else
            echo "ERROR: Number '${choice}' is out of range." >&2
            exit 1
        fi
    fi
    echo "$choice"
}

if [[ $# -eq 0 ]]; then
    if [[ -t 0 ]]; then
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
        zsh "${SCRIPT_DIR}/deploy.zsh"
        echo "==> Running build ..."
        zsh "${SCRIPT_DIR}/build_ng2.zsh" buildng2
        ;;
    production)
        zsh "${SCRIPT_DIR}/production.zsh"
        ;;
    testing)
        zsh "${SCRIPT_DIR}/testing.zsh"
        ;;
    getVersion)
        zsh "${SCRIPT_DIR}/production.zsh" publishVersion
        ;;
    deploy)
        zsh "${SCRIPT_DIR}/deploy.zsh"
        ;;
    audit)
        zsh "${SCRIPT_DIR}/audit.zsh"
        ;;
    cleanDeploy)
        zsh "${SCRIPT_DIR}/deploy.zsh" cleanDeploy
        ;;
    devClean)
        zsh "${SCRIPT_DIR}/deploy.zsh" devClean
        ;;
    build)
        zsh "${SCRIPT_DIR}/build_ng2.zsh" buildng2
        ;;
    bootstrapBuild)
        zsh "${SCRIPT_DIR}/build_ng2.zsh" bootstrapBuild
        ;;
    removeSource)
        zsh "${SCRIPT_DIR}/build_ng2.zsh" removeSource
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
