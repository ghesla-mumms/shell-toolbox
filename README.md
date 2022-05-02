# shell-toolbox
helpful bash scripts

These scripts are convenient and useful for day-to-day work. I've created this repo to track changes to them and to have a backup in case of disaster.

# Sripts:

## certs.sh
*~Greg Hesla*

Add missing certificates to all java JREs installed on the local computer.
- This needs a bit of work before it's ready for prime time.

## cleanHBDev
*~Greg Hesla*

Cleans out the hummingbird project's compiled stuff that eclipse may refuse to clean up.
*May no longer be relevant*

## configureDrFirst.sh
*~Greg Hesla*

This script automates many of the tasks for deploying DrFirst for a given client.
`BIN=abcde USERNAME=vendorab123 PASSWORD="abc123" PRACTICE_USER=ab123 ./configureDrFirst.sh`

## devdb
*~Greg Hesla*

Stand up a database container for various environments.
**No longer relevant, as I just use a locally installed PostgreSQL server that was installed with homebrew**

## git-add-repo.sh
*~Greg Hesla*

Merge another git repo into the current git repo.

### example
From the root directory of the project that you want to mergo *into*
`git-add-repo.sh https://github.com/mummssoftware/git-project.git path/to/directory`

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
*~Brad Durrow*

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

## pimmer.sh
*~Greg Hesla*
### *deprecated*
*This has been deprecated in favor of defining a function in .bashrc that accomplishes the same thing*

Alias to perform a git merge from a branch with the pattern stories/{xxx}/story

For ease of use, this is symlinked to `/usr/local/bin/pimmer` for global access
```
ln -hsf `pwd`/pimmer.sh /usr/local/bin/pimmer
```

## pim-version.sh
*~Greg Hesla*

Update the necessary files in PIM with new version number.

For ease of use, this is symlinked to `/usr/local/bin/pim-version` for global access
```
ln -hsf `pwd`/pim-version.sh /usr/local/bin/pim-version
```

## query.sh
*~Greg Hesla*

Convenience script for querying mumms databases.

For ease of use, this is symlinked to `/usr/local/bin/query` for global access
```
ln -hsf `pwd`/query.sh /usr/local/bin/query
```

## queryTenants.sh
*~Greg Hesla*

Run a sql query against all tenant databases.

For ease of use, this is symlinked to `/usr/local/bin/queryTenants` for global access
```
ln -hsf `pwd`/queryTenants.sh /usr/local/bin/queryTenants
```

## validateEar.sh
*~Brandon Deriso/Greg Hesla*

Validate that the HBEE.ear is ready to be deployed.
