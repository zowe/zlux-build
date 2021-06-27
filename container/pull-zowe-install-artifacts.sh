#!/bin/bash
set -e

mkdir -p files/zlux
git clone https://github.com/zowe/zowe-install-packaging files/zowe-install-packaging
cp files/zowe-install-packaging/manifest.json.template files/manifest.json
mv files/zowe-install-packaging/files/zlux/config files/zlux/config
rm -rf files/zowe-install-packaging