#!/bin/bash
#set -x
set -e

/usr/local/sbin/setPostgresAccess.sh localAdminOnly

INITIAL_RECOVERY_FILE=/var/lib/pgsql/9.4/data/recovery.done

prime_sudo_loop() {
#Try really hard to sudo
  echo 'Priming the sudo pump'
  until sudo -v; do
    echo "Try again...";
    sleep 2;
  done
}

prime_sudo_loop

NEED_TO_MOVE_RECOVERY_FILE=""
if sudo test -e "${INITIAL_RECOVERY_FILE}"; then
  RECOVERY_FILE="${INITIAL_RECOVERY_FILE}"
  NEED_TO_MOVE_RECOVERY_FILE="true"
elif sudo test -e "${INITIAL_RECOVERY_FILE%.done}.conf"; then
  RECOVERY_FILE="${INITIAL_RECOVERY_FILE%.done}.conf"
  echo "WARNING: ${RECOVERY_FILE} already exists; probably from an incomplete sync..."
else
  echo "Couldn't find appropriate recovery.done or recovery.conf; bailing out..."
  exit 9
fi

echo "Calculating WAL-E configs from ${RECOVERY_FILE}..."
WAL_E_CONFIG=$(sudo sed -nre 's#^restore_command\s*=\s*'\''(.*wal-e)\s*wal-fetch .*$#\1#p' ${RECOVERY_FILE})

if [ -z "${WAL_E_CONFIG}" ]; then
  echo "FATAL: Could not calculate wal-e config from ${RECOVERY_FILE}; bailing..."
  exit 9
fi

echo ${WAL_E_CONFIG}
#exit 1

echo 'Stopping postgres'
sudo /usr/sbin/service postgresql-9.4 stop

echo 'Cleaning /var/lib/pgsql/9.4/data...'
sudo find /var/lib/pgsql/9.4/data \! \( -name "*.json" -o -name "*.conf" -o -name "recovery.done" \) -type f -delete

echo 'Fetching the wal-e backup which will be replayed when postgres is started.'

sudo -u postgres sh -c "${WAL_E_CONFIG} backup-fetch /var/lib/pgsql/9.4/data LATEST"

echo "Phase one PITR (backup-fetch) complete; re-priming sudo..."
prime_sudo_loop

echo 'Editing service file if necessary...'
sudo sed -i'' -Ee 's/^(ExecStart=.*) -w (.*)$/\1 -W \2/' /usr/lib/systemd/system/postgresql-9.4.service
sudo systemctl daemon-reload

if [ -n "${NEED_TO_MOVE_RECOVERY_FILE}" ]; then
  echo 'Priming the recovery configuration'
  sudo mv ${INITIAL_RECOVERY_FILE} ${INITIAL_RECOVERY_FILE%.done}.conf
fi


echo 'Starting postgres'
sudo /usr/sbin/service postgresql-9.4 start

pg_do () {
  psql --dbname="${1}" --username="${2}" --command="${3}"
}
   
echo "Waiting for postgres to start."
until [[ $(pg_do postgres hummingbird "SELECT pg_is_in_recovery()") == *f* ]]; do
sleep 60
done

echo "Updating datasource definitions to match this server"
PG_SQL="${PG_SQL} UPDATE hospice SET dbhost = '$(hostname -s).mumms.com'; UPDATE hospice SET bihost = '$(hostname -s).mumms.com';"
pg_do hummingbird hummingbird "${PG_SQL}"

echo "Updating Clearscripts credentials to match this server"
PG_SQL="\
  UPDATE med.site_config SET api_username = 'mavendor4991', tenant_username = 'mu98009', drfirst_systemname = 'mavendor4991', api_password = '3bt6zgi2' WHERE thirdparty_id = -1; 
  UPDATE med.site_config SET tenant_username = 'mumms_demo1_stage' WHERE thirdparty_id = -100;
  UPDATE person SET clearscriptslogin = 'mdoctor1287' WHERE id = -47;
  UPDATE person SET clearscriptslogin = 'maagent9923' WHERE id in (-48,-49);
"
pg_do hb_demo1 hummingbird "${PG_SQL}"

echo "Updating pimreader credentials to match this server"
PG_SQL="alter role pimreader password 'EWxiEzTIGYGLDgJKOIlJhvQsCKzJFCAjyzTEYpmhnvSRdCBR';"
pg_do hummingbird hummingbird "${PG_SQL}"

/usr/local/sbin/setPostgresAccess.sh restoreAccess

echo 'Tail the postgres log and look for \"database system is ready to accept connections\"'

exit 
