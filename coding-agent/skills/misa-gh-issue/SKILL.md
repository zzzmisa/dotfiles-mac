---
name: misa-gh-issue
description: Draft, create, or update GitHub Issues using repository-specific rules and templates when present, otherwise Misa's template. Also investigate repository evidence for refactoring or cleanup Issue proposals. Use for Issue作成・起票・更新, 改善Issue, 技術的負債, 未使用コード, performance, or app-size Issue requests; do not implement the proposed refactor.
---

# GitHub Issue

## Workflow

Before drafting or creating the Issue:

1. Identify the target repository.
2. Read all applicable repository instructions, including `AGENTS.md` and
   `CLAUDE.md`, plus relevant contribution guidance and Issue templates such as
   `CONTRIBUTING.md` and `.github/ISSUE_TEMPLATE/` when present.
3. Follow explicit instructions from the current user first, then the target
   repository's rules and templates. Repository-specific guidance overrides this
   skill's default format.

If the repository has an applicable Issue template, use its sections and
requirements. Otherwise, read `references/ai-task-issue.md` and use Misa's
default template.

For a refactoring, cleanup, performance, or app-size investigation whose requested
outcome is an Issue, also read `references/refactor-investigation.md`. Investigate
first and stop after drafting or creating the Issue; do not implement it.

### Misa's default template

When the repository has no applicable Issue template, use these body sections
in the same order:

- `目的`
- `やること`
- `やらないこと`
- `完了条件`

Use the frontmatter in `references/ai-task-issue.md` only as template metadata, not as Issue body text. Set the Issue title from the user's actual task.

Fill comments and placeholders with concrete, concise Japanese. Remove HTML comments from the final Issue body. If `やらないこと` has no entries, write `なし`.

Keep the default completion checklist unless the user asks for different acceptance criteria; add task-specific checks only when they clarify done-ness.

If the user asks to actually create the Issue and a GitHub tool or `gh` is available, create it after preparing the title and body. If the user asks only for a draft, return the Markdown body without creating anything.
