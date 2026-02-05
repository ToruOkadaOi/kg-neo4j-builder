#!/usr/bin/env bash
set -euo pipefail

  IMPORT_DIR="${IMPORT_DIR:-/import}"
  KG_NAME="${KG_NAME:-kg-microbe}"

  NODES_FILE="${NODES_FILE:-merged-kg_nodes.fixed.tsv}"
  EDGES_FILE="${EDGES_FILE:-merged-kg_edges.tsv}"

  mkdir -p "$IMPORT_DIR"

  # If local files are present, use them.
  if [[ -f "$IMPORT_DIR/$NODES_FILE" && -f "$IMPORT_DIR/$EDGES_FILE" ]]; then
    echo "Using local files in $IMPORT_DIR"
  else
    # Otherwise attempt download (non-interactive)
    echo "Local files missing; attempting download for: $KG_NAME"
    python3 /app/query-parquet.py \
      "$KG_NAME" \
      --all \
      --out-dir "$IMPORT_DIR"
  fi

  # Hard fail if still missing (covers 'registry has no files' case)
  if [[ ! -f "$IMPORT_DIR/$NODES_FILE" || ! -f "$IMPORT_DIR/$EDGES_FILE" ]]; then
    echo "Import inputs still missing in $IMPORT_DIR:"
    echo "  $NODES_FILE"
    echo "  $EDGES_FILE"
    exit 2
  fi

  # Run import (one-time) then start Neo4j
  echo "Running import..."
  /app/import.sh

  echo "Starting Neo4j..."
  exec neo4j console