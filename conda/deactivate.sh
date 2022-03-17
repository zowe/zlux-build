#!/bin/sh

# This program and the accompanying materials are
# made available under the terms of the Eclipse Public License v2.0 which accompanies
# this distribution, and is available at https://www.eclipse.org/legal/epl-v20.html
# 
# SPDX-License-Identifier: EPL-2.0
# 
# Copyright Contributors to the Zowe Project.

if [ -d "${ZOWE_WORKSPACE_DIR}/app-server/ZLUX" ]
then
  ZOWE_INST=${ZOWE_WORKSPACE_DIR}/../
elif [ -e "${ZOWE_INSTANCE_DIR}/workspace/app-server/ZLUX" ]
then
  ZOWE_INST=${ZOWE_INSTANCE_DIR}
elif [ -e "${WORKSPACE_DIR}/app-server/ZLUX" ]
then
  ZOWE_INST=${WORKSPACE_DIR}/../
elif [ -e "${INSTANCE_DIR}/workspace/app-server/ZLUX" ]
then
  ZOWE_INST=${INSTANCE_DIR}
fi

if [ -e "${ZOWE_INST}/workspace/app-server/plugins/${PKG_NAME}.json" ]
then
  location=$PREFIX/opt/zowe/plugins/app-server/$PKG_NAME
  node -e "const fs=require('fs'); const content=require('${ZOWE_INST}/workspace/app-server/plugins/${PKG_NAME}.json'); if (content.pluginLocation == '${location}') { fs.unlinkSync('${ZOWE_INST}/workspace/app-server/plugins/${PKG_NAME.json}'); }"
fi
