This program and the accompanying materials are
made available under the terms of the Eclipse Public License v2.0 which accompanies
this distribution, and is available at https://www.eclipse.org/legal/epl-v20.html

SPDX-License-Identifier: EPL-2.0

Copyright Contributors to the Zowe Project.

# zlux-build
Repository for build scripts used for ease of building Zowe App Framework code as well as Apps that rely upon it.

**To request features or report bugs, please use the issues page at the [zlux repo](https://github.com/zowe/zlux/issues) with the CI/CD tag**

These scripts require at least version 1.9.1 of Apache Ant. ant-contrib is also required.

Use 'ant help' to get list of targets accessible from this directory

The script has two primary parts: deploy and build. Deploy populates the deploy directory under zlux-app-server. Build will build the source of the file so it can be used within the brower

The default behavior for a plugin is to navigate to its home directory, as defined by the directory given in its _pluginDefinition.json_ file, and then run _npm install_ and _npm run build_. This can be altered by adding a build/build.xml file to the plugin's home directory. Having a _deploy_ target in this file will cause it to be run during the deploy step. This is useful for adding plugin-specific configuration files. If there is a _build_ target in this file, it will be run instead of _npm install_ and _npm run build_. You can still call those functions within the _build_ target, but you can use ant to do whatever other build steps need to be done

The build requires a plugin directory which is defined in _common.properties_. This directory lists all the plugins that will be deployed and built.

There is an optional value to pass to the build task: 'noInstall'
noInstall does not run 'npm install', only 'npm run build'. If node modules are already installed, this will cut down the install time in about half.

This flag is set in the following manner: -D [flag]=[value]
The script logic only looks for the two option flags to be set, the value does not matter.

This program and the accompanying materials are
made available under the terms of the Eclipse Public License v2.0 which accompanies
this distribution, and is available at https://www.eclipse.org/legal/epl-v20.html

SPDX-License-Identifier: EPL-2.0

Copyright Contributors to the Zowe Project.
