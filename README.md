# shell-toolbox
helpful bash scripts

These scripts are convenient and useful for day-to-day work. I've created this repo to track changes to them and to have a backup in case of disaster.

# Sripts:

## cleanHBDev
*~Greg Hesla*

Cleans out the hummingbird project's compiled stuff that eclipse may refuse to clean up.
*May no longer be relevant*

## devdb
*~Greg Hesla*

Stand up a database container for various environments.
**No longer relevant, as I just use a locally installed PostgreSQL server that was installed with homebrew**

## gitcheats
*~Greg Hesla*

Display a git cheat sheet with commonly used git commands

## kcCurl.sh
*~Greg Hesla*

Used to test keycloak-secured endpoints in api servers.

For ease of use, this is symlinked to `/usr/local/bin/kcCurl` for global access
```
ln -hsf `pwd`/kcCurl.sh /usr/local/bin/kcCurl
```

## oc-switch.sh
*~Brad Durrow.*

Used to switch easily between clusters in OpenShift

For ease of use, this is symlinked to `/usr/local/bin/oc-switch` for global access
```
ln -hsf `pwd`/oc-switch.sh /usr/local/bin/oc-switch
```

## oc-wlc.sh
*~Brad Durrow.*

Finds workloads that are having problems in OpenShift.

For ease of use, this is symlinked to `/usr/local/bin/oc-wlc.sh` for global access
```
ln -hsf `pwd`/oc-wlc.sh /usr/local/bin/oc-wlc
```

## pimmer
*~Greg Hesla*

Alias to perform a git merge from a branch with the pattern stories/{xxx}/story

For ease of use, this is symlinked to `/usr/local/bin/pimmer` for global access
```
ln -hsf `pwd`/pimmer /usr/local/bin/pimmer
```

## query
*~Greg Hesla*

Convenience script for querying mumms databases.

For ease of use, this is symlinked to `/usr/local/bin/query` for global access
```
ln -hsf `pwd`/query /usr/local/bin/query
```

## QueryTenants.sh
*~Greg Hesla*

Run a sql query against all tenant databases.

For ease of use, this is symlinked to `/usr/local/bin/queryTenants` for global access
```
ln -hsf `pwd`/QueryTenants.sh /usr/local/bin/queryTenants
```
