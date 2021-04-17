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

/*
* zluxParameters is a map with key and value, if the value is empty it will automatically use staging for the key. 
* To build a specific pull request just add the pull request number to the value of the repository you want to build. 
*/

def zluxParameters = [
  "PR_ZLUX_APP_MANAGER" : "",
  "PR_ZLUX_APP_SERVER" : "",
  "PR_ZLUX_PLATFORM" : "",
  "PR_ZLUX_SERVER_FRAMEWORK" : "",
  "PR_ZLUX_SHARED" : "",
  "PR_ZLUX_BUILD" : ""
]

DEFAULT_BRANCH = "staging"

properties([
  parameters(zluxParameters)
])


import org.jenkinsci.plugins.workflow.steps.FlowInterruptedException


JENKINS_NODE = "zlux-agent"
GITHUB_PROJECT = "zowe"
GITHUB_TOKEN = "zowe-robot-github"
GITHUB_SSH_KEY = "zlux-jenkins"

ZLUX_CORE_PLUGINS = [
  "zlux-app-manager",
  "zlux-app-server",
  "zlux-build",
  "zlux-platform",
  "zlux-server-framework",
  "zlux-shared"
]
ZOWE_MANIFEST_URL = \
"https://raw.githubusercontent.com/zowe/zowe-install-packaging/staging/manifest.json.template"
ARTIFACTORY_SERVER = "zoweArtifactory"
ARTIFACTORY_REPO = "libs-snapshot-local/org/zowe/zlux"
PAX_HOSTNAME = "zzow01.zowe.marist.cloud"
PAX_SSH_PORT = 22
PAX_CREDENTIALS = "ssh-marist-server-zzow01"
NODE_VERSION = "v12.16.1"
USER_EMAIL = "zowe-robot@zowe.org"
USER_NAME = "Zowe Robot"

NODE_HOME = "/ZOWE/node/node-${NODE_VERSION}-os390-s390x"
NODE_ENV_VARS = "_TAG_REDIR_ERR=txt _TAG_REDIR_IN=txt _TAG_REDIR_OUT=txt __UNTAGGED_READ_MODE=V6"

def setGithubStatus(authToken, pullRequests, status, description) {
  pullRequests.each {
    repoName, pullRequest ->
    def response = httpRequest \
    authentication: authToken, httpMode: "POST",
      url: "https://api.github.com/repos/${GITHUB_PROJECT}/${repoName}/" +
      "statuses/${pullRequest['head']['sha']}",
      requestBody: \
      """
         {
          "state": "${status}",
          "target_url": "${env.RUN_DISPLAY_URL}",
          "description": "${description}",
          "context": "continuous-integration/jenkins/pr-merge"
         }
      """
  }
}


def getPullRequest(authToken, repoName, prNumber) {
  def response = httpRequest \
  authentication: authToken, httpMode: 'GET',
    url: "https://api.github.com/repos/${GITHUB_PROJECT}/${repoName}/pulls/${prNumber}",
    validResponseContent: 'head'
  return readJSON(text: response.content)
}


def getZoweVersion() {
  def response = httpRequest url: ZOWE_MANIFEST_URL
  echo "Zowe manifest template:\n${response.content}"
  return (response.content =~ /"version"\s*:\s*"(.*)"/)[0][1]
}


def pullRequests = [:]
def zoweVersion = null
def paxPackageDir = "/ZOWE/tmp/~${env.BUILD_TAG}"
def mergedComponent = null
def branchName = "-"+DEFAULT_BRANCH
def zluxbuildpr = null

node(JENKINS_NODE) {
  currentBuild.result = "SUCCESS"
  try {

    stage("Prepare") {
      zoweVersion = getZoweVersion()
    zluxbuildpr = env.BRANCH_NAME
    if (zluxbuildpr.startsWith("PR-")){
    pullRequests['zlux-build'] = getPullRequest(GITHUB_TOKEN, 'zlux-build', zluxbuildpr.drop(3)) 
    } else {
	DEFAULT_BRANCH = env.BRANCH_NAME.toLowerCase()
    echo "building ${DEFAULT_BRANCH}"
    }
    
    zluxParameters.each {
          key, value ->
          if (key.startsWith("PR_")) {
            if (value) {
              def repoName = key[3..-1].toLowerCase().replaceAll('_', '-')
              pullRequests[repoName] = getPullRequest(GITHUB_TOKEN, repoName, value)
            }
            
          }
        }
    
      setGithubStatus(GITHUB_TOKEN, pullRequests, "pending", "This commit is being built")

    }
    sshagent(credentials: [GITHUB_SSH_KEY]) {
      stage("Checkout") {
        sh \
        """
         mkdir zlux
         git config --global user.email ${USER_EMAIL}
         git config --global user.name ${USER_NAME}
        """
        ZLUX_CORE_PLUGINS.each {
          sh \
          """
           cd zlux
           git clone https://github.com/zowe/${it}.git
           cd ${it}
           git checkout ${DEFAULT_BRANCH}
          """
        }
        pullRequests.each {
          repoName, pullRequest ->
      sh \
      """
       cd zlux/${repoName}
       git fetch origin pull/${pullRequest['number']}/head:pr
       git merge pr
      """
        }
      }
      stage("Set version") {
        def (majorVersion, minorVersion, microVersion) = zoweVersion.tokenize(".")
        sh \
        """
          cd zlux/zlux-build
          sed -i -e "s/MAJOR_VERSION=0/MAJOR_VERSION=${majorVersion}/" \\
                 -e "s/MINOR_VERSION=8/MINOR_VERSION=${minorVersion}/" \\
                 -e "s/REVISION=4/REVISION=${microVersion}/" \\
                  version.properties
          echo "Set version to:"
          cat version.properties
          cd ../zlux-app-server
          if [ -e "manifest.yaml" ]; then
            export commit_hash=\$(git rev-parse --verify HEAD)
            export current_timestamp=\$(date +%s%3N)
            export zlux_version="${majorVersion}.${minorVersion}.${microVersion}"
            sed -i -e "s|{{build\\.branch}}|${BRANCH_NAME}|g" \\
                   -e "s|{{build\\.number}}|${BUILD_NUMBER}|g" \\
                   -e "s|{{build\\.commitHash}}|\${commit_hash}|g" \\
                   -e "s|{{build\\.timestamp}}|\${current_timestamp}|g" \\
                   -e "s|{{build\\.version}}|\${zlux_version}|g" \\
                   "manifest.yaml"
            echo "manifest is:"
            cat manifest.yaml
          fi
        """
      }
      stage("Build") {
        sh "bash -c 'cd zlux/zlux-build && set -o pipefail && ant testing 2>&1 | grep -vE \"^\\s+\\[exec\\]\\s+0\\% compiling\"'"
      }
      stage("Test") {
        pullRequests.each {
          repoName, pullRequest ->
          if (repoName != "zlux-app-server") {
            sh \
            """
             cd dist
             packages=\$(find ./${repoName} -name package.json | { grep -v node_modules || true; })
             for package in \$packages
             do
               sh -c "cd `dirname \$package` && npm run test --if-present"
             done
            """
          }
        }
        setGithubStatus(GITHUB_TOKEN, pullRequests, "success", "This commit looks good")
        sh "cd zlux/zlux-build && ant -Dcapstone=../../dist removeSource"
    }
      stage("Package") {
    sh \
          """
            chmod +x dist/zlux-build/*.sh
            cd dist
            tar cf ../zlux.tar -H ustar *
            cd ..
            git clone -b feature/tag-script https://github.com/1000TurquoisePogs/zowe-install-packaging.git
            """
          withCredentials([usernamePassword(
            credentialsId: PAX_CREDENTIALS,
            usernameVariable: "PAX_USERNAME",
            passwordVariable: "PAX_PASSWORD"
          )]) {
            def PAX_SERVER = [
              name         : PAX_HOSTNAME,
              host         : PAX_HOSTNAME,
              port         : PAX_SSH_PORT,
              user         : PAX_USERNAME,
              password     : PAX_PASSWORD,
              allowAnyHosts: true
            ]
            sshCommand remote: PAX_SERVER, command: \
            "rm -rf ${paxPackageDir} && mkdir -p ${paxPackageDir}"
            sshPut remote: PAX_SERVER, from: "zlux.tar", into: "${paxPackageDir}/"
            sshPut remote: PAX_SERVER, from: "zowe-install-packaging/scripts/tag-files.sh", into: "${paxPackageDir}/"
            sshCommand remote: PAX_SERVER, command:  \
            """
              export _BPXK_AUTOCVT=ON &&
              cd ${paxPackageDir} &&
              chtag -tc iso8859-1 tag-files.sh &&
              chmod +x tag-files.sh &&
              mkdir -p zlux/share && cd zlux &&
              mkdir bin && cd share &&
              tar xpoUf ../../zlux.tar &&
              ../../tag-files.sh . &&
              cd zlux-server-framework &&
              rm -rf node_modules &&
              ${NODE_ENV_VARS} PATH=${NODE_HOME}/bin:$PATH npm install &&
              cd .. &&
              iconv -f iso8859-1 -t 1047 zlux-app-server/defaults/serverConfig/server.json > zlux-app-server/defaults/serverConfig/server.json.1047 &&
              mv zlux-app-server/defaults/serverConfig/server.json.1047 zlux-app-server/defaults/serverConfig/server.json &&
              chtag -tc 1047 zlux-app-server/defaults/serverConfig/server.json &&
              cd zlux-app-server/bin &&
              cp start.sh configure.sh ../../../bin &&
              if [ -e "validate.sh" ]; then
                cp validate.sh ../../../bin
              fi
              cd ..
              if [ -e "manifest.yaml" ]; then
                cp manifest.yaml ../../
              fi
              cd ../../
              pax -x os390 -pp -wf ../zlux.pax *
              """
            sshGet remote: PAX_SERVER, from: "${paxPackageDir}/zlux.pax", into: "zlux.pax"
            sshCommand remote: PAX_SERVER, command: "rm -rf ${paxPackageDir}"
          }
    
      }
      stage("Deploy") {
        def artifactoryServer = Artifactory.server ARTIFACTORY_SERVER
        def timestamp = (new Date()).format("yyyyMMdd.HHmmss")
        def target = null
		if (zluxbuildpr.startsWith("PR-")){
			target = "${ARTIFACTORY_REPO}/zlux-core/" +
            "${zoweVersion}${zluxbuildpr}/" +
            "zlux-core-${zoweVersion}-${timestamp}"
          ["tar", "pax"].each {
            def uploadSpec = """{"files": [{"pattern": "zlux.${it}", "target": "${target}.${it}"}]}"""
            def buildInfo = Artifactory.newBuildInfo()
            artifactoryServer.upload spec: uploadSpec, buildInfo: buildInfo
            artifactoryServer.publishBuildInfo buildInfo
          }
		}

          target = "${ARTIFACTORY_REPO}/zlux-core/" +
            "${zoweVersion}${branchName.toUpperCase()}/" +
            "zlux-core-${zoweVersion}-${timestamp}"
          ["tar", "pax"].each {
            def uploadSpec = """{"files": [{"pattern": "zlux.${it}", "target": "${target}.${it}"}]}"""
            def buildInfo = Artifactory.newBuildInfo()
            artifactoryServer.upload spec: uploadSpec, buildInfo: buildInfo
            artifactoryServer.publishBuildInfo buildInfo
          }
          target = "${ARTIFACTORY_REPO}/${mergedComponent}/" +
            "${zoweVersion}${branchName.toUpperCase()}/" +
            "${mergedComponent}-${zoweVersion}-${timestamp}"
          ["tar", "pax"].each {
            def uploadSpec = """{"files": [{"pattern": "${mergedComponent}.${it}", "target": "${target}.${it}"}]}"""
            def buildInfo = Artifactory.newBuildInfo()
            artifactoryServer.upload spec: uploadSpec, buildInfo: buildInfo
            artifactoryServer.publishBuildInfo buildInfo
          }
      }
    }
  } catch (FlowInterruptedException  e) {
    setGithubStatus(
      GITHUB_TOKEN, pullRequests, "failure", "The build of this commit was aborted"
    )
    currentBuild.result = "ABORTED"
    throw e
  } catch (e) {
    if (e.getMessage() != 'nothing to build') {
      currentBuild.result = "FAILURE"
      setGithubStatus(GITHUB_TOKEN, pullRequests, "failure", "This commit cannot be built")
      throw e
    }
  } finally {
    stage("Report") {
      def prettyParams = ""
      if (pullRequests) {
        pullRequests.each{
          repoName, pullRequest ->
          prettyParams += "<br/>&nbsp;&nbsp;&nbsp;<a href=\"${pullRequest['html_url']}" +
            "\">${repoName} PR #${pullRequest["number"]}</a>"
        }
      } else {
        prettyParams = "n/a"
      }
      emailext \
      subject: """${env.JOB_NAME} [${env.BUILD_NUMBER}]: ${currentBuild.result}""",
      attachLog: true,
        mimeType: "text/html",
        recipientProviders: [
        [$class: "RequesterRecipientProvider"],
        [$class: "CulpritsRecipientProvider"],
        [$class: "DevelopersRecipientProvider"],
        [$class: "UpstreamComitterRecipientProvider"]
      ],
        body: \
      """
                    <p><b>${currentBuild.result}</b></p>
                    <hr/>
                    <ul>
                        <li>Duration: ${currentBuild.durationString[0..-14]}</li>
                        <li>Build link: <a href="${env.RUN_DISPLAY_URL}">
                            ${env.JOB_NAME} [${env.BUILD_NUMBER}]</a></li>
                        <li>Pull requests: ${prettyParams}</li>
                    </ul>
                    <hr/>
                    """
    }
  }
}
