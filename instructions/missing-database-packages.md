# Missing Database Packages

Canonical inventory of database / data-store packages in ekapkgs (plus the
corepkgs base it overlays): what is present, what was added by this effort, and
what remains with the exact blocker for each.

Last updated: 2026-10-09 (corepkgs pin bumped for beamPackages; +17 more PG extensions)

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
| `age` | PGXS | CREATE EXTENSION age + Cypher CREATE returns a vertex |
| `wal2json` | PGXS (logical decoding) | slot decodes an INSERT into JSON |
| `pg_hll` | PGXS | hll_cardinality of an added element |
| `pg_net` | PGXS (curl) | CREATE EXTENSION pg_net (shared_preload_libraries) |
| `pg_roaringbitmap` | PGXS | rb_to_array(rb_build('{1,2,3}')) = {1,2,3} |
| `plpgsql_check` | PGXS | CREATE EXTENSION plpgsql_check |
| `pg_bigm` | PGXS | CREATE EXTENSION pg_bigm |
| `temporal_tables` | PGXS | CREATE EXTENSION temporal_tables |
| `pg_squeeze` | PGXS | CREATE EXTENSION pg_squeeze (shared_preload_libraries) |
| `pg_csv` | PGXS | CREATE EXTENSION pg_csv |
| `pg_rational` | PGXS | SELECT '7/3'::rational = 7/3 |
| `jsonb_deep_sum` | PGXS | CREATE EXTENSION jsonb_deep_sum |
| `periods` | PGXS | CREATE EXTENSION periods |
| `pg_relusage` | PGXS | CREATE EXTENSION pg_relusage |
| `pg_libversion` | PGXS | CREATE EXTENSION libversion |
| `pg_tle` | PGXS | CREATE EXTENSION pg_tle (shared_preload_libraries) |
| `pgsql-http` | PGXS (curl) | CREATE EXTENSION http |
| `sqlite_fdw` | PGXS (sqlite) | CREATE EXTENSION sqlite_fdw |
| `tds_fdw` | PGXS (freetds) | CREATE EXTENSION tds_fdw |
| `pg_similarity` | PGXS | CREATE EXTENSION pg_similarity |
| `repmgr` | PGXS (flex/json-c) | CREATE EXTENSION repmgr |
| `pg_auto_failover` | PGXS | CREATE EXTENSION pgautofailover |
| `pgsodium` | PGXS (libsodium) | CREATE EXTENSION pgsodium + version() |
| `pg_background` | PGXS | CREATE EXTENSION pg_background |
| `pg_byteamagic` | PGXS (file) | CREATE EXTENSION byteamagic |
| `pgddl` | PGXS (perl) | CREATE EXTENSION ddlx |
| `apache_datasketches` | PGXS (boost) | CREATE EXTENSION datasketches |
| `postgresql-lantern` | CMake (openssl) | CREATE EXTENSION lantern |

### Extensions still missing

| Extension | Build | Blocker |
|---|---|---|
| `pg_graphql` | pgrx | needs `cargo-pgrx` **0.16.0** exactly; corepkgs ships 0.16.1 → `cargo-pgrx and pgrx library versions must be identical` |
| `pgtap` | PGXS | needs `perlPackages.TAPParserSourceHandlerpgTAP` (absent) + `which` |
| `patroni` | Python | pre-existing base failure: `python3.13-aiohttp` fails on broken python pkgconfig hook; `py-consul` depends on it |
| `pgvecto-rs` | pgrx | upstream marks `broken` for PG ≥ 17 (we are 17.11); also needs cargo-pgrx 0.12-alpha |
| `vectorchord` | pgrx | needs `cargo-pgrx` 0.16.0 (have 0.16.1) |
| `pg_search` (ParadeDB) | pgrx | no expression in pinned nixpkgs |
| `anonymizer` | pgrx | needs `pg-dump-anon` (absent) |
| `pgrouting` | PGXS/CMake | hard-requires the `postgis` extension, whose build needs `gdal` (absent from corepkgs) |
| `postgis` | PGXS/CMake | needs `gdal`/`gdalMinimal` (absent from corepkgs) |
| `pg-gvm` | CMake | needs `gvm-libs` (present, but no expression in pinned nixpkgs) |
| `pgroonga` | PGXS | needs `groonga` (absent from corepkgs) |
| `smlar` | PGXS | upstream marks `broken` for PG ≥ 16 (we are 17) |
| `cstore_fdw` | PGXS | upstream marks `broken` for PG ≥ 14 (we are 17) |
| `pg_ed25519` | PGXS | upstream marks `broken` for PG ≥ 16 (we are 17) |
| `timescaledb_toolkit` | pgrx | needs `cargo-pgrx_0_12_6` (present) but the pgrx build is unverified |
| `omnigres` | PGXS/CMake | needs `clang_18` + python; large, unported |
| `plperl`/`plpython3`/`pltcl`/`plr` | PGXS | procedural language handlers; require postgresql.withPackages support (absent) |

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
| `rethinkdb` | document | autotools (protobuf.v21) | live server "Server ready" |
| `solr` | search | Java binary (java.v17) | live server, core, index + query |
| `accumulo` | wide-column | Java binary (java.v11) | `accumulo-util dump-zoo` vs live ZooKeeper |
| `m3db` | TSDB | Go (buildGoModule) | live m3dbnode, /health `{"ok":true}` |
| `cortex` | TSDB | Go (buildGoModule) | live distributor, /ready + push API |

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
| `rabbitmq-server` | streaming | Erlang/Mix | L | `beamPackages` now in scope (corepkgs#225 merged, pin bumped), but the Elixir-based CLI build hits a corepkgs bug: the default scope pairs Erlang OTP 27 with an Elixir built for OTP 28 — ekala-project/corepkgs#227 |
| `emqx` | streaming | Erlang/Mix | L | `beamPackages` now in scope; Mix/rebar3 build with a large vendored dep set — not yet attempted |
| `hadoop` | batch | Java/Maven | XL | intrinsic |
| `spark` | batch | Scala/sbt | XL | no sbt toolchain |
| `pinot` | OLAP | Java/Maven | XL | intrinsic |
| `trino` | OLAP | Java/Maven | XL | intrinsic |
| `presto` | OLAP | Java/Maven | XL | intrinsic |
| `doris` / `starrocks` | OLAP | Java+C++ | XL | intrinsic |
| `tikv` | KV | Rust | XL | intrinsic |
| `yugabyte` | RDBMS | C++/CMake | XL | intrinsic |
| `memgraph` | graph | CMake + Conan2 | XL | 34 Conan requires incl. custom forks (boost/nuraft/pulsar-client-cpp `-memgraph`), no release binaries |
| `arangodb` | graph | C++/CMake | XL | intrinsic |
| `dragonflydb` | KV | CMake | XL | needs `croncpp`, `flatbuffers_23`, `hnswlib` (absent) |
| `foundationdb` | KV | CMake | XL | intrinsic (openjdk, mono, boost) |
| `ceph` | object store | CMake | XL | intrinsic |
| `pgvecto-rs`, `vectorchord`, `pg_search` | vector (PG) | pgrx | — | see §1 |
| `valkey-search` | vector | Rust module | M | needs module build support |
| `redisearch` | search | C module | M | needs module build support |
| `mssql` / `oracle` / `db2` | RDBMS | proprietary | — | not redistributable |

**Remaining count:** ~26 missing databases (streaming 3, OLAP 5, KV 3,
graph 2, wide-column 1, batch 2, object-store 1, plus pgext 20,
vector 1, search 1, and 3 proprietary).

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
- **`java.buildGradlePackage` does not fetch dependencies**: it always runs
  `gradle --offline` with an empty cache and ignores its `gradleHash` argument,
  so only dependency-free projects build. Tracked in ekala-project/corepkgs#226.
  This blocks source builds of Gradle-based packages (e.g. Apache Solr); they
  are packaged from their upstream binary tarballs instead.
- **`jdk8`** is provided by this repo (`pkgs/jdk8`) since corepkgs' `java` scope
  starts at 11. Needed by Java-8-era toolchains (GWT 2.6.1 in `opentsdb`).
- **`beamPackages`** is now in scope after bumping the corepkgs pin to
  `433e1ddb` (corepkgs#225). `buildMix` works for ordinary Mix projects.
  However the *default* scope pairs Erlang OTP 27 with an Elixir built for
  OTP 28, so Elixir `.beam` files fail to load (`{undef,[{elixir,start,...}]}`);
  use `erlang.v28.beamPackages` for a matched pair. Tracked in
  ekala-project/corepkgs#227.
- **`postgresql` has no `withPackages`**: PG extensions are installed as
  standalone derivations and must be composed onto the server tree by the
  service layer (as the verification harness does).

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
