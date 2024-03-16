#!/bin/bash
#
# Remove an existing core and then reload it from disk
# arguments are: corename configdir
# To simply create a core:
#      docker run -P -d solr solr-recreate mycore
# To create a core from mounted config:
#      docker run -P -d -v $PWD/myconfig:/myconfig solr solr-recreate mycore /myconfig
# To create a core in a mounted directory:
#      mkdir myvarsolr; chown 8983:8983 myvarsolr
#      docker run -it --rm -P -v $PWD/myvarsolr://var/solr solr solr-recreate mycore
set -e

echo "Executing $0" "$@"

if [[ "${VERBOSE:-}" == "yes" ]]; then
    set -x
fi

# init script for handling an empty /var/solr
/opt/solr/docker/scripts/init-var-solr

# ensure that the target core directory is empty prior to recreation
rm -rf /var/solr/data/$1
echo "Removed $1 core prior to recreation"

# run the precreate-core script again to bring in any new config
/opt/solr/docker/scripts/precreate-core "$@"

# set correct solr.lock.type for Lagoon
grep -rl solr.lock.type /var/solr/data/$1 | xargs sed -i '/solr.lock.type/ s/native/none/'
echo "solr.lock.type set for $1 core"
grep -r solr.lock.type /var/solr/data/$1

# the solr-recreate command only removes and recreates the cores, it doesn't start the solr process
echo "Please ensure that you run solr-foreground after this command as part of your CMD statement"
