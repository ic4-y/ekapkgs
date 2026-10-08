{
  lib,
  stdenv,
  fetchurl,
  installShellFiles,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "m3db";
  version = "1.6.0";

  src = fetchurl {
    url = "https://github.com/m3db/m3/releases/download/v${finalAttrs.version}/m3_${finalAttrs.version}_linux_amd64.tar.gz";
    hash = "sha256-0NG4+ZWaNFiq7YeQMUnsB34Iqcs1X9giarHf1gx9v7I=";
  };

  sourceRoot = "m3_${finalAttrs.version}_linux_amd64";

  nativeBuildInputs = [ installShellFiles ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -m755 m3dbnode m3query m3coordinator m3aggregator $out/bin/
    runHook postInstall
  '';

  meta = {
    description = "Distributed, scalable time series database";
    homepage = "https://m3db.io";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "m3dbnode";
  };
})
