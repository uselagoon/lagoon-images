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
/opt/docker-solr/scripts/init-var-solr

# ensure that the target directory is empty prior to recreation

rm -rf /var/solr/data/$1
echo "Removed $1 core prior to recreation"

# run the precreate-core script again to bring in any new config
/opt/docker-solr/scripts/precreate-core "$@"

# the solr-recreate command only removes and recreates the cores, it doesn't start the solr process
echo "Please ensure that you run solr-foreground after this command as part of your CMD statement"