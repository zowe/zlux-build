#!/bin/sh

# This program and the accompanying materials are
# made available under the terms of the Eclipse Public License v2.0 which accompanies
# this distribution, and is available at https://www.eclipse.org/legal/epl-v20.html
# 
# SPDX-License-Identifier: EPL-2.0
# 
# Copyright Contributors to the Zowe Project.

# /plugins is a primary location for plugins of a component. Secondarily, /components/componentname/plugins

destination=$PREFIX/opt/zowe/plugins/app-server/$PKG_NAME
mkdir -p $destination
cp -r ${SRC_DIR}/* $destination
cd $destination
rm -f build_env_setup.sh conda_build.sh metadata_conda_debug.yaml *.ppf

#mkdir -p "${PREFIX}/etc/conda/activate.d"
#mkdir -p "${PREFIX}/etc/conda/deactivate.d"
#cp "${RECIPE_DIR}/activate.sh" "${PREFIX}/etc/conda/activate.d/${PKG_NAME}_activate.sh"
#cp "${RECIPE_DIR}/activate.bat" "${PREFIX}/etc/conda/activate.d/${PKG_NAME}_activate.bat"
#cp "${RECIPE_DIR}/deactivate.sh" "${PREFIX}/etc/conda/deactivate.d/${PKG_NAME}_deactivate.sh"
#cp "${RECIPE_DIR}/deactivate.bat" "${PREFIX}/etc/conda/deactivate.d/${PKG_NAME}_deactivate.bat"

#mkdir -p "${PREFIX}/bin"
#cp "${RECIPE_DIR}/post-link.sh" "${PREFIX}/bin/.${PKG_NAME}-post-link.sh"
#cp "${RECIPE_DIR}/pre-unlink.sh" "${PREFIX}/bin/.${PKG_NAME}-pre-unlink.sh"

#
#for CHANGE in "activate" "deactivate"
#do
#    mkdir -p "${PREFIX}/etc/conda/${CHANGE}.d"
#    cp "${RECIPE_DIR}/${CHANGE}.sh" "${PREFIX}/etc/conda/${CHANGE}.d/${PKG_NAME}_${CHANGE}.sh"
#done
#
#
# bin/.<name>-<action>.sh
# bin/.org.zowe.blah-pre-link.sh
#
#
# pre-link---Executed before the package is installed. An error is indicated by a nonzero exit and causes conda to stop and causes the installation to fail.
#
# post-link---Executed after the package is installed. An error is indicated by a nonzero exist and causes installation to fail. If there is an error, conda does not write any package metadata.
#
# pre-unlink---Executed before the package is removed. An error is indicated by a nonzero exist and causes the removal to fail.
#
# PREFIX
# The install prefix.
# PKG_NAME
#
#
# The name of the package.
# PKG_VERSION
# The version of the package.
#
# PKG_BUILDNUM
# The build number of the package.
#



exit 0
