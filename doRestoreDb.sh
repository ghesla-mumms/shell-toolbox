#!/bin/bash

##########
##
##         doRefreshScramble.sh
##
## This script is intended to provide a simple method of creating a scrambled
## database with fresh data. It will
##  - back up the source database from the source server in its entirety
##  - clear out the destination database on the destination server by dropping and recreating all schemas
##  - restore the backup of the source database into the destination database on the destination server
##  - scramble the data in the destination database on the destination server
##    - scramble patient and person names
##    - overwrite MBI/Policy numbers with predefined values
##    - overwrite idg team narratives
##  - ensure that person with id -1 is set to "Physician, No Attending"
##  - if destination database is hb_demo1
##    - add clearscripts users
##      - "Clearscripts, Nurse" (g.hesla+csnurse48@mumms.com)
##      - "Clearscripts, Physician" (g.hesla+csphys47@mumms.com)
##    - add apple physician (for testing doclink app)
##      - "Apple, Physician" (jeff+physapple@mumms.com)
##    - ensure clearscripts configuration is properly set up
##    - set up demo data
##      - add Julia demo physician "Johnson, Joy" (j.hayes+demo1rn2@mumms.com)
##      - add Brad demo physician "Acme, Physician" (bradt+phys46@mumms.com)
##      - required fields, facesheet settings, demo patients, etc
##  - if destination database is hb_csdemo2 or hb_csdemo3
##    - ensure clearscripts configuration is properly set up
##
##########

cd `dirname "${BASH_SOURCE[0]}"`
scriptname=`basename $0`

. utilities.sh

#####
## define our helper functions...
#####

function usage()
{
  echo ""
  echo -e "Usage: $scriptname -sh src.mumms.com -sd hb_srcdb -dh dest.mumms.com -dd hb_destdb\n\
          -bf (REQUIRED) the backup filename\n\
          -dh (REQUIRED) the fully-qualified destinate hostname\n\
          -dd (REQUIRED) the destination database\n\
              Note: this script will create the destination database if it does not exist\n\
          -L log level (Default ERROR)\n\
              Options: ERROR, WARN, INFO, DEBUG\n\n\
          -?,--help Show this help screen\n"
}

#
# Set Defaults
#
function setDefaults() {
  printf "\033c"
  LOG_LEVEL=INFO
  setLogLevel $LOG_LEVEL
  SRC_BACKUPFILE=
  DEST_HOST=
  DEST_DBNAME=
  BACKUPLOC=../data
} #end setDefaults

#
# Parse the command line arguments and set globals
#
function parseArgs() {
  while [ "$#" -gt 0 ]; do
    PARAM=$1
    VALUE=$2
    case $PARAM in
      -\?|--help)
        usage
        exit
        ;;
      -bf)
        SRC_BACKUPFILE=$VALUE
        shift 2
        continue
        ;;
      -dh)
        DEST_HOST=$VALUE
        shift 2
        continue
        ;;
      -dd)
        DEST_DBNAME=$VALUE
        shift 2
        continue
        ;;
      -L)
        LOG_LEVEL=$VALUE
        if [ $? -ne 0 ]; then
          LOG_LEVEL=ERROR
        fi
        setLogLevel $LOG_LEVEL
        shift 2
        continue
        ;;
      *)
        echo ""
        echo "ERROR: unknown parameter \"$PARAM\""
        usage
        exit 1
        ;;
    esac
  done

  checkVAR "$SRC_BACKUPFILE" "The backup filename (-bf) is required."
  checkVAR "$DEST_HOST" "The destination hostname (-dh) is required."
  checkVAR "$DEST_DBNAME" "The destination database (-dd) is required."
} #end parseArgs

function confirmProcess() {
  local confirmResponse=
  # Get the user's attention with a beep
  echo -ne '\007'
  echo ""
  echo "You are about to restore $DEST_DBNAME on $DEST_HOST with a the backup found in $SRC_BACKUPFILE."
  echo ""
  echo "ALL existing data in $DEST_DBNAME on $DEST_HOST will be lost PERMANENTLY!"
  echo ""
  read -p " Are you sure that you want to do this (y/n)? " confirmResponse

  if [ "$confirmResponse" != "y" ] && [ "$confirmResponse" != "Y" ]; then
    echo ""
    echo "Received response: \"$confirmResponse\" - aborting refresh/scramble process!";
    exit 1
  else
    echo ""
    echo "Proceeding with restore...";
  fi
}

function prepareDestinationDB() {
  log 2 " Preparing destation database $DEST_DBNAME on $DEST_HOST to to receive the backed up data..."
  local DEST_DATABASE_EXISTS=
  if psql -lqt -h $DEST_HOST | cut -d \| -f 1 | grep -qw $DEST_DBNAME; then
    ## if the database exists, drop all schemas
    echo -ne '\007'
    echo ""
    echo "Database $DEST_DBNAME on $DEST_HOST exists - clearing all schemas"
    read -p "All data in the $DEST_DBNAME database on $DEST_HOST will be PERMANENTLY deleted. Press the 'Enter' to continue or ctrl-c to cancel this process."
    SCHEMA_ROWS=$(psql -t -h $DEST_HOST -d $DEST_DBNAME -c "\dn")
    while read SCHEMA_ROW; do
      if [[ -z "${SCHEMA_ROW}" ]]; then
        continue;
      fi
      SCHEMA_NAME=`echo "${SCHEMA_ROW}" | cut -d '|' -f 1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
      log 3 " dropping schema $SCHEMA_NAME"
      executeSql $DEST_HOST $DEST_DBNAME "drop schema $SCHEMA_NAME cascade;"
    done <<< "$(echo -e "${SCHEMA_ROWS}")";

    # and create the public schema
    log 3 " creating public schema"
    executeSql $DEST_HOST $DEST_DBNAME "create schema if not exists public;"
  else
    ## if the database does not exist, create it
    log 3 " Database $DEST_DBNAME on $DEST_HOST does not exist - creating new database."
    echo "create database $DEST_DBNAME;" | psql -h $DEST_HOST
    checkStatus "An error occurred creating database $DBNAME on $DEST_HOST"
  fi
}

function restoreDestinationDB() {
  if [ ! -f $SRC_BACKUPFILE ]; then
    echo "File not found!"
  fi
  log 2 " Restoring $DEST_DBNAME on $DEST_HOST from backup..."

  pg_restore -j 4 -h ${DEST_HOST} -d ${DEST_DBNAME} $SRC_BACKUPFILE > /dev/null
  #
  # We cannot check the return status here, because the restore process always encounters
  # harmless errors which, nevertheless, cause a non-0 return code.
  #
  # checkStatus "An error occurred restoring the backed up data from $BACKUPLOC/${SRC_DBNAME}.dump to $DEST_DBNAME on $DEST_HOST"
}

#####
## begin processing...
#####

setDefaults

log 2 " begin"

parseArgs $@

## confirmation
confirmProcess

##  - clear out the destination database on the destination server by dropping and recreating all schemas
prepareDestinationDB

##  - restore the backup of the source database into the destination database on the destination server
restoreDestinationDB
