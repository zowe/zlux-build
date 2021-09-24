# Pre-Reqs - Dockerfiles
- manifest.json - zowe-install-packaging
- files/zlux/config - zowe-install-packaging

# Helper Scripts
- `pull-zowe-install-artifacts.sh` 
- `download-zlux.sh` - downloads component builds listed in manifest.json
- `build.sh` - build pp-server container based on Dockerfile.zlux
- `start.sh` - start built container on localhost, modify target zosmf, zss hostname and ports in this script
- `run.sh` - run scripts in sequence `pull-zowe-install-artifacts.sh`, `download-zlux.sh`, `build.sh`, and then `start.sh`

# TODO:
- container script `app-install-container.sh` copied from `server-bundle` is not used as of now
- when running the run script make sure to 'export ZLUX_DOWNLOAD_API_TOKEN' with a proper 'X-JFrog-Art-Api'

# Container Scripts
- `install-container.sh`  -> layout binaries, and scripts
- `configure-container.sh` -> create logs folder, and calls `internal-install.sh`
- `internal-install.sh` -> copy default plugin tars and default plugins configs
- `start-container.sh` -> entrypoint, calls lifecycle scripts `configure.sh` & `start.sh`

# Steps
```
  cd container
  chmod +x *.sh
  #edit start.sh parameter for zss & zosmf
  ./run.sh
```