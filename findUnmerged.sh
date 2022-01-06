#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

#####
# findUnmerged.sh
#
# Author: g.hesla
# Version: 1.0
# Description: Find branches that have not yet been merged into the target branch. If no target branch is provided, we will assume the current local branch.
#####
# Change log:
#   2022-01-03: Created script.
#####

TARGETBRANCH=${1}

git branch -a --no-merged ${TARGETBRANCH} | fgrep -e "OP-28" -e "OP-27" |  fgrep -v -e "release/"
