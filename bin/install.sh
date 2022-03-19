#!/usr/bin/env bash

set -o errexit
set -o pipefail

# @author: PunchPlatform Team
# @desc: Installer script for the PunchPlatform Light Operator.

###########################
## Variables and constants
###########################

## COLORS ##
# use printf "${red}string in red${clrend}" for example
clrend=$'\e[0m'
wht=$'\e[97m'
red=$'\e[31m'
grn=$'\e[32m'
blu=$'\e[34m'
yel=$'\e[33m'
mag=$'\e[35m'
cyn=$'\e[36m'
# bold
bred=$'\e[1;31m'
bgrn=$'\e[1;32m'
bblu=$'\e[1;34m'
byel=$'\e[1;33m'
bmag=$'\e[1;35m'
bcyn=$'\e[1;36m'

kookerDir="$( cd "$( dirname "${BASH_SOURCE[0]}")/.." && pwd )"

function check_dependencies() {
  for dependency in curl docker realpath unzip ; do
    which "${dependency}" > /dev/null || fatal "Please install needed packages providing '$dependency' command."
  done
}

function generate_activate_sh() {
  activateShell=${kookerDir}/activate.sh
  source ${kookerDir}/bin/env.sh
  cat > ${activateShell} << EOF
export PATH=${kookerDir}/bin:${kookerDir}/starter_tools:\$PATH
export PS1='\[\e[1;32m\]kooker:\[\e[0m\][\W]\$ '

# If tools are not set up natively, define aliases to use downloaded tool

for tool in kubectl helm k3d ; do
  alias \${tool}=${kookerDir}/downloads/\${tool}
done


# Define a 'kesapi' function for easy ES querying
function kesapi() {
  url="\${1:-}"
  if [ \$# -gt 0 ] ; then shift ; fi
  curl -u "$ES_USER:$ES_PASSWORD" http://${ELASTICSEARCH_EXTERNAL_API_URL}/\${url} "\${@}"
}


# Define a 'kkafka' function for easy usage of in-kube kafka broker node and binaries

function kkafka () { 
  if [ \$# -eq 0 ] || [ "\$1" == "--help" ] ; then
    {
      echo "Usage:    kkafka <command> <args> ..."
      echo "            Will run this command inside kafka binaries folder in the kooker broker pod"
      echo ""
      echo "       e.g.:  kkafka ls   # => Will list commands in kafka binary folder"
      echo ""

    } 1>& 2
    return 1
  fi

  BROKER_POD=\$(kubectl get pods -n processing -l app.kubernetes.io/name=kafka -o name)
  echo "using broker pod '\${BROKER_POD}'..."
  kubectl exec -i -t -n processing "\${BROKER_POD}" -- /bin/bash -c "cd /opt/kafka/bin ; \$*  " 
}


# Define a 'chclient' function for easy clickhouse querying

function chclient() {
  if [ "\${1:-}" == "--help" ] ; then
    cat 1>&2 << EOUSAGE

  chclient <args>
    will run a clickhouse-client in the kube for you.
    e.g. chclient --query 'show tables'
    Because this runs in the kube, you cannot access local files.
    But you can use a pipe:

         cat SomeQueriesFile | chclient

EOUSAGE
    return 0
  fi

  DEFARGS=("\$@" --multiquery --date_time_input_format best_effort --output_format_json_quote_64bit_integers 0 --date_time_output_format iso)
  if ! [[ "\$@" =~ '--format' ]] ; then
    DEFARGS+=(--format PrettyCompact)
  fi
  if ! [[ "\$@" =~ '--host' ]] ; then
    DEFARGS+=(--host 127.0.0.1 )
  fi

  kubectl exec -ti -n ${CLICKHOUSE_NAMESPACE} chi-punch-ch-punch-ch-0-0-0 -c clickhouse -- clickhouse-client "\${DEFARGS[@]}" --user clickhouse_operator --password clickhouse_operator_password 
}


EOF
  chmod ugo+x "$activateShell"
}

function main() {
  check_dependencies
  generate_activate_sh
}
main $@