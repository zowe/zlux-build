@echo off

REM Available env vars:
REM PREFIX - The location you must copy content to be included into the package
REM PKG_NAME - The name of your package as seen by a user
REM PKG_VERSION - The version, as seen by a user
REM PKG_BUILDNUM - The build number, can be used to distinguish patches by the user


REM /plugins is a primary location for plugins of a component. Secondarily, /components/componentname/plugins
REM PKG_NAME should be meaningful in the case that multiple plugin dirs (app, cli, apiml) exist within.
REM If your package includes multiple plugins for a type (such as 2 app framework plugins),
REM There are different solutions but you may wish to either place common utilities outside the below variables,
REM While keeping the plugins within these below locations, in a 1-plugin-per-directory scheme
REM To maintain consistency with other plugins.

set zowe_plugins=%PREFIX%\opt\zowe\plugins
set app_plugin_dir=%zowe_plugins%\%PKG_NAME%\app-server
set cli_plugin_dir=%zowe_plugins%\%PKG_NAME%\cli
set apiml_plugin_dir=%zowe_plugins%\%PKG_NAME%\api-mediation
REM Special case: zos isnt a component, just a way to make clear what must be put onto zos
set zos_content_dir=%zowe_plugins%\%PKG_NAME%\zos

REM In the case that the structure of https://github.com/zowe/zowe-install-packaging/issues/1569 is not followed
REM Then this is assuming it's an app framework plugin.
if exist %SRC_DIR%\pluginDefinition.json (
    mkdir %app_plugin_dir%
    robocopy %SRC_DIR% %app_plugin_dir% * /E > nul
) else (
REM Otherwise, if it is following the scheme, here's some hardcoded components that may have content
    if exist %SRC_DIR%\app-server (
        mkdir %app_plugin_dir%
        robocopy %SRC_DIR%\app-server %app_plugin_dir% * /E > nul
    )
    if exist %SRC_DIR%\cli (
        mkdir %cli_plugin_dir%
        robocopy %SRC_DIR%\cli %cli_plugin_dir% * /E > nul
    )
    if exist %SRC_DIR%\api-mediation (
        mkdir %apiml_plugin_dir%
        robocopy %SRC_DIR%\api-mediation %apiml_plugin_dir% * /E > nul
    )
REM TODO: Is there more to do here for the case of zos content, or is that an install-time concern?
    if exist %SRC_DIR%\zos (
        mkdir %zos_content_dir%
        robocopy %SRC_DIR%\zos %zos_content_dir% * /E > nul
    )
)

REM It's fine to copy an entire source directory into $zowe_plugins, but the above is explicit to be educational

REM If present in the same directory as this file, if pre-link, post-link, or pre-unlink .sh or .bat
REM Files are present, then they will be copied into this package and assist with automation on end user device

REM pre-link---Executed before the package is installed. An error is indicated by a nonzero exit and causes conda to stop and causes the installation to fail.
REM
REM post-link---Executed after the package is installed. An error is indicated by a nonzero exist and causes installation to fail. If there is an error, conda does not write any package metadata.
REM
REM pre-unlink---Executed before the package is removed. An error is indicated by a nonzero exist and causes the removal to fail.
REM


exit 0

