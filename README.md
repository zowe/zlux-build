This program and the accompanying materials are
made available under the terms of the Eclipse Public License v2.0 which accompanies
this distribution, and is available at https://www.eclipse.org/legal/epl-v20.html

SPDX-License-Identifier: EPL-2.0

Copyright Contributors to the Zowe Project.

# zlux-build

This repository includes build scripts used for building Zowe App Framework code, and a build pipeline for building Zowe App Framework with multiple pull requests.

- [Build Scripts](#build-scripts)
  - [Entry Points](#entry-points)
  - [Script Reference](#script-reference)
  - [Targets](#targets)
  - [Plugin Build Hooks](#plugin-build-hooks)
  - [Configuration](#configuration)
  - [Options](#options)
- [Build Pipeline](#build-pipeline)
- [Copyright](#copyright)

## Build Scripts

**To request features or report bugs, please use the issues page at the [zlux repo](https://github.com/zowe/zlux/issues) with the CI/CD tag**

The build system requires Node.js and npm. No Java or Apache Ant dependency is needed.

Scripts are provided in three flavours depending on your platform:

| Platform | Location | Extension |
|---|---|---|
| Linux / macOS / z/OS (bash) | `scripts/bash/` | `.sh` |
| macOS / z/OS (zsh) | `scripts/zsh/` | `.zsh` |
| Windows (PowerShell) | `scripts/powershell/` | `.ps1` |

### Entry Points

Convenience entry points are provided at the root of the repository that delegate to the appropriate script directory:

- **`build.sh`** — bash entry point (Linux, macOS, z/OS)
- **`build.zsh`** — zsh entry point (macOS, z/OS)
- **`build.ps1`** — PowerShell entry point (Windows)
- **`build.bat`** — batch wrapper that invokes `build.ps1` via PowerShell (Windows cmd.exe)

### Script Reference

Each flavour contains the same set of scripts:

| Script | Description |
|---|---|
| `common.sh` / `common.zsh` / `common.ps1` | Shared helper functions (npm wrappers, plugin traversal, OS detection) |
| `build.sh` / `.zsh` / `.ps1` | Main dispatcher — delegates to other scripts based on the target |
| `build_ng2.sh` / `.zsh` / `.ps1` | Builds Angular components (platform, bootstrap, desktop, plugins, shared modules) |
| `deploy.sh` / `.zsh` / `.ps1` | Populates deploy/instance directories with plugin definitions and server config |
| `production.sh` / `.zsh` / `.ps1` | Creates a production distribution (copies sources to `dist/`, replaces version tokens, builds) |
| `testing.sh` / `.zsh` / `.ps1` | Creates a testing distribution (same as production but also runs deploy) |
| `copy_node.sh` / `.zsh` / `.ps1` | Copies `nodeServer/node_modules` into `lib/node_modules` |
| `audit.sh` / `.zsh` / `.ps1` | Runs `npm audit` across all plugins and writes reports to `artifacts/audit/` |

### Targets

When run with no arguments from an interactive terminal all entry-point scripts display a numbered menu and prompt you to choose a target:

```
zlux-build — available targets:
-----------------------------------
   1) buildAll            Run deploy then build (default)
   2) build               Build all ng2/Angular components
   3) bootstrapBuild      Build only server framework and bootstrap
   ...
Enter target number or name [1 = buildAll]:
```

You can type the number (e.g. `2`) or the target name directly. When stdin is not a terminal (e.g. in CI) the scripts fall back to `buildAll` silently.

When a target is supplied directly no prompt is shown. Available targets:

| Target | Description |
|---|---|
| `buildAll` | Run deploy then build (default) |
| `build` | Build all ng2/Angular components |
| `bootstrapBuild` | Build only the server framework and bootstrap components |
| `deploy` | Deploy plugin definitions and server config to the instance directory |
| `cleanDeploy` | Remove the instance and site deploy directories |
| `devClean` | Remove only the instance plugins and user/group data |
| `production` | Build a production distribution into `../dist/` |
| `testing` | Build a testing distribution (deploy + build) into `../dist/` |
| `getVersion` | Write the current version string to `fullVersion.properties` |
| `audit` | Run `npm audit` on all plugins |
| `removeSource` | Remove source files not needed for production (TypeScript, node_modules, etc.) |
| `help` | List available targets |

**bash usage:**
```sh
bash build.sh [target]
# e.g.
bash build.sh buildAll
bash build.sh deploy
```

**zsh usage:**
```zsh
zsh build.zsh [target]
# e.g.
zsh build.zsh buildAll
zsh build.zsh deploy
```

**PowerShell usage:**
```powershell
.\build.ps1 [-Target <target>]
# e.g.
.\build.ps1 -Target buildAll
.\build.ps1 -Target deploy
```

### Plugin Build Hooks

The default behavior for a plugin is to navigate to its home directory (as defined by the `pluginLocation` field in its `pluginDefinition.json`) and run `npm install` followed by `npm run build`.

This can be overridden by adding a `build/build.sh` (or `build.zsh` / `build.ps1`) script to the plugin's home directory. If a `deploy` target is implemented in that script it will be invoked during the deploy step, which is useful for adding plugin-specific configuration files. If a `build` target is implemented it will be called instead of the default `npm install` + `npm run build`.

### Configuration

The plugin directory is defined in `common.properties`:

```properties
plugins=../zlux-app-server/defaults/plugins
```

This directory contains the JSON plugin definition files that list all plugins to be deployed and built.

Version information is stored in `version.properties`:

```properties
PRODUCT_MAJOR_VERSION=0
PRODUCT_MINOR_VERSION=8
PRODUCT_REVISION=4
```

### Options

Setting the `NO_INSTALL` environment variable skips `npm install` and runs only `npm run build`. This is useful when `node_modules` are already present and you want to reduce build time.

```sh
NO_INSTALL=1 bash build.sh build
```

```powershell
$env:NO_INSTALL = "1"
.\build.ps1 -Target build
```

## Build Pipeline

To build zlux-core with multiple pull requests, edit the workflow inputs in `.github/workflows/build-core.yml`. There is a `workflow_dispatch` trigger with inputs for each repository's PR number. Leave a value empty to use the default branch (`v3.x/staging`).

## Copyright

This program and the accompanying materials are
made available under the terms of the Eclipse Public License v2.0 which accompanies
this distribution, and is available at https://www.eclipse.org/legal/epl-v20.html

SPDX-License-Identifier: EPL-2.0

Copyright Contributors to the Zowe Project.
