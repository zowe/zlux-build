#!/usr/bin/env zsh
# build_ng2.zsh - Builds Angular/ng2 components for zlux.
# Mirrors the targets defined in build_ng2.xml.
#
# Usage: build_ng2.zsh [target]
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

emulate -L zsh
setopt ERR_EXIT PIPE_FAIL

SCRIPT_DIR="${0:A:h}"
BUILD_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${SCRIPT_DIR}/common.zsh"

CAPSTONE="${CAPSTONE:-$(cd "${BUILD_DIR}/.." && pwd)}"
load_common_properties "$BUILD_DIR"
load_version_properties "$BUILD_DIR"

# Resolve the plugin directory.
if [[ "${plugins:-}" == ../* ]]; then
    PLUGIN_DIR="$(cd "${BUILD_DIR}/${plugins}" 2>/dev/null && pwd)" || \
        PLUGIN_DIR="${CAPSTONE}/zlux-app-server/defaults/plugins"
elif [[ -n "${plugins:-}" ]]; then
    PLUGIN_DIR="${plugins}"
else
    PLUGIN_DIR="${CAPSTONE}/zlux-app-server/defaults/plugins"
fi

NO_INSTALL="${NO_INSTALL:-}"

platform_build() {
    echo "==> platformBuild: installing zlux-platform dependencies ..."
    [[ -z "$NO_INSTALL" ]] && npm_install "${CAPSTONE}/zlux-platform"
}

bootstrap_build() {
    echo "==> bootstrapBuild: building bootstrap components ..."
    if [[ -z "$NO_INSTALL" ]]; then
        npm_install "${CAPSTONE}/zlux-server-framework"
        npm_install "${CAPSTONE}/zlux-app-server"
        npm_install "${CAPSTONE}/zlux-app-manager/bootstrap"
    fi
    npm_build "${CAPSTONE}/zlux-app-manager/bootstrap" "build"
    npm_build "${CAPSTONE}/zlux-server-framework" "build"
}

desktop_build() {
    echo "==> desktopBuild: building virtual-desktop ..."
    [[ -z "$NO_INSTALL" ]] && npm_install "${CAPSTONE}/zlux-app-manager/virtual-desktop"
    npm_build "${CAPSTONE}/zlux-app-manager/virtual-desktop" "build:externals"
    npm_build "${CAPSTONE}/zlux-app-manager/virtual-desktop" "build"
}

build_plugin() {
    local plugin_rel="$1"
    local plugin_id="${2:-}"
    local plugin_path="${CAPSTONE}/zlux-app-server/lib/${plugin_rel}"
    local build_script="${plugin_path}/build/build.zsh"
    local build_ran=false

    if [[ -f "$build_script" ]]; then
        echo "Running build target in ${plugin_path}/build for ${plugin_id}"
        (cd "${plugin_path}/build" && zsh build.zsh build) && build_ran=true || true
    fi

    local skip=false
    if [[ "$plugin_rel" == "../../zlux-app-manager/bootstrap" ]] || \
       [[ "$plugin_rel" == "../../zlux-app-manager/virtual-desktop" ]]; then
        skip=true
    fi

    if [[ "$skip" == "false" ]]; then
        if [[ -z "$NO_INSTALL" ]] && [[ "$build_ran" == "false" ]]; then
            npm_install "$plugin_path"
        fi
        npm_build "$plugin_path" "build"
    fi

    if [[ -d "$plugin_path" ]]; then
        for subfolder in "${plugin_path}"/*/; do
            [[ -d "$subfolder" ]] || continue
            [[ -z "$NO_INSTALL" ]] && npm_install "$subfolder"
            npm_build "$subfolder" "build"
        done
    fi
}

traverse_build() {
    _do_build_plugin() {
        build_plugin "$1" "$2"
    }
    traverse_plugins "$PLUGIN_DIR" _do_build_plugin
}

get_desktop_dir() {
    MVD_DESKTOP_DIR="$(dirname "${CAPSTONE}/zlux-app-manager/virtual-desktop/package.json")"
    export MVD_DESKTOP_DIR
    echo "MVD_DESKTOP_DIR is ${MVD_DESKTOP_DIR}"
    echo "Plugin directory is ${PLUGIN_DIR}"
}

build_ng2() {
    get_desktop_dir
    platform_build
    bootstrap_build
    desktop_build
    traverse_build

    npm_install "${CAPSTONE}/zlux-shared/src/logging"
    npm_build   "${CAPSTONE}/zlux-shared/src/logging" "build"
    npm_install "${CAPSTONE}/zlux-shared/src/obfuscator"
    npm_build   "${CAPSTONE}/zlux-shared/src/obfuscator" "build"

    npm_install "${CAPSTONE}/zlux-app-manager/system-apps/admin-notification-app/webClient"
    npm_build   "${CAPSTONE}/zlux-app-manager/system-apps/admin-notification-app/webClient" "build"

    npm_install "${CAPSTONE}/zlux-app-manager/system-apps/web-browser-app/webClient"
    npm_build   "${CAPSTONE}/zlux-app-manager/system-apps/web-browser-app/webClient" "build"
    npm_install "${CAPSTONE}/zlux-app-manager/system-apps/web-browser-app/nodeServer"
    npm_build   "${CAPSTONE}/zlux-app-manager/system-apps/web-browser-app/nodeServer" "build"

    npm_run_compress "${CAPSTONE}/zlux-app-manager/virtual-desktop"

    local require_src="${CAPSTONE}/zlux-app-manager/virtual-desktop/node_modules/requirejs/require.js"
    local require_dst="${CAPSTONE}/zlux-app-manager/virtual-desktop/web/require.js"

    if is_zos; then
        cp -p "$require_src" "$require_dst"
    else
        cp "$require_src" "$require_dst"
    fi
}

remove_source() {
    local capstone="${CAPSTONE}"
    echo "==> removeSource: removing development files from ${capstone} ..."

    local server_nm="${capstone}/zlux-app-server/node_modules"
    local framework_nm="${capstone}/zlux-server-framework/node_modules"

    find "$capstone" -mindepth 2 -name ".*" \
        -not -path "${server_nm}/*" -not -path "${framework_nm}/*" | \
        while read -r item; do rm -rf "$item"; done

    find "$capstone" -type d -name "node_modules" \
        -not -path "${server_nm}" -not -path "${server_nm}/*" \
        -not -path "${framework_nm}" -not -path "${framework_nm}/*" | \
        while read -r dir; do
            echo "Removing ${dir}"
            rm -rf "$dir"
        done

    find "$capstone" -type d -name "dco-signoffs" | \
        while read -r dir; do rm -rf "$dir"; done

    rm -rf "${capstone}/zlux-app-manager/system-apps/app-generator"

    # Remove top-level test directories (e.g. zlux-app-server/test).
    find "$capstone" -mindepth 2 -maxdepth 2 -type d -name "test" | \
        while read -r dir; do
            echo "Removing ${dir}"
            rm -rf "$dir"
        done

    # Remove top-level .ppf files.
    find "$capstone" -mindepth 2 -maxdepth 2 -name "*.ppf" -delete

    for dir_name in src dts nodeServer webClient; do
        find "$capstone" -type d -name "$dir_name" \
            -not -path "*/zssServer/*" \
            -not -path "${capstone}/zlux-app-manager/virtual-desktop/*" \
            -not -path "${capstone}/zlux-platform/interface/*" \
            -not -path "${server_nm}/*" -not -path "${framework_nm}/*" \
            -not -path "${capstone}/zlux-shared/*" | \
            while read -r dir; do
                echo "Removing ${dir}"
                rm -rf "$dir"
            done
    done

    find "$capstone" -name "sonar-project.properties" \
        -not -path "${server_nm}/*" -not -path "${framework_nm}/*" -delete

    find "$capstone" \( -name "*.ts" -o -name "tsconfig*.json" \
        -o -name "tslint.json" -o -name "webpack.config.js" \) \
        -not -path "${capstone}/zlux-app-server/*" \
        -not -path "${capstone}/zlux-build/*" \
        -not -path "*/node_modules/*" \
        -not -path "${capstone}/zlux-app-manager/virtual-desktop/*" \
        -not -path "${capstone}/zlux-platform/interface/*" \
        -not -path "${capstone}/zlux-shared/src/*" -delete

    # Remove test certificate files and cert-generation scripts.
    find "$capstone" \( -name "*.cer" -o -name "*.key" -o -name "*.p12" \) \
        -not -path "*/node_modules/*" -delete
    rm -f "${capstone}/zlux-app-server/defaults/serverConfig/generate_zlux_certificates.sh"
    rm -f "${capstone}/zlux-app-server/defaults/README.md"
}

remove_zss_source() {
    echo "==> removeZssSource: removing zssServer directories ..."
    find "${CAPSTONE}" -type d -name "zssServer" | \
        while read -r dir; do rm -rf "$dir"; done
}

TARGET="${1:-buildng2}"

case "$TARGET" in
    buildng2)        build_ng2          ;;
    bootstrapBuild)  bootstrap_build    ;;
    desktopBuild)    desktop_build      ;;
    platformBuild)   platform_build     ;;
    buildPlugin)     build_plugin "${2:-}" "${3:-}" ;;
    removeSource)    remove_source      ;;
    removeZssSource) remove_zss_source  ;;
    *)
        echo "ERROR: Unknown target '${TARGET}'" >&2
        exit 1
        ;;
esac
