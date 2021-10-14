#!/bin/bash

#########################################################################################
#                                                                                       #
# This program and the accompanying materials are made available under the terms of the #
# Eclipse Public License v2.0 which accompanies this distribution, and is available at  #
# https://www.eclipse.org/legal/epl-v20.html                                            #
#                                                                                       #
# SPDX-License-Identifier: EPL-2.0                                                      #
#                                                                                       #
# Copyright IBM Corporation 2021                                                        #
#                                                                                       #
#########################################################################################

if [ -z "$ZLUX_BRANCH" ]; then
	echo " Default branch will be staging, to change branch please set environment ZLUX_BRANCH. Set with for example export ZLUX_BRANCH=..."
	export ZLUX_BRANCH="staging"
fi

set -e

# refresh
rm -rf files/zlux 2>/dev/null
rm -rf files/zowe-install-packaging 2>/dev/null
mkdir -p files/zlux

# clone zowe-install-packaging - copy manifest, files/zlux/config
git clone --branch "$ZLUX_BRANCH" https://github.com/zowe/zowe-install-packaging  files/zowe-install-packaging

# copy manifest to files
mv files/zowe-install-packaging/manifest.json.template files/manifest.json

#cp files/zowe-install-packaging/manifest.json.template files/manifest.json
mv files/zowe-install-packaging/files/zlux/config files/zlux/config
# clear zowe-install-packaging
rm -rf files/zowe-install-packaging
