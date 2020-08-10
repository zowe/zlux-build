@echo off

REM /plugins is a primary location for plugins of a component. Secondarily, /components/componentname/plugins

if not exist %PREFIX%\opt\zowe\plugins\app-server\%PKG_NAME% mkdir %PREFIX%\opt\zowe\plugins\app-server\%PKG_NAME%
robocopy %SRC_DIR% %PREFIX%\opt\zowe\plugins\app-server\%PKG_NAME% * /E > nul

exit 0
