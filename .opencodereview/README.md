# `.opencodereview` — ekapkgs review rules for open-code-review

This directory customises [open-code-review (OCR)](https://github.com/alibaba/open-code-review)
for the ekala package set. OCR runs an LLM review over a pull request's diff and
resolves, per file, a natural-language rule that tells the model what to look
for. This directory supplies the ekapkgs-specific rules.

```
.opencodereview/
├── rule.json          # project layer: maps path globs to rules
├── rules/ekapkgs.md   # the authored rule text (referenced by rule.json)
├── test.sh            # executable specification / regression check
└── README.md          # this file
```

## How OCR resolves these rules

OCR resolves a rule for each changed file through four layers, in order; the
first matching entry wins (`v1.13.3`):

1. `--rule <path>` CLI override
2. **`<repo>/.opencodereview/rule.json`** ← this file
3. `~/.opencodereview/rule.json`
4. the embedded system rules (one per language)

Two mechanics matter for authoring:

- A `rules[].rule` value that contains **no spaces or newlines** and ends in
  `.md`/`.txt`/`.markdown` is treated as a **file reference** and inlined
  relative to the repo root. That is how `rule.json` pulls in
  `rules/ekapkgs.md` instead of duplicating its text.
- `merge_system_rule: true` **combines** the matched user rule with the *system*
  rule for that file (the built-in `**/*.nix` rule here). Without it, the user
  rule *replaces* the system rule. The merge reaches only the system layer: two
  of our own entries never combine — the first match wins outright.

### Why one entry, not one entry per scope

It is tempting to add a narrower entry per ecosystem (`python/pkgs/**` →
`python.md`, `pkgs-many/**` → `variants.md`, …). Don't. Because sibling user
entries never merge, a file matching a narrow entry would silently lose both the
system rule and any shared ekapkgs rules unless every entry re-declared them —
duplicating the shared rule text once per scope. Instead there is exactly **one**
`**/*.nix` entry, and scope-specific guidance lives as labelled sections inside
`rules/ekapkgs.md`. OCR has no rule-include mechanism, so this is the only
non-duplicating composition available.

If a future OCR release gains path-scoped includes, this can be split back into
one file per concern without changing the rule content.

## Rule taxonomy

The rule file is its own table of contents. `.opencodereview/rules/ekapkgs.md`
organises the rules into `##` sections by concern and is the single source of
truth for what is covered; this README does not maintain a parallel index.

## ekapkgs deltas from nixpkgs

Several upstream nixpkgs rules are **inverted** or **dropped** here. The
canonical text lives in `rules/ekapkgs.md` under the `## Inverted nixpkgs
conventions` heading, where each delta is stated as a single-line `- MUST NOT`
prohibition. `test.sh` holds an explicit identity oracle — the expected delta
tokens — and asserts that each appears on a `MUST NOT` line, and that the
pure-prohibition tokens appear *only* there. Adding a delta therefore means
adding its token to that oracle as well; the oracle is what makes the list
enforceable, not a claim that no second edit exists. Do not restate the list
anywhere else.

## Review scope: the root `pkgs/` is reviewable

OCR drops files under a fixed set of "provider directories" at the repository
root before rules are even considered (`internal/diff/git.go`,
`providerDirIgnoreDirs`). That list used to include `pkgs/`, which made every
file under a repository-root `pkgs/` — where the new packages live —
unreviewable, with no rule able to re-admit it. It was reported upstream as
[alibaba/open-code-review#1654](https://github.com/alibaba/open-code-review/issues/1654)
and fixed by [alibaba/open-code-review#1642](https://github.com/alibaba/open-code-review/pull/1642)
(merge commit `313519f`), which landed in v1.13.3.

The packaged open-code-review in this repository is v1.13.3, so the whole tree
is reviewable and covered by the single `**/*.nix` entry: root `pkgs/`,
`python/pkgs/`, `perl/pkgs/`, `writers/pkgs/`, `pkgs-many/`, `ekaos/modules/`,
root-level `*.nix` (`top-level.nix`, `all-packages.nix`, `pkgs-module.nix`,
`python-packages.nix`, …), and `ci/`.

`test.sh` deliberately does not assert the scope. It is a property of the
packaged open-code-review — v1.13.3 is what removed the exclusion — and
pinning an upstream detail here would make the harness fail on a version
bump rather than on a broken rule.

## Adding or changing a rule

1. Edit `.opencodereview/rules/ekapkgs.md`. Keep the review posture: precise,
   actionable, and never a formatting or attribute-order remark.
2. If the rule is a new ekapkgs-vs-nixpkgs divergence, add it to the
   `## Inverted nixpkgs conventions` registry in the same file as a single-line
   `- MUST NOT` entry, and add any new token it needs to the `inversions` list in
   `test.sh`.
3. Run `./.opencodereview/test.sh` (needs the OCR binary; set `OCR=/path/to/ocr`
   to override discovery at `./result/bin/ocr` or `$PATH`).
4. To see the exact text the model will receive for a path:

   ```
   ./result/bin/ocr rules check pkgs/<name>/default.nix
   ```

   It prints the resolving layer, the matched glob, and the merged rule text.

## Verification

`test.sh` asserts, against the real binary:

- every representative reviewable path resolves to the project layer with
  pattern `**/*.nix`;
- the resolved rule contains both the built-in system rule and the ekapkgs rules
  (`merge_system_rule` is doing its job);
- the expected inverted-convention tokens are present on `- MUST NOT` lines in
  the registry, and the pure-prohibition tokens appear nowhere else;
- resolution semantics hold: file-reference inlining, replacement without
  `merge_system_rule`, missing-reference fallback, and sibling first-match-wins.

It skips cleanly (exit 0) when the OCR binary is not installed.
