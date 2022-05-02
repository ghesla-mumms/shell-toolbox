#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# uncomment the line below for debugging
# set -x

#####
# pimver.sh
#
# Author: g.hesla
# Version: 1.0
# Description: This script updates the pim version in the current directory.
#####
# Change log:
#   2022-01-03: Created script.
#####

NEWVER=${1}

if [ -z ${NEWVER} ]; then
  echo "ERROR: a new version is required"
  exit 1;
fi

grep hbgwt/HBDynaWeb/build.xml -e "property name=\"MinorVersion\""
sed -i '' "s/property name=\"MinorVersion\" value=\".*\"/property name=\"MinorVersion\" value=\"${NEWVER}\"/" hbgwt/HBDynaWeb/build.xml
grep hbgwt/HBDynaWeb/build.xml -e "property name=\"MinorVersion\""
grep hbgwt/HBUnitTest/pom.xml -e "<version>2\..*-SNAPSHOT</version>"
sed -E -i '' "s/<version>(.*)\..*-SNAPSHOT<\/version>/<version>\1.${NEWVER}-SNAPSHOT<\/version>/" hbgwt/HBUnitTest/pom.xml
grep hbgwt/HBUnitTest/pom.xml -e "<version>2\..*-SNAPSHOT</version>"
