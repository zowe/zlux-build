#!/bin/sh

# This program and the accompanying materials are
# made available under the terms of the Eclipse Public License v2.0 which accompanies
# this distribution, and is available at https://www.eclipse.org/legal/epl-v20.html
# 
# SPDX-License-Identifier: EPL-2.0
# 
# Copyright Contributors to the Zowe Project.


if [ -e "${INSTANCE_DIR}/bin/install-app.sh" ]; then
    # TODO reconsider if this is safe or will cause end-user confusion when configuration is required
    ${INSTANCE_DIR}/bin/install-app.sh $APP_PLUGIN_DIR >> $PREFIX/.messages.txt
elif [ -e "${ZLUX_ROOT}/zlux-app-server/bin/install-app.sh" ]; then
    if [ -n ${INSTANCE_DIR} ]; then
        ${ZLUX_ROOT}/zlux-app-server/bin/install-app.sh $APP_PLUGIN_DIR >> $PREFIX/.messages.txt
    else
        echo "${PKG_NAME} not registered to Zowe because no instance found. To manually install, run INSTANCE_DIR/bin/install-app.sh $APP_PLUGIN_DIR" >> ${PREFIX}/.messages.txt
    fi
fi
