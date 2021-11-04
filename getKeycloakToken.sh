#!/bin/bash

#####
# testKcCurl.sh
#
# This script can be used to test keycloak-secured api endpoints.
#
# This script will prompt the user for a username and password and create a keycloak
# token for that user. Then, it will make a curl call to the endpoint provided, passing
# the keycloak token as a header.
#
#####
function usage() {
  printf "usage: $0 [options] \n\
    example: ./$0 -X GET -h https://med-history-dev.gca-dev.mumms.com\n\
    options:\n\
      -env,--environment    --  The environment to run against\n\
                                  Default: qa\n\
                                  Options: qa, demo, stage, prod\n\
      -u,--user             --  Keycloak user for authentication\n\
      -pw,--password        --  Password for keycloak user\n\
      -cl,--clientid        --  Keycloak client id\n\
      -?,--help             --  This message\n\n"
  exit 1;
}

getToken() {
  local ENV=$1
  local USER=$2
  local PASS=$3
  local CLIENTID=$4
  local KEYCLOAK=
  local REALM=

  if [[ -z "$USER" ]] || [[ -z "$PASS" ]]; then
    read -p "Username: " USER
    read -s -p "Password" PASS
  fi

  if [ "$ENV" == "qa" ]; then
    local KEYCLOAK="https://keycloak-keycloak-dev-ha.gca-dev.mumms.com/auth"
    local REALM=hbqa04
  elif [ "$ENV" == "demo" ]; then
    local KEYCLOAK="https://keycloak-keycloak-dev-ha.gca-dev.mumms.com/auth"
    local REALM=hbdemo04
  elif [ "$ENV" == "stage" ]; then
    local KEYCLOAK="https://keycloak.gca-prod.mumms.com/auth"
    local REALM=hbstage04
  elif [ "$ENV" == "prod" ]; then
    local KEYCLOAK="https://keycloak.gca-prod.mumms.com/auth"
    local REALM=hbprod
  fi

  local TOKEN_ENDPOINT=/realms/$REALM/protocol/openid-connect/token
  local USERID_ENDPOINT="/admin/realms/$REALM/users"
  local KEYCLOAK_URI=$KEYCLOAK$TOKEN_ENDPOINT
  local CLIENT=$CLIENTID
  TOKEN=`curl -s -d "client_id=$CLIENT" \
              -d "grant_type=password" \
              --data-urlencode "username=$USER" \
              --data-urlencode "password=$PASS" \
            $KEYCLOAK$TOKEN_ENDPOINT | python2 -c "import sys, json; print json.load(sys.stdin)['access_token']"`
            # $KEYCLOAK$TOKEN_ENDPOINT | python3 -c "import sys, json; print(json.load(sys.stdin)['access_token'])"`
            # $KEYCLOAK$TOKEN_ENDPOINT | jq -r .access_token `

  echo "$TOKEN"
}

TGT_ENV="qa"
KC_USER=
KC_USERPASS=
KC_CLIENT=pim-login

while [ "$#" -gt 0 ]; do
  case $1 in
    -env|--emvironment) TGT_ENV=$2; shift 2; continue;;
    -u|--user) KC_USER=$2; shift 2; continue;;
    -pw|--password) KC_USERPASS=$2; shift 2; continue;;
    -cl|--clientid) KC_CLIENT=$2; shift 2; continue;;
    -?|--help) usage;;
    *)
  esac
  shift
done

TOKEN=$( getToken  "$TGT_ENV" "$KC_USER" "$KC_USERPASS" "$KC_CLIENT")

echo "${TOKEN}"
