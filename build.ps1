# build.ps1 - Entry point for zlux-build on Windows.
# Delegates to scripts/powershell/build.ps1.
#
# Usage: .\build.ps1 [-Target <target>]
# See scripts\powershell\build.ps1 for available targets.
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

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& "$ScriptDir\scripts\powershell\build.ps1" -Target $Target
