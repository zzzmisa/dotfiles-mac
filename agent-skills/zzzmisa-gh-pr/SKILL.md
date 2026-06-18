---
name: zzzmisa-gh-pr
description: Create or draft GitHub pull requests using Misa's PR template. Use when the user asks Codex to create, open, draft, publish, or 作成 a PR or pull request; read references/pull_request_template.md and preserve its section structure.
---

# GitHub Pull Request

## Workflow

Read `references/pull_request_template.md` before drafting or creating the PR body.

Use the template sections in the same order:

- `対応Issue`
- `変更内容`
- `実装理由`
- `確認したこと`
- `確認できていないこと・残る懸念点`
- `レビューしてほしいポイント`
- `AIへの指示`

Fill comments and placeholders with concrete, concise Japanese. Remove HTML comments from the final PR body.

In `対応Issue`, use `Closes #<number>` when the linked Issue number is known. Do not invent an Issue number; leave `Closes #` or write `なし` according to the user's context.

In `確認したこと`, mark `[x]` only for checks that were actually run or verified in this session. Leave unchecked items as `[ ]` when not confirmed.

For `確認できていないこと・残る懸念点` and `レビューしてほしいポイント`, write `なし` when there is nothing specific to call out.

Preserve the `AIへの指示` section unless the user explicitly asks to change it.

If the user asks to actually create the PR and a GitHub tool or `gh` is available, create it after preparing the title and body. If another PR-publishing skill is also active, use this skill specifically for the PR body format.
