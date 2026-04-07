# testing.ps1 - Creates a testing distribution of zlux.
# Mirrors the targets defined in testing.xml.
# This is similar to production.ps1 but also runs the deploy step.
#
# Usage: .\testing.ps1 [-Target <target>]
# Targets: setup-dist (default), publishVersion
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v2.0 which accompanies this
# distribution, and is available at https://www.eclipse.org/legal/epl-v20.html
#
# SPDX-License-Identifier: EPL-2.0
#
# Copyright Contributors to the Zowe Project.

param(
    [string]$Target = "setup-dist"
)

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
$VersionProps = Import-PropertiesFile (Join-Path $BuildDir "version.properties")

$CorePluginProps = @{}
$CorePluginsFile = Join-Path $BuildDir "core-plugins.properties"
if (Test-Path $CorePluginsFile) {
    $CorePluginProps = Import-PropertiesFile $CorePluginsFile
}

$VersionDate         = (Get-Date -Format "yyyyMMdd")
$ProductMajorVersion = if ($VersionProps.ContainsKey("PRODUCT_MAJOR_VERSION")) { $VersionProps["PRODUCT_MAJOR_VERSION"] } else { "0" }
$ProductMinorVersion = if ($VersionProps.ContainsKey("PRODUCT_MINOR_VERSION")) { $VersionProps["PRODUCT_MINOR_VERSION"] } else { "8" }
$ProductRevision     = if ($VersionProps.ContainsKey("PRODUCT_REVISION"))      { $VersionProps["PRODUCT_REVISION"] }      else { "4" }
$VersionString       = "${ProductMajorVersion}.${ProductMinorVersion}.${ProductRevision}+${VersionDate}"

$DistDir = [System.IO.Path]::GetFullPath((Join-Path $Capstone "..\dist"))

function Invoke-SetupDist {
    Write-Host "==> setup-dist (testing): creating testing distribution in ${DistDir} ..."

    if (Test-Path $DistDir) { Remove-Item -Recurse -Force $DistDir }
    New-Item -ItemType Directory -Force -Path $DistDir | Out-Null

    $capstoneParen = [System.IO.Path]::GetFullPath((Join-Path $Capstone ".."))
    Copy-Item -Path "$capstoneParen\*" -Destination $DistDir -Recurse -Force

    if ($CorePluginProps.ContainsKey("CORE_PLUGINS")) {
        $corePluginsRaw = $CorePluginProps["CORE_PLUGINS"]
        $corePluginsRaw -split "," | ForEach-Object {
            $relPath = $_.Trim()
            if ([string]::IsNullOrEmpty($relPath)) { return }
            $targetFile = Join-Path $DistDir $relPath.Replace("/", "\")
            if (Test-Path $targetFile) {
                Write-Host "Replacing version token in ${targetFile}"
                $content = Get-Content $targetFile -Raw
                $content = $content -replace [regex]::Escape("0.0.0-zlux.version.replacement"), $VersionString
                Set-Content -Path $targetFile -Value $content -NoNewline
            }
        }
    }

    $distBuildDir = Join-Path $DistDir "zlux-build"
    $env:CAPSTONE = $DistDir

    # testing.xml runs deploy first, then build (unlike production.xml).
    Write-Host "==> Running deploy in ${distBuildDir} ..."
    & "$distBuildDir\scripts\powershell\deploy.ps1"

    Write-Host "==> Running build in ${distBuildDir} ..."
    & "$distBuildDir\scripts\powershell\build_ng2.ps1" -Target buildng2

    $env:CAPSTONE = ""
    Write-Host "setup-dist (testing) complete. Distribution is at ${DistDir}"
}

function Invoke-PublishVersion {
    $outFile = Join-Path $BuildDir "fullVersion.properties"
    "PRODUCT_FULL_VERSION=${VersionString}" | Set-Content -Path $outFile
    Write-Host "Published version: ${VersionString}"
}

switch ($Target) {
    { $_ -in "setup-dist", "setupDist" } { Invoke-SetupDist }
    "publishVersion" { Invoke-PublishVersion }
    default {
        Write-Error "Unknown target '${Target}'"
        exit 1
    }
}
