docker pull node:12
docker build --pull -f Dockerfile.zlux --no-cache -t ompzowe/app-server:testing .