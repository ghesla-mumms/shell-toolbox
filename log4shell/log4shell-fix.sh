#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
# set -x

#####
# https://logging.apache.org/log4j/2.x/security.html
# Remove the JndiLookup class from the log4j-core jar file
#####

# /opt/TIBCOJaspersoft-7.1.1.backup/TIBCOJaspersoft-7.1.1/cmdline/studio/configuration/.m2/repository/org/apache/logging/log4j/log4j-core/2.11.1/log4j-core-2.11.1.jar
# test for a single file
# JARFILE=$1

# echo "Validating sudo permissions. Please provide your password if requested..."
# sudo -v

echo "Finding log4j-core*.jar files that need fixing..."
for JARFILE in $(sudo find / -path /home -prune -o -name "log4j-core*.jar" -type f 2>/dev/null)
do
  echo "Processing file ${JARFILE}"
  JARFILEDIR=$(dirname ${JARFILE})
  # If the jarfile contains the class JndiLookup class...
  if sudo zip -sf ${JARFILE} | fgrep JndiLookup.class
  then
    # create a zip backup of the jar file to be fixed so that java won't be able to read it
    echo " JndiLookup found. Backing up file and removing class..."
    sudo cp -p ${JARFILE} ${JARFILE}.orig
    sudo gzip ${JARFILE}.orig
    sudo zip -q -d ${JARFILE} org/apache/logging/log4j/core/lookup/JndiLookup.class
    if sudo zip -sf ${JARFILE} | fgrep JndiLookup.class
    then
      echo "  JndiLookup.class still exists in ${JARFILE}. Failing out!"
      exit 1
    fi
  else
    echo " No JndiLookip class found. Skipping ${JARFILE}"
  fi
  echo ""
done

echo "done"
