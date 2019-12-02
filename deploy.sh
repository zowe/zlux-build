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

if [ -n WORKSPACE_DIR ]
then
  zlux_instance_dir=$WORKSPACE_DIR/app-server
  zlux_site_dir=$WORKSPACE_DIR/app-server/site
elif [ -n INSTANCE_DIR ]
then
  zlux_instance_dir=$INSTANCE_DIR/workspace/app-server
  zlux_site_dir=$INSTANCE_DIR/workspace/app-server/site
else
  zlux_instance_dir=../zlux-app-server/deploy/instance
  zlux_site_dir=../zlux-app-server/deploy/site
fi

zlux_users_dir=$zlux_instance_dir/users
zlux_groups_dir=$zlux_instance_dir/groups  
  
mkdir -p ../zlux-app-server/defaults/plugins
mkdir -p ../zlux-app-server/defaults/ZLUX/pluginStorage
mkdir -p ../zlux-app-server/defaults/serverConfig

mkdir -p $zlux_site_dir/plugins
mkdir -p $zlux_site_dir/ZLUX/pluginStorage
mkdir -p $zlux_site_dir/serverConfig

mkdir -p $zlux_instance_dir/plugins
mkdir -p $zlux_instance_dir/ZLUX/pluginStorage
mkdir -p $zlux_instance_dir/serverConfig

mkdir -p $zlux_users_dir/ZLUX/pluginStorage
mkdir -p $zlux_groups_dir/ZLUX/pluginStorage

cp -vr ../zlux-app-server/defaults/* $zlux_instance_dir/serverConfig
cp -vr ../zlux-app-server/defaults/ZLUX/pluginStorage/* $zlux_instance_dir/ZLUX/pluginStorage
# This program and the accompanying materials are
# made available under the terms of the Eclipse Public License v2.0 which accompanies
# this distribution, and is available at https://www.eclipse.org/legal/epl-v20.html
# 
# SPDX-License-Identifier: EPL-2.0
# 
# Copyright Contributors to the Zowe Project.
