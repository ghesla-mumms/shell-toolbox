#!/bin/bash


function usage() {
  if [[ -n "$1" ]]; then
    echo ""
    echo "ERROR: $1"
    usage;
  fi

  echo ""
  echo "This script configures DrFirst for a tenant"
  echo ""
  echo -e "The following environment variables are required
    BIN - The PIM bin value for this tenant
    USERNAME - The vendor username for this DrFirst practice
    PASSWORD - The password for the DrFirst vendor username
    PRACTICE_USER - The DrFirst practice username
    REGION (3) - The DrFirst region to use (defaults to 3)
    CHARTMEDS_ID - If provided, will set up tenant for ChartMeds
    DRY_RUN - Do (false) | do not [true] actually make database changes

    Example: BIN=abcde USERNAME=vendorab123 PASSWORD=\"abc123\" PRACTICE_USER=ab123 $0"
    exit 1
}

DRY_RUN=false

USERNAME=${USERNAME:-}
PASSWORD=${PASSWORD:-}
PRACTICE_USER=${PRACTICE_USER:-}
BIN=${BIN:-}
REGION=${REGION:-3}
CHARTMEDS_ID=${CHARTMEDS_ID:-}
VERBOSE=false
SHOWLOGGING=true

DBHOST=${DBHOST:-hb-rootdb.mumms.com}
DW3HOST=${DW3HOST:-prod-gce-dw-3.mumms.com}

STEP=1
NUMSTEPS=10

while [ "$#" -gt 0 ]; do
  case $1 in
    -v|--verbose) VERBOSE=true; shift; continue;;
    --silent) SHOWLOGGING=false; shift; continue;;
    -h|--help) usage;;
    *)
  esac
  shift
done

if [[ -z "$USERNAME" ]]; then
  usage "The vendor username (USERNAME) must be provided."
fi
if [[ -z "$PASSWORD" ]]; then
  usage "The password for the vendor username (PASSWORD) must be provided."
fi
if [[ -z "$PRACTICE_USER" ]]; then
  usage "The practice username (PRACTICE_USER) must be provided."
fi
if [[ -z "$BIN" ]]; then
  usage "The PIM bin (BIN) value must be provided."
fi
if [[ -z "$DBHOST" ]]; then
  usage "The database hostname (DBHOST) value must be provided."
fi
if [[ -z "$DW3HOST" ]]; then
  usage "The DW3 database hostname (DW3HOST) value must be provided."
fi

echo ""
echo "Configuring DrFirst for tenant $BIN in the $DBHOST database using USERNAME: $USERNAME, PASSWORD: $PASSWORD, PRACTICE_USER: $PRACTICE_USER, REGION: $REGION"
echo ""
read -p "Press Ctrl-C to quit, or enter to continue. To do a dry run which does not make any db changes, run this command with DRY_RUN=true"

DBNAME=hb_${BIN}

$DRY_RUN || echo ""
$DRY_RUN || echo "Configuring site_config for DrFirst..."
$DRY_RUN || psql -h $DBHOST -U hummingbird -d $DBNAME -c "insert into med.site_config (id, deleted, version, lastupdateuser, lastupdatetime, site_id, api_username, tenant_username, drfirst_systemname, api_password, ui_url, upload_api_url, download_api_url, thirdparty_id)
 (select nextval('med.hibernate_sequence'), false, now(), 'g.hesla', now(), site.id, '$USERNAME', '$PRACTICE_USER', '$USERNAME', '$PASSWORD', 'https://web3.drfirst.com/sso/portalServices', 'https://engine${REGION}01.drfirst.com/servlet/rcopia.servlet.EngineServlet', 'https://update${REGION}01.drfirst.com/servlet/rcopia.servlet.EngineServlet', -1
 from office site where site.officetype = 'Site' and not site.deleted and not exists (select 1 from med.site_config where site_id = site.id and thirdparty_id = -1));"

echo ""
echo "Configured site_config for DrFirst..."
psql -h $DBHOST -U hummingbird -d $DBNAME -c "select * from med.site_config where thirdparty_id = -1;"

if [[ -n "$CHARTMEDS_ID" ]]; then
  $DRY_RUN || echo ""
  $DRY_RUN || echo "Configuring site_config for ChartMeds..."
  $DRY_RUN || psql -h $DBHOST -U hummingbird -d $DBNAME -c "insert into med.site_config (id, deleted, version, lastupdateuser, lastupdatetime, site_id, api_username, tenant_username, drfirst_systemname, api_password, ui_url, upload_api_url, thirdparty_id, download_api_url, embeddable, verification_startdate)
  (select nextval('med.hibernate_sequence'), false, now(), 'g.hesla', now(), site.id, null, '${CHARTMEDS_ID}', null, 'a7e0022b-457c-47c2-a894-7015cacf5413', null, 'https://www.chartmeds.com/ChartMeds/Authorize/Interfacexml', -100, null, false, null
  from office site where site.officetype = 'Site' and not site.deleted and not exists (select 1 from med.site_config where site_id = site.id and thirdparty_id = -100));"

  echo ""
  echo "Configured site_config for ChartMeds..."
  psql -h $DBHOST -U hummingbird -d $DBNAME -c "select * from med.site_config where thirdparty_id = -100;"
fi

echo ""
echo "Use the following values to populate the configmap values"
psql -h $DBHOST -U hummingbird -d $DBNAME -c "select h.name, h.bin, s.nickname, s.hbclocation, s.id, s.medsandprescriptions_id from hospice h, office s where s.officetype = 'Site' and not s.deleted;"

echo ""
echo -e "Navigate to \033[0;34mhttps://console.gca-prod4.mumms.com/k8s/ns/dr-first/configmaps/drfirst-tenant-config-prod\033[0m and add the following to the configmap, making changes where apropriate"
echo "# {hospice_name} in production (drfirst-service-prod.gca-prod.mumms.com)
      - name: $BIN
        locations:
        - name: {nickname}
          config:
            vendorUserName: $USERNAME
            systemName: $USERNAME
            vendorPassword: $PASSWORD
            rcopiaPracticeUserName: $PRACTICE_USER
            locationId: 1
            pimBin: $BIN
            pimSite: {nickname}
            drFirstUrl: https://update301.drfirst.com/servlet/rcopia.servlet.EngineServlet
        - name: {hbclocation}
          config:
            vendorUserName: $USERNAME
            systemName: $USERNAME
            vendorPassword: $PASSWORD
            rcopiaPracticeUserName: $PRACTICE_USER
            locationId: 1
            pimBin: $BIN
            pimSite: {nickname}
            drFirstUrl: https://update301.drfirst.com/servlet/rcopia.servlet.EngineServlet"

echo ""
read -p "Press enter when the configmap has been updated to continue" CONT

echo ""
echo -e "Navigate to \033[0;34mhttps://console.gca-prod4.mumms.com/k8s/ns/dr-first/deploymentconfigs/drfirst-service-prod\033[0m and rollout the drfirst-service-prod deploymentconfig"
read -p "Press enter when the deploymentconfig has been rolled out to continue" CONT

echo ""
echo -e "Navigate to \033[0;34mhttp://prod-gce-etl-2.mumms.com:8080/org.talend.administrator/\033[0m and kill the 'ClearScripts-Prod' ETL job"

echo ""
read -p "Press enter when the ClearScripts-Prod job has been killed to continue" CONT

$DRY_RUN || echo ""
$DRY_RUN || echo "Ensuring that the $DBNAME database exists in the DW3 database server"
$DRY_RUN || psql -h $DW3HOST -U hummingbird -d postgres -tc "select 1 from pg_database where datname = '$DBNAME';" | grep -q 1 || psql -h $DW3HOST -U hummingbird -d postgres -c "create database $DBNAME;"

echo ""
read -p "Press enter when ready to enable DrFirst for this tenant in PIM" CONT

$DRY_RUN || echo ""
$DRY_RUN || echo "Enabling DrFirst for tenant $BIN in the $DBNAME database on $DBHOST"
$DRY_RUN || psql -h $DBHOST -U hummingbird -d $DBNAME -c "update office set medsandprescriptions_id = -1 where officetype = 'Site' and not deleted;"

echo ""
echo -e "Navigate to \033[0;34mhttp://prod-gce-etl-2.mumms.com:8080/org.talend.administrator/\033[0m and restart the 'ClearScripts-Prod' ETL job"

echo ""
read -p "Press enter when the ClearScripts-Prod job has been started to continue" CONT

echo ""
echo "We will now tail the etl log. Ctrl-C to stop once we verify that demographics and diagnoses are flowing for tenant $BIN"
read -p "Press enter to continue" CONT
echo ""
ssh etl2 './tailetl.sh 30'

echo ""
echo "Last step is to enable DrFirst in C-II. Add the following to the <medications> section in the location.xml for all sites."
echo "\$ ssh hbc[1|2]"
echo "\$ cdxml"
echo "\$ cd $BIN\{location}"
echo "\$ vi location.xml"
echo ""
echo "      <order-entry-system id=\"DrFirst\">
        <name>Dr. First</name>
        <system>clearscript</system>
        <client>true</client>
      </order-entry-system>"
