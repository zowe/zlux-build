# build_ng2.ps1 - Builds Angular/ng2 components for zlux.
# Mirrors the targets defined in build_ng2.xml.
#
# Usage: .\build_ng2.ps1 [-Target <target>]
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

param(
    [string]$Target      = "buildng2",
    [string]$PluginRel   = "",
    [string]$PluginId    = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BuildDir  = [System.IO.Path]::GetFullPath((Join-Path $ScriptDir "..\.."))

. "$ScriptDir\common.ps1"

$CapstoneEnv = [System.Environment]::GetEnvironmentVariable("CAPSTONE")
$Capstone    = if ($CapstoneEnv) { $CapstoneEnv } else {
    [System.IO.Path]::GetFullPath((Join-Path $BuildDir ".."))
}

$CommonProps  = Import-PropertiesFile (Join-Path $BuildDir "common.properties")
$VersionProps = Import-PropertiesFile (Join-Path $BuildDir "version.properties")

$PluginsValue = if ($CommonProps.ContainsKey("plugins")) { $CommonProps["plugins"] } else { "" }
$PluginDir    = Resolve-PluginDir -BuildDir $BuildDir -PluginsValue $PluginsValue -Capstone $Capstone

$NoInstall    = [System.Environment]::GetEnvironmentVariable("NO_INSTALL")

function Invoke-PlatformBuild {
    Write-Host "==> platformBuild: installing zlux-platform dependencies ..."
    if (-not $NoInstall) {
        Invoke-NpmInstall -Location (Join-Path $Capstone "zlux-platform")
    }
}

function Invoke-BootstrapBuild {
    Write-Host "==> bootstrapBuild: building bootstrap components ..."
    if (-not $NoInstall) {
        Invoke-NpmInstall -Location (Join-Path $Capstone "zlux-server-framework")
        Invoke-NpmInstall -Location (Join-Path $Capstone "zlux-app-server")
        Invoke-NpmInstall -Location (Join-Path $Capstone "zlux-app-manager\bootstrap")
    }
    Invoke-NpmBuild -Location (Join-Path $Capstone "zlux-app-manager\bootstrap") -BuildType "build"
    Invoke-NpmBuild -Location (Join-Path $Capstone "zlux-server-framework") -BuildType "build"
}

function Invoke-DesktopBuild {
    Write-Host "==> desktopBuild: building virtual-desktop ..."
    if (-not $NoInstall) {
        Invoke-NpmInstall -Location (Join-Path $Capstone "zlux-app-manager\virtual-desktop")
    }
    Invoke-NpmBuild -Location (Join-Path $Capstone "zlux-app-manager\virtual-desktop") -BuildType "build:externals"
    Invoke-NpmBuild -Location (Join-Path $Capstone "zlux-app-manager\virtual-desktop") -BuildType "build"
}

function Invoke-GetDesktopDir {
    $desktopDir = Split-Path -Parent (Join-Path $Capstone "zlux-app-manager\virtual-desktop\package.json")
    $env:MVD_DESKTOP_DIR = $desktopDir
    Write-Host "MVD_DESKTOP_DIR is ${desktopDir}"
    Write-Host "Plugin directory is ${PluginDir}"
}

function Invoke-BuildPlugin {
    param([string]$PluginRelPath, [string]$PlugId = "")
    $pluginPath   = Join-Path $Capstone "zlux-app-server\lib\$PluginRelPath"
    $buildScript  = Join-Path $pluginPath "build\build.ps1"
    $buildRan     = $false

    if (Test-Path $buildScript) {
        Write-Host "Running build target in ${pluginPath}\build for ${PlugId}"
        try {
            Push-Location (Join-Path $pluginPath "build")
            & .\build.ps1 -Target build
            $buildRan = $true
        } catch {
            # Silently continue if the target does not exist in the local script.
        } finally {
            Pop-Location
        }
    }

    $skip = ($PluginRelPath -eq "..\..\zlux-app-manager\bootstrap") -or
            ($PluginRelPath -eq "..\..\zlux-app-manager\virtual-desktop")

    if (-not $skip) {
        if ((-not $NoInstall) -and (-not $buildRan)) {
            Invoke-NpmInstall -Location $pluginPath
        }
        Invoke-NpmBuild -Location $pluginPath -BuildType "build"
    }

    if (Test-Path $pluginPath) {
        Get-ChildItem -Path $pluginPath -Directory | ForEach-Object {
            if (-not $NoInstall) {
                Invoke-NpmInstall -Location $_.FullName
            }
            Invoke-NpmBuild -Location $_.FullName -BuildType "build"
        }
    }
}

function Invoke-TraverseBuild {
    Invoke-TraversePlugins -PluginDir $PluginDir -Callback {
        param($PluginLocation, $PlugId)
        Invoke-BuildPlugin -PluginRelPath $PluginLocation -PlugId $PlugId
    }
}

function Invoke-BuildNg2 {
    Invoke-GetDesktopDir
    Invoke-PlatformBuild
    Invoke-BootstrapBuild
    Invoke-DesktopBuild
    Invoke-TraverseBuild

    Invoke-NpmInstall -Location (Join-Path $Capstone "zlux-shared\src\logging")
    Invoke-NpmBuild   -Location (Join-Path $Capstone "zlux-shared\src\logging") -BuildType "build"
    Invoke-NpmInstall -Location (Join-Path $Capstone "zlux-shared\src\obfuscator")
    Invoke-NpmBuild   -Location (Join-Path $Capstone "zlux-shared\src\obfuscator") -BuildType "build"

    $adminApp = Join-Path $Capstone "zlux-app-manager\system-apps\admin-notification-app\webClient"
    Invoke-NpmInstall -Location $adminApp
    Invoke-NpmBuild   -Location $adminApp -BuildType "build"

    $webBrowserClient = Join-Path $Capstone "zlux-app-manager\system-apps\web-browser-app\webClient"
    Invoke-NpmInstall -Location $webBrowserClient
    Invoke-NpmBuild   -Location $webBrowserClient -BuildType "build"

    $webBrowserServer = Join-Path $Capstone "zlux-app-manager\system-apps\web-browser-app\nodeServer"
    Invoke-NpmInstall -Location $webBrowserServer
    Invoke-NpmBuild   -Location $webBrowserServer -BuildType "build"

    # Compress is Unix-only in the original; skip silently on Windows.
    Write-Host "INFO: npm run compress is Unix-only; skipping on Windows."

    # Copy require.js to the web output.
    $requireSrc = Join-Path $Capstone "zlux-app-manager\virtual-desktop\node_modules\requirejs\require.js"
    $requireDst = Join-Path $Capstone "zlux-app-manager\virtual-desktop\web\require.js"
    Copy-Item -Path $requireSrc -Destination $requireDst -Force
}

function Invoke-RemoveSource {
    Write-Host "==> removeSource: removing development files from ${Capstone} ..."

    $serverNm    = Join-Path $Capstone "zlux-app-server\node_modules"
    $frameworkNm = Join-Path $Capstone "zlux-server-framework\node_modules"

    # Remove node_modules (except in app-server and server-framework).
    Get-ChildItem -Path $Capstone -Recurse -Filter "node_modules" -Directory |
        Where-Object {
            $_.FullName -ne $serverNm -and
            -not $_.FullName.StartsWith("$serverNm\") -and
            $_.FullName -ne $frameworkNm -and
            -not $_.FullName.StartsWith("$frameworkNm\")
        } | ForEach-Object {
            Write-Host "Removing $($_.FullName)"
            Remove-Item -Recurse -Force $_.FullName
        }

    # Remove dco-signoffs directories.
    Get-ChildItem -Path $Capstone -Recurse -Filter "dco-signoffs" -Directory |
        ForEach-Object { Remove-Item -Recurse -Force $_.FullName }

    # Remove app-generator.
    $appGen = Join-Path $Capstone "zlux-app-manager\system-apps\app-generator"
    if (Test-Path $appGen) { Remove-Item -Recurse -Force $appGen }

    # Remove top-level test directories (e.g. zlux-app-server\test).
    Get-ChildItem -Path $Capstone -Depth 1 -Filter "test" -Directory |
        ForEach-Object {
            Write-Host "Removing $($_.FullName)"
            Remove-Item -Recurse -Force $_.FullName
        }

    # Remove top-level .ppf files.
    Get-ChildItem -Path $Capstone -Depth 1 -Filter "*.ppf" -File |
        Remove-Item -Force

    # Remove src, dts, nodeServer, webClient directories.
    foreach ($dirName in @("src", "dts", "nodeServer", "webClient")) {
        Get-ChildItem -Path $Capstone -Recurse -Filter $dirName -Directory |
            Where-Object {
                $p = $_.FullName
                -not ($p -like "*\zssServer\*") -and
                -not ($p.StartsWith((Join-Path $Capstone "zlux-app-manager\virtual-desktop"))) -and
                -not ($p.StartsWith((Join-Path $Capstone "zlux-platform\interface"))) -and
                -not ($p.StartsWith($serverNm)) -and
                -not ($p.StartsWith($frameworkNm)) -and
                -not ($p.StartsWith((Join-Path $Capstone "zlux-shared")))
            } | ForEach-Object {
                Write-Host "Removing $($_.FullName)"
                Remove-Item -Recurse -Force $_.FullName
            }
    }

    # Remove sonar-project.properties.
    Get-ChildItem -Path $Capstone -Recurse -Filter "sonar-project.properties" |
        Where-Object {
            -not $_.FullName.StartsWith($serverNm) -and
            -not $_.FullName.StartsWith($frameworkNm)
        } | Remove-Item -Force

    # Remove TypeScript sources and configs.
    $tsPatterns = @("*.ts", "tsconfig*.json", "tslint.json", "webpack.config.js")
    foreach ($pattern in $tsPatterns) {
        Get-ChildItem -Path $Capstone -Recurse -Filter $pattern |
            Where-Object {
                $p = $_.FullName
                -not ($p.StartsWith((Join-Path $Capstone "zlux-app-server"))) -and
                -not ($p.StartsWith((Join-Path $Capstone "zlux-build"))) -and
                -not ($p -like "*\node_modules\*") -and
                -not ($p.StartsWith((Join-Path $Capstone "zlux-app-manager\virtual-desktop"))) -and
                -not ($p.StartsWith((Join-Path $Capstone "zlux-platform\interface"))) -and
                -not ($p.StartsWith((Join-Path $Capstone "zlux-shared\src")))
            } | Remove-Item -Force
    }

    # Remove test certificate files and cert-generation scripts.
    Get-ChildItem -Path $Capstone -Recurse -Include "*.cer","*.key","*.p12" |
        Where-Object { $_.FullName -notlike "*\node_modules\*" } |
        Remove-Item -Force
    $certScript = Join-Path $Capstone "zlux-app-server\defaults\serverConfig\generate_zlux_certificates.sh"
    if (Test-Path $certScript) { Remove-Item -Force $certScript }
    $defaultsReadme = Join-Path $Capstone "zlux-app-server\defaults\README.md"
    if (Test-Path $defaultsReadme) { Remove-Item -Force $defaultsReadme }
}

function Invoke-RemoveZssSource {
    Write-Host "==> removeZssSource: removing zssServer directories ..."
    Get-ChildItem -Path $Capstone -Recurse -Filter "zssServer" -Directory |
        ForEach-Object { Remove-Item -Recurse -Force $_.FullName }
}

switch ($Target) {
    "buildng2"        { Invoke-BuildNg2 }
    "bootstrapBuild"  { Invoke-BootstrapBuild }
    "desktopBuild"    { Invoke-DesktopBuild }
    "platformBuild"   { Invoke-PlatformBuild }
    "buildPlugin"     { Invoke-BuildPlugin -PluginRelPath $PluginRel -PlugId $PluginId }
    "removeSource"    { Invoke-RemoveSource }
    "removeZssSource" { Invoke-RemoveZssSource }
    default {
        Write-Error "Unknown target '${Target}'"
        exit 1
    }
}
