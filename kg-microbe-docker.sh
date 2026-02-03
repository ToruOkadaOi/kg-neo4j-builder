#!/bin/bash

# env vars

export NEO4J_CONTAINER=neo4j-microbekg2
export NEO4J_VERSION=5.18
export HTTP_PORT=3300
export BOLT_PORT=3600
export NEO4J_AUTH=none
export HEAP_MAX=4G
export OFFHEAP_MAX=4G
export NODES_FILE=merged-kg_nodes.fixed.tsv
export EDGES_FILE=merged-kg_edges.tsv
export BACKUP_DIR=/home/amannalakath/neo4j-microbekg/backups
export IMPORT_DIR=/home/amannalakath/neo4j-microbekg/import/
