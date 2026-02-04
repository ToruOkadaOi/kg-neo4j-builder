# skill.md

Shareable runbook for standing up **multiple Neo4j-backed knowledge graphs (KGs)** and importing data using `neo4j-admin`.

This is written to be copy/paste friendly for a lab environment: no user-specific home paths or hardcoded credentials.

---

## 1) Prerequisites

- Docker installed and working.
- Input files available on the host (TSV/CSV or `.neo4j` dump).

---

## 2) Variables (set once per KG instance)

Choose a per-KG “home” directory, container name, and ports.

```bash
# Per-KG root folder (choose any location)
export KG_HOME="$PWD/kg-microbe"

# Neo4j container name
export NEO4J_CONTAINER="neo4j-kg-microbe"

# Ports (pick unique values per KG, check which ports are available)
export HTTP_PORT=7474
export BOLT_PORT=7687

# Neo4j settings
export NEO4J_VERSION=5.18
export HEAP_MAX=4G
export OFFHEAP_MAX=4G

# Auth: use "none" only for local testing.
export NEO4J_AUTH="neo4j/change-me"

# Derived directories
export IMPORT_DIR="$KG_HOME/import"
export DATA_DIR="$KG_HOME/data"
```

Create directories and ensure they are writable:

```bash
mkdir -p "$IMPORT_DIR" "$DATA_DIR"
chmod -R u+rwX,g+rwX "$KG_HOME"
```

---

## 3) Put data into the import directory

### KG-Microbe (TSV)

```bash
cp /path/to/merged-kg_edges.tsv "$IMPORT_DIR/"
cp /path/to/merged-kg_nodes.tsv "$IMPORT_DIR/"
```

### Other KGs

Copy the KG-specific files into `$IMPORT_DIR` (examples):

- RNA: `nodes.csv`, `edges.csv`
- Monarch: `monarch-kg.neo4j` dump, or CSVs

---

## 4) Start a Neo4j container (APOC enabled)

```bash
docker run -d \
  --name "$NEO4J_CONTAINER" \
  -p "$HTTP_PORT":7474 -p "$BOLT_PORT":7687 \
  -v "$IMPORT_DIR":/import \
  -v "$DATA_DIR":/data \
  -e NEO4J_server_memory_heap_max__size="$HEAP_MAX" \
  -e NEO4J_dbms_memory_off_heap_max__size="$OFFHEAP_MAX" \
  -e NEO4J_AUTH="$NEO4J_AUTH" \
  -e NEO4J_PLUGINS='["apoc"]' \
  neo4j:"$NEO4J_VERSION"
```

---

## 5) Pre-processing (KG-Microbe TSV only)

Neo4j bulk import expects specific headers.

### 5.1 Relationships (edges) header

```bash
sed -i '1s/.*/:START_ID\t:TYPE\t:END_ID/' "$IMPORT_DIR/merged-kg_edges.tsv"
```

### 5.2 Nodes header

```bash
sed -i '1s/^id/id:ID(Node)/' "$IMPORT_DIR/merged-kg_nodes.tsv"
```

### 5.3 Fix rows with missing trailing column

Some node rows may have one fewer column. This pads a missing last column with an empty tab.

```bash
awk -F'\t' 'NR==1{print; cols=NF; next} NF==cols{print; next} NF==cols-1{$0=$0"\t"; print; next}' \
  "$IMPORT_DIR/merged-kg_nodes.tsv" \
  > "$IMPORT_DIR/merged-kg_nodes.fixed.tsv"
```

---

## 6) Preferred import pattern (stop DB, one-shot `neo4j-admin`, start DB)

For repeatable lab workflows, prefer running `neo4j-admin` in a **one-shot container** using the same volumes as the Neo4j container.

### Why
- avoids `docker exec` into a long-running container
- keeps “import” actions clearly separated from “serve” actions
- easy to standardize for multiple KGs

### Sequence

```bash
# Stop Neo4j before doing `database import full`
docker stop "$NEO4J_CONTAINER"

# Run the import using the Neo4j image, mounting the *same* volumes from the stopped container
docker run --rm \
  --volumes-from "$NEO4J_CONTAINER" \
  --user neo4j \
  neo4j:"$NEO4J_VERSION" \
  neo4j-admin database import full \
    ...

# Start Neo4j again
docker start "$NEO4J_CONTAINER"
```

---

## 7) Import: KG-Microbe (TSV) using the preferred pattern

```bash
docker stop "$NEO4J_CONTAINER"

docker run --rm \
  --volumes-from "$NEO4J_CONTAINER" \
  --user neo4j \
  neo4j:"$NEO4J_VERSION" \
  neo4j-admin database import full \
    --delimiter='\t' \
    --array-delimiter='|' \
    --skip-duplicate-nodes=true \
    --skip-bad-relationships=true \
    --skip-bad-entries-logging=true \
    --ignore-extra-columns=true \
    --overwrite-destination=true \
    --multiline-fields=true \
    --verbose \
    --bad-tolerance=1017 \
    --high-parallel-io=on \
    --max-off-heap-memory="$OFFHEAP_MAX" \
    --nodes=Node=/import/merged-kg_nodes.fixed.tsv \
    --relationships=/import/merged-kg_edges.tsv

docker start "$NEO4J_CONTAINER"
```

---

## 8) Import: KG-RNA (CSV) using the preferred pattern

Assumes `/import/nodes.csv` and `/import/edges.csv` exist.

```bash
docker stop "$NEO4J_CONTAINER"

docker run --rm \
  --volumes-from "$NEO4J_CONTAINER" \
  --user neo4j \
  neo4j:"$NEO4J_VERSION" \
  neo4j-admin database import full \
    --delimiter=',' \
    --array-delimiter='|' \
    --skip-duplicate-nodes=true \
    --skip-bad-relationships=true \
    --skip-bad-entries-logging=true \
    --ignore-extra-columns=true \
    --overwrite-destination=true \
    --multiline-fields=true \
    --verbose \
    --bad-tolerance=1000 \
    --high-parallel-io=on \
    --max-off-heap-memory="$OFFHEAP_MAX" \
    --nodes=Node=/import/nodes.csv \
    --relationships=/import/edges.csv

docker start "$NEO4J_CONTAINER"
```

---

## 9) Monarch KG: load + migrate a `.neo4j` dump

Assumes a file like `monarch-kg.neo4j` is present in `$IMPORT_DIR`.

Load:

```bash
docker run --interactive --tty --rm \
  --volume="$DATA_DIR":/data \
  --volume="$IMPORT_DIR":/import \
  neo4j:"$NEO4J_VERSION" \
  neo4j-admin database load monarch-kg.neo4j --from-path=/import/ --verbose
```

Migrate (if needed):

```bash
docker run --interactive --tty --rm \
  --volume="$DATA_DIR":/data \
  neo4j:"$NEO4J_VERSION" \
  neo4j-admin database migrate monarch-kg.neo4j ---verbose
```

Then start Neo4j (Section 4).

---

## 10) Managing multiple KGs

Run one KG per directory + port pair:

- `KG_HOME=.../kg-microbe` → `HTTP_PORT=7474`, `BOLT_PORT=7687`
- `KG_HOME=.../kg-rna` → `HTTP_PORT=7475`, `BOLT_PORT=7688`
- `KG_HOME=.../kg-monarch` → `HTTP_PORT=7476`, `BOLT_PORT=7689`

Keep container names unique:

```bash
export NEO4J_CONTAINER="neo4j-kg-rna"
```

---
