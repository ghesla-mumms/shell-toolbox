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
      -hdr1                 --  Add header to request\n\
      -hdr2                 --  Add header to request\n\
      -hdr3                 --  Add header to request\n\
      -hdr4                 --  Add header to request\n\
      -hdr5                 --  Add header to request\n\
      -v                    --  Show script progress\n\
      --verbose             --  Show verbose response\n\
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

  if [[ -z "$USER" ]]; then
    read -p "Username: " USER
  fi

  if [[ -z "$PASS" ]]; then
    read -s -p "Password for $USER: " PASS
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

HOSTURL=
ENDPOINT=
TGT_ENV="qa"
KC_USER=${KC_USER:-}
KC_USERPASS=${KC_USERPASS:-}
KC_CLIENT=pim-login
ORIGIN=
CURL_CMD="GET"
DATA=
SHOW_RESPONSE_HEADER=
CTX_HEADER=
CTT_HEADER=
CTJ_HEADER=
ACCJSON_HEADER=
ACCXML_HEADER=
TOKEN=
VERBOSE_RESPONSE=
REQUEST_HEADER1=
REQUEST_HEADER2=
REQUEST_HEADER3=
REQUEST_HEADER4=
REQUEST_HEADER5=

verbose=false

while [ "$#" -gt 0 ]; do
  case $1 in
    -h|--host) HOSTURL=$2; shift 2; continue;;
    -e|--endpoint) ENDPOINT=$2; shift 2; continue;;
    -env|--environment) TGT_ENV=$2; shift 2; continue;;
    -u|--user) KC_USER=$2; shift 2; continue;;
    -pw|--password) KC_USERPASS=$2; shift 2; continue;;
    -cl|--clientid) KC_CLIENT=$2; shift 2; continue;;
    -t|--token) TOKEN=$2; shift 2; continue;;
    -j|--json) ACCJSON_HEADER="Accept: application/json"; shift; continue;;
    -x|--xml) ACCXML_HEADER="Accept: application/xml"; shift; continue;;
    -o|--origin) ORIGIN=$2; shift 2; continue;;
    -X|--cmd) CURL_CMD=$2; shift 2; continue;;
    -d|--data) DATA=$2; shift 2; continue;;
    -df|--datafile) DATA="@${2}"; shift 2; continue;;
    -i) SHOW_RESPONSE_HEADER=true; shift; continue;;
    -ctx) CTX_HEADER="Content-Type: application/xml"; shift; continue;;
    -ctt) CTT_HEADER="Content-Type: text/plain"; shift; continue;;
    -ctj) CTT_HEADER="Content-Type: application/json"; shift; continue;;
    -hdr1) REQUEST_HEADER1=$2; shift 2; continue;;
    -hdr2) REQUEST_HEADER2=$2; shift 2; continue;;
    -hdr3) REQUEST_HEADER3=$2; shift 2; continue;;
    -hdr4) REQUEST_HEADER4=$2; shift 2; continue;;
    -hdr5) REQUEST_HEADER5=$2; shift 2; continue;;
    -v) verbose=true; shift; continue;;
    --verbose) VERBOSE_RESPONSE="--verbose"; shift; continue;;
    -?|--help) usage;;
    *)
  esac
  shift
done

if [[ -z "$HOSTURL" ]]; then
  echo "The host url must be provided"
  usage
fi

if [[ -z "$TOKEN" ]]; then
  $verbose && echo ""
  $verbose && echo "generating keycloak token"
  TOKEN=$( getToken  "$TGT_ENV" "$KC_USER" "$KC_USERPASS" "$KC_CLIENT")
else
  $verbose && echo ""
  $verbose && echo "using provided token"
fi

HOST="${HOSTURL}"

if [[ -n "$ENDPOINT" ]]; then
  HOST="$HOST/$ENDPOINT"
fi

$verbose && echo ""
$verbose && echo "" && echo "Executing curl..."
$verbose && echo "curl -X ${CURL_CMD} \\"
$verbose && [ -n "${TOKEN}" ] && echo "     -H \"Authorization: Bearer ${TOKEN}\" \\"
$verbose && [ -n "${ACCJSON_HEADER}" ] && echo "     -H \"${ACCJSON_HEADER}\" \\"
$verbose && [ -n "${ACCXML_HEADER}" ] && echo "     -H \"${ACCXML_HEADER}\" \\"
$verbose && [ -n "${CTX_HEADER}" ] && echo "     -H \"${CTX_HEADER}\" \\"
$verbose && [ -n "${CTT_HEADER}" ] && echo "     -H \"${CTT_HEADER}\" \\"
$verbose && [ -n "${CTJ_HEADER}" ] && echo "     -H \"${CTJ_HEADER}\" \\"
$verbose && [ -n "${REQUEST_HEADER1}" ] && echo "  -H \"${REQUEST_HEADER1}\" \\"
$verbose && [ -n "${REQUEST_HEADER2}" ] && echo "  -H \"${REQUEST_HEADER2}\" \\"
$verbose && [ -n "${REQUEST_HEADER3}" ] && echo "  -H \"${REQUEST_HEADER3}\" \\"
$verbose && [ -n "${REQUEST_HEADER4}" ] && echo "  -H \"${REQUEST_HEADER4}\" \\"
$verbose && [ -n "${REQUEST_HEADER5}" ] && echo "  -H \"${REQUEST_HEADER5}\" \\"
$verbose && [ -n "${DATA}" ] && echo "     -d \"${DATA}\" \\"
$verbose && [ -n "${SHOW_RESPONSE_HEADER}" ] && echo "     -i \\"
$verbose && [ -n "${VERBOSE_RESPONSE}" ] && echo "     ${VERBOSE_RESPONSE} \\"

$verbose && echo "     \"${HOST}\""
$verbose && echo ""

curl -X $CURL_CMD -H "Authorization: Bearer $TOKEN" \
    ${ACCJSON_HEADER:+ -H "$ACCJSON_HEADER"} \
    ${ACCXML_HEADER:+ -H "$ACCXML_HEADER"} \
    ${CTX_HEADER:+ -H "$CTX_HEADER"} \
    ${CTT_HEADER:+ -H "$CTT_HEADER"} \
    ${CTJ_HEADER:+ -H "$CTJ_HEADER"} \
    ${REQUEST_HEADER1:+ -H "$REQUEST_HEADER1"} \
    ${REQUEST_HEADER2:+ -H "$REQUEST_HEADER2"} \
    ${REQUEST_HEADER3:+ -H "$REQUEST_HEADER3"} \
    ${REQUEST_HEADER4:+ -H "$REQUEST_HEADER4"} \
    ${REQUEST_HEADER5:+ -H "$REQUEST_HEADER5"} \
    ${ORIGIN:+ -H "Origin: $ORIGIN"} \
    ${DATA:+ -d $DATA} \
    ${SHOW_RESPONSE_HEADER:+ -i} \
    ${VERBOSE_RESPONSE:+ $VERBOSE_RESPONSE} \
    $HOST
echo
