#!/bin/bash

USER=g.hesla

case "$1" in
  prod)
    CONTEXT=gca-prod
    shift
    ;;
  dev)
    CONTEXT=gca-dev
    shift
    ;;
  *)
    echo "Usage: $0 {dev|prod}"
    exit 1
    ;;
esac

oc config use-context ${CONTEXT}
if ! oc status | egrep "In project.*on server"; then
  oc login --username="${USER}" $@ \
    && oc status | egrep "In project.*on server"
fi

