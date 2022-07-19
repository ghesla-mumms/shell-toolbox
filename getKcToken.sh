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

TGT_ENV="qa"
KC_USER=${KC_USER:-}
KC_USERPASS=${KC_USERPASS:-}
KC_CLIENT=pim-login
TOKEN=

verbose=false

while [ "$#" -gt 0 ]; do
  case $1 in
    -env|--environment) TGT_ENV=$2; shift 2; continue;;
    -u|--user) KC_USER=$2; shift 2; continue;;
    -pw|--password) KC_USERPASS=$2; shift 2; continue;;
    -cl|--clientid) KC_CLIENT=$2; shift 2; continue;;
    -v) verbose=true; shift; continue;;
    -?|--help) usage;;
    *)
  esac
  shift
done

${verbose} && set -x

${verbose} && echo ""
${verbose} && echo "generating keycloak token"

# TOKEN=$( getToken  "${TGT_ENV}" "${KC_USER}" "${KC_USERPASS}" "${KC_CLIENT}")
   ENV="${TGT_ENV}"
   USER="${KC_USER}"
   PASS="${KC_USERPASS}"
   CLIENTID="${KC_CLIENT}"
  KEYCLOAK=
   REALM=

  if [[ -z "${USER}" ]]; then
    read -p "Username: " USER
  fi

  if [[ -z "${PASS}" ]]; then
    read -s -p "Password for ${USER}: " PASS
  fi

  if [ "${ENV}" == "qa" ]; then
    KEYCLOAK="https://keycloak-keycloak-dev-ha.gca-dev.mumms.com/auth"
     REALM=hbqa04
  elif [ "${ENV}" == "demo" ]; then
     KEYCLOAK="https://keycloak-keycloak-dev-ha.gca-dev.mumms.com/auth"
     REALM=hbdemo04
  elif [ "${ENV}" == "stage" ]; then
     KEYCLOAK="https://keycloak.gca-prod.mumms.com/auth"
     REALM=hbstage04
  elif [ "${ENV}" == "prod" ]; then
     KEYCLOAK="https://keycloak.gca-prod.mumms.com/auth"
     REALM=hbprod
  fi

   TOKEN_ENDPOINT=/realms/${REALM}/protocol/openid-connect/token
   USERID_ENDPOINT="/admin/realms/${REALM}/users"
   CLIENT=$CLIENTID

  CURL_RESPONSE=`CURL_SSL_BACKEND=SecureTransport curl -s \
              -d "client_id=${CLIENT}" \
              -d "grant_type=password" \
              --data-urlencode "username=${USER}" \
              --data-urlencode "password=${PASS}" \
              ${KEYCLOAK}${TOKEN_ENDPOINT}`

  echo "curl Response: ${CURL_RESPONSE}"
  TOKEN=$(echo -n ${CURL_RESPONSE} | jq -r '.access_token')

  echo "TOKEN: ${TOKEN}"
            # ${KEYCLOAK}${TOKEN_ENDPOINT} | python2 -c "import sys, json; print json.load(sys.stdin)['access_token']"`
            # | python3 -c "import sys, json; print(json.load(sys.stdin)['access_token'])"`
            # ${KEYCLOAK}${TOKEN_ENDPOINT}

  if [ -z ${TOKEN} ] || [ "${TOKEN}" = "null" ]; then
    echo "ERROR: ${CURL_RESPONSE}"
  else
    echo "${TOKEN}"
  fi

# TOKEN=$( getToken  "${TGT_ENV}" "${KC_USER}" "${KC_USERPASS}" "${KC_CLIENT}")

if [[ "${TOKEN}" == "***ERROR***" ]]; then
  echo ""
  echo "***ERROR: An error occurred generating the keycloak token. Please verify your username and password."
  exit 1
fi

echo "Got a token: ${TOKEN}"

${verbose} && set +x

echo
