#!/bin/bash

#####
#
# verifyChangeLogs.sh
#
# This script will check databases to ensure that liquibase changelogs have been run against them.
#
# This script assumes a properly established .pgpass file for database connectivity.
#
# ./verifyChangeLogs.sh -l {HBDIR}/hbgwt/HBJPA/liquibase/changelog -h hbqa.mumms.com -lb LATEST
#
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
URL=
INACTIVE=false
CHANGELOGDIR=
CHANGELOGLOOKBACK="LATEST"
# QUERYSTRING=
# QUERYFILE=

verbose=false

function usage() {
  printf "usage: $0 [options] \n\
    example: $0 -l {HBDIR}/hbgwt/HBJPA/liquibase/changelog -h hbqa.mumms.com -lb LATEST
    options:\n\
      -h,--host             --  The target database host (required)\n\
      -U,--dbuser           --  The username for the db connection (default: ${DBUSER}) (required)\n\
      -p,--dbport           --  The port for the db connection (default: ${DBPORT}) (required)\n\
      -d,--dbname           --  The target tenant dbname\n\
      -b,--bin              --  The target tenant bin\n\
      -i,--inactive         --  Process inactive tenants\n\
      -l,--changelogdir     --  Location where changelogs are located\n\
      -lb,--lookback        --  How far through the changelogs should we look?\n\
                                  FULL - check full history (This will take a long time!)\n\
                                  SAMPLE - check the last 20 lines from each changelog file\n\
                                  LATEST (default) - check the last 20 lines from the latest changelog file\n\
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
    -i|--inactive) INACTIVE=true; shift; continue;;
    -l|--changelogdir) CHANGELOGDIR=$2; shift 2; continue;;
    -lb|--lookback) CHANGELOGLOOKBACK=$2; shift; continue;;

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

if [[ -n "$TENANTBIN" && -n "$DBNAME" ]]; then
  echo "Do not provide both a bin and a dbname."
  usage;
fi

if [[ -z "$CHANGELOGDIR" ]]; then
  echo "The changelog directory (-l,--changelogdir) parameter is required."
  usage;
fi

echo ""
echo "Begin verifying liquibase changelog application..."
echo ""

$verbose && [ -n "${TENANTBIN}" ] && echo "Querying ${DBHOST} for bin ${TENANTBIN}"
$verbose && [ -n "${DBNAME}" ] && echo "Querying ${DBHOST} for db ${DBNAME}"
$verbose && [ -z "${TENANTBIN}" ] && [ -z "${DBNAME}" ] && echo "Querying ${DBHOST} for all tenants"

TGT_DBHOST=
TGT_DBNAME=
TGT_BIN=
TGT_FIRM=
TGT_LOCATIONNAME=
TGT_LOCATION=
HOSPICERECORD=
TENANTRECORD=

CHANGESETSFROMFILE=""
CHANGESETS=""
[ "$CHANGELOGLOOKBACK" == "FULL" ] && echo -e "Checking all changelogs - this will take awhile!\n"
[ "$CHANGELOGLOOKBACK" == "SAMPLE" ] && echo -e "Checking last 20 changesets of each changelog file.\n"
[ "$CHANGELOGLOOKBACK" == "LATEST" ] && echo -e "Checking last 20 changesets of latest changelog file. \n"

for changelog in `ls ${CHANGELOGDIR}/db.changelog-v*`; do
  if [ "$CHANGELOGLOOKBACK" == "FULL" ]; then
    $verbose && echo " Adding all changesets from ${changelog}"
    [ -n "$CHANGESETS" ] && CHANGESETS="${CHANGESETS}\n"
    CHANGESETS="${CHANGESETS}$(cat $changelog | grep "<changeSet id=" | cut -d "\"" -f 2)"
  fi
  if [ "$CHANGELOGLOOKBACK" == "SAMPLE" ]; then
    $verbose && echo " Adding last 20 changesets of ${changelog}"
    CHANGESETSFROMFILE="$(cat $changelog | grep "<changeSet id=" | cut -d "\"" -f 2)"
    [ -n "$CHANGESETS" ] && CHANGESETS="${CHANGESETS}\n"
    CHANGESETS="${CHANGESETS}$(echo -e "$CHANGESETSFROMFILE" | tail -20 )"
  fi
done;
if [ "$CHANGELOGLOOKBACK" == "LATEST" ]; then
  $verbose && echo " Adding last 20 changesets lines of ${changelog}"
  [ -n "$CHANGESETS" ] && CHANGESETS="${CHANGESETS}\n"
  CHANGESETSFROMFILE="$(cat $changelog | grep "<changeSet id=" | cut -d "\"" -f 2)"
  CHANGESETS="$(echo -e "$CHANGESETSFROMFILE" | tail -20 )"
fi

$verbose && echo "  checking for the following changesets..."
$verbose && echo "${CHANGESETS}"
$verbose && echo ""

SUPPORTQUERY="select dbhost as TGT_DBHOST, dbname as TGT_DBNAME, bin as TGT_BIN, hbcfirm as TGT_FIRM from hospice"
[ -n "$TENANTBIN" ] && SUPPORTQUERY="${SUPPORTQUERY} where bin='${TENANTBIN}';"
[ -n "$DBNAME" ] && SUPPORTQUERY="${SUPPORTQUERY} where dbname='${DBNAME}';"
if [ -z "${TENANTBIN}" ] && [ -z "${DBNAME}" ]; then
  SUPPORTQUERY="${SUPPORTQUERY} where dbname <> '' and bin <> '' ";
  if ! $INACTIVE; then
    SUPPORTQUERY="${SUPPORTQUERY} and status = 'ACTIVE' "
  fi
  SUPPORTQUERY="${SUPPORTQUERY} order by bin;"
fi

$verbose && echo "querying support database (${ROOTDBNAME}): ${SUPPORTQUERY}"
$verbose && echo "cmd: psql -t -h ${DBHOST} -p ${DBPORT} -d ${ROOTDBNAME} -U ${DBUSER} -c \"${SUPPORTQUERY}\""
MISSINGTENANTLIST=""
MISSINGTENANTLISTSEP=""
HOSPICERECORDS=$(psql -t -h "${DBHOST}" -p "${DBPORT}" -d "${ROOTDBNAME}" -U "${DBUSER}" -c "${SUPPORTQUERY}")

$verbose && echo ""

# psql -t -h "${DBHOST}" -p "${DBPORT}" -d "${ROOTDBNAME}" -U "${DBUSER}" -c "${SUPPORTQUERY}" | while read HOSPICERECORD; do
while read HOSPICERECORD; do
  if [[ -z "${HOSPICERECORD}" ]]; then
    continue;
  fi
  $verbose && echo "${HOSPICERECORD}"
  TGT_DBHOST=`echo "${HOSPICERECORD}" | cut -d '|' -f 1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
  TGT_DBNAME=`echo "${HOSPICERECORD}" | cut -d '|' -f 2 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
  TGT_BIN=`echo "${HOSPICERECORD}" | cut -d '|' -f 3 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
  TGT_FIRM=`echo "${HOSPICERECORD}" | cut -d '|' -f 4 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
  echo "Processing bin ${TGT_BIN} (dbhost: ${TGT_DBHOST}, dbname: ${TGT_DBNAME}, firm: ${TGT_FIRM})"

  MISSINGCHANGESETLIST=""
  MISSINGCHANGESETLISTSEP=""

  ! $verbose && printf " "
  while read CHANGESET; do
    ! $verbose && printf "."
    $verbose && printf "  ${TGT_DBNAME} verifying changeset [${CHANGESET}]"
    COUNT=
    COUNT=`psql -t -h "${DBHOST}" -p "${DBPORT}" -d "${ROOTDBNAME}" -U "${DBUSER}" -c "select count(*) from databasechangelog where id = '${CHANGESET}';" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`

    if [[ "${COUNT}" != "1" ]]; then
      $verbose && printf " - MISSING"
      MISSINGCHANGESETLIST="${MISSINGCHANGESETLIST}${MISSINGCHANGESETLISTSEP} - ${CHANGESET}"
      MISSINGCHANGESETLISTSEP="\n"
    else
      $verbose && printf " - OK"
    fi
    $verbose && printf "\n"

  done <<< "$(echo -e "${CHANGESETS}")";
  ! $verbose && printf "\n"

  if [[ "${MISSINGCHANGESETLIST}" != "" ]]; then
    echo -e "${TGT_DBNAME} is missing the following changesets: \n${MISSINGCHANGESETLIST}"
    echo ""
  fi

  $verbose && echo ""
done <<< "$(echo -e "${HOSPICERECORDS}")";

$verbose && echo ""
$verbose && echo "done"
$verbose && echo ""

exit;
