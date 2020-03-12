#!/bin/sh

# This program and the accompanying materials are
# made available under the terms of the Eclipse Public License v2.0 which accompanies
# this distribution, and is available at https://www.eclipse.org/legal/epl-v20.html
# 
# SPDX-License-Identifier: EPL-2.0
# 
# Copyright Contributors to the Zowe Project.

mkdir -p $PREFIX/share/zowe/app-server/plugins/$PKG_NAME/$PKG_VERSION
cp -r ${SRC_DIR}/* $PREFIX/share/zowe/app-server/plugins/$PKG_NAME/$PKG_VERSION
mkdir -p $PREFIX/share/zowe/app-server/zlux-app-server/defaults/plugins
echo "{\"identifier\":\"${PKG_NAME}\",\"pluginLocation\":\"${PREFIX}/share/zowe/app-server/plugins/${PKG_NAME}/${PKG_VERSION}\"}" \
     > $PREFIX/share/zowe/app-server/zlux-app-server/defaults/plugins/${PKG_NAME}.json

cd $PREFIX/share/zowe/app-server/plugins/$PKG_NAME/$PKG_VERSION
rm -f build_env_setup.sh conda_build.sh metadata_conda_debug.yaml *.ppf

exit 0
