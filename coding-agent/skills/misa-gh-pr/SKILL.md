---
name: misa-gh-pr
description: Draft or create GitHub pull requests using repository-specific rules and templates when present, otherwise Misa's template and delivery rules. Use for PR作成, pull request, draft PR, or publishing completed local changes as a PR; never merge.
---

# GitHub Pull Request

## Workflow

Before drafting or creating the PR:

1. Identify the target repository.
2. Read all applicable repository instructions, including `AGENTS.md` and
   `CLAUDE.md`, plus relevant contribution guidance and PR templates such as
   `CONTRIBUTING.md`, `.github/pull_request_template.md`, and
   `.github/PULL_REQUEST_TEMPLATE/` when present.
3. Follow explicit instructions from the current user first, then the target
   repository's rules and templates. Repository-specific guidance overrides this
   skill's default format and delivery conventions.

If the repository has an applicable PR template, use its sections and
requirements. Otherwise, read `references/pull_request_template.md` and use
Misa's default template.

### Misa's default template

When the repository has no applicable PR template, use these sections in the
same order:

- `対応Issue`
- `変更内容`
- `実装理由`
- `確認したこと`
- `確認できていないこと・残る懸念点`
- `レビューしてほしいポイント`

Fill comments and placeholders with concrete, concise Japanese. Remove HTML comments from the final PR body.

In `対応Issue`, use `Closes #<number>` when the linked Issue number is known. Do not invent an Issue number; leave `Closes #` or write `なし` according to the user's context.

In `確認したこと`, mark `[x]` only for checks that were actually run or verified in this session. Leave unchecked items as `[ ]` when not confirmed.

For `確認できていないこと・残る懸念点` and `レビューしてほしいポイント`, write `なし` when there is nothing specific to call out.

Also apply these delivery rules unless the repository has a more specific rule:

- Use a work branch. When creating the branch for a numbered Issue, name it `issue-<number>-<short-description>` (for example, `issue-1-add-new-feature`).
- If the implementation appears to require a major design change or unrequested specification expansion, stop before implementing or creating the PR and report the proposal to the user.
- For mobile apps, install and verify on a physical device when the environment supports it and the change requires device verification.

Unless the repository specifies another title format, set the PR title to
`Issue #<number> <summary>` when the Issue number is known (for example,
`Issue #1 音声ボタンの追加`). Do not invent an Issue number.

If the user asks to actually create the PR and a GitHub tool or `gh` is available, create it after preparing the title and body. If the user asks only for a draft, return the Markdown body without creating anything.

Never merge the PR. The user performs the merge.
