#!/bin/bash

# env vars (change)

export NEO4J_CONTAINER=neo4j-microbekg-tt
export NEO4J_VERSION=5.18
export HTTP_PORT=3300
export BOLT_PORT=3600
export NEO4J_AUTH=none
export HEAP_MAX=4G
export OFFHEAP_MAX=4G

# KG download settings
export KG_NAME=kg-microbe

# Import file settings
export IMPORT_DIR=/import
export NODES_FILE=merged-kg_nodes.fixed.tsv
export EDGES_FILE=merged-kg_edges.tsv

# Host paths (for volume mounts)
export BACKUP_DIR=/home/amannalakath/neo4j-microbekg/backups
export HOST_IMPORT_DIR=/home/amannalakath/neo4j-microbekg/import/
