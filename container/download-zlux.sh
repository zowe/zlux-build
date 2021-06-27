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

ZOWE_REPOSITORY=https://zowe.jfrog.io/artifactory

output=$(node getPackagePaths.js)
read -r PACKAGES URLS <<<$(echo $output | sed "s/;/ /g")
PACKAGES=($(echo $PACKAGES | sed "s/,/ /g"))
URLS=($(echo $URLS | sed "s/,/ /g"))

for i in "${!URLS[@]}";
do
  # echo package zlux/"${PACKAGES[i]}".tar
  echo url "${URLS[i]}"
  curl -s "${URLS[i]}" -o files/zlux/"${PACKAGES[i]}".tar && echo "${PACKAGES[i]} done" &
done
wait

mv files/zlux/zlux-core.tar files/zlux-core.tar