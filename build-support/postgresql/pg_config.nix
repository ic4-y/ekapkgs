# pg_config — a relocatable replacement for PostgreSQL's removed shell script.
#
# The corepkgs postgresql derivation builds and installs its own pg_config into
# the dev output ($dev/bin/pg_config) and records `nix-support/pg_config.env`
# with @out@/@man@ placeholders, but does not expose a usable `pg_config` attr
# (upstream nixpkgs does, via this file). This reconstructs it so PGXS
# extensions and buildPgrxExtension can consume `postgresql.pg_config`.
#
# Source: nixpkgs pkgs/servers/sql/postgresql/pg_config.nix
{
  diffutils,
  lib,
  replaceVarsWith,
  runtimeShell,
  # The PostgreSQL package this pg_config describes.
  postgresql,
  # The placeholders in the packaged pg_config.env that must be substituted,
  # keyed by output name.
  outputs,
}:

replaceVarsWith {
  name = "pg_config";
  src = ./pg_config.sh;
  dir = "bin";
  isExecutable = true;
  replacements = {
    inherit runtimeShell;
    "pg_config.env" = replaceVarsWith {
      name = "pg_config.env";
      src = "${lib.getDev postgresql}/nix-support/pg_config.env";
      replacements = outputs;
    };
  };
  nativeCheckInputs = [ diffutils ];
  # The expected output only matches when outputs have *not* been altered by
  # postgresql.withPackages.
  postCheck = lib.optionalString (outputs.out == lib.getOutput "out" postgresql) ''
    if [ -e ${lib.getDev postgresql}/nix-support/pg_config.expected ]; then
        diff ${lib.getDev postgresql}/nix-support/pg_config.expected <($out/bin/pg_config)
    fi
  '';
}
