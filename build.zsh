#!/usr/bin/env zsh
# build.zsh - Entry point for zlux-build using zsh.
# Delegates to scripts/zsh/build.zsh.
#
# Usage: zsh build.zsh [target]
# See scripts/zsh/build.zsh for available targets.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v2.0 which accompanies this
# distribution, and is available at https://www.eclipse.org/legal/epl-v20.html
#
# SPDX-License-Identifier: EPL-2.0
#
# Copyright Contributors to the Zowe Project.

SCRIPT_DIR="${0:A:h}"
zsh "${SCRIPT_DIR}/scripts/zsh/build.zsh" "$@"
