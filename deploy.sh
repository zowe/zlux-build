#!/bin/sh
# This program and the accompanying materials are
# made available under the terms of the Eclipse Public License v2.0 which accompanies
# this distribution, and is available at https://www.eclipse.org/legal/epl-v20.html
# 
# SPDX-License-Identifier: EPL-2.0
# 
# Copyright Contributors to the Zowe Project.

# Create deploy directories, out of which the server runs. 
# the heirarchy of the configuration is, from broadest to narrowest scope
# product
# site
# instance
# |--  group
# |--  user
#
# group and user are members of an instance, of which there can be more than one per site
# but the product folder is meant to be read-only defaults that Rocket ships.
#
# within each scope, the structure of the folder should contain the PRODUCT, such as MVD
# although the design accomodates for multiple products.
#
# Within a product, there exists 3 subdirectories
# plugins - includes a plugins for the server, by having this folder contain a collection of jsons 
#           which specify the location of each plugin
#
# pluginStorage - the folder for which any user data, preferences, configuration may be stored, accessible over a network
#
# serverConfig - the folder for storing information that the server needs at startup, such as a json describing
#                the port to use, or other files for security certificates

# Don't do permission changes in this script because final changes such as these happen after this script is executed
# Such as, currently in zowe-runtime-authorize.sh

rm -rf ../zlux-app-server/deploy/product/ZLUX/plugins
rm -rf ../zlux-app-server/deploy/site/ZLUX/plugins
rm -rf ../zlux-app-server/deploy/instance/ZLUX/plugins

mkdir -p ../zlux-app-server/deploy/product
mkdir -p ../zlux-app-server/deploy/product/ZLUX
mkdir -p ../zlux-app-server/deploy/product/ZLUX/plugins
mkdir -p ../zlux-app-server/deploy/product/ZLUX/pluginStorage
mkdir -p ../zlux-app-server/deploy/product/ZLUX/serverConfig

mkdir -p ../zlux-app-server/deploy/site
mkdir -p ../zlux-app-server/deploy/site/ZLUX
mkdir -p ../zlux-app-server/deploy/site/ZLUX/plugins
mkdir -p ../zlux-app-server/deploy/site/ZLUX/pluginStorage
mkdir -p ../zlux-app-server/deploy/site/ZLUX/serverConfig

mkdir -p ../zlux-app-server/deploy/instance
mkdir -p ../zlux-app-server/deploy/instance/ZLUX
mkdir -p ../zlux-app-server/deploy/instance/ZLUX/plugins
mkdir -p ../zlux-app-server/deploy/instance/ZLUX/pluginStorage
mkdir -p ../zlux-app-server/deploy/instance/ZLUX/serverConfig

mkdir -p ../zlux-app-server/deploy/instance/users
mkdir -p ../zlux-app-server/deploy/instance/groups

# MVD bootstrap
cp -vr ../zlux-app-server/config/* ../zlux-app-server/deploy/product/ZLUX/serverConfig
cp -vr ../zlux-app-server/plugins/*.json ../zlux-app-server/deploy/product/ZLUX/plugins
cp -v ../zlux-app-server/plugins/*.json ../zlux-app-server/deploy/instance/ZLUX/plugins

cp -vr ../zlux-app-server/config/zluxserver.json ../zlux-app-server/deploy/instance/ZLUX/serverConfig
cp -vr ../zlux-app-server/config/zlux.keystore.key ../zlux-app-server/deploy/instance/ZLUX/serverConfig
cp -vr ../zlux-app-server/config/zlux.keystore.cer ../zlux-app-server/deploy/instance/ZLUX/serverConfig
cp -vr ../zlux-app-server/config/apiml-localca.cer ../zlux-app-server/deploy/instance/ZLUX/serverConfig

cp -vr ../zlux-app-server/pluginDefaults/* ../zlux-app-server/deploy/instance/ZLUX/pluginStorage

mkdir -p ../zlux-app-server/deploy/instance/ZLUX/pluginStorage/org.zowe.terminal.tn3270
mkdir -p ../zlux-app-server/deploy/instance/ZLUX/pluginStorage/org.zowe.terminal.tn3270/sessions
cp -v ../tn3270-ng2/_defaultTN3270.json ../zlux-app-server/deploy/instance/ZLUX/pluginStorage/org.zowe.terminal.tn3270/sessions/_defaultTN3270.json

mkdir -p ../zlux-app-server/deploy/instance/ZLUX/pluginStorage/org.zowe.terminal.vt
mkdir -p ../zlux-app-server/deploy/instance/ZLUX/pluginStorage/org.zowe.terminal.vt/sessions
cp -v ../vt-ng2/_defaultVT.json ../zlux-app-server/deploy/instance/ZLUX/pluginStorage/org.zowe.terminal.vt/sessions/_defaultVT.json
# This program and the accompanying materials are
# made available under the terms of the Eclipse Public License v2.0 which accompanies
# this distribution, and is available at https://www.eclipse.org/legal/epl-v20.html
# 
# SPDX-License-Identifier: EPL-2.0
# 
# Copyright Contributors to the Zowe Project.
