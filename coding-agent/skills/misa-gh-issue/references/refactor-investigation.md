# Refactoring Issue Investigation

Investigate the repository and turn evidence into a concrete Issue. Do not implement the proposal.

## Evidence

- Search code references with `rg`.
- Inspect manifests, dependencies, assets, generated files, tests, and build settings.
- Run cheap project-native analysis commands when useful.
- Cite concrete paths, symbols, assets, or dependencies.

## Candidate areas

- Unused code, files, assets, feature flags, or build settings.
- Legacy code, technical debt, unclear ownership, or duplicate implementations.
- Unnecessary processing, readability problems, and missing tests or documentation.
- Performance and app-size improvements, including oversized assets and unnecessary dependencies.

Prefer small follow-up tasks over broad rewrites. State uncertainty when runtime or product confirmation is needed, and avoid generic recommendations without repository evidence.
