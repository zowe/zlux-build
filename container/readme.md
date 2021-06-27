# Pre-Reqs - Dockerfiles
- manifest.json - zowe-install-packaging
- files/zlux/config - zowe-install-packaging

# Helper Scripts
- pull-zowe-install-artifacts.sh 
- download-zlux.sh - downloads component builds listed in manifest.json
- build.sh - build pp-server container based on Dockerfile.zlux
- start.sh - start built container on localhost, modify target zosmf, zss hostname and ports in this script
- run.sh - run all helper scripts in sequence pull,download,build,and then start

# TODO:
- container script `run-app-installs.sh` copied from `server-bundle` is not used as of now
- `internal-install.sh` will directly come from `zlux-app-server/bin` instead of `files/scripts`
# Steps
- cd container
- Modify container/start.sh parameter for zss & zosmf
- ./run.sh