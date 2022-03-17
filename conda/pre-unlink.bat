@echo off
REM This program and the accompanying materials are
REM made available under the terms of the Eclipse Public License v2.0 which accompanies
REM this distribution, and is available at https://www.eclipse.org/legal/epl-v20.html
REM 
REM SPDX-License-Identifier: EPL-2.0
REM 
REM Copyright Contributors to the Zowe Project.
setlocal EnableDelayedExpansion

if exist "%ZOWE_WORKSPACE_DIR%\app-server\ZLUX" (
  set ZOWE_INST=%ZOWE_WORKSPACE_DIR%\..\
) else if exist "%ZOWE_INSTANCE_DIR%\workspace\app-server\ZLUX" (
  set ZOWE_INST=%ZOWE_INSTANCE_DIR%
) else if exist "%WORKSPACE_DIR%\app-server\ZLUX" (
  set ZOWE_INST=%WORKSPACE_DIR%\..\
) else if exist "%INSTANCE_DIR%\workspace\app-server\ZLUX" (
  set ZOWE_INST=%INSTANCE_DIR%
)

if exist "!ZOWE_INST!\workspace\app-server\plugins\%PKG_NAME%.json" (
  set location=%PREFIX%\opt\zowe\plugins\app-server\%PKG_NAME%
  node -e "const fs=require('fs'); const content=require('!ZOWE_INST!/workspace/app-server/plugins/%PKG_NAME%.json'); if (content.pluginLocation == '!location!') { fs.unlinkSync('!ZOWE_INST!/workspace/app-server/plugins/%PKG_NAME%.json'); }"
)
