FROM neo4j:5.18

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip bash ca-certificates \
  && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir pandas pyarrow aiohttp rich

WORKDIR /app

COPY scripts/import.sh /app/import.sh
COPY scripts/builder-entrypoint.sh /app/builder-entrypoint.sh
COPY test-parquet/query-parquet.py /app/query-parquet.py

RUN chmod +x /app/import.sh /app/builder-entrypoint.sh \
  && mkdir -p /import \
  && chown -R neo4j:neo4j /app /import

# Default environment variables for kg microbe
ENV KG_NAME=kg-microbe \
    IMPORT_DIR=/import \
    NODES_FILE=merged-kg_nodes.fixed.tsv \
    EDGES_FILE=merged-kg_edges.tsv

USER neo4j
ENTRYPOINT ["/bin/bash","-lc","/app/builder-entrypoint.sh"]
