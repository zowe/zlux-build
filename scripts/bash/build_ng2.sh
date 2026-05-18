#!/usr/bin/env bash
# build_ng2.sh - Builds Angular/ng2 components for zlux.
# Mirrors the targets defined in build_ng2.xml.
#
# Usage: build_ng2.sh [target]
# Targets: buildng2 (default), bootstrapBuild, desktopBuild, platformBuild,
#          buildPlugin, removeSource, removeZssSource
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

PLUGIN_DIR="${PLUGIN_DIR:-${CAPSTONE}/$(echo "${plugins:-../zlux-app-server/defaults/plugins}" | sed 's|^\.\./||')}"
# Resolve the pluginDir relative to BUILD_DIR if it's a relative path.
if [[ "${plugins:-}" == ../* ]]; then
    PLUGIN_DIR="$(cd "${BUILD_DIR}/${plugins}" 2>/dev/null && pwd)" || \
        PLUGIN_DIR="${CAPSTONE}/zlux-app-server/defaults/plugins"
elif [ -n "${plugins:-}" ]; then
    PLUGIN_DIR="${plugins}"
else
    PLUGIN_DIR="${CAPSTONE}/zlux-app-server/defaults/plugins"
fi

NO_INSTALL="${NO_INSTALL:-}"

# -------------------------------------------------------------------------
# Target: platformBuild
# Installs dependencies for zlux-platform.
# -------------------------------------------------------------------------
platform_build() {
    echo "==> platformBuild: installing zlux-platform dependencies ..."
    if [ -z "$NO_INSTALL" ]; then
        npm_install "${CAPSTONE}/zlux-platform"
    fi
}

# -------------------------------------------------------------------------
# Target: bootstrapBuild
# Installs and builds the server framework, app-server, and bootstrap.
# -------------------------------------------------------------------------
bootstrap_build() {
    echo "==> bootstrapBuild: building bootstrap components ..."

    if [ -z "$NO_INSTALL" ]; then
        npm_install "${CAPSTONE}/zlux-server-framework"
        npm_install "${CAPSTONE}/zlux-app-server"
        npm_install "${CAPSTONE}/zlux-app-manager/bootstrap"
    fi

    npm_build "${CAPSTONE}/zlux-app-manager/bootstrap" "build"
    npm_build "${CAPSTONE}/zlux-server-framework" "build"
}

# -------------------------------------------------------------------------
# Target: desktopBuild
# Installs and builds the virtual-desktop.
# -------------------------------------------------------------------------
desktop_build() {
    echo "==> desktopBuild: building virtual-desktop ..."

    if [ -z "$NO_INSTALL" ]; then
        npm_install "${CAPSTONE}/zlux-app-manager/virtual-desktop"
    fi

    npm_build "${CAPSTONE}/zlux-app-manager/virtual-desktop" "build:externals"
    npm_build "${CAPSTONE}/zlux-app-manager/virtual-desktop" "build"
}

# -------------------------------------------------------------------------
# Target: buildPlugin
# Installs and builds a single plugin and its subdirectories.
# plugin_rel is the relative path under zlux-app-server/lib/.
# -------------------------------------------------------------------------
build_plugin() {
    local plugin_rel="$1"
    local plugin_id="${2:-}"
    local capstone="${CAPSTONE}"

    local plugin_path="${capstone}/zlux-app-server/lib/${plugin_rel}"

    # Run a local build script if present (equivalent of antPlugin).
    local build_script="${plugin_path}/build/build.sh"
    local build_ran=false
    if [ -f "$build_script" ]; then
        echo "Running build target in ${plugin_path}/build for ${plugin_id}"
        (cd "${plugin_path}/build" && bash build.sh build) && build_ran=true || true
    fi

    # Skip the top-level app-manager bootstrap and virtual-desktop since they
    # are handled separately.
    local skip=false
    if [ "$plugin_rel" = "../../zlux-app-manager/bootstrap" ] || \
       [ "$plugin_rel" = "../../zlux-app-manager/virtual-desktop" ]; then
        skip=true
    fi

    if [ "$skip" = "false" ]; then
        if [ -z "$NO_INSTALL" ] && [ "$build_ran" = "false" ]; then
            npm_install "$plugin_path"
        fi
        npm_build "$plugin_path" "build"
    fi

    # Build each subfolder of the plugin.
    if [ -d "$plugin_path" ]; then
        for subfolder in "${plugin_path}"/*/; do
            [ -d "$subfolder" ] || continue
            if [ -z "$NO_INSTALL" ]; then
                npm_install "$subfolder"
            fi
            npm_build "$subfolder" "build"
        done
    fi
}

# -------------------------------------------------------------------------
# Target: traverse (buildPlugin for each plugin in pluginDir)
# -------------------------------------------------------------------------
traverse_build() {
    local plugin_dir="${PLUGIN_DIR}"

    _do_build_plugin() {
        local plugin_location="$1"
        local plugin_id="$2"
        build_plugin "$plugin_location" "$plugin_id"
    }

    traverse_plugins "$plugin_dir" _do_build_plugin
}

# -------------------------------------------------------------------------
# Target: getDesktopDir
# Sets MVD_DESKTOP_DIR to the virtual-desktop package.json directory.
# -------------------------------------------------------------------------
get_desktop_dir() {
    MVD_DESKTOP_DIR="$(dirname "${CAPSTONE}/zlux-app-manager/virtual-desktop/package.json")"
    export MVD_DESKTOP_DIR
    echo "MVD_DESKTOP_DIR is ${MVD_DESKTOP_DIR}"
    echo "Plugin directory is ${PLUGIN_DIR}"
}

# -------------------------------------------------------------------------
# Target: buildng2 (default)
# Full Angular build: platform, bootstrap, desktop, plugins, shared modules.
# -------------------------------------------------------------------------
build_ng2() {
    get_desktop_dir
    platform_build
    bootstrap_build
    desktop_build
    traverse_build

    # Build shared logging and obfuscator modules.
    npm_install "${CAPSTONE}/zlux-shared/src/logging"
    npm_build   "${CAPSTONE}/zlux-shared/src/logging" "build"

    npm_install "${CAPSTONE}/zlux-shared/src/obfuscator"
    npm_build   "${CAPSTONE}/zlux-shared/src/obfuscator" "build"

    # Build system apps.
    npm_install "${CAPSTONE}/zlux-app-manager/system-apps/admin-notification-app/webClient"
    npm_build   "${CAPSTONE}/zlux-app-manager/system-apps/admin-notification-app/webClient" "build"

    npm_install "${CAPSTONE}/zlux-app-manager/system-apps/web-browser-app/webClient"
    npm_build   "${CAPSTONE}/zlux-app-manager/system-apps/web-browser-app/webClient" "build"

    npm_install "${CAPSTONE}/zlux-app-manager/system-apps/web-browser-app/nodeServer"
    npm_build   "${CAPSTONE}/zlux-app-manager/system-apps/web-browser-app/nodeServer" "build"

    # Compress the virtual-desktop (Unix only).
    npm_run_compress "${CAPSTONE}/zlux-app-manager/virtual-desktop"

    # Copy require.js to the web output directory.
    local require_src="${CAPSTONE}/zlux-app-manager/virtual-desktop/node_modules/requirejs/require.js"
    local require_dst="${CAPSTONE}/zlux-app-manager/virtual-desktop/web/require.js"

    if is_zos; then
        cp -p "$require_src" "$require_dst"
    else
        cp "$require_src" "$require_dst"
    fi
}

# -------------------------------------------------------------------------
# Target: removeSource
# Removes source files not needed for production deployment.
# -------------------------------------------------------------------------
remove_source() {
    local capstone="${CAPSTONE}"
    echo "==> removeSource: removing development files from ${capstone} ..."

    # Excludes that must be preserved.
    local server_nm="${capstone}/zlux-app-server/node_modules"
    local framework_nm="${capstone}/zlux-server-framework/node_modules"

    # Remove hidden directories and files (e.g. .git, .github, .gitignore, etc.)
    find "$capstone" -mindepth 2 \( -name ".*" \) -not -path "${server_nm}/*" \
        -not -path "${framework_nm}/*" | while read -r item; do
        rm -rf "$item"
    done

    # Remove node_modules directories (except in app-server and server-framework).
    find "$capstone" -type d -name "node_modules" \
        -not -path "${server_nm}" \
        -not -path "${server_nm}/*" \
        -not -path "${framework_nm}" \
        -not -path "${framework_nm}/*" | while read -r dir; do
        echo "Removing ${dir}"
        rm -rf "$dir"
    done

    # Remove dco-signoffs directories.
    find "$capstone" -type d -name "dco-signoffs" | while read -r dir; do
        rm -rf "$dir"
    done

    # Remove app-generator directory.
    rm -rf "${capstone}/zlux-app-manager/system-apps/app-generator"

    # Remove src, dts, nodeServer, webClient directories (with exclusions).
    for dir_name in src dts nodeServer webClient; do
        find "$capstone" -type d -name "$dir_name" \
            -not -path "*/zssServer/*" \
            -not -path "${capstone}/zlux-app-manager/virtual-desktop/*" \
            -not -path "${capstone}/zlux-platform/interface/*" \
            -not -path "${server_nm}/*" \
            -not -path "${framework_nm}/*" \
            -not -path "${capstone}/zlux-shared/*" | while read -r dir; do
            echo "Removing ${dir}"
            rm -rf "$dir"
        done
    done

    # Remove sonar-project.properties files.
    find "$capstone" -name "sonar-project.properties" \
        -not -path "${server_nm}/*" \
        -not -path "${framework_nm}/*" -delete

    # Remove TypeScript sources and config files (with exclusions).
    find "$capstone" \( -name "*.ts" -o -name "tsconfig*.json" \
        -o -name "tslint.json" -o -name "webpack.config.js" \) \
        -not -path "${capstone}/zlux-app-server/*" \
        -not -path "${capstone}/zlux-build/*" \
        -not -path "*/node_modules/*" \
        -not -path "${capstone}/zlux-app-manager/virtual-desktop/*" \
        -not -path "${capstone}/zlux-platform/interface/*" \
        -not -path "${capstone}/zlux-shared/src/*" -delete
}

# -------------------------------------------------------------------------
# Target: removeZssSource
# Removes zssServer source directories.
# -------------------------------------------------------------------------
remove_zss_source() {
    local capstone="${CAPSTONE}"
    echo "==> removeZssSource: removing zssServer directories from ${capstone} ..."
    find "$capstone" -type d -name "zssServer" | while read -r dir; do
        rm -rf "$dir"
    done
}

# -------------------------------------------------------------------------
# Dispatch
# -------------------------------------------------------------------------
TARGET="${1:-buildng2}"

case "$TARGET" in
    buildng2)       build_ng2         ;;
    bootstrapBuild) bootstrap_build   ;;
    desktopBuild)   desktop_build     ;;
    platformBuild)  platform_build    ;;
    buildPlugin)
        build_plugin "${2:-}" "${3:-}"
        ;;
    removeSource)   remove_source     ;;
    removeZssSource) remove_zss_source ;;
    *)
        echo "ERROR: Unknown target '${TARGET}'" >&2
        exit 1
        ;;
esac
