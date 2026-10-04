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
first matching entry wins (`v1.12.11`):

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

`rules/ekapkgs.md` is organised by concern:

| Section | Covers |
| --- | --- |
| Review posture | precision over recall; never flag formatting; no `by-name` layout |
| Evaluation and derivation structure | `finalAttrs` over `rec`, no dangling refs |
| Dependencies | `nativeBuildInputs` vs `buildInputs`, `strictDeps`, `checkInputs` |
| Sources and fetching | pinned hashes, `tag` over `rev`, `refs/tags/` |
| Versioning | must start with a digit, `0-unstable-YYYY-MM-DD` |
| `meta` attributes | description/license/platforms/`mainProgram`/`sourceProvenance` |
| Phases, patches, wrapping | hook discipline, patch comments, `makeBinaryWrapper` |
| Structure and style | avoid `with lib;` |
| Porting from nixpkgs | ekapkgs deltas (see below) |
| Python / Rust / Go / CMake+Meson | build-system specifics |
| Multi-version packages | `pkgs-many` three-file pattern |
| EkaOS modules | option declarations, `settings`, `services.*` |

## Provenance

The rules are **not** invented. They were extracted from two sources:

1. **The ekapkgs/corepkgs conventions themselves** — the pinned corepkgs input's
   `.agents/skills/{packaging,porting,python,rust,go,cmake,meson,structured-attrs,mk-many-variants}`
   skills and `docs/major-differences-nixpkgs.md`. These are authoritative for
   anything that diverges from nixpkgs.
2. **A corpus of real nixpkgs review discussions** — 500 merged new-package pull
   requests (title `init at`, 2024–2025), yielding 14,576 inline review
   comments. Recurring reviewer remarks were clustered by theme and ranked by how
   many distinct PRs raised them, e.g. `finalAttrs`/`rec` (142 PRs), description
   wording (121), input placement (120), `tag` vs `rev` (93), `platforms` (97),
   patch comments (63), `with lib;` (73), `meta.mainProgram` (72).

Rule text is a repo-local authored artifact. It is derived from those sources
but is intentionally not duplicated from the corepkgs prose: the corepkgs skills
remain the source of truth for the conventions, and this file is the
OCR-facing restatement of the subset that a diff reviewer needs.

## ekapkgs deltas from nixpkgs

Several upstream nixpkgs rules are **inverted** or **dropped** here. A rule that
survives review must respect these:

| nixpkgs rule | ekapkgs treatment |
| --- | --- |
| New packages *must* set `meta.maintainers` | **Inverted** — `meta.maintainers`/`meta.teams` are forbidden and fail `check-meta` |
| Add `passthru.updateScript` for automation | **Inverted** — `updateScript` is stripped when porting from nixpkgs |
| Use the `pkgs/by-name/` layout | **Dropped** — packages are auto-registered from `pkgs/<name>/` |
| Format with `nixfmt`/RFC 166, and review it | **Dropped** — CI enforces `nix fmt`; the reviewer must not flag formatting |
| `package.nix` entry point | **Renamed** — ekapkgs uses `default.nix` |
| Implicit CMake/Meson configure phases | **Explicit** — `cmake.configurePhaseHook` / `meson.configurePhaseHook` |
| `doCheck = true` by default | **Inverted** — `doCheck` defaults to `false`; use `passthru.tests` |

## Known limitation: root `pkgs/` is never reviewed

OCR unconditionally excludes a fixed set of "provider directories" at the
repository root before rules are even considered. That list includes `pkgs/`
(`internal/diff/git.go`, `providerDirIgnoreDirs`). Consequences:

- Files under **root `pkgs/`** are reported by `ocr review` as
  _"in provider directories (pkgs/) — not reviewable"_ and are **never sent to
  the model**. The `include` field in `rule.json` cannot re-admit them; the
  comment in the source is explicit that "a `.gitignore` negation cannot
  re-admit one of these paths", and this was confirmed empirically.
- `ocr rules check pkgs/<name>/default.nix` *does* resolve the rule (the filter
  only applies during `ocr review`), so the limitation is invisible unless you
  look at what a review actually selects.

Everything else is reviewable and covered by the single `**/*.nix` entry:
`python/pkgs/`, `perl/pkgs/`, `writers/pkgs/`, `pkgs-many/`, `ekaos/modules/`,
root-level `*.nix` (`top-level.nix`, `all-packages.nix`, `pkgs-module.nix`,
`python-packages.nix`, …), and `ci/`.

Because `pkgs/` is where new packages live, this is a **hard blocker for the
primary goal** while OCR 1.12.11 is unpatched. The fix is to remove `"pkgs/"`
from `providerDirIgnoreDirs` in the packaged open-code-review (or upstream it);
that is tracked as follow-up work, outside Phase 1. `test.sh` pins the current
behaviour so the limitation cannot regress silently, and so the day it is fixed
the test flags it for an update.

## Adding or changing a rule

1. Edit `.opencodereview/rules/ekapkgs.md`. Keep the review posture: precise,
   actionable, and never a formatting or attribute-order remark.
2. If the rule touches an ekapkgs-vs-nixpkgs divergence, update the deltas table
   above as well.
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
- the inverted nixpkgs conventions appear only as prohibitions, never as
  requirements;
- resolution semantics hold: file-reference inlining, replacement without
  `merge_system_rule`, missing-reference fallback, and sibling first-match-wins;
- the documented `pkgs/` provider-directory exclusion still holds.

It skips cleanly (exit 0) when the OCR binary is not installed.
