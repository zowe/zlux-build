@echo off
REM This program and the accompanying materials are
REM made available under the terms of the Eclipse Public License v2.0 which accompanies
REM this distribution, and is available at https://www.eclipse.org/legal/epl-v20.html
REM 
REM SPDX-License-Identifier: EPL-2.0
REM 
REM Copyright Contributors to the Zowe Project.

REM /plugins is a primary location for plugins of a component. Secondarily, /components/componentname/plugins

if not exist %PREFIX%\opt\zowe\plugins\app-server\%PKG_NAME% mkdir %PREFIX%\opt\zowe\plugins\app-server\%PKG_NAME%
robocopy %SRC_DIR% %PREFIX%\opt\zowe\plugins\app-server\%PKG_NAME% * /E > nul

exit 0
