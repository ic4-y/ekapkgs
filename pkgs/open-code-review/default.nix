{
  lib,
  buildGoModule,
  callPackage,
  fetchFromGitHub,
  gitMinimal,
  testers,
}:

let
  # Peeled commit of tag v1.13.3 (tag object dd92520 -> commit 375f64c).
  gitCommit = "375f64cd6f67a48a135da83cfcf59c52669a09cb";
in

buildGoModule (finalAttrs: {
  pname = "open-code-review";
  version = "1.13.3";

  src = fetchFromGitHub {
    owner = "alibaba";
    repo = "open-code-review";
    tag = "v${finalAttrs.version}";
    hash = "sha256-dDKNxjI0pWoJGabUvsGTERYKvKtvEm3UGD/FLPKpfnw=";
  };

  vendorHash = "sha256-LpqnNp6gxHatHH68pM59ESQICDDSVrkZm7AJLVvYTao=";

  subPackages = [ "cmd/opencodereview" ];

  # Upstream's suite shells out to git (git_test.go) — make test assumes it.
  # gitMinimal (as in gitleaks): the full git build needs asciidoc for docs.
  nativeCheckInputs = [ gitMinimal ];

  # buildGoModule already forces CGO_ENABLED=0 (static binary, as upstream's
  # Makefile does) — setting it here collides with the predefined env.

  ldflags = [
    "-s"
    "-w"
    "-X main.Version=v${finalAttrs.version}"
    "-X main.GitCommit=${gitCommit}"
  ];

  # The CLI presents itself as `ocr` (cobra root Use, npm bin, docs) but the
  # Go main package builds as `opencodereview` — link the expected name.
  postInstall = ''
    ln -s $out/bin/opencodereview $out/bin/ocr
  '';

  passthru.tests = {
    # `ocr --version` prints "open-code-review v1.13.3 (<commit>) linux/amd64",
    # so one fixed-string match covers the version and the baked-in commit.
    version = testers.testVersion {
      package = finalAttrs.finalPackage;
      version = "v${finalAttrs.version} (${gitCommit})";
    };

    # Upstream v1.13.3 fixed alibaba/open-code-review#1654: the literal
    # "pkgs/" left the provider-directory blocklist, so a repository-root
    # pkgs/ is reviewable again. Pin that here — see ./test.nix.
    reviewScope = callPackage ./test.nix { open-code-review = finalAttrs.finalPackage; };
  };

  meta = {
    description = "AI-powered code review CLI — reviews git diffs via configurable LLMs";
    homepage = "https://github.com/alibaba/open-code-review";
    changelog = "https://github.com/alibaba/open-code-review/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    mainProgram = "ocr";
    platforms = lib.platforms.linux;
  };
})
