# Missing Database Packages

Canonical inventory of database / data-store packages in ekapkgs (plus the
corepkgs base it overlays): what is present, what was added by this effort, and
what remains with the exact blocker for each.

Last updated: 2026-10-08 (rethinkdb, solr, accumulo, m3db, cortex added)

Legend: **effort** S/M/L/XL (build+port cost); **build** = how it compiles.
`present` rows show where the package lives; `missing` rows show the blocker.

---

## 1. PostgreSQL extensions

### Added by this effort

`postgresqlBuildExtension` (from PR #5) makes these plain `pkgs/<name>/default.nix`
PGXS/pgrx ports. Each was verified with a live `CREATE EXTENSION`.

| Extension | Build | Verified |
|---|---|---|
| `pgvector` | PGXS | CREATE EXTENSION vector + nearest-neighbour query |
| `pgmq` | PGXS | CREATE EXTENSION pgmq |
| `pg_cron` | PGXS | CREATE EXTENSION pg_cron |
| `rum` | PGXS | rum index |
| `timescaledb` | CMake/PGXS | create_hypertable |
| `citus` | PGXS | CREATE EXTENSION citus |
| `pg_partman` | PGXS | CREATE EXTENSION pg_partman |
| `pgaudit` | PGXS | version-keyed to PG major (17.1) |
| `pg_repack` | PGXS | CREATE EXTENSION pg_repack |
| `h3-pg` | CMake/PGXS | CREATE EXTENSION h3 |
| `pg_ivm` | PGXS | CREATE EXTENSION pg_ivm |
| `pgjwt` | PGXS | CREATE EXTENSION pgjwt |
| `pg-semver` | PGXS | CREATE EXTENSION semver |
| `pg_uuidv7` | PGXS | CREATE EXTENSION pg_uuidv7 |
| `pg_hint_plan` | PGXS | version-keyed (1.7.1) |
| `hypopg` | PGXS | CREATE EXTENSION hypopg |
| `ip4r` | PGXS | CREATE EXTENSION ip4r |
| `system_stats` | PGXS | CREATE EXTENSION system_stats |
| `pg_topn` | PGXS | CREATE EXTENSION pg_topn |
| `pg_safeupdate` | PGXS | version-keyed (1.5) |
| `pgvectorscale` | pgrx | CREATE EXTENSION vectorscale (pgrx works) |

### Extensions still missing

| Extension | Build | Blocker |
|---|---|---|
| `pg_graphql` | pgrx | needs `cargo-pgrx` **0.16.0** exactly; corepkgs ships 0.16.1 → `cargo-pgrx and pgrx library versions must be identical` |
| `pgtap` | PGXS | needs `perlPackages.TAPParserSourceHandlerpgTAP` (absent) + `which` |
| `patroni` | Python | pre-existing base failure: `python3.13-aiohttp` fails on broken python pkgconfig hook; `py-consul` depends on it |
| `pgvecto-rs` | pgrx | upstream marks `broken` for PG ≥ 17 (we are 17.11); also needs cargo-pgrx 0.12-alpha |
| `vectorchord` | pgrx | needs `cargo-pgrx` 0.16.0 (have 0.16.1) |
| `pg_search` (ParadeDB) | pgrx | no expression in pinned nixpkgs |
| Other nixpkgs `ext/*` | PGXS | unported but buildable on demand: `age`, `anonymizer`, `apache_datasketches`, `pg_net`, `pg_graphql`, `pgroonga`, `pgrouting`, `postgis`, `wal2json`, `pg_ivm`, etc. |

---

## 2. Standalone servers

### Added by this effort

| Package | Domain | Build | Smoke |
|---|---|---|---|
| `victoriametrics` | metrics TSDB | Go | live health OK + REST query |
| `pyroscope` | continuous profiling | Go | `--version` |
| `influxdb3` | metrics/analytics | Rust | live serve health OK |
| `questdb` | time-series SQL | Java binary | `--version` |
| `opensearch` | search | Java binary | `--version` (live start needs writable logs dir) |
| `janusgraph` | graph | Java binary | `--version` |
| `flink` | stream processing | Java binary | `--version` (with writable FLINK_LOG_DIR) |
| `pgpool` | PG connection pool | autotools | `--version` |
| `mongodb-ce` | document | binary | live `mongod` start |
| `druid` | real-time analytics | Java binary | installed |
| `duckdb` | embeddable OLAP | CMake | live `SELECT` |
| `faiss` | vector similarity lib | CMake | built |
| `typesense` | search | binary | live server `{"ok":true}` |
| `kafka` | streaming | Java binary (KRaft) | live broker + topic create/list |
| `tidb` | RDBMS | Go (pinned go.v1_25) | live server + MySQL protocol |
| `clickhouse` | OLAP | C++/CMake (own LLVM) | `clickhouse local` SQL query |
| `chromadb` | vector | Python/Rust (maturin) | live server heartbeat + create collection |
| `milvus` | vector | binary (milvus-lite wheel) | live server + pymilvus insert |
| `firebird` | RDBMS | CMake | isql create DB + query |
| `cassandra` | wide-column | Java binary (java.v11) | live server + cqlsh query |
| `hbase` | wide-column | Java binary (java.v11) | `hbase version` |
| `manticore` | search | CMake | indexer builds a 2-doc index |
| `graphite-web` | TSDB/graphing | Python | builds + `graphite` imports |

### Present (pre-existing)

`thanos`, `victorialogs`, `immudb`, `dgraph`, `weaviate`, `qdrant`, `surrealdb`,
`garage`, `neo4j`, `zookeeper`, `couchdb`, `postgresql`, `sqlite`, `sqlcipher`,
`mysql80`, `mariadb-galera`, `cockroachdb`, `rqlite`, `monetdb`, `redis`,
`valkey`, `memcached`, `tarantool`, `etcd`, `consul`, `ferretdb`, `pocketbase`,
`influxdb`, `prometheus`, `grafana-loki`, `tempo`, `mimir`, `meilisearch`,
`xapian`, `apache-jena`, `minio`, `seaweedfs`, `glusterfs`, `nats-server`,
`activemq`, `pgbouncer`, `pgbackrest`, `barman`, `leveldb`, `lmdb`,
`python3Packages.lancedb`.

### Still missing

| Package | Category | Build | Effort | Blocker |
|---|---|---|---|---|
| `scylladb` | wide-column | seastar C++ | XL | intrinsic; seastar toolchain |
| `pulsar` | streaming | Java/Maven | L | expression exists but heavy |
| `rabbitmq-server` | streaming | Erlang/Mix | L | needs the `beamPackages` scope — ekala-project/corepkgs#224 |
| `emqx` | streaming | Erlang/Mix | L | needs the `beamPackages` scope — ekala-project/corepkgs#224 |
| `hadoop` | batch | Java/Maven | XL | intrinsic |
| `spark` | batch | Scala/sbt | XL | no sbt toolchain |
| `opentsdb` | TSDB | Java | L | expression exists but heavy (jdk8, maven artifacts) |
| `pinot` | OLAP | Java/Maven | XL | intrinsic |
| `trino` | OLAP | Java/Maven | XL | intrinsic |
| `presto` | OLAP | Java/Maven | XL | intrinsic |
| `doris` / `starrocks` | OLAP | Java+C++ | XL | intrinsic |
| `tikv` | KV | Rust | XL | intrinsic |
| `yugabyte` | RDBMS | C++/CMake | XL | intrinsic |
| `hugegraph` | graph | Java/Maven | L | not ported |
| `memgraph` | graph | CMake | L | no expression in pinned nixpkgs |
| `arangodb` | graph | C++/CMake | XL | intrinsic |
| `orientdb` | graph | Java | L | not ported |
| `keydb` | KV | make | M | no expression in pinned nixpkgs |
| `dragonflydb` | KV | CMake | XL | needs `croncpp`, `flatbuffers_23`, `hnswlib` (absent) |
| `foundationdb` | KV | CMake | XL | intrinsic (openjdk, mono, boost) |
| `ceph` | object store | CMake | XL | intrinsic |
| `pgvecto-rs`, `vectorchord`, `pg_search` | vector (PG) | pgrx | — | see §1 |
| `usearch` | vector | C++ header | S | not ported |
| `valkey-search` | vector | Rust module | M | needs module build support |
| `redisearch` | search | C module | M | needs module build support |
| `mssql` / `oracle` / `db2` | RDBMS | proprietary | — | not redistributable |

**Remaining count:** ~31 missing databases (streaming 3, OLAP 5, KV 4,
graph 4, TSDB 1, wide-column 1, batch 2, object-store 1, plus pgext 3,
vector 2, search 1, and 3 proprietary).

---

## 3. Build infrastructure notes

- **corepkgs cmake hook**: corepkgs' `cmake` setup-hook defines
  `cmakeConfigurePhase` but never assigns it to `configurePhase`, whereas
  nixpkgs assigns it automatically. Packages whose build drives `cmake` as the
  configure phase must add `cmake.configurePhaseHook` to `nativeBuildInputs`
  (`timescaledb`, `duckdb`, `faiss`, `h3-pg`, `onnxruntime`, `oneDNN`,
  `clickhouse`).
- **corepkgs compiler-rt**: corepkgs dropped the LLVM <20 `compiler-rt` patch
  (llvm/llvm-project@59978b2) that fixes the `__sanitizer::termio` type against
  glibc 2.42. Without it `llvmPackages_19.compiler-rt-libc` — and therefore
  `llvmPackages_19.stdenv`, used to build ClickHouse — fails to compile.
  Re-applied via `top-level.nix`.
- **`pg_config` passthru + `postgresqlBuildExtension`** live in
  `build-support/postgresql/` and are wired via `top-level.nix`. `postgresql` is
  single-version (17.11); no `postgresqlPackages` scope yet.
- **cargo-pgrx 0.16.1** is the only pgrx version present; packages pinned to a
  different exact cargo-pgrx (pg_graphql 0.16.0) cannot build.

## 4. Name traps (present but NOT the DB)

- `pkgs/chroma` — syntax highlighter (`alecthomas/chroma`), not ChromaDB.
- `pkgs/loki` — C++ design-pattern library (use `grafana-loki`).
- `pkgs/drill` — HTTP load tester, not Apache Drill.
- `pkgs/chromaprint` — audio fingerprinting.
- `pkgs/nebula` — **absent**; `by-name/ne/nebula` in nixpkgs is Slack's overlay
  VPN, NOT the graph database.
- `python3Packages.dragonfly` — Python library, NOT DragonflyDB (use `dragonflydb`).
- `python3Packages.sphinx` — docs generator, not Sphinx Search.
- nixpkgs `kafka`/`mongodb`/`elasticsearch` by-name hits are language bindings,
  not servers; use `mongodb-ce` for MongoDB.
