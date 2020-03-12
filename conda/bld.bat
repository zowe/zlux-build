@echo off
REM This program and the accompanying materials are
REM made available under the terms of the Eclipse Public License v2.0 which accompanies
REM this distribution, and is available at https://www.eclipse.org/legal/epl-v20.html
REM 
REM SPDX-License-Identifier: EPL-2.0
REM 
REM Copyright Contributors to the Zowe Project.


if not exist %PREFIX%\share\zowe\app-server\zlux-app-server\defaults\plugins mkdir %PREFIX%\share\zowe\app-server\zlux-app-server\defaults\plugins
echo '{"identifier":"%PKG_NAME%","pluginLocation":"%PREFIX%/share/zowe/app-server/plugins/%PKG_NAME%/%PKG_VERSION%"}' ^
     > %PREFIX%\share\zowe\app-server\zlux-app-server\defaults\plugins\%PKG_NAME%.json

if not exist %PREFIX%\share\zowe\app-server\plugins\%PKG_NAME%\%PKG_VERSION% mkdir %PREFIX%\share\zowe\app-server\plugins\%PKG_NAME%\%PKG_VERSION%
robocopy %SRC_DIR% %PREFIX%\share\zowe\app-server\plugins\%PKG_NAME%\%PKG_VERSION% * /E > nul

exit 0
