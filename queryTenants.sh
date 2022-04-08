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
INCLUDESUPPORT=false
SHOWHEADERS=""
QUERYSTRING=
QUERYFILE=

SHOWLOGGING=true
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
      -s,--includesupport   --  Include the support (hummingbird) database
      -t,--tuples-only      --  Turn off printing of column names and result row count footers, etc.
      -c,--command          --  Query/command to run against tenants\n\
      -f,--file             --  File containing query/command to run against tenants\n\
      -v,--verbose          --  Show progress\n\
      --silent              --  Do not show any logging\n\
      --help                --  This message\n\n"
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
    -s|--includesupport) INCLUDESUPPORT=true; shift; continue;;
    -c|--command) QUERYSTRING=$2; shift 2; continue;;
    -f|--file) QUERYFILE=$2; shift 2; continue;;
    -t|--tuples-only) SHOWHEADERS=" -t "; shift; continue;;
    -v|--verbose) verbose=true; shift; continue;;
    --silent) SHOWLOGGING=false; shift; continue;;
    --help) usage;;
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

if [[ -z "$QUERYSTRING" && -z "$QUERYFILE" ]]; then
  echo "We need a query or queryfile to run."
  usage;
fi

if [[ -n "$QUERYSTRING" && -n "$QUERYFILE" ]]; then
  echo "Do not provide both a querystring and a queryfile."
  usage;
fi

echo ""
echo "Begin..."
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

SUPPORTQUERY="select dbhost as TGT_DBHOST, dbname as TGT_DBNAME, bin as TGT_BIN, hbcfirm as TGT_FIRM from hospice"
[ -n "$TENANTBIN" ] && SUPPORTQUERY="${SUPPORTQUERY} where bin='${TENANTBIN}';"
[ -n "$DBNAME" ] && SUPPORTQUERY="${SUPPORTQUERY} where dbname='${DBNAME}';"
if [ -z "${TENANTBIN}" ] && [ -z "${DBNAME}" ]; then
  SUPPORTQUERY="${SUPPORTQUERY} where dbname <> '' and bin <> '' ";
  if ! $INACTIVE; then
    SUPPORTQUERY="${SUPPORTQUERY} and status = 'ACTIVE' "
  fi
  if ! $INCLUDESUPPORT; then
    SUPPORTQUERY="${SUPPORTQUERY} and bin <> 'mummsupport' "
  fi
  SUPPORTQUERY="${SUPPORTQUERY} order by bin;"
fi

$verbose && echo "querying support database (${ROOTDBNAME}): ${SUPPORTQUERY}"
$verbose && echo "cmd: psql -t -h ${DBHOST} -p ${DBPORT} -d ${ROOTDBNAME} -U ${DBUSER} -c \"${SUPPORTQUERY}\""
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
  $SHOWLOGGING && echo "Processing bin ${TGT_BIN} (dbhost: ${TGT_DBHOST}, dbname: ${TGT_DBNAME}, firm: ${TGT_FIRM})"

  psql ${SHOWHEADERS} -h "${TGT_DBHOST}" -p "${DBPORT}" -d "${TGT_DBNAME}" -U "${DBUSER}" ${QUERYSTRING:+ -c "$QUERYSTRING"} ${QUERYFILE:+ -f "$QUERYFILE"}
done <<< "$(echo -e "${HOSPICERECORDS}")";

echo ""
echo "done"
echo ""

exit;
