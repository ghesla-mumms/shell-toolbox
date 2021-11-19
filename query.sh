#!/bin/bash

# To connect to a hummingbird database...
# We assume that the .pgpass file has been set up appropriately.

# What environment are we trying to connect to?
# Valid values are listed in usage

function usage() {
  printf "usage: query {env} \n\
    Where {env} is one of:\n\
      prod\n\
      dev\n\
      demo\n\
      qa\n\
      stage\n\
      stage08\n\
      sales\n\
      support\n\
      cpc\n\
      local\n\
      dw1\n\
      dw3\n\
      gca-prod\n\
      sched-prod\n\
      sched-local\n\
      refqa\n\
      refprod\n\n";
  exit 1;
}

ENV=$1
DB=$2
QRY=$3
HOST=
PORT=5432
USER="hummingbird"
DATABASE="hummingbird"

# if a host is provided in the command, send a curl request passing the token
if [[ -z "$ENV"  ]]; then
  usage;
else
  case $ENV in
    qa) HOST="hbqa.mumms.com";;
    demo) HOST="hbdemo.mumms.com";;
    stage) HOST="hbdb-stage.mumms.com";;
    stage08) HOST="hbstage08.mumms.com";;
    prod) HOST="hb-rootdb.mumms.com";;
    support) HOST="hbsupport.mumms.com";;
    dw1) HOST="prod-gce-dw-1.mumms.com";;
    dw3) HOST="prod-gce-dw-3.mumms.com"; DATABASE="postgres";;
    cpc) HOST="10.128.15.192"; DATABASE="cpc"; USER="cpc";;
    local) HOST="localhost";;
    gca-prod) HOST="gca-prod-00-db-2.mumms.com"; DATABASE="postgres";;
    sched-prod) HOST="gca-prod-00-db-2.mumms.com"; DATABASE="pimcs_prod";;
    sched-local) HOST="localhost"; DATABASE="scheduler"; PORT=5433; USER="scheduler";;
    refqa) HOST="gca-dev-00-db-2.mumms.com"; USER="hb_dev_ref_5_2_rw"; DATABASE="hb_ref_dev_5_2";;
    refprod) HOST="gca-prod-00-db-2.mumms.com"; USER="hb_refdb_rw"; DATABASE="hb_ref_5_2";;
  esac
fi

if [[ -n "$DB" ]]; then
  DATABASE=$DB
fi

if [[ -z "$HOST"  ]]; then
  usage;
fi

CMD="psql -h ${HOST} -p ${PORT} -U ${USER} -d ${DATABASE}"


echo ""
echo "'${ENV}' environment selected. Executing command"
echo "${CMD}"
echo
if [[ -n "$QRY" ]]; then
  eval "echo \"${QRY}\" | ${CMD}"
else
  eval "$CMD"
fi
