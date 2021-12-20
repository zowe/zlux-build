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

set -e

if [ -z "${ZLUX_DOWNLOAD_API_TOKEN}" ]; then
  echo "*** WARNING: This will not download patterned URLs without environment variable ZLUX_DOWNLOAD_API_TOKEN. Set with for example export ZLUX_DOWNLOAD_API_TOKEN=... ***"
fi

./pull-zowe-install-artifacts.sh
./download-zlux.sh
./build.sh
./start.sh
