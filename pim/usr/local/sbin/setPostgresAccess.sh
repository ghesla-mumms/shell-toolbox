#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

#set -x

POSTGRES_DB='hummingbird'
UNSAFE_HOSTNAME='hb-rootdb.mumms.com'
#Should the number of unsafe rows and "0" when safe
SAFETY_CHECK="SELECT COUNT(*) FROM hospice WHERE dbhost='${UNSAFE_HOSTNAME}' OR bihost='${UNSAFE_HOSTNAME}';"

POSTGRES_SERVICE='postgresql-9.4.service'

POSTGRES_USER="postgres"

#Typically /var/lib/pgsql
#POSTGRES_HOME=$(echo ~${POSTGRES_USER})
POSTGRES_HOME=/var/lib/pgsql

#Typically /var/lib/pgsql/9.4/data/pg_hba.conf
PGDATA="${POSTGRES_HOME}/9.4/data"

#Typically /var/lib/pgsql/9.4/data/pg_hba.conf
HBA_PATH="${PGDATA}/pg_hba.conf"

HBA_OPEN_PATH="/var/tmp/pg_hba.open"

#From https://stackoverflow.com/questions/2990414/echo-that-outputs-to-stderr
echoerr() { 
  printf "%s\n" "$*" >&2
}

usage() {
 echoerr "usage: $0 (localAdminOnly|restoreAccess)"
 exit 1
}

if [[ -n ${1:-} ]]; then
  ACTION=${1:-}; shift
else
  usage
fi

localAdminOnly() {
  if sudo test -e "${HBA_OPEN_PATH}"; then
    echoerr "FATAL: Could not safely create backup; ${HBA_OPEN_PATH} already exists"
    exit 1
  fi

  if ! sudo -u "${POSTGRES_USER}" mv "${HBA_PATH}" "${HBA_OPEN_PATH}"; then 
    echoerr "FATAL: Could not move ${HBA_PATH} to ${HBA_OPEN_PATH}"
    exit 1
  fi

  if sudo test -e "${HBA_PATH}"; then
    echoerr "FATAL: ${HBA_OPEN_PATH} still exists when it shouldn't"
    exit 1
  fi

  echo "local all postgres peer" | sudo -u ${POSTGRES_USER} tee -a ${HBA_PATH} >/dev/null
  echo "local all hummingbird md5" | sudo -u ${POSTGRES_USER} tee -a ${HBA_PATH} >/dev/null
}

safetyCheck() {
  if ! sudo -u "${POSTGRES_USER}" psql --quiet -tA -c "SELECT 1;" >/dev/null; then
    echoerr "FATAL: Could not connect to posgres"
    exit 1
  fi

  if ! sudo -u "${POSTGRES_USER}" psql --quiet -tA -d hummingbird -c "SELECT 1;" >/dev/null; then
    echoerr "FATAL: Could not connect to hummingbird database"
    exit 1
  fi

  if ! COUNT=$(sudo -u "${POSTGRES_USER}" psql --quiet -tA -d ${POSTGRES_DB} -c "${SAFETY_CHECK}"); then
    echoerr "FATAL: Could not determine if hospice table was safe (safety check query returned an error)"
    exit 1
  fi

  if [[ -z ${COUNT} ]]; then
    echoerr "FATAL: Could not determine if hospice table was safe (safety check query did not return a value)"
    exit 1
  fi

  if [[ ${COUNT} -gt 0 ]]; then
    echoerr "FATAL: Hospice table was not safe (found ${COUNT} unsafe rows)"
    exit 1
  fi
}

restoreAccess() {
  if ! sudo test -e "${HBA_OPEN_PATH}" ; then
    echoerr "FATAL: ${HBA_OPEN_PATH} does not exist to restore to ${HBA_PATH}"
    echoerr "INFO: Perhaps this script wasn't called with localAdminOnly"
    exit 1
  fi

  if ! sudo -u "${POSTGRES_USER}" mv "${HBA_OPEN_PATH}" "${HBA_PATH}"; then
    echoerr "FATAL: Could not move ${HBA_OPEN_PATH} to ${HBA_PATH}"
    exit 1
  fi
}

postgresReload() {
  if sudo systemctl status "${POSTGRES_SERVICE}" >/dev/null; then
    sudo systemctl reload "${POSTGRES_SERVICE}"
  else
    echoerr "INFO: It doesn't appear that ${POSTGRES_SERVICE} is running so reload is not needed or even possible."
  fi
}

case ${ACTION} in

  localAdminOnly)
    localAdminOnly
    postgresReload
    ;;

  restoreAccess)
    safetyCheck
    restoreAccess
    postgresReload
    ;;

  *)
    usage
    ;;
esac
