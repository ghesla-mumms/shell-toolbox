#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

echo "Patching dc/rabbitmq image in hbc2pim..."
./oc patch -n hbc2pim dc/rabbitmq --type=merge --patch=\
'{"spec":{"template":{"spec":{"$setElementOrder/containers":[{"name":"rabbitmq"}],"containers":[{"image":"rabbitmq:management","name":"rabbitmq"}]}},"triggers":[{"type":"ConfigChange"}]}}'

echo "Patching secret/hbprod-sched-postgres-secret database-url in core-scheduler..."
./oc patch -n core-scheduler secret/hbprod-sched-postgres-secret --type=merge --patch=\
'{"data":{"database-url":"amRiYzpwb3N0Z3Jlc3FsOi8vZ2NhLXByb2QtMDAtZGItMi5tdW1tcy5jb206NTQzMi9waW1jc19wcm9k"}}'

echo "Patching secret/hbstage-sched-postgres-secret database-url in core-scheduler..."
./oc patch -n core-scheduler secret/hbstage-sched-postgres-secret --type=merge --patch=\
'{"data":{"database-url":"amRiYzpwb3N0Z3Jlc3FsOi8vZ2NhLXByb2QtMDAtZGItMi5tdW1tcy5jb206NTQzMi9waW1jc19zdGFnZQ=="}}'

function patchProbeAndResource() {
echo "=> Patching: $@"
local NAMESPACE="$1"; shift
local DC_NAME="$1"; shift
local CPU_REQUEST="$1"; shift
local CPU_LIMIT="$1"; shift
local MEMORY_REQUEST="$1"; shift
local MEMORY_LIMIT="$1"; shift
local STARTUP_FAILURE_THRESHOLD="$1"; shift
#local CHECK="$1"; shift

# ~/work/gca-prod4  oc edit -n smartchart dc/smartchart  --output-patch=true                                ✔  2.35 L
#Patch: {"spec":{"template":{"spec":{"$setElementOrder/containers":[{"name":"smartchart-runtime"}],"containers":[{"livenessProbe":{"httpGet":{"path":"/health","port":8080,"scheme":"HTTP"},"timeoutSeconds":5},"name":"smartchart-runtime","readinessProbe":{"httpGet":{"path":"/health","port":8080,"scheme":"HTTP"},"timeoutSeconds":5},"resources":{"limits":{"cpu":"1000m","memory":"40Mi"},"requests":{"cpu":"1m","memory":"10Mi"}},"startupProbe":{"failureThreshold":10,"httpGet":{"path":"/health","port":8080,"scheme":"HTTP"},"initialDelaySeconds":20,"periodSeconds":10}}]}}}}
#deploymentconfig.apps.openshift.io/smartchart edited

echo "--> Setting resources on dc ${DC_NAME} in ${NAMESPACE}..."
./oc set resources -n ${NAMESPACE} dc ${DC_NAME} \
  --requests=cpu=${CPU_REQUEST},memory=${MEMORY_REQUEST} \
  --limits=cpu=${CPU_LIMIT},memory=${MEMORY_LIMIT} || true

#if [[ ${CHECK} =~ "^--[a-z]" ]]; then 
#  SHELL_CHECK_ARG=""
#else
#  SHELL_CHECK_ARG="--"
#fi
echo "--> Setting readiness probe on dc ${DC_NAME} in ${NAMESPACE}..."
./oc set probe -n ${NAMESPACE} dc ${DC_NAME} --readiness --timeout-seconds=5 --initial-delay-seconds=0 --period-seconds=0 --success-threshold=1 --failure-threshold=3 $@
echo "--> Setting liveness probe on dc ${DC_NAME} in ${NAMESPACE}..."
./oc set probe -n ${NAMESPACE} dc ${DC_NAME} --liveness --timeout-seconds=5 --initial-delay-seconds=0 --period-seconds=0 --success-threshold=1 --failure-threshold=3 $@
echo "--> Setting startup probe on dc ${DC_NAME} in ${NAMESPACE}..."
./oc set probe -n ${NAMESPACE} dc ${DC_NAME} --startup --timeout-seconds=0 --initial-delay-seconds=20 --period-seconds=0 --success-threshold=1 --failure-threshold=${STARTUP_FAILURE_THRESHOLD} $@

if [[ ${DC_NAME} =~ "--selector" ]]; then 
  echo "INFO: selector use detected, iterating over list for rollout.."
  for DC in $(./oc get -n ${NAMESPACE} dc ${DC_NAME} -o name); do
  	echo "--> Rolling out latest dc ${DC} in ${NAMESPACE}..."
  	./oc rollout latest -n ${NAMESPACE} dc/${DC} || true
  done
else
  echo "--> Rolling out latest dc ${DC_NAME} in ${NAMESPACE}..."
  ./oc rollout latest -n ${NAMESPACE} dc/${DC_NAME} || true
fi

}

##
## PG Rest
##

patchProbeAndResource authproxy '--selector=app=postgrest-prod' 2m 1000m 20Mi 100Mi 10 '--get-url=http://:3000/hospice?select=healthChk:id'

##
## Node
##

nodeSmall=(
1m
1000m
10Mi
40Mi
10
--get-url=http://:8080/health
)

nodeMedium=(

10m
1000m
20Mi
80Mi
10
--get-url=http://:8080/health
)

nodeHighMem=(
1m
1000m
400Mi
1Gi
10
--get-url=http://:8080/health
)

if false; then
#patchProbeAndResource idg-ui idg 
#patchProbeAndResource pim-scheduler pim-sched
patchProbeAndResource authproxy authproxy-prod "${nodeSmall[@]}"
patchProbeAndResource certification-app certapp-prod "${nodeSmall[@]}"
patchProbeAndResource clearscripts clearscripts-client-prod "${nodeSmall[@]}"
patchProbeAndResource clearscripts clearscripts-client-stage "${nodeMedium[@]}"
patchProbeAndResource dashboard dashboard-prod "${nodeSmall[@]}"
patchProbeAndResource forms forms "${nodeSmall[@]}"
patchProbeAndResource smartchart smartchart "${nodeSmall[@]}"
fi

##
## SpringBoot
##

springBootSmall=(
5m
1000m
250Mi
600Mi
10
)

springBootMedium=(
10m
1000m
400Mi
1Gi
10
)

#4 Minutes
springBootMediumLongStartup=(
10m
1000m
400Mi
1Gi
22
)

springBootHighCPU=(
750m
2000m
650Mi
1.3Gi
10
)

springHighMem=(
10m
1000m
1Gi
1.5Gi
10
)

hbcExporter=(
10m
1000m
6Gi
8Gi
10
)

patchProbeAndResource access boot-access-boot "${springBootMedium[@]}" --get-url=http://:8080/health/
patchProbeAndResource billing-engine billing-engine "${springBootMedium[@]}" --get-url=http://:8080/pasbe/v1/version
patchProbeAndResource clearscripts clearscripts-server-prod "${springBootMediumLongStartup[@]}" --get-url=http://:8080/actuator/health
patchProbeAndResource clearscripts clearscripts-server-stage "${springBootMediumLongStartup[@]}" --get-url=http://:8080/actuator/health
patchProbeAndResource core-scheduler hbprod-sched-client "${springBootMedium[@]}" --get-url=http://:8080/scheduler/management/health
patchProbeAndResource core-scheduler hbprod-sched-server "${springBootMediumLongStartup[@]}" --get-url=http://:8080/management/health
patchProbeAndResource core-scheduler hbstage-sched-client "${springBootMedium[@]}" --get-url=http://:8080/scheduler/management/health
patchProbeAndResource core-scheduler hbstage-sched-server "${springBootMediumLongStartup[@]}" --get-url=http://:8080/management/health
patchProbeAndResource dr-first drfirst-service-prod "${springBootMedium[@]}" --get-url=http://:8443/drfirst/health
patchProbeAndResource dr-first drfirst-service-stage "${springBootMedium[@]}" --get-url=http://:8443/drfirst/health
patchProbeAndResource facesheet-service hbprod-facesheet "${springBootMedium[@]}" --get-url=http://:8080/v1/health
patchProbeAndResource feature-flags feature-flags "${springBootMedium[@]}" --get-url=http://:8080/ff4j-web-console/
patchProbeAndResource hbc2pim hbc-exporter-prod-hbc-2 "${hbcExporter[@]}" -- bash /opt/scripts/hbc-exporter-log-health.sh
patchProbeAndResource hbc2pim hbc-exporter-production "${hbcExporter[@]}" -- bash /opt/scripts/hbc-exporter-log-health.sh
patchProbeAndResource hbc2pim rabbitmq 20m 1000m 115Mi 230Mi 10 --get-url=http://:15672/
patchProbeAndResource observation observation-prod "${springBootMediumLongStartup[@]}" --get-url=http://:8080/actuator/health
patchProbeAndResource reports boot-reports "${springBootMedium[@]}" --get-url=http://:8080/reports/scripts/reports.js
patchProbeAndResource session-unifier session-unifier-prod "${springBootMedium[@]}" --get-url=http://:8080/actuator/info
patchProbeAndResource session-unifier session-unifier-stage "${springBootMedium[@]}" --get-url=http://:8080/actuator/info
patchProbeAndResource tenant-db-metadata boot-db-meta "${springBootMedium[@]}" --get-url=http://:8080/health
patchProbeAndResource tenant-db-metadata hbfirebird-tendb "${springBootMedium[@]}" --get-url=http://:8080/health
patchProbeAndResource tenant-db-metadata hbprod-tendb "${springBootMedium[@]}" --get-url=http://:8080/health
patchProbeAndResource tenant-db-metadata hbstage-tendb "${springBootMedium[@]}" --get-url=http://:8080/health


#Can not find a health check endpoint for these
#patchProbeAndResource dr-first med-history "${springBootMedium[@]}" ???
#patchProbeAndResource dr-first med-history-stage "${springBootMedium[@]}" ???
#patchProbeAndResource geocalculator boot-geocalc "${springBootHighCPU[@]}" ???
#patchProbeAndResource hbc2pim hbc-importer-production "${springBootHighMem[@]}" ???
#patchProbeAndResource reports boot-httpdump "${springBootSmall[@]}" ???


