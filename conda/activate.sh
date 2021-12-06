#!/bin/sh

# This program and the accompanying materials are
# made available under the terms of the Eclipse Public License v2.0 which accompanies
# this distribution, and is available at https://www.eclipse.org/legal/epl-v20.html
# 
# SPDX-License-Identifier: EPL-2.0
# 
# Copyright Contributors to the Zowe Project.


if [ -d "${ZOWE_ROOT_DIR}/components/app-server" ]
then
  ZOWE_ROOT=$ZOWE_ROOT_DIR
elif [ -d "${ROOT_DIR}/components/app-server" ]
then
  ZOWE_ROOT=$ROOT_DIR
fi
        

if [ -e "${ZOWE_WORKSPACE_DIR}/../bin/install-app.sh" ]
then
  ZOWE_INST=${ZOWE_WORKSPACE_DIR}/../
elif [ -e "${ZOWE_INSTANCE_DIR}/bin/install-app.sh" ]
then
  ZOWE_INST=${ZOWE_INSTANCE_DIR}
elif [ -e "${WORKSPACE_DIR}/../bin/install-app.sh" ]
then
  ZOWE_INST=${WORKSPACE_DIR}/../
elif [ -e "${INSTANCE_DIR}/bin/install-app.sh" ]
then
  ZOWE_INST=${INSTANCE_DIR}
fi

if [ -z "$ZOWE_INST" ]
then
  if [ -d "$ZOWE_ROOT" ]
  then
    ${ZOWE_ROOT}/components/app-server/share/zlux-app-server/bin/install-app.sh $PREFIX/opt/zowe/plugins/app-server/$PKG_NAME
  fi
else
  ${ZOWE_INST}/bin/install-app.sh $PREFIX/opt/zowe/plugins/app-server/$PKG_NAME
fi
