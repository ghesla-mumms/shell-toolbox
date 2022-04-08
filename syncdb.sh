#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

#####
# syncdb.sh
#
# Author: g.hesla
# Version: 1.0
# Description: Sync postgres database from remote to local.
#
#   This uses the pgsync utility provided here:
#     https://github.com/ankane/pgsync
#####
# Change log:
#   2022-01-06: Created script.
#####

#####
# pgsync parameters explained...
#
# --db {dbconfig}        : Use the .pgsync-{dbconfig}.yml configuration file to
#                          perform sync.
# --schema-first         : Sync the schema first, then copy the data.
# --defer-constraints-vs : For foreign keys - add the constraints after the
#                          database has been populated.
#####
pgsync --db qa-demo1 --schema-first --defer-constraints-v2 --debug
