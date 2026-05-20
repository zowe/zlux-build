# build.ps1 - Main build entry point for zlux-build.
# Mirrors the targets defined in build.xml.
#
# Usage: .\build.ps1 [-Target <target>]
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

param(
    [string]$Target = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$BuildDir   = [System.IO.Path]::GetFullPath((Join-Path $ScriptDir "..\.."))
$Capstone   = [System.IO.Path]::GetFullPath((Join-Path $BuildDir ".."))

. "$ScriptDir\common.ps1"

$CommonProps  = Import-PropertiesFile (Join-Path $BuildDir "common.properties")
$VersionProps = Import-PropertiesFile (Join-Path $BuildDir "version.properties")

$TargetList = @(
    @{ Name = "buildAll";       Desc = "Run deploy then build (default)" },
    @{ Name = "build";          Desc = "Build all ng2/Angular components" },
    @{ Name = "bootstrapBuild"; Desc = "Build only server framework and bootstrap" },
    @{ Name = "deploy";         Desc = "Deploy plugin definitions and server config" },
    @{ Name = "cleanDeploy";    Desc = "Remove instance and site deploy directories" },
    @{ Name = "devClean";       Desc = "Remove instance plugins and user/group data" },
    @{ Name = "production";     Desc = "Build a production distribution into ../dist/" },
    @{ Name = "testing";        Desc = "Build a testing distribution (deploy + build) into ../dist/" },
    @{ Name = "getVersion";     Desc = "Write version string to fullVersion.properties" },
    @{ Name = "audit";          Desc = "Run npm audit on all plugins" },
    @{ Name = "removeSource";   Desc = "Remove source files not needed for production" },
    @{ Name = "help";           Desc = "Show this help message" }
)

function Show-Help {
    Write-Host "Available targets:"
    foreach ($entry in $TargetList) {
        Write-Host ("  {0,-18} {1}" -f $entry.Name, $entry.Desc)
    }
}

function Invoke-PromptTarget {
    Write-Host ""
    Write-Host "zlux-build - available targets:"
    Write-Host "-----------------------------------"
    for ($i = 0; $i -lt $TargetList.Count; $i++) {
        Write-Host ("{0,4}) {1,-18} {2}" -f ($i + 1), $TargetList[$i].Name, $TargetList[$i].Desc)
    }
    Write-Host ""
    $choice = Read-Host "Enter target number or name [1 = buildAll]"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "1" }

    # Accept a number.
    $num = 0
    if ([int]::TryParse($choice, [ref]$num)) {
        if ($num -ge 1 -and $num -le $TargetList.Count) {
            return $TargetList[$num - 1].Name
        } else {
            Write-Error "Number '$choice' is out of range."
            exit 1
        }
    }
    return $choice
}

# Prompt when no target was supplied and stdout is interactive.
if ([string]::IsNullOrEmpty($Target)) {
    if ([Environment]::UserInteractive -and [Console]::IsInputRedirected -eq $false) {
        $Target = Invoke-PromptTarget
    } else {
        $Target = "buildAll"
    }
}

switch ($Target) {
    "buildAll" {
        Write-Host "==> Running deploy ..."
        & "$ScriptDir\deploy.ps1"
        Write-Host "==> Running build ..."
        & "$ScriptDir\build_ng2.ps1" -Target buildng2
    }
    "production" {
        & "$ScriptDir\production.ps1"
    }
    "testing" {
        & "$ScriptDir\testing.ps1"
    }
    "getVersion" {
        & "$ScriptDir\production.ps1" -Target publishVersion
    }
    "deploy" {
        & "$ScriptDir\deploy.ps1"
    }
    "audit" {
        & "$ScriptDir\audit.ps1"
    }
    "cleanDeploy" {
        & "$ScriptDir\deploy.ps1" -Target cleanDeploy
    }
    "devClean" {
        & "$ScriptDir\deploy.ps1" -Target devClean
    }
    "build" {
        & "$ScriptDir\build_ng2.ps1" -Target buildng2
    }
    "bootstrapBuild" {
        & "$ScriptDir\build_ng2.ps1" -Target bootstrapBuild
    }
    "removeSource" {
        & "$ScriptDir\build_ng2.ps1" -Target removeSource
    }
    { $_ -in "help", "-h", "--help" } {
        Show-Help
    }
    default {
        Write-Error "Unknown target '${Target}'"
        Show-Help
        exit 1
    }
}
