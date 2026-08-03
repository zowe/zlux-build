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
read -r PACKAGES URLS <<<$(echo "$output" | sed "s/;/ /g")
PACKAGES=($(echo "$PACKAGES" | sed "s/,/ /g"))
URLS=($(echo "$URLS" | sed "s/,/ /g"))

for i in "${!URLS[@]}";
do
  echo url "${URLS[i]}"
  curl -fSL "${URLS[i]}" -o "files/zlux/${PACKAGES[i]}.tar" && echo "${PACKAGES[i]} downloaded" &
done
wait

# Verify checksums via Artifactory REST API (checksums are stored for every artifact)
for i in "${!PACKAGES[@]}"; do
  TARBALL="files/zlux/${PACKAGES[i]}.tar"
  # Convert download URL to Artifactory storage API URL for checksum lookup
  API_URL=$(echo "${URLS[i]}" | sed "s|${ZOWE_REPOSITORY}/|${ZOWE_REPOSITORY}/api/storage/|")
  EXPECTED=$(curl -fSL "$API_URL" 2>/dev/null | node -e "
    let d=''; process.stdin.on('data',c=>d+=c); process.stdin.on('end',()=>{
      try { console.log(JSON.parse(d).checksums.sha256); }
      catch(e) { process.exit(1); }
    });" 2>/dev/null)
  if [[ -n "$EXPECTED" ]]; then
    ACTUAL=$(sha256sum "$TARBALL" | awk '{print $1}')
    if [ "$EXPECTED" != "$ACTUAL" ]; then
      echo "ERROR: Checksum mismatch for ${PACKAGES[i]}. Expected: $EXPECTED, Got: $ACTUAL"
      exit 1
    fi
    echo "Checksum verified for ${PACKAGES[i]}"
  else
    echo "WARNING: Could not retrieve checksum from Artifactory API for ${PACKAGES[i]}, skipping verification"
  fi
done

mv files/zlux/zlux-core.tar files/zlux-core.tar
