#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# For debugging, uncomment the next line
# set -x

#####
# testKcCurl.sh
#
# This script can be used to test keycloak-secured api endpoints.
#
# This script will prompt the user for a username and password and create a keycloak
# token for that user. Then, it will make a curl call to the endpoint provided, passing
# the keycloak token as a header.
#
# You can shortcut the need to pass the username and password to this script by
# setting the KC_USER and KC_USERPASS environment variables.
#  $ export KC_USER="user@mumms.com"
#  $ export KC_USERPASS="userpasswordvalue"
#
#####
function usage() {
  printf "usage: $0 [options] \n\
    example: ./$0 -X GET -h https://med-history-dev.gca-dev.mumms.com\n\
    options:\n\
      -h,--host             --  The host url of the target service (required)\n\
      -e,--endpoint         --  The host url of the target service (required)\n\
      -env,--environment    --  The environment to run against\n\
                                  Default: qa\n\
                                  Options: qa, demo, stage, prod\n\
      -u,--user             --  Keycloak user for authentication\n\
      -pw,--password        --  Password for keycloak user\n\
      -cl,--clientid        --  Keycloak client id\n\
      -t,--token            --  A valid keycloak token\n\
      -j,--json             --  View the output in json\n\
      -x,--xml              --  View the output in xml\n\
      -o,--origin           --  The origin to test from\n\
      -X,--cmd              --  The curl command to use\n\
                                  Default: GET\n\
                                  Options: GET, POST, PUT, DELETE\n\
      -d,--data             --  The data to send to the POST or PUT as the body\n\
                                  * do not use with -df, --datafile\n\
      -df,--datafile        --  The file containg the data to send to the POST or PUT as the body\n\
      -i                    --  Show the http response headers\n\
      -ctx                  --  Include a xml content-type header\n\
      -ctt                  --  Include a text/plain content-type header\n\
      -ctj                  --  Include an application/json content-type header\n\
      -hdr                  --  Add header to request\n\
      -f,--file             --  Output to a file\n\
      -v                    --  Show script progress\n\
      --verbose             --  Show verbose curl response\n\
      --compressed          --  Add flag to curl call\n\
      --insecure            --  Add flag to curl call\n\
      -?,--help             --  This message\n"
  exit 1;
}

getToken() {
  local ENV=$1
  local USER=$2
  local PASS=$3
  local CLIENTID=$4
  local KEYCLOAK=
  local REALM=

  if [[ -z "${USER}" ]]; then
    read -p "Username: " USER
  fi

  if [[ -z "${PASS}" ]]; then
    read -s -p "Password for ${USER}: " PASS
  fi

  if [ "${ENV}" == "qa" ]; then
    local KEYCLOAK="https://keycloak-keycloak-dev-ha.gca-dev.mumms.com/auth"
    local REALM=hbqa04
  elif [ "${ENV}" == "demo" ]; then
    local KEYCLOAK="https://keycloak-keycloak-dev-ha.gca-dev.mumms.com/auth"
    local REALM=hbdemo04
  elif [ "${ENV}" == "stage" ]; then
    local KEYCLOAK="https://keycloak.gca-prod.mumms.com/auth"
    local REALM=hbstage04
  elif [ "${ENV}" == "prod" ]; then
    local KEYCLOAK="https://keycloak.gca-prod.mumms.com/auth"
    local REALM=hbprod
  fi

  local TOKEN_ENDPOINT=/realms/${REALM}/protocol/openid-connect/token
  local USERID_ENDPOINT="/admin/realms/${REALM}/users"
  local CLIENT=$CLIENTID
  TOKEN=`CURL_SSL_BACKEND=SecureTransport curl -s -d "client_id=${CLIENT}" \
              -d "grant_type=password" \
              --data-urlencode "username=${USER}" \
              --data-urlencode "password=${PASS}" \
              ${KEYCLOAK}${TOKEN_ENDPOINT} \
              | jq -r '.access_token'`
            # ${KEYCLOAK}${TOKEN_ENDPOINT} | python2 -c "import sys, json; print json.load(sys.stdin)['access_token']"`
            # | python3 -c "import sys, json; print(json.load(sys.stdin)['access_token'])"`
            # ${KEYCLOAK}${TOKEN_ENDPOINT}

  if [ -z ${TOKEN} ] || [ "${TOKEN}" = "null" ]; then
    echo "***ERROR***"
  else
    echo "${TOKEN}"
  fi
}

TGT_ENV="qa"
KC_USER=${KC_USER:-}
KC_USERPASS=${KC_USERPASS:-}
KC_CLIENT=pim-login
TOKEN=

HOSTURL=
ENDPOINT=
CURL_CMD="GET"

CURL_PARMS=()

verbose=false

while [ "$#" -gt 0 ]; do
  case $1 in
    -env|--environment) TGT_ENV=$2; shift 2; continue;;
    -u|--user) KC_USER=$2; shift 2; continue;;
    -pw|--password) KC_USERPASS=$2; shift 2; continue;;
    -cl|--clientid) KC_CLIENT=$2; shift 2; continue;;
    -t|--token) TOKEN=$2; shift 2; continue;;
    -h|--host) HOSTURL=$2; shift 2; continue;;
    -e|--endpoint) ENDPOINT=$2; shift 2; continue;;
    -X|--cmd) CURL_CMD=$2; shift 2; continue;;
    -j|--json) CURL_PARMS+=("-H" "Accept: application/json"); shift; continue;;
    -x|--xml) CURL_PARMS+=("-H" "Accept: application/xml"); shift; continue;;
    -o|--origin) CURL_PARMS+=("-H" "Origin: $2"); shift 2; continue;;
    -d|--data) CURL_PARMS+=("-d" "$2"); shift 2; continue;;
    -df|--datafile) CURL_PARMS+=("-d" "@$2"); shift 2; continue;;
    -i) CURL_PARMS+=("-i"); shift; continue;;
    -ctx) CURL_PARMS+=("-H" "Content-Type: application/xml"); shift; continue;;
    -ctt) CURL_PARMS+=("-H" "Content-Type: text/plain"); shift; continue;;
    -ctj) CURL_PARMS+=("-H" "Content-Type: application/json"); shift; continue;;
    -hdr) CURL_PARMS+=("-H" "$2"); shift 2; continue;;
    -f|--file) CURL_PARMS+=("-o" "$2"); shift; continue;;
    --compressed) CURL_PARMS+=("--compressed"); shift; continue;;
    --insecure) CURL_PARMS+=("--insecure"); shift; continue;;
    --verbose) CURL_PARMS+=("--verbose"); shift; continue;;
    -v) verbose=true; shift; continue;;
    -?|--help) usage;;
    *)
  esac
  shift
done
${verbose} && set -x

if [[ -z "${HOSTURL}" ]]; then
  echo "The host url must be provided"
  usage
fi

if [[ -z "${TOKEN}" ]]; then
  ${verbose} && echo ""
  ${verbose} && echo "generating keycloak token"
  TOKEN=$( getToken  "${TGT_ENV}" "${KC_USER}" "${KC_USERPASS}" "${KC_CLIENT}")
else
  ${verbose} && echo ""
  ${verbose} && echo "using provided token"
fi

if [[ "${TOKEN}" == "***ERROR***" ]]; then
  echo ""
  echo "***ERROR: An error occurred generating the keycloak token. Please verify your username and password."
  exit 1
fi

CURL_PARMS+=("-H" "Authorization: Bearer ${TOKEN}")

HOST="${HOSTURL}"

if [[ -n "${ENDPOINT}" ]]; then
  HOST="${HOST}/${ENDPOINT}"
fi

CURL_PARMS+=("-X" "${CURL_CMD}")

# If verbose, show the curl command that is being executed
${verbose} && set -x

CURL_SSL_BACKEND=SecureTransport curl "${CURL_PARMS[@]}" ${HOST}

${verbose} && set +x

echo
