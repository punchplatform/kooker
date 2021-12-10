export PATH=/home/punch/workspace/kooker/bin:$PATH
export PS1='\[\e[1;32m\]kooker:\[\e[0m\][\W]$ '

# If tools are not set up natively, define aliases to use downloaded tool

for tool in kubectl helm k3d ; do
  which ${tool} 1>/dev/null || alias ${tool}=/home/punch/workspace/kooker/downloads/${tool}
done


# Define a 'kesapi' function for easy ES querying
function kesapi() {
  url="${1:-}"
  if [ 0 -gt 0 ] ; then shift ; fi
  curl -u "elastic:elastic" http://elasticsearch.kooker:9200/${url} "${@}"
}

# Define a 'chclient' function for easy clickhouse querying

function chclient() {
  if [ "${1:-}" == "--help" ] ; then
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

  DEFARGS=("$@" --multiquery --date_time_input_format best_effort --output_format_json_quote_64bit_integers 0 --date_time_output_format iso)
  if ! [[ "$@" =~ '--format' ]] ; then
    DEFARGS+=(--format PrettyCompact)
  fi
  if ! [[ "$@" =~ '--host' ]] ; then
    DEFARGS+=(--host 127.0.0.1 )
  fi

  kubectl exec -ti -n clickhouse chi-punch-ch-punch-ch-0-0-0 -c clickhouse -- clickhouse-client "${DEFARGS[@]}" --user clickhouse_operator --password clickhouse_operator_password 
}


