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
docker pull node:12.22.3-stretch
docker build --pull -f Dockerfile.zlux --no-cache --progress=plain -t zowe-docker-snapshot.jfrog.io/ompzowe/app-server:testing . 2>&1 | tee logs/docker-build.log