#!/bin/bash

set -e

./pull-zowe-install-artifacts.sh
./download-zlux.sh
./build.sh
./start.sh