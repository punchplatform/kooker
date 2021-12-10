#!/usr/bin/env bash

cat << EOF                                                                          
                           
 _____         _           
|  |  |___ ___| |_ ___ ___ 
|    -| . | . | '_| -_|  _|
|__|__|___|___|_,_|___|_|  
                           

USAGES:

(QUICKSTART)
    - make start
    - make stop
(EXPOSING SERVICES)
    - make network
(GET ENDPOINTS & CREDENTIALS)
    - make credentials
(PUSH RESOURCES)
    - make setup-platform
(ADVANCE)
    # Deploy a clean cluster with minio exposed within your host network
    - make cluster deploy-minio network
(PROFILES)
    - make PROFILE=bin/profiles/default_profile.sh start # OR
(TIPS)
    - for opensearch, you need to setup vm.max_map_count
        - echo "vm.max_map_count=262144" >> /etc/sysctl.conf
        - or by doing: sysctl -w vm.max_map_count=262144
    - alias mks-default="make PROFILE=bin/profiles/default_profile.sh"
    - alias mks-dev="make PROFILE=bin/profiles/dev.sh"
EOF