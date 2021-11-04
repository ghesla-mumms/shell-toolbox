#!/bin/bash

#####
# Sample calls
#
#  to get an xml file of meds
# ./testCurl.sh -X GET -h "https://med-history-stage.gca-dev.mumms.com" -e "api/medications" -f demo1 -l area51 > medications-stage-demo1-area51.xml
#   ... for a single patient
# ./testCurl.sh -X GET -h "https://med-history-stage.gca-dev.mumms.com" -e "api/medications/patient/103342" -f demo1 -l area51 > medications-stage-demo1-area51-103342.xml
#
#  to encode the meds into a file
# ./testCurl.sh -X POST -ctx -df ./medications-stage-demo1-area51.xml -e "api/encode" -h "https://med-history-stage.gca-dev.mumms.com" > ./medications-stage-demo1-area51.enc
#
#  to post meds a file with encoded meds...
# `./testCurl.sh -X POST -df ./medications-stage-demo1-area51.enc -ctt -f demo1 -l area51 -e "api/medications" -h "https://med-history-dev.gca-dev.mumms.com"`
#####

#####
# Local Variables...
#####
DBHOST=
ROOTDBNAME="hummingbird"
DBUSER="hummingbird"
DBPORT=5432
DBNAME=
TENANTBIN=
# QUERYSTRING=
# QUERYFILE=

verbose=false

function usage() {
  printf "usage: testCurl.sh [options] \n\
    example: ./testCurl.sh -f demo1 -l location -h https://med-history-dev.gca-dev.mumms.com\n\
    options:\n\
      -h,--host             --  The host url of the target service (required)\n\
      -U,--dbuser           --  The username for the db connection (default: ${DBUSER}) (required)\n\
      -p,--dbport           --  The port for the db connection (default: ${DBPORT}) (required)\n\
      -d,--dbname           --  The target tenant dbname\n\
      -b,--bin              --  The target tenant bin\n\
      -q,--querystring      --  The query to be processed\n\
      -qf,--queryfile       --  A file containing the sql to be processed\n\
      -v,--verbose          --  Show progress\n\
      -h,--help             --  This message\n\n"
  exit 1;
}

while [ "$#" -gt 0 ]; do
  case $1 in
    -h|--host) DBHOST=$2; shift 2; continue;;
    -U|--dbuser) DBUSER=$2; shift 2; continue;;
    -p|--dbport) DBPORT=$2; shift 3; continue;;
    -d|--dbname) DBNAME=$2; shift 2; continue;;
    -b|--bin) TENANTBIN=$2; shift 2; continue;;
    # -q|--querystring) QUERYSTRING=42; shift 2; continue;;
    # -qf|--queryfile) QUERYFILE=$2; shift 2; continue;;

    -v|--verbose) verbose=true; shift; continue;;
    -h|--help) usage;;
    *)
  esac
  shift
done

#####
# Verify required variables
#####

if [[ -z "$DBHOST" ]]; then
  echo "The Database host must be provided."
  usage;
fi
if [[ -z "$DBUSER" ]]; then
  echo "The Database user must be provided."
  usage;
fi
# if [[ -z "$QUERYSTRING" && -z "$QUERYFILE" ]]; then
#   echo "A query must be provided."
#   usage;
# fi
if [[ -n "$TENANTBIN" && -n "$DBNAME" ]]; then
  echo "Provide EITHER a bin OR a dbname, not both."
  usage;
fi

$verbose && [ -n "${TENANTBIN}" ] && echo "Querying ${DBHOST} for bin ${TENANTBIN}"
$verbose && [ -n "${DBNAME}" ] && echo "Querying ${DBHOST} for db ${DBNAME}"
$verbose && [ -z "${TENANTBIN}" ] && [ -z "${DBNAME}" ] && echo "Querying ${DBHOST} for all tenants"

TGT_DBHOST=
TGT_DBNAME=
TGT_BIN=
TGT_FIRM=
TGT_LOCATIONNAME=
TGT_LOCATION=

SUPPORTQUERY="select dbhost as dbhostvar, dbname as dbnamevar, bin as binvar, hbcfirm as hbcfirmvar from hospice"
[ -n "$TENANTBIN" ] && SUPPORTQUERY="${SUPPORTQUERY} where bin='${TENANTBIN}';"
[ -n "$DBNAME" ] && SUPPORTQUERY="${SUPPORTQUERY} where dbname='${DBNAME}';"
[ -z "${TENANTBIN}" ] && [ -z "${DBNAME}" ] && SUPPORTQUERY="${SUPPORTQUERY} where status = 'ACTIVE' order by bin;"

$vebose && echo "querying support database: ${SUPPORTQUERY}"

psql -t -h $DBHOST -p $DBPORT -d $ROOTDBNAME -U $DBUSER -c "$SUPPORTQUERY" | while read TGT_DBHOST TGT_DBNAME TGT_BIN TGT_FIRM; do
  $verbose && echo "Processing bin ${TGT_BIN} (dbname: ${TGT_DBNAME}, firm: ${TGT_FIRM})"
  psql -t -h $DBHOST -p $DBPORT -d $TGT_DBNAME -U $DBUSER -c "select name, hbclocation from office where medsandprescriptions_id = -1;" | while read TGT_LOCATIONNAME TGT_LOCATION; do
    $verbose && echo "Processing office ${TGT_LOCATIONNAME} (location: ${TGT_LOCATION})"
  done;
done;

exit;


# send the secret to the jar file to get a valid PIM jwt token
# JWT_TOKEN=`java -jar hummingbird-auth-sso-1.0.7-RELEASE-jar-with-dependencies.jar -b $TGT_FIRM -l $TGT_LOCATION -s $JWT_SECRET`
$verbose && echo "creating jwt token for firm ${TGT_FIRM} and location ${TGT_LOCATION} using secret ${JWT_SECRET}"
JWT_TOKEN=$(./jwt.sh ${TGT_FIRM:+ -f $TGT_FIRM} ${TGT_LOCATION:+ -l $TGT_LOCATION} -s "$JWT_SECRET")

HOST="$HOSTURL/$ENDPOINT"

$verbose && echo && echo "Executing curl ${CURL_CMD} to ${HOST} call with headers [${ACCJSON_HEADER:+ -H "$ACCJSON_HEADER"}${ACCXML_HEADER:+ -H "$ACCXML_HEADER"}${CTX_HEADER:+ -H "$CTX_HEADER"}${CTT_HEADER:+ -H "$CTT_HEADER"}]${DATA:+ and data: "$DATA"}" && echo

curl -X $CURL_CMD -H "Authorization: Bearer ${JWT_TOKEN}" \
    ${ACCJSON_HEADER:+ -H "$ACCJSON_HEADER"} \
    ${ACCXML_HEADER:+ -H "$ACCXML_HEADER"} \
    ${CTX_HEADER:+ -H "$CTX_HEADER"} \
    ${CTT_HEADER:+ -H "$CTT_HEADER"} \
    ${DATA:+ -d $DATA} \
    ${SHOW_RESPONSE_HEADER:+ -i} \
    $HOST
echo
