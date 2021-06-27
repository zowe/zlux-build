#!/bin/bash
docker run -it \
    -h zlux-app-server \
    --env ZOSMF_HOST=tvt5003.svl.ibm.com \
    --env ZWED_agent_host=tvt5003.svl.ibm.com \
    --env ZOSMF_PORT=443 \
    --env ZWED_agent_https_port=48542 \
    --env ZLUX_NO_CLUSTER=1 \
    -p 8544:8544 \
    ompzowe/app-server:testing $@
