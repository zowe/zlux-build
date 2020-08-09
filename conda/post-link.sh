#!/bin/sh

# This program and the accompanying materials are
# made available under the terms of the Eclipse Public License v2.0 which accompanies
# this distribution, and is available at https://www.eclipse.org/legal/epl-v20.html
# 
# SPDX-License-Identifier: EPL-2.0
# 
# Copyright Contributors to the Zowe Project.

echo "Initializing for Zowe install" > $PREFIX/.messages.txt

# Before attempting install of plugin into Zowe, must first gather relevant environment variables
# This is not guaranteed, and will fail if the user has not previously specified the location of Zowe

if [ -n "$ZOWE_ROOT_DIR" ]; then
  if [ -d "${ZOWE_ROOT_DIR}/components/app-server" ]; then
      ZLUX_ROOT=$ZOWE_ROOT_DIR/components/app-server/share
  elif [ -d "${ZOWE_ROOT_DIR}/zlux-app-server" ]; then
      ZLUX_ROOT=$ZOWE_ROOT_DIR
  fi
elif [ -n "$ROOT_DIR" ]; then
  if [ -d "${ROOT_DIR}/components/app-server" ]; then
    ZLUX_ROOT=$ROOT_DIR/components/app-server/share
  elif [ -d "${ROOT_DIR}/zlux-app-server" ]; then
    ZLUX_ROOT=$ROOT_DIR  
  fi
fi

echo "Finding root... ZLUX_ROOT=${ZLUX_ROOT}, ZOWE_ROOT_DIR=${ZOWE_ROOT_DIR}, ROOT_DIR=${ROOT_DIR}" >> $PREFIX/.messages.txt


if [ -e "${ZOWE_WORKSPACE_DIR}/../bin/install-app.sh" ]; then
  ZOWE_INST=${ZOWE_WORKSPACE_DIR}/../
elif [ -d "${ZOWE_WORKSPACE_DIR}/app-server" ]; then
  ZOWE_INST=${ZOWE_WORKSPACE_DIR}/../
elif [ -e "${ZOWE_INSTANCE_DIR}/bin/install-app.sh" ]; then
  ZOWE_INST=${ZOWE_INSTANCE_DIR}
elif [ -d "${ZOWE_INSTANCE_DIR}/workspace/app-server" ]; then
  ZOWE_INST=${ZOWE_INSTANCE_DIR}
elif [ -e "${WORKSPACE_DIR}/../bin/install-app.sh" ]; then
  ZOWE_INST=${WORKSPACE_DIR}/../
elif [ -d "${WORKSPACE_DIR}/app-server" ]; then
  ZOWE_INST=${WORKSPACE_DIR}/../
elif [ -e "${INSTANCE_DIR}/bin/install-app.sh" ]; then
  ZOWE_INST=${INSTANCE_DIR}
elif [ -d "${INSTANCE_DIR}/workspace/app-server" ]; then
    ZOWE_INST=${INSTANCE_DIR}
elif [ -d "${HOME}/.zowe/workspace/app-server" ]; then
    echo "Warning: Using fallback default location for zowe instance of ~/.zowe" >> $PREFIX/.messages.txt
    ZOWE_INST=${HOME}/.zowe
fi

echo "Finding instance... ZOWE_INST=${ZOWE_INST}, ZOWE_INSTANCE_DIR=${ZOWE_INSTANCE_DIR}, INSTANCE_DIR=${INSTANCE_DIR}, ZOWE_WORKSPACE_DIR=${ZOWE_WORKSPACE_DIR}, WORKSPACE_DIR=${WORKSPACE_DIR}" >> $PREFIX/.messages.txt


# Relevant environment variables hopefully exist by this time.
# Here we determing if any automatic actions can be taken, based on what the package contains.

if [ -e "$PREFIX/opt/zowe/plugins/app-server/$PKG_NAME/autoinstall.sh" ]; then
    #autoinstall script exists, try it.
    #Map environment variables in a way that is package manager neutral, in case scripts are reused outside of conda
    INSTANCE_DIR=$ZOWE_INST ZLUX_ROOT=$ZLUX_ROOT APP_PLUGIN_DIR=$PREFIX/opt/zowe/plugins/app-server/$PKG_NAME $PREFIX/opt/zowe/plugins/app-server/$PKG_NAME/autoinstall.sh
elif [ -d "$PREFIX/opt/zowe/plugins/app-server/$PKG_NAME" ]; then
    if [ -e "${ZOWE_INST}/bin/install-app.sh" ]; then
        # TODO reconsider if this is safe or will cause end-user confusion when configuration is required
        ${ZOWE_INST}/bin/install-app.sh $PREFIX/opt/zowe/plugins/app-server/$PKG_NAME >> $PREFIX/.messages.txt
    elif [ -e "${ZLUX_ROOT}/zlux-app-server/bin/install-app.sh" ]; then
        if [ -n ${ZOWE_INST} ]; then
            ${ZLUX_ROOT}/zlux-app-server/bin/install-app.sh $PREFIX/opt/zowe/plugins/app-server/$PKG_NAME >> $PREFIX/.messages.txt
        else
            echo "${PKG_NAME} not registered to Zowe because no instance found. To manually install, run INSTANCE_DIR/bin/install-app.sh $PREFIX/opt/zowe/plugins/app-server/$PKG_NAME" >> ${PREFIX}/.messages.txt
        fi
    fi
fi

# Here: plugins for other components can potentially be auto-installed

# TODO: Print a warning if zos folder seen but not running on zos
