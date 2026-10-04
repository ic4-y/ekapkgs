#!/usr/bin/env bash
# Verifies that ekapkgs' open-code-review (ocr) rules resolve as documented.
#
# Usage:  .opencodereview/test.sh
#   OCR=/path/to/ocr  override binary discovery (default: ./result/bin/ocr, then $PATH)
#
# Exit status: 0 = all assertions passed (or skipped because ocr is unavailable),
#              1 = one or more assertions failed.

set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

OCR="${OCR:-}"
if [ -z "$OCR" ]; then
  for candidate in "$REPO/result/bin/ocr" "$(command -v ocr 2>/dev/null || true)"; do
    if [ -n "$candidate" ] && [ -x "$candidate" ]; then OCR="$candidate"; break; fi
  done
fi
if [ -z "$OCR" ] || [ ! -x "$OCR" ]; then
  echo "SKIP: open-code-review (ocr) not found; set OCR=/path/to/ocr" >&2
  exit 0
fi

RULE_JSON=".opencodereview/rule.json"
RULE_MD=".opencodereview/rules/ekapkgs.md"

fails=0
pass() { printf 'ok   - %s\n' "$1"; }
fail() { printf 'FAIL - %s\n' "$1" >&2; fails=$((fails + 1)); }
assert_contains() { # <haystack-file> <needle> <label>
  if grep -qF -- "$2" "$1"; then pass "$3"; else fail "$3 (missing: $2)"; fi
}

# ── 1. Project rule file exists and references the rule markdown ────────────
if [ -f "$RULE_JSON" ] && [ -f "$RULE_MD" ]; then
  pass "project rule files present"
else
  fail "missing $RULE_JSON or $RULE_MD"
fi

# ── 2. Representative reviewable paths resolve to the project rule ──────────
# Note: root pkgs/ is a provider directory and is never reviewed; it is covered
# by its own assertion below. These are the paths a review actually sees.
for path in \
  python/pkgs/requests/default.nix \
  perl/pkgs/foo/default.nix \
  writers/pkgs/bar/default.nix \
  pkgs-many/isl/generic.nix \
  ekaos/modules/services/sshd.nix \
  top-level.nix \
  all-packages.nix \
  pkgs-module.nix \
  ci/eval.nix
do
  out="$("$OCR" rules check "$path" 2>&1)"
  if grep -q 'Source: Project (.opencodereview/rule.json)' <<<"$out" \
     && grep -q 'Pattern: \*\*/\*\.nix' <<<"$out"; then
    pass "$path -> project rule"
  else
    fail "$path did not resolve to the project rule"
  fi
done

# ── 3. The resolved rule merges the built-in nix rule with the ekapkgs rules ─
resolved="$("$OCR" rules check top-level.nix 2>&1)"
if grep -q 'System-Specific Rules (Mandatory)' <<<"$resolved" \
   && grep -q 'User-Specific Rules (Mandatory)' <<<"$resolved"; then
  pass "system rule merged with user rule"
else
  fail "expected System+User rule sections in resolved rule"
fi
if grep -q 'Favor precision over recall' <<<"$resolved" && grep -q 'Ekala' <<<"$resolved"; then
  pass "resolved rule contains built-in and ekapkgs content"
else
  fail "resolved rule is missing built-in or ekapkgs content"
fi

# ── 4. Inverted nixpkgs conventions live in one MUST NOT registry ───────────
# Every ekapkgs/nixpkgs delta must be registered as a "MUST NOT" line in the
# rule file, so the reviewer is never asked for the nixpkgs behaviour. The check
# is structural (line prefix), not a guess over wording.
inversions=(
  'meta.maintainers'
  'meta.teams'
  'passthru.updateScript'
  'pkgs/by-name'
  'nixfmt'
  'package.nix'
  'configurePhaseHook'
  'doCheck'
)
if [ -f "$RULE_MD" ]; then
  if grep -qE '^## Inverted nixpkgs conventions' "$RULE_MD"; then
    pass "inverted-conventions registry present"
  else
    fail "missing '## Inverted nixpkgs conventions' registry section"
  fi
  must_not="$(grep -E '^- MUST NOT ' "$RULE_MD" || true)"
  for token in "${inversions[@]}"; do
    if grep -qF -- "$token" <<<"$must_not"; then
      pass "inversion registered as MUST NOT: $token"
    else
      fail "inversion not registered as a MUST NOT line: $token"
    fi
  done
  # Pure prohibitions must not also appear as positive requirements elsewhere.
  for token in 'meta.maintainers' 'meta.teams' 'passthru.updateScript' 'pkgs/by-name'; do
    total="$(grep -cF -- "$token" "$RULE_MD" || true)"
    within="$(grep -F -- "$token" <<<"$must_not" | wc -l)"
    if [ "$total" = "$within" ]; then
      pass "pure prohibition only on MUST NOT lines: $token"
    else
      fail "inverted convention '$token' also appears outside the registry"
    fi
  done
fi

# ── 5. Resolution semantics: merge, replacement, and missing-ref fallback ────
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/.opencodereview/rules"
printf 'PROBE-USER-RULE\n' > "$scratch/.opencodereview/rules/r.md"
printf '{ }: { }\n' > "$scratch/foo.nix"
git -C "$scratch" init -q

check_semantics() { # <rule.json body> <expected needle> <label>
  printf '%s\n' "$1" > "$scratch/.opencodereview/rule.json"
  local out
  out="$(cd "$scratch" && "$OCR" rules check foo.nix 2>&1)"
  if grep -qF -- "$2" <<<"$out"; then pass "$3"; else fail "$3"; fi
}

check_semantics \
  '{ "rules": [ { "path": "**/*.nix", "rule": ".opencodereview/rules/r.md", "merge_system_rule": true } ] }' \
  'User-Specific Rules (Mandatory)' \
  "merge_system_rule=true inlines the rule file"

check_semantics \
  '{ "rules": [ { "path": "**/*.nix", "rule": ".opencodereview/rules/r.md" } ] }' \
  'PROBE-USER-RULE' \
  "merge_system_rule absent replaces the system rule"

check_semantics \
  '{ "rules": [ { "path": "**/*.nix", "rule": ".opencodereview/rules/missing.md", "merge_system_rule": true } ] }' \
  'Favor precision over recall' \
  "missing rule file falls back to the system rule"

# First-match-wins across sibling entries.
printf '%s\n' '{ "rules": [ { "path": "**/*.nix", "rule": "FIRST-WINS" }, { "path": "**/*.nix", "rule": "SECOND" } ] }' \
  > "$scratch/.opencodereview/rule.json"
first="$(cd "$scratch" && "$OCR" rules check foo.nix 2>&1 | grep -cE 'FIRST-WINS|SECOND')"
if [ "$first" = "1" ] && (cd "$scratch" && "$OCR" rules check foo.nix 2>&1 | grep -q 'FIRST-WINS'); then
  pass "sibling entries resolve first-match-wins"
else
  fail "sibling entries did not resolve first-match-wins"
fi

# ── 6. Documented limitation: root pkgs/ is a provider directory ────────────
lim="$(mktemp -d)"
trap 'rm -rf "$scratch" "$lim"' EXIT
mkdir -p "$lim/pkgs/foo" "$lim/python/pkgs/bar"
printf '{ }: { }\n' > "$lim/pkgs/foo/default.nix"
printf '{ }: { }\n' > "$lim/python/pkgs/bar/default.nix"
git -C "$lim" init -q
git -C "$lim" -c user.email=t@t -c user.name=t add -A
git -C "$lim" -c user.email=t@t -c user.name=t commit -qm base
printf '# x\n' >> "$lim/pkgs/foo/default.nix"
printf '# x\n' >> "$lim/python/pkgs/bar/default.nix"
preview="$(cd "$lim" && "$OCR" review --preview 2>&1)"
if grep -q 'provider directories (pkgs/)' <<<"$preview" \
   && grep -q 'python/pkgs/bar/default.nix' <<<"$preview"; then
  pass "root pkgs/ excluded as provider dir; python/pkgs/ reviewed"
else
  fail "provider-directory behaviour changed; re-check documented limitation"
fi

# ── Summary ─────────────────────────────────────────────────────────────────
if [ "$fails" -eq 0 ]; then
  echo "all rule assertions passed"
  exit 0
fi
echo "$fails assertion(s) failed" >&2
exit 1
