# Ekala package set review rules

Applies to every Nix expression in this repository. These rules refine the
merged built-in Nix rule (see `.opencodereview/README.md` for provenance).

## Review posture

- Favour precision over recall. Report an issue only when it is likely to break
  evaluation, reproducibility, build isolation, security, or deployment.
- Do not report formatting, attribute ordering, or whitespace: `nix fmt` (treefmt
  with `nixfmt`) runs in CI and is the single source of truth for that.
- Do not require a `pkgs/by-name/` layout. Ekala auto-registers packages from
  their directory name under `pkgs/<name>/` and `pkgs-many/<name>/`.

## Evaluation and derivation structure

- Prefer the `finalAttrs:` fixed-point pattern over `rec { }` for
  self-referencing derivations. `rec` produces surprising overriding semantics
  and is the single most common review remark in the upstream corpus.
- Do not mix bare attribute references with `finalAttrs.`-prefixed ones for the
  same value (for example `version = …` and `finalAttrs.version`).
- Do not define a package as a lambda whose only purpose is to be immediately
  called; pass overridable inputs as function arguments instead.
- Do not reference names that are not in scope (`self`, `super`, `pkgs`,
  `config`, or a function argument the expression does not take).

## Dependencies

- `nativeBuildInputs` is for executables that run on the build platform
  (`pkg-config`, `cmake`, language tools, hook packages). `buildInputs` is for
  libraries linked or loaded on the host platform.
- Flag a build tool placed in `buildInputs`, or a runtime library placed in
  `nativeBuildInputs`.
- Recommend `strictDeps = true` when input placement looks fragile or the
  package is expected to cross-compile; it forces the correct split.
- Check-only dependencies belong in `checkInputs` / `nativeCheckInputs`.

## Sources and fetching

- Every fetcher (`fetchFromGitHub`, `fetchurl`, `fetchgit`, `fetchTarball`,
  `builtins.fetch*`) must pin an immutable revision and a `hash`. Flag mutable
  branches, missing hashes, or a version bump that changes the version but not
  the source revision/hash.
- Prefer `fetchFromGitHub`/`fetchgit` over a raw `fetchurl` tarball when the
  upstream is a Git host, and prefer the official or a trusted mirror.
- Prefer a `tag` over a raw `rev` when upstream publishes tags, and use
  `tag = "v${finalAttrs.version}"` so the fetcher stays in sync with the version.
  Use an explicit `refs/tags/…` only to disambiguate; a plain commit hash is
  acceptable when no tag matches.

## Versioning

- `version` must start with a digit. Strip a leading `v`.
- For unreleased or untagged commits use `0-unstable-YYYY-MM-DD`, or
  `<next-or-last>.Y-unstable-YYYY-MM-DD` when the base version is known.

## `meta` attributes

- `meta.description` must be capitalised, must not start with a definite or
  indefinite article (`A`, `An`, `The`), must not restate the package name, must
  not use subjective language, and must not end with a period.
- `meta.license` must match the upstream project's actual license. Do not guess;
  flag a mismatch or an obviously wrong license value.
- `meta.platforms` must be set; do not claim `linux`/`darwin`/`all` the project
  does not actually support.
- Set `meta.mainProgram` whenever the package installs a primary executable; it
  is required by `lib.getExe` and `nix run`.
- For prebuilt binaries or vendored native code that is not built from source,
  set `meta.sourceProvenance` (`lib.sourceTypes.binaryNativeCode` and friends).
- Add a `meta.changelog` URL when upstream publishes releases.
- Never require `meta.maintainers` or `meta.teams`: they are forbidden here and
  a package that sets them fails `check-meta`.

## Phases, patches, and wrapping

- Do not override `patchPhase`; add to `postPatch` instead.
- When overriding `installPhase` or another default phase, it must call
  `runHook preInstall` / `runHook postInstall` (respectively) so hooks still run.
- Every patch in `patches` needs a comment naming the upstream issue/PR URL, or
  the reason it was not upstreamed. Prefer `fetchpatch`/`fetchpatch2` over
  vendoring a patch file in the tree when it can be fetched immutably.
- Prefer `makeBinaryWrapper`/`makeWrapper` with `wrapProgram` over manually
  editing scripts in `$out`, and add the `makeWrapper` input to
  `nativeBuildInputs`.
- Use `copyDesktopItems` with `desktopItems` for desktop entries rather than
  installing them ad hoc.

## Structure and style to avoid

- Avoid a blanket `with lib;`. Prefer qualified `lib.` references, which keep the
  evaluation scope small.
- Do not add a `passthru.updateScript` to a ported package: it is stripped when
  porting from nixpkgs and is not wanted in this package set.

## Porting a package from nixpkgs

- The entry point is renamed `package.nix` → `default.nix`.
- Build-manager hooks are explicit here: add `cmake.configurePhaseHook`, or
  `meson.configurePhaseHook` plus `ninja`, to `nativeBuildInputs`. A missing hook
  that leaves the package unable to configure is a defect.
- Do not set `doCheck = false` / `doInstallCheck = false` explicitly; they are
  already the defaults. Express test coverage through `passthru.tests`.
- Record every feature disabled for a missing dependency as a
  `# TODO(corepkgs): Port <dep> for <feature>` comment next to the affected input
  or flag. A silent omission is a defect.
- Preserve the upstream license and any security patches.

## Python (`python/pkgs/**`)

- Use `buildPythonPackage` with the `finalAttrs:` pattern.
- Prefer `testPaths` to defer the test suite into `passthru.tests.python`; do not
  set `doCheck = true`.
- `pythonImportsCheck` is set automatically and needs no explicit enabling.
- Flag interpreters other than plain `python3Packages.python` in `nativeBuildInputs`
  unless a specific version is required.

## Rust

- Use `buildRustPackage` with `finalAttrs:` and a valid `cargoHash`.
- Native build tools (`pkg-config`, `rustPlatform.bindgenHook`) go in
  `nativeBuildInputs`; system libraries in `buildInputs`.

## Go

- Use `buildGoModule` with `finalAttrs:` and a valid `vendorHash`.
- Put `ldflags`/`-X` version injection behind a consistent `version` attribute;
  avoid hard-coded version strings duplicated outside `version`.

## CMake and Meson

- Pass cache entries as `cmakeEntries = { … }` (booleans canonicalised to
  `ON`/`OFF`) and Meson options as `mesonEntries = { … }` rather than building
  `-D` flags by hand. `cmakeFlags`/`mesonFlags` remain only for non-`-D` flags.
- Include the corresponding `configurePhaseHook` in `nativeBuildInputs`.

## Multi-version packages (`pkgs-many/**`)

- Follow the `default.nix` / `variants.nix` / `generic.nix` three-file pattern.
- Version comparisons must use `packageOlder` / `packageAtLeast` /
  `packageBetween`, not string comparisons.
- Mark end-of-life variants with `eol` and removed variants with `removed`
  instead of deleting them.

## EkaOS modules (`ekaos/modules/**`)

- Declare options with `mkOption` and a `type`; do not read an option before it is
  declared.
- Application settings belong under a `settings` submodule; the service command
  and args are set in `config`, not user-facing options.
- Keep `command`, `args`, `user`, and `restartPolicy` on the shared `services.*`
  interface and put systemd-specific settings under `systemd = { … }`.
- Flag option defaults whose type does not match the declared `types.*`.
