#!/usr/bin/env zsh
# deploy.zsh - Deploy ZLUX with plugins defined in the plugin directory.
# Mirrors the targets defined in deploy.xml.
#
# Usage: deploy.zsh [target]
# Targets: deploy (default), cleanDeploy, devClean
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

ZLUX_APP_SERVER="${CAPSTONE}/zlux-app-server"
HOME_DIR="${ZLUX_APP_SERVER}"

if [[ "${plugins:-}" == ../* ]]; then
    PLUGIN_DIR="$(cd "${BUILD_DIR}/${plugins}" 2>/dev/null && pwd)" || \
        PLUGIN_DIR="${CAPSTONE}/zlux-app-server/defaults/plugins"
elif [[ -n "${plugins:-}" ]]; then
    PLUGIN_DIR="${plugins}"
else
    PLUGIN_DIR="${CAPSTONE}/zlux-app-server/defaults/plugins"
fi

if [[ -n "${INSTANCE_DIR:-}" ]]; then
    INSTANCE_DIR_RESOLVED="${INSTANCE_DIR}/workspace/app-server"
    SITE_DIR="${INSTANCE_DIR}/workspace/app-server/site"
    SERVER_CONFIG="${INSTANCE_DIR_RESOLVED}/serverConfig"
    INSTANCE_PLUGINS="${INSTANCE_DIR_RESOLVED}/plugins"
else
    INSTANCE_DIR_RESOLVED="${ZLUX_APP_SERVER}/deploy/instance"
    SITE_DIR="${ZLUX_APP_SERVER}/deploy/site"
    SERVER_CONFIG="${INSTANCE_DIR_RESOLVED}/ZLUX/serverConfig"
    INSTANCE_PLUGINS="${INSTANCE_DIR_RESOLVED}/ZLUX/plugins"
fi

do_deploy() {
    echo "==> Deploying ZLUX ..."

    mkdir -p "${HOME_DIR}/defaults/ZLUX/pluginStorage/org.zowe.zlux.ng2desktop/actions"
    mkdir -p "${HOME_DIR}/defaults/ZLUX/pluginStorage/org.zowe.zlux.ng2desktop/recognizers"
    mkdir -p "${HOME_DIR}/defaults/ZLUX/pluginStorage/org.zowe.zlux.ivydesktop/actions"
    mkdir -p "${HOME_DIR}/defaults/ZLUX/pluginStorage/org.zowe.zlux.ivydesktop/recognizers"

    mkdir -p "${SITE_DIR}/ZLUX/pluginStorage/org.zowe.zlux.ng2desktop/actions"
    mkdir -p "${SITE_DIR}/ZLUX/pluginStorage/org.zowe.zlux.ng2desktop/recognizers"
    mkdir -p "${SITE_DIR}/ZLUX/pluginStorage/org.zowe.zlux.ivydesktop/actions"
    mkdir -p "${SITE_DIR}/ZLUX/pluginStorage/org.zowe.zlux.ivydesktop/recognizers"

    mkdir -p "${INSTANCE_PLUGINS}"
    mkdir -p "${SERVER_CONFIG}"
    mkdir -p "${INSTANCE_DIR_RESOLVED}/ZLUX/pluginStorage/org.zowe.zlux.ng2desktop/actions"
    mkdir -p "${INSTANCE_DIR_RESOLVED}/ZLUX/pluginStorage/org.zowe.zlux.ng2desktop/recognizers"
    mkdir -p "${INSTANCE_DIR_RESOLVED}/ZLUX/pluginStorage/org.zowe.zlux.ivydesktop/actions"
    mkdir -p "${INSTANCE_DIR_RESOLVED}/ZLUX/pluginStorage/org.zowe.zlux.ivydesktop/recognizers"
    mkdir -p "${INSTANCE_DIR_RESOLVED}/users"
    mkdir -p "${INSTANCE_DIR_RESOLVED}/groups"

    if is_zos; then
        cp -pR "${PLUGIN_DIR}"/*.json "${INSTANCE_PLUGINS}/" 2>/dev/null || true
    else
        find "${PLUGIN_DIR}" -maxdepth 1 -name "*.json" -exec cp {} "${INSTANCE_PLUGINS}/" \;
    fi

    local server_defaults="${HOME_DIR}/defaults/serverConfig"
    local cert_files=(zlux.keystore.cer zlux.keystore.key apiml-localca.cer tomcat.xml)
    for cert_file in "${cert_files[@]}"; do
        if [[ -f "${server_defaults}/${cert_file}" ]]; then
            if is_zos; then
                cp -pR "${server_defaults}/${cert_file}" "${SERVER_CONFIG}/"
            else
                cp "${server_defaults}/${cert_file}" "${SERVER_CONFIG}/" 2>/dev/null || true
            fi
        fi
    done

    _do_deploy_plugin() {
        local plugin_location="$1"
        local plugin_id="$2"
        local plugin_build="${CAPSTONE}/zlux-app-server/lib/${plugin_location}/build"
        if [[ -f "${plugin_build}/build.zsh" ]]; then
            echo "Running deploy in ${plugin_build} for ${plugin_id}"
            (cd "$plugin_build" && zsh build.zsh deploy) || true
        fi
    }
    traverse_plugins "$PLUGIN_DIR" _do_deploy_plugin

    if is_zos && [[ -f "${CAPSTONE}/../zss/bin/zssServer" ]]; then
        cp -pR "${CAPSTONE}/../zss/bin/zssServer" "${HOME_DIR}/bin/zssServer"
    fi

    if ! is_windows; then
        chmod 750 "${SERVER_CONFIG}"
        find "${SERVER_CONFIG}" -maxdepth 1 -type f -exec chmod 640 {} \;
    fi

    echo "Deploy complete."
}

clean_deploy() {
    echo "==> Cleaning deploy directories ..."
    rm -rf "${INSTANCE_DIR_RESOLVED}" 2>/dev/null || true
    rm -rf "${SITE_DIR}" 2>/dev/null || true
    echo "cleanDeploy complete."
}

dev_clean() {
    echo "==> Running devClean ..."
    rm -rf "${INSTANCE_PLUGINS}" 2>/dev/null || true
    find "${INSTANCE_DIR_RESOLVED}" -mindepth 1 \
        \( -path "*/users/*" -o -path "*/groups/*" \) -delete 2>/dev/null || true
    echo "devClean complete."
}

TARGET="${1:-deploy}"

case "$TARGET" in
    deploy)      do_deploy   ;;
    cleanDeploy) clean_deploy ;;
    devClean)    dev_clean   ;;
    *)
        echo "ERROR: Unknown target '${TARGET}'" >&2
        exit 1
        ;;
esac
