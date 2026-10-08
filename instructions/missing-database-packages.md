# Missing Database Packages

Database / data-store packages added to or still missing from ekapkgs (plus
the corepkgs base it overlays). Canonical inventory — other DB tables should
link here rather than duplicate membership.

Last updated: 2026-10-07

## Infrastructure added by this effort

corepkgs' `postgresql` did not expose the `pg_config` attribute that both
PGXS and pgrx extension builds require, so **no** PostgreSQL extension could be
built. This PR adds, in `build-support/postgresql/`:

- `pg_config.nix` / `pg_config.sh` — relocatable `pg_config` wrapper, attached
  to `postgresql.passthru.pg_config`.
- `postgresqlBuildExtension.nix` — PGXS builder (DESTDIR + nested-store
  cleanup), exposed top-level as `postgresqlBuildExtension`.

There is deliberately **no** flat `postgresqlPackages` scope: postgres has one
version here, and extension attrs are a function of the `postgresql` package.

## Added

| Package | Domain | Build | Notes |
|---|---|---|---|
| `postgresqlBuildExtension` | infra | — | PGXS builder |
| `pg_config` (passthru) | infra | — | unblocks all PG extensions |
| `pgvector` | vector (PG) | PGXS | `CREATE EXTENSION vector` smoke-tested |
| `pgmq` | queue (PG) | PGXS | `CREATE EXTENSION pgmq` smoke-tested |
| `pg_cron` | scheduler (PG) | PGXS | `CREATE EXTENSION pg_cron` smoke-tested |
| `rum` | FTS index (PG) | PGXS | index smoke-tested |
| `timescaledb` | time-series (PG) | CMake/PGXS | hypertable smoke-tested |
| `citus` | distributed (PG) | PGXS | `CREATE EXTENSION citus` smoke-tested |
| `thanos` | metrics | Go | `--version` |
| `victorialogs` | logs | Go | `--version` |
| `immudb` | immutable KV | Go | `version` |
| `dgraph` | graph | Go | `version` |
| `weaviate` | vector | Go | `--help` |
| `qdrant` | vector | Rust | `--version` |
| `surrealdb` | document-graph | Rust | `version` |
| `garage` | object store | Rust | `--version` |
| `neo4j` | graph | Java (binary) | `--version` |
| `zookeeper` | coordination | Java (binary) | `version` |
| `couchdb` | document | Erlang | HTTP welcome + create DB smoke-tested |

Python deps added in `python-packages.nix` for the patroni attempt:
`pysyncobj`, `python-etcd`, `ydiff`.

## Already present (not missing)

`postgresql`, `sqlite`, `sqlcipher`, `mysql80`, `mariadb-galera`, `cockroachdb`,
`rqlite`, `monetdb`, `redis`, `valkey`, `memcached`, `tarantool`, `etcd`,
`consul`, `ferretdb`, `pocketbase`, `influxdb`, `prometheus`, `grafana-loki`,
`tempo`, `mimir`, `meilisearch`, `xapian`, `apache-jena`, `minio`, `seaweedfs`,
`glusterfs`, `nats-server`, `activemq`, `pgbouncer`, `pgbackrest`, `barman`,
`leveldb`, `lmdb`, `python3Packages.lancedb`.

## Blocked / deferred (with evidence)

| Package | Blocker | Evidence |
|---|---|---|
| `patroni` | pre-existing base failure: `python3.13-aiohttp-3.14.3` fails to build (broken python `pkgconfig` setup hook: `export: NIX_@wrapperName@... not a valid identifier`), and `py-consul` depends on it. Its 3 new Python deps (`pysyncobj`, `python-etcd`, `ydiff`) were added and build. | `nix-build python3Packages.aiohttp` fails |
| `pgvecto-rs` | upstream marks `broken` for PostgreSQL ≥ 17; our postgres is 17.11. Also needs `cargo-pgrx` 0.12-alpha (we have 0.16.1). | nixpkgs `ext/pgvecto-rs/package.nix` `meta.broken` |
| `vectorchord` | needs `cargo-pgrx` 0.16.0; corepkgs has only `cargo-pgrx` 0.16.1 which does not match. | `pkgs/cargo-pgrx/default.nix:59` |
| `rabbitmq-server` | needs the `beamPackages` Mix/Rebar scope, absent in corepkgs (`erlang` compiler alone is not enough). | `beamPackages` attr absent |
| `emqx` | Erlang release built with the same beamPackages/Mix tooling. | absent |
| `graphite-web` | needs `django-tagging` (absent) plus a heavy Django build. | dep check |
| `solr` | expression absent in pinned nixpkgs. | `ls-tree` |
| `spark` | needs Scala/sbt build tooling absent in corepkgs (`scala` compiler exists, but no sbt). | `sbt` attr absent |
| `clickhouse`, `arangodb`, `scylladb`, `milvus`, `redpanda`, `yugabyte`, `ceph`, `hadoop`, `trino`, `presto`, `elasticsearch`, `opensearch` | intrinsic XL builds; each is a project. | scope decision |

## Name traps (present but NOT the DB)

- `pkgs/chroma` — syntax highlighter (`alecthomas/chroma`), not ChromaDB.
- `pkgs/loki` — C++ design-pattern library (use `grafana-loki`).
- `pkgs/drill` — HTTP load tester, not Apache Drill.
- `pkgs/chromaprint` — audio fingerprinting.
- `python3Packages.sphinx` — docs generator, not Sphinx Search.
