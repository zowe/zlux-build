# common.ps1 - Shared utilities for zlux-build PowerShell scripts.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v2.0 which accompanies this
# distribution, and is available at https://www.eclipse.org/legal/epl-v20.html
#
# SPDX-License-Identifier: EPL-2.0
#
# Copyright Contributors to the Zowe Project.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Load a .properties file and return a hashtable of key/value pairs.
function Import-PropertiesFile {
    param([string]$PropertiesPath)
    $result = @{}
    if (Test-Path $PropertiesPath) {
        # Pre-join backslash-continuation lines before parsing key=value pairs.
        $joinedLines = [System.Collections.Generic.List[string]]::new()
        $accumulator = $null
        foreach ($rawLine in (Get-Content $PropertiesPath)) {
            if ($rawLine -match '\\$') {
                $segment = $rawLine -replace '\\$', ''
                if ($null -eq $accumulator) {
                    $accumulator = $segment
                } else {
                    $accumulator += $segment.TrimStart()
                }
            } else {
                if ($null -ne $accumulator) {
                    $joinedLines.Add($accumulator + $rawLine.TrimStart())
                    $accumulator = $null
                } else {
                    $joinedLines.Add($rawLine)
                }
            }
        }
        if ($null -ne $accumulator) { $joinedLines.Add($accumulator) }

        foreach ($line in $joinedLines) {
            $line = $line.Trim()
            if ($line -match '^\s*#' -or [string]::IsNullOrWhiteSpace($line)) { continue }
            $parts = $line -split '=', 2
            if ($parts.Length -eq 2) {
                $key   = $parts[0].Trim()
                $value = $parts[1].Trim()
                $result[$key] = $value
            }
        }
    }
    return $result
}

# Run npm install in a directory that contains a package.json.
# Uses 'npm ci' when a package-lock.json is present (faster, reproducible CI
# installs), falling back to 'npm install' when no lockfile exists.
# Parameters:
#   Location        - Directory path.
#   LegacyPeerDeps  - When $true, passes --legacy-peer-deps (install fallback only).
function Invoke-NpmInstall {
    param(
        [string]$Location,
        [switch]$LegacyPeerDeps
    )
    if (-not (Test-Path (Join-Path $Location "package.json"))) {
        Write-Host "No package.json found in ${Location}, skipping install."
        return
    }
    Push-Location $Location
    try {
        if (Test-Path (Join-Path $Location "package-lock.json")) {
            Write-Host "Running npm ci in ${Location} ..."
            & npm ci
        } elseif ($LegacyPeerDeps) {
            Write-Host "Running npm install --legacy-peer-deps in ${Location} (no package-lock.json found) ..."
            & npm install --legacy-peer-deps
        } else {
            Write-Host "Running npm install in ${Location} (no package-lock.json found) ..."
            & npm install
        }
        if ($LASTEXITCODE -ne 0) {
            throw "install failed in ${Location} with exit code ${LASTEXITCODE}"
        }
    } finally {
        Pop-Location
    }
    Write-Host "Install completed in ${Location}."
}

# Run an npm build script inside a directory.
# Parameters:
#   Location  - Directory path.
#   BuildType - The npm script name to run (e.g. "build", "build:externals").
function Invoke-NpmBuild {
    param(
        [string]$Location,
        [string]$BuildType
    )
    if (-not (Test-Path (Join-Path $Location "package.json"))) {
        Write-Host "No package.json found in ${Location}, skipping build."
        return
    }
    Write-Host "Running npm run ${BuildType} in ${Location} ..."
    Push-Location $Location
    try {
        $env:MVD_DESKTOP_DIR = if ($env:MVD_DESKTOP_DIR) { $env:MVD_DESKTOP_DIR } else { "" }
        & npm run $BuildType
        if ($LASTEXITCODE -ne 0) {
            throw "npm run ${BuildType} failed in ${Location} with exit code ${LASTEXITCODE}"
        }
    } finally {
        Pop-Location
    }
    Write-Host "npm run ${BuildType} completed in ${Location}."
}

# Run npm run compress inside a directory.
function Invoke-NpmRunCompress {
    param([string]$Location)
    if (-not (Test-Path (Join-Path $Location "package.json"))) {
        Write-Host "No package.json found in ${Location}, skipping compress."
        return
    }
    Write-Host "Running npm run compress in ${Location} ..."
    Push-Location $Location
    try {
        & npm run compress
        if ($LASTEXITCODE -ne 0) {
            throw "npm run compress failed in ${Location} with exit code ${LASTEXITCODE}"
        }
    } finally {
        Pop-Location
    }
    Write-Host "npm run compress completed in ${Location}."
}

# Parse a plugin definition JSON file and return the pluginLocation and identifier.
function Get-PluginInfo {
    param([string]$JsonPath)
    try {
        $json = Get-Content $JsonPath -Raw | ConvertFrom-Json
        return @{
            PluginLocation = if ($json.pluginLocation) { $json.pluginLocation } else { $null }
            Identifier     = if ($json.identifier)     { $json.identifier }     else { $null }
        }
    } catch {
        return @{ PluginLocation = $null; Identifier = $null }
    }
}

# Traverse the plugin directory, invoking a scriptblock for each discovered plugin.
# The scriptblock receives ($PluginLocation, $PluginId) as positional parameters.
function Invoke-TraversePlugins {
    param(
        [string]$PluginDir,
        [scriptblock]$Callback
    )
    if (-not (Test-Path $PluginDir)) {
        Write-Warning "Plugin directory '${PluginDir}' does not exist, skipping traversal."
        return
    }
    Get-ChildItem -Path $PluginDir -Recurse -Filter "*.json" | ForEach-Object {
        $info = Get-PluginInfo -JsonPath $_.FullName
        if ($info.PluginLocation) {
            & $Callback $info.PluginLocation $info.Identifier
        }
    }
}

# Resolve the plugin directory from common.properties values.
function Resolve-PluginDir {
    param(
        [string]$BuildDir,
        [string]$PluginsValue,
        [string]$Capstone
    )
    if ([string]::IsNullOrEmpty($PluginsValue)) {
        return Join-Path $Capstone "zlux-app-server\defaults\plugins"
    }
    # If the path starts with ../ it is relative to the build directory.
    if ($PluginsValue.StartsWith("../") -or $PluginsValue.StartsWith("..\")) {
        $resolved = Join-Path $BuildDir $PluginsValue
        return [System.IO.Path]::GetFullPath($resolved)
    }
    return $PluginsValue
}
