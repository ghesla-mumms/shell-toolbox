#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

#####
# git-add-repo.sh
#
# Author: g.hesla
# Version: 1.0
# Description: This script is designed to import a git repo into a subdirectory
# of another git repo.
#####
# Change log:
#   2022-04-08: Created script from https://stackoverflow.com/questions/15715825/how-do-you-get-the-git-repositorys-name-in-some-git-repository
#####


repo="$1"
dir="$(echo "$2" | sed 's/\/$//')"
path="$(pwd)"

tmp="$(mktemp -d)"
remote="$(echo "$tmp" | sed 's/\///g'| sed 's/\./_/g')"

git clone "$repo" "$tmp"
cd "$tmp"
reponame="$(basename -s .git `git config --get remote.origin.url`)"
git filter-repo --to-subdirectory-filter ${dir}

cd "$path"
git checkout main
git fetch && git pull
git checkout -b "stories/add-repo/${reponame}"
git remote add ${reponame} ${tmp}
git fetch ${reponame} --no-tags
EDITOR=true git merge --allow-unrelated-histories ${reponame}/master
git remote remove ${reponame}
rm -rf ${tmp}
git status
