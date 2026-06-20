---
name: zzzmisa-refactor-issue
description: Investigate refactoring and cleanup opportunities, then draft or create a GitHub Issue before implementation. Use for リファクタリング調査, 改善Issue作成, 技術的負債の洗い出し, 未使用コード削除案, performance, or app size reduction proposals; use zzzmisa-gh-issue for the Issue template.
---

# Refactor Issue

## Workflow

Do not start implementation. Investigate the repository and produce a concrete refactoring Issue or Issue draft.

Prefer evidence from the project over generic advice:

- Search code references with `rg`.
- Check manifests, dependencies, assets, generated files, and build settings.
- Run cheap project-native analysis commands when useful.

Pass the final Issue drafting/creation to `zzzmisa-gh-issue`.

## Investigation Scope

Cover these areas when relevant to the repository:

- Unused code, files, assets, feature flags, or build settings.
- Legacy code, technical debt, anti-patterns, and unclear ownership.
- Duplicate implementations, unnecessary processing, and readability problems.
- Performance improvement candidates.
- App size reduction candidates, such as unused assets, oversized images, and unnecessary dependencies.
- Other cleanup, testing, documentation, or migration opportunities.

## Quality Bar

Include concrete paths, symbols, assets, or dependencies where possible. Avoid vague recommendations, prefer small follow-up tasks, and call out uncertainty when runtime or product confirmation is needed.
