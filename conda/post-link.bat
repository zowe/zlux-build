@echo off
REM This program and the accompanying materials are
REM made available under the terms of the Eclipse Public License v2.0 which accompanies
REM this distribution, and is available at https://www.eclipse.org/legal/epl-v20.html
REM 
REM SPDX-License-Identifier: EPL-2.0
REM 
REM Copyright Contributors to the Zowe Project.
setlocal EnableDelayedExpansion

if exist "%ZOWE_ROOT_DIR%\components\app-server" (
  set ZOWE_ROOT=%ZOWE_ROOT_DIR%
) else if exist "%ROOT_DIR%\components\app-server" (
  set ZOWE_ROOT=%ROOT_DIR%
)
        

if exist "%ZOWE_WORKSPACE_DIR%\..\bin\install-app.bat" (
  set ZOWE_INST=%ZOWE_WORKSPACE_DIR%\..\
) else if exist "%ZOWE_INSTANCE_DIR%\bin\install-app.bat" (
  set ZOWE_INST=%ZOWE_INSTANCE_DIR%
) else if exist "%WORKSPACE_DIR%\..\bin\install-app.bat" (
  set ZOWE_INST=%WORKSPACE_DIR%\..\
) else if exist "%INSTANCE_DIR%\bin\install-app.bat" (
  set ZOWE_INST=%INSTANCE_DIR%
)

if not defined ZOWE_INST (
  if not defined ZOWE_ROOT (
    echo "%PKG_NAME% not registered to Zowe because no instance found. To manually install, run INSTANCE_DIR\bin\install-app.bat %PREFIX%\opt\zowe\plugins\app-server\%PKG_NAME%"
    exit 1
  ) else (
    !ZOWE_ROOT!\components\app-server\share\zlux-app-server\bin\install-app.bat %PREFIX%\opt\zowe\plugins\app-server\%PKG_NAME%
  )
) else (
  !ZOWE_INST!\bin\install-app.bat %PREFIX%\opt\zowe\plugins\app-server\%PKG_NAME%
)
