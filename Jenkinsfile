#!groovy

/**
 * This program and the accompanying materials are
 * made available under the terms of the Eclipse Public License v2.0 which accompanies
 * this distribution, and is available at https://www.eclipse.org/legal/epl-v20.html
 *
 * SPDX-License-Identifier: EPL-2.0
 *
 * Copyright Contributors to the Zowe Project.
 */


JENKINS_NODE = "zlux-agent"
GITHUB_PROJECT = "zowe"
GITHUB_TOKEN = "zowe-robot-github"
GITHUB_SSH_KEY = "zlux-jenkins"
RELEASE_BRANCH = "v2.x/rc"
MASTER_BRANCH = "v2.x/master"

REPOS = [

    "zlux-app-manager",
    "zlux-app-server",
    "zlux-build",
    "zlux-platform",
    "zlux-server-framework",
    "zlux-shared",

    "sample-angular-app",
    "sample-iframe-app",
    "sample-react-app",
    "tn3270-ng2",
    "vt-ng2",
    "zlux-editor",

    "zss",
    "zowe-common-c",
]


properties([
    parameters([
        string(
            name: "RELEASE_VERSION",
            defaultValue: "",
            description: "Version of release (vX.X.X)",
            trim: true
        ),
        booleanParam(
            name: "CREATE_RELEASE",
            defaultValue: false,
            description: "Create github release"
        ),
        booleanParam(
            name: "MERGE_TO_MASTER",
            defaultValue: false,
            description: "Merge rc branches to master"
        ),
        booleanParam(
            name: "UPDATE_RC",
            defaultValue: false,
            description: "Merge staging branches to rc"
        ),
        string(
            name: "ZOWE_COMMON_C_HEAD",
            defaultValue: "staging",
            description: "Head of zowe-common-c to merge to RC",
            trim: true
        )
    ])
])


node(JENKINS_NODE) {
    currentBuild.result = "SUCCESS"
    sshagent(credentials: [GITHUB_SSH_KEY]) {

        stage("Make releases") {
            if (params.CREATE_RELEASE) {
                REPOS.each {
                    def tagName = null
                    def name = null
                    if (it == 'zowe-common-c') {
                        tagName = "zss-${params.RELEASE_VERSION}"
                        name = "ZSS ${params.RELEASE_VERSION}"
                    } else {
                        tagName = "${params.RELEASE_VERSION}"
                        name = "${params.RELEASE_VERSION}"
                    }
                    def response = httpRequest \
                            authentication: GITHUB_TOKEN,
                            httpMode: 'POST',
                            url: "https://api.github.com/repos/${GITHUB_PROJECT}/${it}/releases",
                            requestBody: \
                                """
                                {
                                "tag_name": "${tagName}",
                                "target_commitish": "${RELEASE_BRANCH}",
                                "name": "${name}",
                                "body": "",
                                "draft": false,
                                "prerelease": false
                                }
                                """
                    echo response.content
                }
            } else {
                echo "nothing to do"
            }
        }

        stage("Merge to master") {
            if (params.MERGE_TO_MASTER) {
                REPOS.each {
                    def response = httpRequest \
                            authentication: GITHUB_TOKEN,
                            httpMode: 'POST',
                            url: "https://api.github.com/repos/${GITHUB_PROJECT}/${it}/merges",
                            requestBody: \
                                """
                                {
                                "base": "${MASTER_BRANCH}",
                                "head": "${RELEASE_BRANCH}",
                                "commit_message": "Zowe Suite ${params.RELEASE_VERSION}"
                                }
                                """
                    echo response.content
                }
            } else {
                echo "nothing to do"
            }
        }

        stage("Update rc") {
            if (params.UPDATE_RC) {
                REPOS.each {
				    def head = "v2.x/staging"
					if (it == 'zowe-common-c') {
                        head = params.ZOWE_COMMON_C_HEAD
                    }
                    def response = httpRequest \
                            authentication: GITHUB_TOKEN,
                            httpMode: 'POST',
                            url: "https://api.github.com/repos/${GITHUB_PROJECT}/${it}/merges",
                            requestBody: \
                                """
                                {
                                "base": "${RELEASE_BRANCH}",
                                "head": "${head}",
                                "commit_message": "Zowe Suite ${params.RELEASE_VERSION}"
                                }
                                """
                    echo response.content
                }
            } else {
                echo "nothing to do"
            }
        }

    }
}
