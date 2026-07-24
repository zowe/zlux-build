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
  echo url "${URLS[i]}"
  curl -fSL "${URLS[i]}" -o "files/zlux/${PACKAGES[i]}.tar" && echo "${PACKAGES[i]} downloaded" &
  curl -fSL "${URLS[i]}.sha256" -o "files/zlux/${PACKAGES[i]}.tar.sha256" 2>/dev/null &
done
wait

# Verify checksums for all downloaded artifacts
for i in "${!PACKAGES[@]}"; do
  TARBALL="files/zlux/${PACKAGES[i]}.tar"
  CHECKSUM_FILE="${TARBALL}.sha256"
  if [ -f "$CHECKSUM_FILE" ]; then
    EXPECTED=$(cat "$CHECKSUM_FILE" | tr -d '[:space:]')
    ACTUAL=$(sha256sum "$TARBALL" | awk '{print $1}')
    if [ "$EXPECTED" != "$ACTUAL" ]; then
      echo "ERROR: Checksum mismatch for ${PACKAGES[i]}. Expected: $EXPECTED, Got: $ACTUAL"
      exit 1
    fi
    echo "Checksum verified for ${PACKAGES[i]}"
  else
    echo "WARNING: No .sha256 checksum file available for ${PACKAGES[i]}, skipping verification"
  fi
done

mv files/zlux/zlux-core.tar files/zlux-core.tar