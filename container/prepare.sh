#!/bin/bash

################################################################################
# This program and the accompanying materials are made available under the terms of the
# Eclipse Public License v2.0 which accompanies this distribution, and is available at
# https://www.eclipse.org/legal/epl-v20.html
#
# SPDX-License-Identifier: EPL-2.0
#
# Copyright Contributors to the Zowe Project.
################################################################################

################################################################################
# prepare docker build context
#
# This script will be executed with 2 parameters:
# - linux-distro
# - cpu-arch

################################################################################
# This script prepares all required files we plan to put into zowe-launch-scripts
# image.
#
# Prereqs:
# - must run with Github Actions (with GITHUB_RUN_NUMBER and GITHUB_SHA)
# - must provide $GITHUB_PR_ID is it's pull request
# - jq

# exit if there are errors
set -e

###############################
# check parameters
linux_distro=$1
cpu_arch=$2
if [ -z "${linux_distro}" ]; then
  echo "Error: linux-distro parameter is missing."
  exit 1
fi
if [ -z "${cpu_arch}" ]; then
  echo "Error: cpu-arch parameter is missing."
  exit 1
fi

################################################################################
# CONSTANTS
# this should be containers/zowe-launch-scripts
BASE_DIR=$(cd $(dirname $0);pwd)
REPO_ROOT_DIR=$(cd $(dirname $0)/../;pwd)
WORK_DIR=tmp
UNTAR_DIR=untar
JFROG_REPO_SNAPSHOT=libs-snapshot-local
JFROG_REPO_RELEASE=libs-release-local
JFROG_URL=https://zowe.jfrog.io/zowe/

###############################
echo ">>>>> clean up folder"
rm -fr "${BASE_DIR}/${WORK_DIR}"
mkdir -p "${BASE_DIR}/${WORK_DIR}"

###############################
# Download zlux
echo ">>>> prepare zlux"
cd "${BASE_DIR}"
chmod +x *.sh
if [ ! -f pull-zowe-install-artifacts.sh ]; then
  echo "Error: pull-zowe-install-artifacts script is missing."
  exit 3
fi
if [ ! -f download-zlux.sh ]; then
  echo "Error: download-zlux script is missing."
  exit 4
fi
./pull-zowe-install-artifacts.sh
./download-zlux.sh

###############################
# untar zlux-core and copy package.json,manifest.yaml
echo ">>>>> create tmp folder to extract tar"
rm -fr "${BASE_DIR}/${UNTAR_DIR}"
mkdir -p "${BASE_DIR}/${UNTAR_DIR}"
cd "${BASE_DIR}/${UNTAR_DIR}"
tar -xvf ../zlux-core.tar
cp zlux-app-server/manifest.yaml "${REPO_ROOT_DIR}"
cp zlux-app-server/package.json "${REPO_ROOT_DIR}"
rm -fr "${BASE_DIR}/${UNTAR_DIR}"

###############################
echo ">>>>> prepare basic files"
cd "${REPO_ROOT_DIR}"
package_version=$(jq -r '.version' package.json)
package_release=$(echo "${package_version}" | awk -F. '{print $1;}')

###############################
# copy Dockerfile
echo ">>>>> copy Dockerfile to ${linux_distro}/${cpu_arch}/Dockerfile"
cd "${BASE_DIR}"
mkdir -p "${linux_distro}/${cpu_arch}"
if [ ! -f Dockerfile.zlux ]; then
  echo "Error: Dockerfile file is missing."
  exit 2
fi
cat Dockerfile.zlux | sed -e "s#version=\"0\.0\.0\"#version=\"${package_version}\"#" -e "s#release=\"0\"#release=\"${package_release}\"#" > "${linux_distro}/${cpu_arch}/Dockerfile"


###############################
echo ">>>>> prepare basic files"
cd "${REPO_ROOT_DIR}"
cp README.md "${BASE_DIR}/${WORK_DIR}"
cp LICENSE "${BASE_DIR}/${WORK_DIR}"
cp package.json "${BASE_DIR}/${WORK_DIR}"
mv "${BASE_DIR}/files" "${BASE_DIR}/${WORK_DIR}"
cd "${BASE_DIR}/${WORK_DIR}"
find .

###############################
echo ">>>>> prepare manifest.json"
cd "${REPO_ROOT_DIR}"
if [ -n "${GITHUB_PR_ID}" ]; then
  GITHUB_BRANCH=PR-${GITHUB_PR_ID}
else
  GITHUB_BRANCH=${GITHUB_REF#refs/heads/}
fi
echo "    - branch: ${GITHUB_BRANCH}"
echo "    - build number: ${GITHUB_RUN_NUMBER}"
echo "    - commit hash: ${GITHUB_SHA}"
# assume to run in Github Actions
cat manifest.yaml | \
  sed -e "s#{{build\.branch}}#${GITHUB_BRANCH}#" \
      -e "s#{{build\.number}}#${GITHUB_RUN_NUMBER}#" \
      -e "s#{{build\.commitHash}}#${GITHUB_SHA}#" \
      -e "s#{{build\.timestamp}}#$(date +%s)#" \
  > "${BASE_DIR}/${WORK_DIR}/manifest.yaml"


 ###############################
# copy to target context
echo ">>>>> copy to target build context"
cp -r "${BASE_DIR}/${WORK_DIR}/." "${BASE_DIR}/${linux_distro}/${cpu_arch}"

###############################
# done
echo ">>>>> all done" 