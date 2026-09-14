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

mkdir -p logs
if [ -n "$ZOWE_BASE_IMAGE_DIGEST" ]; then
  ZOWE_BASE_IMAGE_REFERENCE="zowe-docker-release.jfrog.io/ompzowe/base-node@${ZOWE_BASE_IMAGE_DIGEST}"
  docker pull "$ZOWE_BASE_IMAGE_REFERENCE"
  docker build --pull -f Dockerfile.zlux --no-cache --progress=plain --build-arg ZOWE_BASE_IMAGE_REFERENCE="$ZOWE_BASE_IMAGE_REFERENCE" -t zowe-docker-snapshot.jfrog.io/ompzowe/app-server:testing . 2>&1 | tee logs/docker-build.log
else
  docker pull zowe-docker-release.jfrog.io/ompzowe/base-node:$ZOWE_BASE_IMAGE
  docker build --pull -f Dockerfile.zlux --no-cache --progress=plain --build-arg ZOWE_BASE_IMAGE=$ZOWE_BASE_IMAGE -t zowe-docker-snapshot.jfrog.io/ompzowe/app-server:testing . 2>&1 | tee logs/docker-build.log
fi

