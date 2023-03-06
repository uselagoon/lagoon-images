#!/usr/bin/env bash

set -eo pipefail

ep /usr/share/opensearch/config/opensearch.yml

if [ ! -z "$EXTRA_OPTS" ]; then
  echo -e "${EXTRA_OPTS}" >> /usr/share/opensearch/config/opensearch.yml
fi

if [ -z "$POD_NAMESPACE" ]; then
  # Single container runs in docker
  echo "POD_NAMESPACE not set, spin up single node"
  sed -i 's/cluster.initial_cluster_manager_nodes:.*//' /usr/share/opensearch/config/opensearch.yml
  echo "cluster.initial_cluster_manager_nodes: ${HOSTNAME}" >> /usr/share/opensearch/config/opensearch.yml
else
  # Is running in Kubernetes/OpenShift, so find all other pods
  # belonging to the namespace
  echo "Opensearch: Running in Kubernetes, setting up for clustering"
  K8S_SVC_NAME=$(hostname -f | cut -d"." -f2)
  echo "Using service name: ${K8S_SVC_NAME}"
  sed -i 's/discovery.seed_hosts:.*//' /usr/share/opensearch/config/opensearch.yml
  sed -i 's/cluster.initial_cluster_manager_nodes:.*//' /usr/share/opensearch/config/opensearch.yml
  echo "discovery.seed_hosts: ${K8S_SVC_NAME}" >> /usr/share/opensearch/config/opensearch.yml
  echo "cluster.initial_cluster_manager_nodes: ${K8S_SVC_NAME}-0" >> /usr/share/opensearch/config/opensearch.yml
fi
