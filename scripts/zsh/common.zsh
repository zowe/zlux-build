#!/usr/bin/env zsh
# common.zsh - Shared utilities for zlux-build zsh scripts.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v2.0 which accompanies this
# distribution, and is available at https://www.eclipse.org/legal/epl-v20.html
#
# SPDX-License-Identifier: EPL-2.0
#
# Copyright Contributors to the Zowe Project.

emulate -L zsh
setopt ERR_EXIT PIPE_FAIL NO_UNSET

# Detect operating environment.
is_zos() {
    uname -s 2>/dev/null | grep -qi "os/390\|z/os"
}

is_windows() {
    case "$(uname -s 2>/dev/null)" in
        MINGW*|CYGWIN*|MSYS*) return 0 ;;
    esac
    return 1
}

# Resolve the directory of the currently-executing zsh script.
# Usage: SCRIPT_DIR=$(get_script_dir)
get_script_dir() {
    local script_path="${(%):-%x}"
    local dir
    dir="$(cd "$(dirname "$script_path")" && pwd)"
    echo "$dir"
}

# Load a .properties file, exporting each key=value pair as an environment variable.
load_properties() {
    local props_file="$1"
    if [[ -f "$props_file" ]]; then
        while IFS='=' read -r key value; do
            # Skip comments and blank lines.
            [[ "$key" =~ ^[[:space:]]*'#' ]] && continue
            [[ -z "${key// }" ]] && continue
            key="${key// /}"
            value="${value// /}"
            export "$key"="$value"
        done < "$props_file"
    fi
}

load_common_properties() {
    local build_dir="$1"
    load_properties "${build_dir}/common.properties"
}

load_version_properties() {
    local build_dir="$1"
    load_properties "${build_dir}/version.properties"
}

# Run npm install in a directory that contains a package.json.
# Uses 'npm ci' when a package-lock.json is present (faster, reproducible CI
# installs), falling back to 'npm install' when no lockfile exists.
# Usage: npm_install <directory>
npm_install() {
    local location="$1"

    if [[ ! -f "${location}/package.json" ]]; then
        echo "No package.json found in ${location}, skipping install."
        return 0
    fi

    local cmd
    if [[ -f "${location}/package-lock.json" ]]; then
        echo "Running npm ci in ${location} ..."
        cmd="npm ci"
    else
        echo "Running npm install in ${location} (no package-lock.json found) ..."
        cmd="npm install"
    fi
    (cd "$location" && eval "$cmd")
    local rc=$?
    echo "Result of install in ${location}: ${rc}"
    if (( rc != 0 )); then
        echo "ERROR: install failed in ${location}" >&2
        return 1
    fi
}

# Run an npm build script in a directory.
# Usage: npm_build <directory> <build-type>
npm_build() {
    local location="$1"
    local build_type="$2"

    if [[ ! -f "${location}/package.json" ]]; then
        echo "No package.json found in ${location}, skipping build."
        return 0
    fi

    echo "Running npm run ${build_type} in ${location} ..."
    (cd "$location" && MVD_DESKTOP_DIR="${MVD_DESKTOP_DIR:-}" npm run "$build_type")
    local rc=$?
    echo "Result of npm run ${build_type} in ${location}: ${rc}"
    if (( rc != 0 )); then
        echo "ERROR: npm run ${build_type} failed in ${location}" >&2
        return 1
    fi
}

# Run npm run compress in a directory.
# Usage: npm_run_compress <directory>
npm_run_compress() {
    local location="$1"

    if [[ ! -f "${location}/package.json" ]]; then
        echo "No package.json found in ${location}, skipping compress."
        return 0
    fi

    echo "Running npm run compress in ${location} ..."
    (cd "$location" && npm run compress)
    local rc=$?
    echo "Result of npm run compress in ${location}: ${rc}"
    if (( rc != 0 )); then
        echo "ERROR: npm run compress failed in ${location}" >&2
        return 1
    fi
}

# Parse pluginLocation and identifier from a plugin JSON file.
_parse_plugin_json() {
    local json_file="$1"
    local plugin_location=""
    local plugin_id=""

    if command -v jq >/dev/null 2>&1; then
        plugin_location=$(jq -r '.pluginLocation // empty' "$json_file" 2>/dev/null)
        plugin_id=$(jq -r '.identifier // empty' "$json_file" 2>/dev/null)
    else
        # Fallback: naive line-by-line parsing.
        local next_value="searching"
        while IFS= read -r line; do
            line="${line//\"/}"
            line="${line//,/}"
            line="${line// /}"
            case "$next_value" in
                predir)  next_value="dir" ;;
                dir)
                    plugin_location="$line"
                    next_value="searching"
                    ;;
                preid)   next_value="id" ;;
                id)
                    plugin_id="$line"
                    next_value="searching"
                    ;;
                searching)
                    case "$line" in
                        *pluginLocation*) next_value="predir" ;;
                        *identifier*)     next_value="preid"  ;;
                    esac
                    ;;
            esac
        done < "$json_file"
    fi

    echo "${plugin_location}:${plugin_id}"
}

# Traverse pluginDir and invoke a callback for each plugin found.
# Usage: traverse_plugins <plugin_dir> <callback_function>
traverse_plugins() {
    local plugin_dir="$1"
    local callback="$2"

    if [[ ! -d "$plugin_dir" ]]; then
        echo "WARNING: Plugin directory '${plugin_dir}' does not exist, skipping traversal." >&2
        return 0
    fi

    while IFS= read -r -d '' json_file; do
        local parsed
        parsed=$(_parse_plugin_json "$json_file")
        local plugin_location="${parsed%%:*}"
        local plugin_id="${parsed#*:}"

        if [[ -n "$plugin_location" ]]; then
            "$callback" "$plugin_location" "$plugin_id"
        fi
    done < <(find "$plugin_dir" -name "*.json" -print0)
}
