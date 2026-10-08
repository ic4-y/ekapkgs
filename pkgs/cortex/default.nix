{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "1.21.1";
  base = "https://github.com/cortexproject/cortex/releases/download/v${version}";
  cortex = fetchurl {
    url = "${base}/cortex-linux-amd64";
    hash = "sha256-mT+No9TJnZ+4K14mNpUCwaes9MK5XkuHGQ5gjNtXxkk=";
  };
  query-tee = fetchurl {
    url = "${base}/query-tee-linux-amd64";
    hash = "sha256-bQd4p4ZWCRdT/bF+YiEyOkL8SanZLHS9P2EyuSkufH8=";
  };
in
stdenv.mkDerivation {
  pname = "cortex";
  inherit version;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -m755 ${cortex} $out/bin/cortex
    install -m755 ${query-tee} $out/bin/query-tee
    runHook postInstall
  '';

  meta = {
    description = "Horizontally scalable, highly available multi-tenant Prometheus";
    homepage = "https://cortexmetrics.io";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "cortex";
  };
}
