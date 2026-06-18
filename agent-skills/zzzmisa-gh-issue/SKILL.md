---
name: zzzmisa-gh-issue
description: Create, draft, or update GitHub Issues using Misa's AI task issue template. Use when the user asks Codex to create, open, register, draft, 起票, update, rewrite, or reformat a GitHub Issue body/description, especially for AI implementation task Issues; read references/ai-task-issue.md and preserve its section structure.
---

# GitHub Issue

## Workflow

Read `references/ai-task-issue.md` before drafting or creating the Issue body.

Use the template's body sections in the same order:

- `目的`
- `やること`
- `やらないこと`
- `完了条件`
- `AIへの指示`

Use the frontmatter in `references/ai-task-issue.md` only as template metadata, not as Issue body text. Set the Issue title from the user's actual task.

Fill comments and placeholders with concrete, concise Japanese. Remove HTML comments from the final Issue body. If `やらないこと` has no entries, write `なし`.

Keep the default completion checklist unless the user asks for different acceptance criteria; add task-specific checks only when they clarify done-ness.

Preserve the `AIへの指示` section unless the user explicitly asks to change the agent workflow.

If the user asks to actually create the Issue and a GitHub tool or `gh` is available, create it after preparing the title and body. If the user asks only for a draft, return the Markdown body without creating anything.
