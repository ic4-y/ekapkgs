{
  buildPgrxExtension,
  cargo-pgrx,
  fetchFromGitHub,
  lib,
  postgresql,
}:

buildPgrxExtension (finalAttrs: {
  pname = "pgvectorscale";
  version = "0.9.0";

  src = fetchFromGitHub {
    owner = "timescale";
    repo = "pgvectorscale";
    tag = finalAttrs.version;
    hash = "sha256-whGTJI73wifYkleC+aAbDV4nhwls3uFs1xKcB0zLDRo=";
  };

  doCheck = false;

  cargoHash = "sha256-uaRKUtsUdZPcrQLAixCiEphXQqdsRhi8nSfh9b3w0ao=";
  cargoPatches = [ ./add-Cargo.lock.patch ];

  cargoPgrxFlags = [
    "-p"
    "vectorscale"
  ];

  inherit postgresql;
  inherit cargo-pgrx;

  meta = {
    # Upstream removed support for PostgreSQL 13 on 0.9.0.
    broken = lib.versionOlder postgresql.version "14";
    homepage = "https://github.com/timescale/pgvectorscale";
    description = "Complement to pgvector for high performance, cost efficient vector search on large workloads";
    license = lib.licenses.postgresql;
    platforms = postgresql.meta.platforms;
    changelog = "https://github.com/timescale/pgvectorscale/releases/tag/${finalAttrs.version}";
  };
})
