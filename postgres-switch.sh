#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# uncomment the line below for debugging
# set -x

#####
# postgres-switch.sh
#
# Author: g.hesla
# Version: 1.0
# Description: Switch running postgresql instance using homebrew.
#####
# Change log:
#   2022-05-03: Created script.
#####

PROGRAMNAME=${0}

function usage() {
  local MSG=$1
  [ -z ${MSG} ] && echo -e "\n${MSG}"
  echo -e "\nUsage: ${PROGRAMNAME} {version}"
  echo "  where {version} is the desired version of postgres to run (must be installed via homebrew). "
  echo ""
  GOODVER=$(brew services list | egrep "postgresql@.*none" | head -n 1 | awk '{print $1}'| sed 's/postgresql@//')
  echo "For example: ${PROGRAMNAME} ${GOODVER}"
  echo -e "\n  The following are currently installed versions of postgresql..."
  brew services list | fgrep "postgresql@" | awk '{print $1}'
  exit;
}

if [[ $# == 0 ]]; then
  usage "ERROR: please provide a postgresql version"
fi

TGT_VERSION=${1:-}

if [ -z ${TGT_VERSION} ]; then
  usage "ERROR: please provide a postgresql version"
fi

echo "Switching to PostgreSQL version ${TGT_VERSION}"

# Check to see that PostgreSQL with the desired version is installed via homebrew
$(brew services list | fgrep "postgresql@${TGT_VERSION}" >/dev/null 2>&1) || usage "ERROR: Target version ${TGT_VERSION} is not installed"

# stop the running version of PostgreSQL
RUNNINGVER=$(brew services list | egrep "postgresql@.*started" | head -n 1 | awk '{print $1}'| sed 's/postgresql@//')
if [[ "${RUNNINGVER}" == "${TGT_VERSION}" ]]; then
  echo "  postgresql@${TGT_VERSION} is already running"
else
  echo "  ...stopping postgresql@${RUNNINGVER}"
  brew services stop postgresql@${RUNNINGVER}
  sleep 3
  echo "  ...starting postgresql@${TGT_VERSION}"
  brew services start postgresql@${TGT_VERSION}
  sleep 3
fi

echo "Done. Postgresql ${TGT_VERSION} should be running..."
psql -h localhost -c "select version();"
