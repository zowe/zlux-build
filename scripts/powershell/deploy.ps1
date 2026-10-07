# deploy.ps1 - Deploy ZLUX with plugins defined in the plugin directory.
# Mirrors the targets defined in deploy.xml.
#
# Usage: .\deploy.ps1 [-Target <target>]
# Targets: deploy (default), cleanDeploy, devClean
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v2.0 which accompanies this
# distribution, and is available at https://www.eclipse.org/legal/epl-v20.html
#
# SPDX-License-Identifier: EPL-2.0
#
# Copyright Contributors to the Zowe Project.

param(
    [string]$Target = "deploy"
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
$PluginsValue = if ($CommonProps.ContainsKey("plugins")) { $CommonProps["plugins"] } else { "" }
$PluginDir    = Resolve-PluginDir -BuildDir $BuildDir -PluginsValue $PluginsValue -Capstone $Capstone

$ZluxAppServer = Join-Path $Capstone "zlux-app-server"
$HomeDir       = $ZluxAppServer

# Determine instance/site directories based on INSTANCE_DIR environment variable.
$InstanceDirEnv = [System.Environment]::GetEnvironmentVariable("INSTANCE_DIR")
if ($InstanceDirEnv) {
    $InstanceDirResolved = Join-Path $InstanceDirEnv "workspace\app-server"
    $SiteDir             = Join-Path $InstanceDirEnv "workspace\app-server\site"
    $ServerConfig        = Join-Path $InstanceDirResolved "serverConfig"
    $InstancePlugins     = Join-Path $InstanceDirResolved "plugins"
} else {
    $InstanceDirResolved = Join-Path $ZluxAppServer "deploy\instance"
    $SiteDir             = Join-Path $ZluxAppServer "deploy\site"
    $ServerConfig        = Join-Path $InstanceDirResolved "ZLUX\serverConfig"
    $InstancePlugins     = Join-Path $InstanceDirResolved "ZLUX\plugins"
}

function Invoke-Deploy {
    Write-Host "==> Deploying ZLUX ..."

    $dirs = @(
        "$HomeDir\defaults\ZLUX\pluginStorage\org.zowe.zlux.ng2desktop\actions",
        "$HomeDir\defaults\ZLUX\pluginStorage\org.zowe.zlux.ng2desktop\recognizers",
        "$HomeDir\defaults\ZLUX\pluginStorage\org.zowe.zlux.ivydesktop\actions",
        "$HomeDir\defaults\ZLUX\pluginStorage\org.zowe.zlux.ivydesktop\recognizers",
        "$SiteDir\ZLUX\pluginStorage\org.zowe.zlux.ng2desktop\actions",
        "$SiteDir\ZLUX\pluginStorage\org.zowe.zlux.ng2desktop\recognizers",
        "$SiteDir\ZLUX\pluginStorage\org.zowe.zlux.ivydesktop\actions",
        "$SiteDir\ZLUX\pluginStorage\org.zowe.zlux.ivydesktop\recognizers",
        $InstancePlugins,
        $ServerConfig,
        "$InstanceDirResolved\ZLUX\pluginStorage\org.zowe.zlux.ng2desktop\actions",
        "$InstanceDirResolved\ZLUX\pluginStorage\org.zowe.zlux.ng2desktop\recognizers",
        "$InstanceDirResolved\ZLUX\pluginStorage\org.zowe.zlux.ivydesktop\actions",
        "$InstanceDirResolved\ZLUX\pluginStorage\org.zowe.zlux.ivydesktop\recognizers",
        "$InstanceDirResolved\users",
        "$InstanceDirResolved\groups"
    )
    foreach ($dir in $dirs) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }

    # Copy plugin JSON files.
    Get-ChildItem -Path $PluginDir -MaxDepth 1 -Filter "*.json" |
        Copy-Item -Destination $InstancePlugins -Force

    # Copy server configuration files.
    $serverDefaults = Join-Path $HomeDir "defaults\serverConfig"
    $certFiles = @("zlux.keystore.cer", "zlux.keystore.key", "apiml-localca.cer", "tomcat.xml")
    foreach ($cert in $certFiles) {
        $src = Join-Path $serverDefaults $cert
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination $ServerConfig -Force -ErrorAction SilentlyContinue
        }
    }

    # Traverse plugins and run their deploy scripts.
    Invoke-TraversePlugins -PluginDir $PluginDir -Callback {
        param($PluginLocation, $PlugId)
        $pluginBuild = Join-Path $Capstone "zlux-app-server\lib\$PluginLocation\build"
        $deployScript = Join-Path $pluginBuild "build.ps1"
        if (Test-Path $deployScript) {
            Write-Host "Running deploy in $pluginBuild for $PlugId"
            try {
                Push-Location $pluginBuild
                & .\build.ps1 -Target deploy
            } catch { } finally {
                Pop-Location
            }
        }
    }

    # Set restrictive ACLs on serverConfig.
    # On Windows, we use icacls to restrict access.
    if (Test-Path $ServerConfig) {
        & icacls "$ServerConfig" /inheritance:r /grant:r "${env:USERNAME}:(OI)(CI)F" 2>$null | Out-Null
    }

    Write-Host "Deploy complete."
}

function Invoke-CleanDeploy {
    Write-Host "==> Cleaning deploy directories ..."
    if (Test-Path $InstanceDirResolved) { Remove-Item -Recurse -Force $InstanceDirResolved }
    if (Test-Path $SiteDir)             { Remove-Item -Recurse -Force $SiteDir }
    Write-Host "cleanDeploy complete."
}

function Invoke-DevClean {
    Write-Host "==> Running devClean ..."
    if (Test-Path $InstancePlugins) { Remove-Item -Recurse -Force $InstancePlugins }
    $usersDir  = Join-Path $InstanceDirResolved "users"
    $groupsDir = Join-Path $InstanceDirResolved "groups"
    if (Test-Path $usersDir)  { Remove-Item -Recurse -Force $usersDir }
    if (Test-Path $groupsDir) { Remove-Item -Recurse -Force $groupsDir }
    Write-Host "devClean complete."
}

switch ($Target) {
    "deploy"      { Invoke-Deploy }
    "cleanDeploy" { Invoke-CleanDeploy }
    "devClean"    { Invoke-DevClean }
    default {
        Write-Error "Unknown target '${Target}'"
        exit 1
    }
}
