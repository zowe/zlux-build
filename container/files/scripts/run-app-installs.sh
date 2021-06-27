#!/bin/bash

if [ -d "${apps_dir}" ]; then
  export ZLUX_ROOT=/home/zowe/install/components/app-server/share
  cd ${apps_dir}
  for D in */;
   do
    if test -f "$D/autoinstall.sh"; then
      app=$(cd $D && pwd)
      ZLUX_ROOT=$ZLUX_ROOT APP_PLUGIN_DIR=app ./$D/autoinstall.sh
    elif test -f "$D/pluginDefinition.json"; then
        $INSTANCE_DIR/bin/install-app.sh ${apps_dir}/$D
    elif test -f "$D/manifest.yaml"; then
        $ROOT_DIR/bin/zowe-install-component.sh -o ${apps_dir}/$D -i $INSTANCE_DIR
    elif test -f "$D/manifest.yml"; then
        $ROOT_DIR/bin/zowe-install-component.sh -o ${apps_dir}/$D -i $INSTANCE_DIR
    elif test -f "$D/manifest.json"; then
        $ROOT_DIR/bin/zowe-install-component.sh -o ${apps_dir}/$D -i $INSTANCE_DIR
    fi
  done
fi