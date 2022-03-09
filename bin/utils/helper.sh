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
(ADVANCE)
    # Deploy a clean cluster with minio exposed within your host network
    - make cluster deploy-minio network
(PROFILES)
    - make PROFILE=bin/profiles/profile-defaults.sh start # OR
(TIPS)
    - for opensearch, you need to setup vm.max_map_count
        - echo "vm.max_map_count=262144" >> /etc/sysctl.conf
        - or by doing: sysctl -w vm.max_map_count=262144
    - alias mks-default="make PROFILE=bin/profiles/profile-defaults.sh"
    - alias mks-dev="make PROFILE=bin/profiles/dev.sh"


    Once deployed, you can activate a helper environment using 

        source activate.sh

    This will provide you with the following tools in your PATH:
     - kubectl
     - k3d
     - helm
     - kesapi  # a helper function to invoke Elasticsearch/Opensearch REST APIs
     - kkafka # a helper function to invoke kafka binaries for troubleshooting, from inside the kafka broker container
     - cchclient # a helper function to connect to clickhouse using an in-kube command-line client

EOF