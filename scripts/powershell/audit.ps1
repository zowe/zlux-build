# audit.ps1 - Runs npm audit for all plugins to check for security violations.
# Mirrors the targets defined in audit.xml.
#
# Usage: .\audit.ps1
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

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BuildDir  = [System.IO.Path]::GetFullPath((Join-Path $ScriptDir "..\.."))

. "$ScriptDir\common.ps1"

$CapstoneEnv  = [System.Environment]::GetEnvironmentVariable("CAPSTONE")
$Capstone     = if ($CapstoneEnv) { $CapstoneEnv } else {
    [System.IO.Path]::GetFullPath((Join-Path $BuildDir ".."))
}

$CommonProps  = Import-PropertiesFile (Join-Path $BuildDir "common.properties")
$PluginsValue = if ($CommonProps.ContainsKey("plugins")) { $CommonProps["plugins"] } else { "" }
$PluginDir    = Resolve-PluginDir -BuildDir $BuildDir -PluginsValue $PluginsValue -Capstone $Capstone

$ArtifactsDir = Join-Path $BuildDir "artifacts\audit"
New-Item -ItemType Directory -Force -Path $ArtifactsDir | Out-Null

function Invoke-GenerateAuditReport {
    param([string]$Location, [string]$PluginId)

    if (-not (Test-Path (Join-Path $Location "package.json"))) {
        return
    }

    $safeId  = $PluginId -replace "[/\\ ]", "_"
    $logFile = Join-Path $ArtifactsDir "${safeId}_audit.log"

    Write-Host "Running npm audit in ${Location} -> ${logFile}"
    Push-Location $Location
    try {
        & npm audit 2>&1 | Tee-Object -FilePath $logFile | Out-Null
    } catch {
        # npm audit exits non-zero when vulnerabilities are found; capture output regardless.
        $_ | Out-File -Append -FilePath $logFile
    } finally {
        Pop-Location
    }
}

function Invoke-Audit {
    Invoke-TraversePlugins -PluginDir $PluginDir -Callback {
        param($PluginLocation, $PlugId)
        $pluginPath = Join-Path $Capstone "zlux-app-server\lib\$PluginLocation"

        Invoke-GenerateAuditReport -Location $pluginPath -PluginId $PlugId

        if (Test-Path $pluginPath) {
            Get-ChildItem -Path $pluginPath -Directory | ForEach-Object {
                $subId = "${PlugId}_$($_.Name)"
                Invoke-GenerateAuditReport -Location $_.FullName -PluginId $subId
            }
        }
    }
}

Write-Host "==> Running audit for all plugins. Reports will be written to ${ArtifactsDir}"
Invoke-Audit
Write-Host "Audit complete."
