# copy_node.ps1 - Copies node_modules from nodeServer to lib/node_modules.
# Mirrors the targets defined in copy_node.xml.
#
# Usage: .\copy_node.ps1
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

. "$ScriptDir\common.ps1"

# The ant copy_node.xml uses ${user.dir} which is the working directory at
# the time ant is invoked. We default to the current working directory.
$UserDirEnv = [System.Environment]::GetEnvironmentVariable("USER_DIR")
$UserDir    = if ($UserDirEnv) { $UserDirEnv } else { (Get-Location).Path }

$SourceDir = [System.IO.Path]::GetFullPath((Join-Path $UserDir "..\nodeServer\node_modules"))
$DestDir   = [System.IO.Path]::GetFullPath((Join-Path $UserDir "..\lib\node_modules"))

Write-Host "==> copynode: copying node_modules from ${SourceDir} to ${DestDir} ..."

if (-not (Test-Path $SourceDir)) {
    Write-Error "Source directory '${SourceDir}' does not exist."
    exit 1
}

New-Item -ItemType Directory -Force -Path $DestDir | Out-Null
Copy-Item -Path "$SourceDir\*" -Destination $DestDir -Recurse -Force

Write-Host "copynode complete."
