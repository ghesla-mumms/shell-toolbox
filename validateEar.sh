#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# set -x

#####
# validateEar.sh
#
# Author: Brandon Deriso/Greg Hesla
# Version: 1.0
# Description: Validate that the HBEE.ear is ready to be deployed.
#####
# Change log:
#   2022-04-28: Created script.
#####

if [[ $# == 0 ]]; then
  # demo is excluded from the below list because it happens automatically
  echo "Please provide a deployment phase (qa|demo|stage|prod)"
  exit 1
fi

PHASE=${1}
BUILDER_DIR=
IPA_DIR=
BUILDER_SHA=
IPA_SHA=

case ${PHASE} in
  "qa")
    echo "validating qa"
    BUILDER_DIR="/usr/local/persistent/artifacts/wf-dev/current-qa"
    IPA_DIR="/var/cf-masterfiles/external/hummingbird/wf-dev"
    ;;
  "demo")
    echo "validating demo"
    BUILDER_DIR="/usr/local/persistent/artifacts/wf-master/current"
    IPA_DIR="/var/cf-masterfiles/external/hummingbird/wf-master"
    ;;
  "stage")
    echo "validating stage"
    BUILDER_DIR="/usr/local/persistent/artifacts/wf-release/current-stage"
    IPA_DIR="/var/cf-masterfiles/external/hummingbird/wf-stage"
    ;;
  "prod")
    echo "validating prod"
    BUILDER_DIR="/usr/local/persistent/artifacts/wf-release/current-prod"
    IPA_DIR="/var/cf-masterfiles/external/hummingbird/wf-prod"
    ;;
esac

AWK () {
 awk '{print $1}'
}

BUILDER_SHA=$(ssh prod-gce-hbbuild-2.mumms.com sha1sum ${BUILDER_DIR}/HBEE.ear | AWK)
IPA_SHA=$(ssh ipa.mumms.com sha1sum ${IPA_DIR}/HBEE.ear | AWK)

echo "Builder hash: ${BUILDER_SHA}"
echo "IPA hash: ${IPA_SHA}"

if [ "${BUILDER_SHA}" != "${IPA_SHA}" ]; then
 echo "The ear is NOT in place!"
 exit 1
else
 echo "The ear is in place."
 exit
fi
