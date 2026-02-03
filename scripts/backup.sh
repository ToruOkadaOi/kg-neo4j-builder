#!/usr/bin/env bash
set -euo pipefail

tar czf neo4j_data_backup_$(date +%Y%m%d%H%M%S).tar.gz -C /volume-source . &&
docker exec neo4j neo4j-admin dump --to /host-backup/neo4j.dump