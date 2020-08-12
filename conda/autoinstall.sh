#!/bin/sh

if [ -e "${INSTANCE_DIR}/bin/install-app.sh" ]; then
    ${INSTANCE_DIR}/bin/install-app.sh $APP_PLUGIN_DIR >> $PREFIX/.messages.txt
elif [ -e "${ZLUX_ROOT}/zlux-app-server/bin/install-app.sh" ]; then
    if [ -n ${INSTANCE_DIR} ]; then
        ${ZLUX_ROOT}/zlux-app-server/bin/install-app.sh $APP_PLUGIN_DIR >> $PREFIX/.messages.txt
    else
        echo "${PKG_NAME} not registered to Zowe because no instance found. To manually install, run INSTANCE_DIR/bin/install-app.sh $APP_PLUGIN_DIR" >> ${PREFIX}/.messages.txt
    fi
fi
