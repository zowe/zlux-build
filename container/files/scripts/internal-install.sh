#!/bin/bash

cp ${INSTALL_DIR}/files/zlux/config/pinnedPlugins.json ${ZLUX_APP_SERVER}/defaults/ZLUX/pluginStorage/org.zowe.zlux.ng2desktop/ui/launchbar/plugins/ 
cp ${INSTALL_DIR}/files/zlux/config/allowedPlugins.json ${ZLUX_APP_SERVER}/defaults/ZLUX/pluginStorage/org.zowe.zlux.bootstrap/plugins/ 
cp ${INSTALL_DIR}/files/zlux/config/zluxserver.json ${ZLUX_APP_SERVER}/defaults/serverConfig/server.json 
cp -r ${INSTALL_DIR}/files/zlux/config/plugins/* ${ZLUX_APP_SERVER}/defaults/plugins