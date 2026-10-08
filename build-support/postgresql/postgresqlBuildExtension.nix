# postgresqlBuildExtension — PGXS builder for PostgreSQL extensions.
#
# PostgreSQL's PGXS assumes all extensions install into the PostgreSQL prefix
# and that pg_config returns those paths. Under Nix every extension is its own
# derivation, so we set DESTDIR to the extension's output and strip the nested
# /nix/store/<postgresql> afterwards.
#
# Source: nixpkgs pkgs/servers/sql/postgresql/postgresqlBuildExtension.nix
{
  lib,
  stdenv,
  postgresql,
  nix-update-script,
}:

lib.extendMkDerivation {
  constructDrv = stdenv.mkDerivation;

  excludeDrvArgNames = [
    "enableUpdateScript"
  ];

  extendDrvArgs =
    finalAttrs:
    {
      enableUpdateScript ? true,
      ...
    }@prevAttrs:
    {
      passthru =
        prevAttrs.passthru or { }
        // lib.optionalAttrs enableUpdateScript {
          updateScript =
            prevAttrs.passthru.updateScript or (nix-update-script (
              lib.optionalAttrs (lib.hasInfix "unstable" prevAttrs.version) {
                extraArgs = [ "--version=branch" ];
              }
            ));
        };

      strictDeps = true;
      buildInputs = [ postgresql ] ++ prevAttrs.buildInputs or [ ];
      nativeBuildInputs = [ postgresql.pg_config ] ++ prevAttrs.nativeBuildInputs or [ ];

      installFlags = [
        "DESTDIR=${placeholder "out"}"
      ]
      ++ prevAttrs.installFlags or [ ];

      postInstall = ''
        # DESTDIR + pg_config install the files into
        # /nix/store/<extension>/nix/store/<postgresql>/...
        # We'll now remove the /nix/store/<postgresql> part:
        if [[ -d "$out${postgresql}" ]]; then
            cp -alt "$out" "$out${postgresql}"/*
            rm -r "$out${postgresql}"
        fi

        if [[ -d "$out${postgresql.dev}" ]]; then
            mkdir -p "''${dev:-$out}"
            cp -alt "''${dev:-$out}" "$out${postgresql.dev}"/*
            rm -r "$out${postgresql.dev}"
        fi

        if [[ -d "$out${postgresql.lib}" ]]; then
            mkdir -p "''${lib:-$out}"
            cp -alt "''${lib:-$out}" "$out${postgresql.lib}"/*
            rm -r "$out${postgresql.lib}"
        fi

        if [[ -d "$out${postgresql.doc}" ]]; then
            mkdir -p "''${doc:-$out}"
            cp -alt "''${doc:-$out}" "$out${postgresql.doc}"/*
            rm -r "$out${postgresql.doc}"
        fi

        if [[ -d "$out${postgresql.man}" ]]; then
            mkdir -p "''${man:-$out}"
            cp -alt "''${man:-$out}" "$out${postgresql.man}"/*
            rm -r "$out${postgresql.man}"
        fi

        # In some cases (postgis) parts of the install script
        # actually work "OK", before we add DESTDIR, so some
        # files end up in
        # /nix/store/<extension>/nix/store/<extension>/...
        if [[ -d "$out$out" ]]; then
            cp -alt "$out" "$out$out"/*
            rm -r "$out$out"
        fi

        if [[ -d "$out/nix/store" ]]; then
            if ! rmdir "$out/nix/store" "$out/nix"; then
              find "$out/nix"
              nixErrorLog 'Found left-overs in $out/nix/store, make sure to move them into $out properly.'
              exit 1
            fi
        fi
      ''
      + prevAttrs.postInstall or "";
    };
}
