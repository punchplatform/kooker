
 # This script is intended to be sourced, to provide useful shortcuts when working with a kubernetes

: ${PUNCH_TENANT_NAMESPACE:=mytenant}
: ${VERBOSE_FUNC:=1}

: ${OPENSEARCH:=0}

if [ $OPENSEARCH -eq 1 ] ; then  
  : ${KIBANA_APP_NAME:=opensearch-dashboards}
	: ${KIBANA_CONTAINER_NAME:=dashboards}
  : ${KIBANA_NAMESPACE:=logs}
  : ${ESAPI_URL:=http://elasticsearch.doc-store:9200}
else
	: ${KIBANA_APP_NAME:=kibana}
	: ${KIBANA_CONTAINER_NAME:=kibana}
  : ${KIBANA_NAMESPACE:=visualization}
  : ${ESAPI_URL:=http://elasticsearch-master.doc-store:9200}

fi
TOOLS_DIR=$(dirname $(realpath "${BASH_SOURCE}"))

if ! declare -f error > /dev/null ; then
    for commons in commons-lib.sh functions.sh ; do
      libFile="${TOOLS_DIR}/${commons}"
      if [ -f "${libFile}" ] ; then
        source "${libFile}"
        break
      fi
    done
    if ! declare -f error > /dev/null ; then
      error "Fatal: could no load any standard shell lib providing 'error' function."
      return 13
    fi
fi

function give_hint () {
  if [ $VERBOSE_FUNC -eq 1 ] ; then 
    if [ $# -eq 0 ] ; then
        cat
    else
     echo "$@"
    fi 
  fi
}

# Define a 'kcurl' function for easy curls from within the kube (delegated to the kibana pod)
function kcurl() {
  
  KIB_POD=$(kubectl get pods -n ${KIBANA_NAMESPACE} -o name)
  if [ -z "${KIB_POD}" ] ; then
    error "Unable to find a pod with app=${KIBANA_APP_NAME}."
    return 12
  fi

  kubectl exec -i -n ${KIBANA_NAMESPACE} "${KIB_POD}" -c ${KIBANA_CONTAINER_NAME} -- /bin/bash -c "curl -s ${@}"

}


give_hint << EOF

  Defined 'kcurl' function for in-kube querying. Try it:
   
    kcurl prometheus-operated.cattle-monitoring-system:9090/metrics

EOF

function _init_kesapi_secrets () {
  if [ "${KESAPI_ESC:-}" == "" ] ; then
    source _get_secrets_json.sh
    KESAPI_RENDERING_TEMPLATE_FILE="${TOOLS_DIR}/_esc_rendering.yaml.j2"
    KESAPI_SECRETS="$(renderJinja2Template.py "${KESAPI_RENDERING_TEMPLATE_FILE}" "${SECRETS_JSON}")"
    : ${KESAPI_ESUSER:=$(jq -r .user <<< "${KESAPI_SECRETS}")}
    : ${KESAPI_ESPWD=$(jq -r .password <<< "${KESAPI_SECRETS}")}
    KESAPI_ESC="${KESAPI_ESUSER}:${KESAPI_ESPWD}"
  fi
  export KESAPI_ESC
}

# Define a 'kesapi' function for easy ES querying
function kesapi() {
  FOPT=""
  if [ "${1:-}" == "-f" ] ; then
    FOPT="-f"
    shift
  fi

  url="${1:-}"
  if [ $# -gt 0 ] ; then shift ; fi

  KIB_POD=$(kubectl get pods -n ${KIBANA_NAMESPACE} -l app=${KIBANA_APP_NAME} -o name)
  if [ -z "${KIB_POD}" ] ; then
    error "Unable to find a pod with app=${KIBANA_APP_NAME}."
    return 12
  fi

  if [ "${KESAPI_ESC:-}" == "" ] ; then
     _init_kesapi_secrets
  fi
  CURL_ARGS="-u '${KESAPI_ESC}' ${ESAPI_URL}/${url} ${@}"
  
  
  
  if [[ "$@" =~ "@-" ]] ; then
      # The request uses the stdin flow
    # We store the input stream copy, because we may have to run the curl twice if '-f' is provided
    # Once to detect non-nominal HTTP return code, and a second time to fetch the error document that is retrieved
    # only when -f is not provided.
    
    payload="$(cat)"
  else
    payload=""
  fi
  
  rc=0
  echo "$payload" | kubectl exec -i -n ${KIBANA_NAMESPACE} "${KIB_POD}" -c ${KIBANA_CONTAINER_NAME} -- /bin/bash -c "curl -s ${FOPT} ${CURL_ARGS}" || rc=$?
    
  
  
  if [ $rc -ne 0 ] && [ "$FOPT" == "-f" ] ; then
  # To detect non-nominal HTTP codes, we may have uses '-f' curl option at first try
  # Then because it has failed, we repeat the curl without the '-f' to get the returned HTTP object
      cat <<- EOF
      kubectl exec -i -n ${KIBANA_NAMESPACE} "${KIB_POD}" -c ${KIBANA_CONTAINER_NAME} -- /bin/bash -c "curl -s ${FOPT} ${CURL_ARGS}"
EOF
    echo "$payload" | kubectl exec -i -n ${KIBANA_NAMESPACE} "${KIB_POD}" -c ${KIBANA_CONTAINER_NAME} -- /bin/bash -c "curl -s ${CURL_ARGS}"  
  fi
  echo ""
  return $rc

}

give_hint << EOF
  Defined 'kesapi' function for in-kube querying of Elasticsearch/Opensearch API. Try it: 

    kesapi _cat/indices   # List ES Indices - for other APIs see online Elastic documentation
    kesapi myindice/_doc " -H 'content-type: application/json' -XPOST -D '{\"hello\":\"world\"}' "
 
EOF

# Define a 'kkafka' function for easy usage of in-kube kafka broker node and binaries

function kkafka () { 
  if [ $# -eq 0 ] || [ "$1" == "--help" ] ; then
    {
      echo "Usage:    kkafka <command> <args> ..."
      echo "            Will run this command inside kafka binaries folder in the kooker broker pod"
      echo ""
      echo "       e.g.:  kkafka ls   # => Will list commands in kafka binary folder"
      echo ""

    } 1>& 2
    return 1
  fi

  BROKER_POD=$(kubectl get pods -n processing -l app.kubernetes.io/name=kafka -o name | tail -n 1)
  if [ -z "${BROKER_POD}" ] ; then
    error "Unable to find a pod with app.kubernetes.io/name=kafka. Is Kafka deployed ?"
    return 12
  fi

  echo "using broker pod '${BROKER_POD}'..."
  kubectl exec -i -t -n processing "${BROKER_POD}" -- /bin/bash -c "cd /opt/kafka/bin ; $*  " 
}

give_hint << EOF
  Defined 'kkafka' function for in-kube launching of kafka standard command-tools. Try it: 

    kkafka ls   # To list kafka tools
    kkafka ./punchplatform-kafka-topics.sh --bootstrap-server localhost:9092   # To list topics

EOF


