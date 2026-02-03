#!/usr/bin/env bash
set -euo pipefail

/var/lib/neo4j/bin/neo4j-admin database import full \
  --delimiter='\t' \
  --array-delimiter='|' \
  --ignore-extra-columns=true \
  --overwrite-destination=true \
  --multiline-fields=true \
  --max-off-heap-memory="${OFFHEAP_MAX:-4G}" \
  --nodes="Node=/import/${NODES_FILE:-merged-kg_nodes.fixed.tsv}" \
  --relationships="/import/${EDGES_FILE:-merged-kg_edges.tsv}" \
