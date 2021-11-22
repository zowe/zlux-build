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

mkdir -p "${PREFIX}/etc/conda/activate.d"
mkdir -p "${PREFIX}/etc/conda/deactivate.d"
cp "${RECIPE_DIR}/activate.sh" "${PREFIX}/etc/conda/activate.d/${PKG_NAME}_activate.sh"
cp "${RECIPE_DIR}/activate.bat" "${PREFIX}/etc/conda/activate.d/${PKG_NAME}_activate.bat"
cp "${RECIPE_DIR}/deactivate.sh" "${PREFIX}/etc/conda/deactivate.d/${PKG_NAME}_deactivate.sh"
cp "${RECIPE_DIR}/deactivate.bat" "${PREFIX}/etc/conda/deactivate.d/${PKG_NAME}_deactivate.bat"

exit 0
