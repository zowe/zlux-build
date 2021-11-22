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
pkg_dir=$zowe_plugins/$PKG_NAME

function packageByFolder {
    # In the case that the structure of https://github.com/zowe/zowe-install-packaging/issues/1569 is not followed
    # Then this is assuming it's an app framework plugin.
    if [ -e "$1/pluginDefinition.json" ]
    then
        mkdir -p $2/app-server
        cp -r $1/* $2/app-server
        cd $2/app-server
        rm -f build_env_setup.sh conda_build.sh metadata_conda_debug.yaml *.ppf
        # Otherwise, if it is following the scheme, here's some hardcoded components that may have content
    else
        if [ -d "$1/app-server" ]; then
            mkdir -p $2/app-server
            cp -r $1/app-server/* $2/app-server
            cd $2/app-server
            rm -f build_env_setup.sh conda_build.sh metadata_conda_debug.yaml *.ppf
        fi
        if [ -d "$1/cli" ]; then
            mkdir -p $2/cli
            cp -r $1/cli/* $2/cli
        fi
        if [ -d "$1/api-mediation" ]; then
            mkdir -p $2/api-mediation
            cp -r $1/api-mediation/* $2/api-mediation
        fi
        # TODO: Is there more to do here for the case of zos content, or is that an install-time concern?
        if [ -d "$1/zos" ]; then
            #special case: zos isnt a component, just a folder to alert that zos code is needed to be installed
            mkdir -p $2/zos
            cp -r $1/zos/* $2/zos
        fi
    fi
}


packageByFolder ${SRC_DIR} ${pkg_dir}

if [ ! -d "${pkg_dir}" ]; then
    for D in `find . -maxdepth 1 type -d printf %f\\\\n`
    do
        packageByFolder ${SRC_DIR}/$D ${pkg_dir}/$D
    done
fi


# It's fine to copy an entire source directory into $zowe_plugins, but the above is explicit to be educational

# If present in the same directory as this file, if pre-link, post-link, or pre-unlink .sh or .bat
# Files are present, then they will be copied into this package and assist with automation on end user device

# pre-link---Executed before the package is installed. An error is indicated by a nonzero exit and causes conda to stop and causes the installation to fail.
#
# post-link---Executed after the package is installed. An error is indicated by a nonzero exist and causes installation to fail. If there is an error, conda does not write any package metadata.
#
# pre-unlink---Executed before the package is removed. An error is indicated by a nonzero exist and causes the removal to fail.
#


exit 0
