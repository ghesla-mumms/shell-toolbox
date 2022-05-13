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
MAJOR=$(echo "${NEWVER}" | cut -d . -f 1)
MINOR=$(echo "${NEWVER}" | cut -d . -f 2)

if [ -z ${NEWVER} ]; then
  echo "ERROR: a new version is required"
  exit 1;
fi
echo -e "\nUpdating PIM version to ${NEWVER}"

echo -e "\n  Updating PIM version in hbgwt/HBDynaWeb/build.xml:"
echo "    ...major version before:"
grep hbgwt/HBDynaWeb/build.xml -e "property name=\"MajorVersion\""
echo "    ...minor version before:"
grep hbgwt/HBDynaWeb/build.xml -e "property name=\"MinorVersion\""

sed -i '' "s/property name=\"MajorVersion\" value=\".*\"/property name=\"MajorVersion\" value=\"${MAJOR}\"/" hbgwt/HBDynaWeb/build.xml
sed -i '' "s/property name=\"MinorVersion\" value=\".*\"/property name=\"MinorVersion\" value=\"${MINOR}\"/" hbgwt/HBDynaWeb/build.xml

echo -e "\n    ...major version after:"
grep hbgwt/HBDynaWeb/build.xml -e "property name=\"MajorVersion\""
echo "    ...minor version after:"
grep hbgwt/HBDynaWeb/build.xml -e "property name=\"MinorVersion\""

echo -e "\n  Updating PIM version in hbgwt/HBUnitTest/pom.xml:"
echo "    ...before:"
grep hbgwt/HBUnitTest/pom.xml -e "<version>.*-SNAPSHOT</version>"

sed -E -i '' "s/<version>.*-SNAPSHOT<\/version>/<version>${NEWVER}-SNAPSHOT<\/version>/" hbgwt/HBUnitTest/pom.xml

echo "    ...after:"
grep hbgwt/HBUnitTest/pom.xml -e "<version>.*-SNAPSHOT</version>"
