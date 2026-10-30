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

CURL_OPTS=(-fSL --proto '=https' --proto-redir '=https' --tlsv1.2)

PIDS=()
for i in "${!URLS[@]}";
do
  echo url "${URLS[i]}"
  curl "${CURL_OPTS[@]}" "${URLS[i]}" -o "files/zlux/${PACKAGES[i]}.tar" && echo "${PACKAGES[i]} downloaded" &
  PIDS+=($!)
done
# a bare 'wait' ignores the exit status of background jobs, so a failed download would go unnoticed
for pid in "${PIDS[@]}"; do
  wait "$pid" || { echo "ERROR: download failed" >&2; exit 1; }
done

# Verify checksums via Artifactory REST API (checksums are stored for every artifact)
for i in "${!PACKAGES[@]}"; do
  TARBALL="files/zlux/${PACKAGES[i]}.tar"
  # Convert download URL to Artifactory storage API URL for checksum lookup
  API_URL=$(echo "${URLS[i]}" | sed "s|${ZOWE_REPOSITORY}/|${ZOWE_REPOSITORY}/api/storage/|")
  EXPECTED=$(curl "${CURL_OPTS[@]}" "$API_URL" 2>/dev/null | node -e "
    let d=''; process.stdin.on('data',c=>d+=c); process.stdin.on('end',()=>{
      try { console.log(JSON.parse(d).checksums.sha256); }
      catch(e) { process.exit(1); }
    });" 2>/dev/null) || EXPECTED=""
  if [[ -n "$EXPECTED" ]]; then
    ACTUAL=$(sha256sum "$TARBALL" | awk '{print $1}')
    if [ "$EXPECTED" != "$ACTUAL" ]; then
      echo "ERROR: Checksum mismatch for ${PACKAGES[i]}. Expected: $EXPECTED, Got: $ACTUAL"
      exit 1
    fi
    echo "Checksum verified for ${PACKAGES[i]}"
  else
    echo "ERROR: Could not retrieve checksum from Artifactory API for ${PACKAGES[i]}, refusing to use an unverified artifact" >&2
    exit 1
  fi
done

mv files/zlux/zlux-core.tar files/zlux-core.tar
