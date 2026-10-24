# Pins open-code-review's review scope for a Nix package repository.
#
# Upstream compiles a blocklist of "provider directories" into the binary
# (internal/diff/git.go). A file under one of them is dropped before the
# per-file selection gates run, so no rule can bring it back and the tool
# reports a review with the file silently missing. Upstream v1.13.3
# (alibaba/open-code-review#1642) removed the literal "pkgs/" from that list;
# before it, every file under a repository-root pkgs/ — where Nix package
# sources live — was dropped.
#
# The check runs offline: `ocr review --preview` returns before the LLM
# runtime is loaded (cmd/opencodereview/review_cmd.go), so no API key and no
# network are involved.
{
  runCommand,
  gitMinimal,
  jq,
  open-code-review,
}:

runCommand "open-code-review-review-scope"
  {
    nativeBuildInputs = [
      gitMinimal
      jq
      open-code-review
    ];

    meta.description = ''
      Checks that a repository-root pkgs/ stays inside open-code-review's
      review scope and that no file is dropped as a provider directory
    '';
  }
  ''
    repo="$TMPDIR/repo"
    mkdir -p "$repo/pkgs/foo" "$repo/python/pkgs/bar"
    printf '{ }: { }\n' > "$repo/pkgs/foo/default.nix"
    printf '{ }: { }\n' > "$repo/python/pkgs/bar/default.nix"

    export HOME="$TMPDIR"
    git -C "$repo" init -q
    git -C "$repo" config user.email test@example.com
    git -C "$repo" config user.name "Test User"
    git -C "$repo" add -A
    git -C "$repo" commit -qm base

    printf '# change\n' >> "$repo/pkgs/foo/default.nix"
    printf '# change\n' >> "$repo/python/pkgs/bar/default.nix"

    preview="$(cd "$repo" && ocr review --preview --format json)"
    echo "$preview"

    # The root pkgs/ file is the one upstream used to drop; the nested one
    # guards the prefix match against a regression that excludes every
    # directory containing "pkgs".
    for path in pkgs/foo/default.nix python/pkgs/bar/default.nix; do
      if ! jq -e --arg path "$path" \
        'any(.files[]; .path == $path and .will_review)' <<< "$preview" > /dev/null; then
        echo "$path is not in the review set" >&2
        exit 1
      fi
    done

    if jq -e 'any(.files[]; .exclude_reason == "provider_directory")' <<< "$preview" > /dev/null; then
      echo "a file was dropped as a provider directory" >&2
      exit 1
    fi

    touch $out
  ''
