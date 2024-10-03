#!/bin/bash

check_http(){
  DURATION=$(</dev/stdin)
  if (($DURATION <= 15000 )); then 
    exit 60
  else
    if ! curl --silent --show-error --fail http://localhost:3338/v1/info &>/dev/null; then
      echo "The HTTP API is unreachable" >&2
      exit 1
    fi
  fi
}

check_rpc(){
  DURATION=$(</dev/stdin)
  if (($DURATION <= 15000 )); then 
    exit 60
  else
    if ! nc -z localhost 3339 &>/dev/null; then
      echo "The RPC API is unreachable" >&2
      exit 1
    fi
  fi
}

case "$1" in
	http)
    check_http
    ;;
	rpc)
    check_rpc
    ;;
  *)
    echo "Usage: $0 [command]"
    echo
    echo "Commands:"
    echo "         http"
    echo "         rpc"
esac