#!/bin/bash
##########
##
## ./syncPatientMeds.sh -env prod -d hb_demo1 -u 'g.hesla+csnurse48@mumms.com' -pw 'Newp33ps#' -fr '2020-09-01' -v
## ./syncPatientMeds.sh -env prod -d hb_transition -u 'j.hayes+transition@mumms.com' -pw 'Todaysword#14' -fr '2020-08-01' -v
## ./syncPatientMeds.sh -env prod -d hb_angelok -u 'j.hayes+angelok@mumms.com' -pw 'Todaysword#14' -fr '2020-08-01' -v
## ./syncPatientMeds.sh -env prod -d hb_sovereign -u 'j.hayes+sovereign@mumms.com' -pw 'Todaysword#14' -fr '2020-08-01' -v
## ./syncPatientMeds.sh -env prod -d hb_eleos -u 'j.hayes+eleos@mumms.com' -pw 'Todaysword#14' -fr '2020-08-01' -v
##
##########

TGT_ENV="qa"
TGT_KC_ENV="qa"
KC_USER=
KC_USERPASS=
DBNAME=
DBHOST=
TGT_PATIENTNUMBER=
FROMDATE=
CSHOST=
verbose=false

function usage() {
  printf "usage: $0 [options] \n\
    options:\n\
      -env,--environment    --  The environment to run against\n\
                                  Default: qa\n\
                                  Options: local, qa, demo, stage, prod\n\
      -u,--user             --  Keycloak user for authentication\n\
      -pw,--password        --  Password for keycloak user\n\
      -d,--dbname           --  the tenant dbname\n\
      -pn,--patientnumber   --  The patientnumber to process (omit to process all)\n\
      -fr,--fromdate        --  Force a re-sync from a given date (omit to sync since last sync)\n\
      -v                    --  Show script progress\n\
      --verbose             --  Show verbose response\n\
      -?,--help             --  This message\n\n"
  exit 1;
}

while [ "$#" -gt 0 ]; do
  case $1 in
    -env|--environment) TGT_ENV=$2; shift 2; continue;;
    -u|--user) KC_USER=$2; shift 2; continue;;
    -pw|--password) KC_USERPASS=$2; shift 2; continue;;
    -d|--dbname) DBNAME=$2; shift 2; continue;;
    -pn|--patientnumber) TGT_PATIENTNUMBER=$2; shift 2; continue;;
    -fr|--fromdate) FROMDATE=$2; shift 2; continue;;
    -v) verbose=true; shift; continue;;
    --verbose) VERBOSE_RESPONSE="--verbose"; shift; continue;;
    -?|--help) usage;;
    *)
  esac
  shift
done

TGT_KC_ENV="$TGT_ENV"

if [ "$TGT_ENV" == "local" ]; then
  DBHOST="localhost"
  CSHOST="http://localhost:3000"
  TGT_KC_ENV="qa"
elif [ "$TGT_ENV" == "qa" ]; then
  DBHOST="hbqa.mumms.com"
  CSHOST="https://clearscripts-server-qa.gca-dev.mumms.com"
elif [ "$TGT_ENV" == "demo" ]; then
  DBHOST="hbdemo.mumms.com"
  CSHOST="https://clearscripts-server-demo.gca-dev.mumms.com"
elif [ "$TGT_ENV" == "stage" ]; then
  DBHOST="hbdb-stage.mumms.com"
  CSHOST="https://clearscripts-server-stage.gca-prod.mumms.com"
elif [ "$TGT_ENV" == "prod" ]; then
  DBHOST="hb-rootdb.mumms.com"
  CSHOST="https://clearscripts-server-prod.gca-prod.mumms.com"
fi

$verbose && echo "proceeding with dbhost $DBHOST"

PATIENTQUERY="select distinct patientnumber from patient "

if [[ -n "$TGT_PATIENTNUMBER" ]]; then
  PATIENTQUERY="${PATIENTQUERY} where patientnumber = '$TGT_PATIENTNUMBER'"
else
  PATIENTQUERY="${PATIENTQUERY} where currentstatus = 'Admitted' or dischargedate >= now() - interval '90 day';"
fi

# PATIENTQUERY="${PATIENTQUERY} limit 5"

$verbose && echo "querying patients: $PATIENTQUERY"

PATIENTNUMBERS=$(psql -t -h "${DBHOST}" -d "${DBNAME}" -U "hummingbird" -c "${PATIENTQUERY}")

echo -e "$PATIENTNUMBERS"

while read PATIENTNUMBER; do
  if [[ -z "${PATIENTNUMBER}" ]]; then
    continue;
  fi

  echo ""
  echo "Processing patient [$PATIENTNUMBER]"

  if [[ -n "$FROMDATE" ]]; then
    echo "..Updating last sync time to $FROMDATE for patient $PATIENTNUMBER"

    VERIFY_PDS_QUERY1="select * from med.patient_data_sync where patientnumber = '${PATIENTNUMBER}';"
    VERIFYRESULT1=$(psql -h "${DBHOST}" -d "${DBNAME}" -U "hummingbird" -c "${VERIFY_PDS_QUERY1}")
    echo "....upsert result:"
    echo "$VERIFYRESULT1"

    INSERT_PDS_QUERY1="insert into med.patient_data_sync (id, deleted, version, lastupdateuser, lastupdatetime, patientnumber, datatype, maintaction, maintactiontime, lastsynctime, lastsynctrigger, medsandprescriptions_id) values (nextval('med.hibernate_sequence'), false, now(), 'g.hesla', now(), '$PATIENTNUMBER', 'MEDICATION', 'PENDING', now(), '${FROMDATE}', 'n/a', -1);"
    INSERTRESULT1=$(psql -h "${DBHOST}" -d "${DBNAME}" -U "hummingbird" -c "${INSERT_PDS_QUERY1}")
    echo "....insert result 1:"
    echo "$INSERTRESULT1"

    INSERT_PDS_QUERY2="insert into med.patient_data_sync (id, deleted, version, lastupdateuser, lastupdatetime, patientnumber, datatype, maintaction, maintactiontime, lastsynctime, lastsynctrigger, medsandprescriptions_id) values (nextval('med.hibernate_sequence'), false, now(), 'g.hesla', now(), '$PATIENTNUMBER', 'ALLERGY', 'PENDING', now(), '${FROMDATE}', 'n/a', -1);"
    INSERTRESULT2=$(psql -h "${DBHOST}" -d "${DBNAME}" -U "hummingbird" -c "${INSERT_PDS_QUERY2}")
    echo "....insert result 2:"
    echo "$INSERTRESULT2"

    INSERT_PDS_QUERY3="insert into med.patient_data_sync (id, deleted, version, lastupdateuser, lastupdatetime, patientnumber, datatype, maintaction, maintactiontime, lastsynctime, lastsynctrigger, medsandprescriptions_id) values (nextval('med.hibernate_sequence'), false, now(), 'g.hesla', now(), '$PATIENTNUMBER', 'PRESCRIPTION', 'PENDING', now(), '${FROMDATE}', 'n/a', -1);"
    INSERTRESULT3=$(psql -h "${DBHOST}" -d "${DBNAME}" -U "hummingbird" -c "${INSERT_PDS_QUERY3}")
    echo "....insert result 3:"
    echo "$INSERTRESULT3"

    UPDATE_PDS_QUERY="update med.patient_data_sync set lastsynctime = '${FROMDATE}' where patientnumber = '${PATIENTNUMBER}';"
    UPDATERESULT=$(psql -h "${DBHOST}" -d "${DBNAME}" -U "hummingbird" -c "${UPDATE_PDS_QUERY}")
    echo "....update result:"
    echo "$UPDATERESULT"

    VERIFY_PDS_QUERY="select * from med.patient_data_sync where patientnumber = '${PATIENTNUMBER}';"
    VERIFYRESULT=$(psql -h "${DBHOST}" -d "${DBNAME}" -U "hummingbird" -c "${VERIFY_PDS_QUERY}")
    echo "....verify result:"
    echo "$VERIFYRESULT"
  fi

  $verbose && echo "..calling sync endpoint..."
  ./kcCurl.sh -h "${CSHOST}" -e "clearscripts/syncdata/patient/$PATIENTNUMBER" -u ${KC_USER} -pw $KC_USERPASS -env $TGT_ENV -X POST

done <<< "$(echo -e "${PATIENTNUMBERS}")";

echo ""
echo "fin"
