#!/usr/bin/env bash
# Builds the package tests this repository runs in CI.
#
# This script is the single home for the list of tests: the workflow calls it
# without naming a single test, so adding a package test cannot mean editing
# the workflow as well.
#
# It also cross-checks the open-code-review release identity. The package
# pins the upstream tag mechanically (src.tag) and the commit it advertises
# by hand (the gitCommit ldflag), and only the first of those can drift
# silently: the version test compares the binary against the same literal it
# baked in. Comparing the advertised commit with the tag's peeled commit
# turns that into a red job.
#
# See ci/eval.sh for the sibling gate.
#
# Usage:  ./ci/tests.sh

set -euo pipefail

cd "$(dirname "$0")/.."

pkg=".#legacyPackages.x86_64-linux.open-code-review"
tests=(
  tests.reviewScope
  tests.version
)

for test in "${tests[@]}"; do
  echo "building open-code-review.$test"
  nix build --no-link "$pkg.$test"
done

# The upstream repository and the tag the package was fetched from, read back
# off the package itself so this check cannot drift from what was built.
read -r homepage tag <<<"$(
  nix eval --raw "$pkg" --apply 'p: "${p.meta.homepage} ${p.src.tag}"'
)"

out="$(nix build --no-link --print-out-paths "$pkg")"
baked="$("$out/bin/ocr" --version | sed -n 's/.*(\([0-9a-f]\{40\}\)).*/\1/p')"

if [ -z "$baked" ]; then
  echo "could not read the advertised commit from $out/bin/ocr --version" >&2
  exit 1
fi

# "refs/tags/<tag>^{}" peels an annotated tag to the commit it points at.
expected="$(git ls-remote --tags "$homepage.git" "refs/tags/$tag^{}" | cut -f1)"

if [ "$baked" != "$expected" ]; then
  echo "open-code-review advertises commit $baked, but tag $tag points at $expected" >&2
  echo "update the gitCommit ldflag in pkgs/open-code-review/default.nix" >&2
  exit 1
fi

echo "open-code-review $tag is commit $baked"
