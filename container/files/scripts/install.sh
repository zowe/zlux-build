#!/bin/bash

# TMP_DIR='..'
# ZLUX_ROOT='../zlux/share'
PLUGINS=(`echo "${INSTALL_DIR}"/files/zlux/*.tar`)

# extract plugins
for p in "${PLUGINS[@]}" ; do
  bn=$(basename -- "$p" .tar)
  mkdir -p "${TMP_DIR}"/zlux/"$bn"
  tar xvf "$p" -C "${TMP_DIR}"/zlux/"$bn"
  mv "${TMP_DIR}"/zlux/"$bn" ${ZLUX_ROOT}
done