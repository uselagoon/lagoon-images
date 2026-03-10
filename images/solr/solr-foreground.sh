#!/bin/bash
# Run the initdb, then start solr in the foreground.
# Lagoon override: in Solr 10 the default mode is SolrCloud; inject
# --user-managed to keep standalone mode unless SOLR_CLOUD_MODE=true.
set -e

if [[ "$VERBOSE" == "yes" ]]; then
    set -x
fi

# Could set env-variables for solr-fg
source run-initdb

if [[ "${SOLR_CLOUD_MODE:-}" != "true" ]] && [[ "$*" != *"--user-managed"* ]]; then
    set -- --user-managed "$@"
fi

exec solr-fg "$@"
