#!/bin/sh

if [ -d "${ZOWE_WORKSPACE_DIR}/app-server/ZLUX" ]; then
  ZOWE_INST=${ZOWE_WORKSPACE_DIR}/../
elif [ -e "${ZOWE_INSTANCE_DIR}/workspace/app-server/ZLUX" ]; then
  ZOWE_INST=${ZOWE_INSTANCE_DIR}
elif [ -e "${WORKSPACE_DIR}/app-server/ZLUX" ]; then
  ZOWE_INST=${WORKSPACE_DIR}/../
elif [ -e "${INSTANCE_DIR}/workspace/app-server/ZLUX" ]; then
  ZOWE_INST=${INSTANCE_DIR}
fi

if [ -n "$NODE_HOME" ]
then
  NODE_BIN=${NODE_HOME}/bin/node
else
  NODE_BIN=node
fi

package_location=$PREFIX/opt/zowe/plugins/app-server/$PKG_NAME
json_location=${ZOWE_INST}/workspace/app-server/plugins/${PKG_NAME}.json

if [ -e "${json_location}" ]; then
  _BPXK_AUTOCVT=ON _TAG_REDIR_ERR=txt _TAG_REDIR_IN=txt _TAG_REDIR_OUT=txt __UNTAGGED_READ_MODE=V6 \
  ${NODE_BIN} -e "const fs=require('fs'); const content=require('${json_location}'); if (content.pluginLocation == '${package_location}') { fs.unlinkSync('${json_location}'); }" > $PREFIX/.messages.txt
fi

