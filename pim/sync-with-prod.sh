#!/bin/bash
#set -x
set -e
#set -u
set -o pipefail

trap "echo 'Exiting.'; rm -f /var/tmp/SYNC_IN_PROGRESS" EXIT

if [ -f /var/tmp/SYNC_IN_PROGRESS ]; then
  echo "Another Sync is in progress."
  exit 1
fi

echo -n "[$(date -u)] "

if [ -f /opt/hummingbird/SUPPRESS_SYNC ]; then
  echo "Sync is disabled."
  exit 1
fi


COPY_FROM_APP_SERVER=hb-internal.mumms.com
COPY_FROM_PRIMARY_DB=prod-gce-dw-1.mumms.com
COPY_FROM_SECONDARY_DB=gca-prod-00-db-2.mumms.com
SHORT_HOSTNAME=$(hostname -s)
APP_SERVER=${SHORT_HOSTNAME}.mumms.com
DB_LOAD_WINDOW=1440 #In minutes, 1440 = 24 hours
PG_SQL=""

cd /

shopt -s nocasematch

case ${SHORT_HOSTNAME} in
  hbstage06)
    DB_SERVER=hbdb-stage.mumms.com
    ;;

  hbprod-*)
    SKIP_DBS="true"
    echo "Abort!"
    exit 9
    ;;

  *)
    DB_SERVER=${APP_SERVER}
    ;;
esac

pg_do() {
  PGHOST=${1}
  PGDATABASE=${2}
  PGUSER=${3}
  PG_SQL=${4}
  
  PG_COMMAND="psql"

  if [[ ${PGHOST%%.*} == ${HOSTNAME%%.*} && ${PGUSER} == "postgres"} ]]; then
    unset PGHOST
    PG_COMMAND="sudo -u postgres psql --username=${PGUSER}"
  else
    PG_COMMAND="psql --host=${PGHOST} --username=${PGUSER}"
  fi

  ${PG_COMMAND} --tuples-only --no-align --set ON_ERROR_STOP=on --command="${PG_SQL}" ${PGDATABASE}
}

shell_do() {
  SHELL_HOST=${1}
  SHELL_USER=${2}
  SHELL_COMMAND=${3}
  
  SHELL_AUTH=""

  if [[ ${SHELL_HOST%%.*} != ${HOSTNAME%%.*} ]]; then
    SHELL_AUTH="ssh -t hummingbird_sync_user@${SHELL_HOST}"
  fi

  if [[ ${SHELL_USER} != ${USER} ]]; then
    SHELL_AUTH="${SHELL_AUTH} sudo -Hu ${SHELL_USER}"
  fi

  ${SHELL_AUTH} ${SHELL_COMMAND}
}

########################
# Pre-requisite checks #
########################
#
#PREREQ_LIST=(
#  ${APP_SERVER} ${USER} /opt/wildfly/bin/jboss-cli.sh
#  ${DB_SERVER}  ${USER} /usr/local/sbin/setPostgresAccess.sh
#  ${DB_SERVER}  ${USER} /usr/local/sbin/sync_postgres_with_prod_wal-e.sh
#)
#
#MISSING_PREREQ_COUNTER=0
#
#for PREREQ in ${PREREQ_LIST[@]}; do
#  shell_do "${PREREQ%%/*}" << 'EOF'
#    CHECK_REQ () {
#      if ! [[ -e "${PREREQ##* }" ]]; then
#        echo "${PREREQ##* } is missing on ${SHELL_HOST}."
#        MISSING_PREREQ_COUNTER=$((++MISSING_PREREQ_COUNTER))
#      fi
#    }
#    CHECK_REQ
#EOF
#done
#
#if [[  ${MISSING_PREREQ_COUNTER} > 0  ]]; then
#  exit 1
#fi
#
###########################
#End Pre-requisite checks #
###########################

shell_do ${APP_SERVER} root 'touch /var/tmp/SYNC_IN_PROGRESS'

echo 'Making sure we are running in "screen"...'
if [[ ! $TERM == screen* ]]; then
  echo "It does not appear that you are running inside a \"screen\"."
  answer=""
  while [[ ${answer} != YES && ${answer} != NO ]]; do
    read -p "Would you like to continue against advisement (YES or NO please)?" answer
  done
  if [[ ${answer} == NO ]]; then
    echo "Okay, bailing..."
    exit 1
  fi
fi

shell_do ${APP_SERVER} root "/sbin/service cfengine3 stop"

echo "rsyncing ${COPY_FROM_APP_SERVER}:/opt/hummingbird to /opt/hummingbird (locally as root)..."
until shell_do ${APP_SERVER} root "rsync -avzXP --delete-before --exclude '**/data/console.log' hummingbird_sync_user@${COPY_FROM_APP_SERVER}:/opt/hummingbird/ /opt/hummingbird/"; do
  echo "Retrying rsync..."
done

echo "Trying to undeploy HBEE.ear, this may fail; if it hangs for more than a"
echo "minute press ctrl-c once and the script may recover."
shell_do ${APP_SERVER} wildfly '/opt/wildfly/bin/jboss-cli.sh --connect --command="undeploy HBEE.ear"' || true
echo "Undeploy completed with RC=$?"

shell_do ${APP_SERVER} root '/sbin/service wildfly stop'

shell_do ${APP_SERVER} root '/sbin/service httpd stop'

echo "Trying to remove slapcat.ldif..."
sudo rm /tmp/slapcat.ldif || true

echo "Creating slapcat.ldif on ${COPY_FROM_APP_SERVER}..."
shell_do ${COPY_FROM_APP_SERVER} ldap '/usr/sbin/slapcat -l /tmp/slapcat.ldif'

echo "Copying slapcat.ldif from ${COPY_FROM_APP_SERVER}..."
scp hummingbird_sync_user@${COPY_FROM_APP_SERVER}:/tmp/slapcat.ldif /tmp/

if [[ ${SHORT_HOSTNAME%%.*} != ${APP_SERVER%%.*} ]]; then
  echo "Copying ldif to ${APP_SERVER}..."
  scp /tmp/slapcat.ldif ${APP_SERVER}:/tmp/
fi

shell_do ${APP_SERVER} root "/sbin/service slapd stop" || true

echo "Removing all files from /var/lib/ldap..."
shell_do ${APP_SERVER} ldap 'find /var/lib/ldap/ -type f -delete'

echo "Loading ldif..."
shell_do ${APP_SERVER} ldap 'slapadd -l /tmp/slapcat.ldif'

shell_do ${APP_SERVER} root '/sbin/service slapd start'

if [[ -n ${SKIP_DBS} ]]; then
  echo "Skipping DB Syncs."
else
  echo "Triggering wal-e backup-fetch followed by WAL replay on ${DB_SERVER}..."
  if [[ ${DB_SERVER} = ${APP_SERVER} ]]; then
    DB_SERVER=${APP_SERVER}
  fi

  #It would be nice to do this async
  shell_do ${DB_SERVER} ${USER} '/usr/local/sbin/sync_postgres_with_prod_wal-e.sh'
  
fi #if [[ -n ${SKIP_DBS} ]]

shell_do ${APP_SERVER} root '/sbin/service wildfly start'

shell_do ${APP_SERVER} root '/sbin/service httpd start'

echo "Trying to deploy /opt/hummingbird/HBEE.ear..."
HB_REDEPLOY_COMMAND="/opt/wildfly/bin/jboss-cli.sh --connect --commands=\"if \(result.value == true\) of /deployment=HBEE.ear:read-attribute\(name=status\), undeploy HBEE.ear, end-if, deploy --force /opt/hummingbird/HBEE.ear\""
shell_do ${APP_SERVER} wildfly "${HB_REDEPLOY_COMMAND}"

shell_do ${APP_SERVER} root '/sbin/service cfengine3 start'

echo "Waiting for all tenants to start-up..."
until [ $(pg_do ${DB_SERVER} hummingbird hummingbird "select count(bin) from hospice where status != 'ACTIVE' AND \"hospiceETL\"") = 0 ]; do
  sleep 10
done

shell_do ${APP_SERVER} root 'touch /opt/hummingbird/SUPPRESS_SYNC'

shell_do ${APP_SERVER} root 'rm /var/tmp/SYNC_IN_PROGRESS'

echo "Finished!"
