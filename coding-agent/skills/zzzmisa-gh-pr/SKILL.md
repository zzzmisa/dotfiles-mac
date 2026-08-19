---
name: zzzmisa-gh-pr
description: Draft or create GitHub pull requests with Misa's template and delivery rules. Use for PR作成, pull request, draft PR, or publishing completed local changes as a PR; never merge.
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

Fill comments and placeholders with concrete, concise Japanese. Remove HTML comments from the final PR body.

In `対応Issue`, use `Closes #<number>` when the linked Issue number is known. Do not invent an Issue number; leave `Closes #` or write `なし` according to the user's context.

In `確認したこと`, mark `[x]` only for checks that were actually run or verified in this session. Leave unchecked items as `[ ]` when not confirmed.

For `確認できていないこと・残る懸念点` and `レビューしてほしいポイント`, write `なし` when there is nothing specific to call out.

Before drafting or creating the PR:

- Read applicable `AGENTS.md` files and follow their product, design, and workflow instructions.
- Use a work branch. When creating the branch for a numbered Issue, name it `issue-<number>-<short-description>` (for example, `issue-1-add-new-feature`).
- If the implementation appears to require a major design change or unrequested specification expansion, stop before implementing or creating the PR and report the proposal to the user.
- For mobile apps, install and verify on a physical device when the environment supports it and the change requires device verification.

Set the PR title to `Issue #<number> <summary>` when the Issue number is known (for example, `Issue #1 音声ボタンの追加`). Do not invent an Issue number.

If the user asks to actually create the PR and a GitHub tool or `gh` is available, create it after preparing the title and body. If the user asks only for a draft, return the Markdown body without creating anything.

Never merge the PR. The user performs the merge.
