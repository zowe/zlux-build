#!/bin/sh

# Available env vars:
# PREFIX - The location you must copy content to be included into the package
# PKG_NAME - The name of your package as seen by a user
# PKG_VERSION - The version, as seen by a user
# PKG_BUILDNUM - The build number, can be used to distinguish patches by the user


# /plugins is a primary location for plugins of a component. Secondarily, /components/componentname/plugins
# PKG_NAME should be meaningful in the case that multiple plugin dirs (app, cli, apiml) exist within.
# If your package includes multiple plugins for a type (such as 2 app framework plugins),
# There are different solutions but you may wish to either place common utilities outside the below variables,
# While keeping the plugins within these below locations, in a 1-plugin-per-directory scheme
# To maintain consistency with other plugins.

zowe_plugins=$PREFIX/opt/zowe/plugins
app_plugin_dir=$zowe_plugins/app-server/$PKG_NAME
cli_plugin_dir=$zowe_plugins/cli/$PKG_NAME
apiml_plugin_dir=$zowe_plugins/api-mediation/$PKG_NAME
# Special case: zos isnt a component, just a way to make clear what must be put onto zos
zos_content_dir=$zowe_plugins/zos/$PKG_NAME

# In the case that the structure of https://github.com/zowe/zowe-install-packaging/issues/1569 is not followed
# Then this is assuming it's an app framework plugin.
if [ -e "${SRC_DIR}/pluginDefinition.json" ]
then
    mkdir -p $app_plugin_dir
    cp -r ${SRC_DIR}/* $app_plugin_dir
    cd $app_plugin_dir
    rm -f build_env_setup.sh conda_build.sh metadata_conda_debug.yaml *.ppf

# Otherwise, if it is following the scheme, here's some hardcoded components that may have content
else
    if [ -d "${SRC_DIR}/app-server" ]; then
        mkdir -p $app_plugin_dir
        cp -r ${SRC_DIR}/app-server/* $app_plugin_dir
        cd $app_plugin_dir
        rm -f build_env_setup.sh conda_build.sh metadata_conda_debug.yaml *.ppf
    fi
    if [ -d "${SRC_DIR}/cli" ]; then
        mkdir -p $cli_plugin_dir
        cp -r ${SRC_DIR}/cli/* $cli_plugin_dir
    fi
    if [ -d "${SRC_DIR}/api-mediation" ]; then
        mkdir -p $apiml_plugin_dir
        cp -r ${SRC_DIR}/api-mediation/* $apiml_plugin_dir
    fi
# TODO: Is there more to do here for the case of zos content, or is that an install-time concern?
    if [ -d "${SRC_DIR}/zos" ]; then
        mkdir -p $zos_content_dir
        cp -r ${SRC_DIR}/zos/* $zos_content_dir
    fi
fi

# If present in the same directory as this file, if pre-link, post-link, or pre-unlink .sh or .bat
# Files are present, then they will be copied into this package and assist with automation on end user device

# pre-link---Executed before the package is installed. An error is indicated by a nonzero exit and causes conda to stop and causes the installation to fail.
#
# post-link---Executed after the package is installed. An error is indicated by a nonzero exist and causes installation to fail. If there is an error, conda does not write any package metadata.
#
# pre-unlink---Executed before the package is removed. An error is indicated by a nonzero exist and causes the removal to fail.
#


exit 0
