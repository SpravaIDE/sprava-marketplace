---
name: writing-implementation-overview
description: Creates implementation overview documents summarizing completed work with key decisions and files for review.
---

# Writing Implementation Overview

Creates implementation overview documents summarizing completed work.

## When to Use

- After completing implementation of a subtask
- When the `/overview` command is invoked

## Instructions

### 1. Gather Context

- Read `to-do.md` and implementation plan from the feature directory
- Review all files created or modified during the subtask
- Identify key decisions made during implementation

### 2. Create Overview Document

**File naming:**
- If `to-do.md` exists and subtask ID is known: `.sprava/features/<ISSUE-ID>/<taskId>-implementation-overview.md`
- Otherwise: `.sprava/features/<ISSUE-ID>/implementation-overview.md`

**Structure:**

```markdown
# <TaskId> Implementation Overview: <Short Title>

## Summary

One paragraph: what was built and why. Be concise — no code snippets.

## Key Decisions

1. **Decision title** — Why this approach was chosen over alternatives.
2. **Another decision** — Rationale.

## Files for Review

(Use `writing-files-for-review` skill for this section)
```

### 3. Guidelines

- Keep it concise — describe decisions, don't copy code
- Summary should be 1-3 sentences
- Key Decisions: only include non-obvious choices worth explaining
- Skip Key Decisions section entirely if all choices were straightforward
- For simple changes (single file, no decisions), Summary + Files for Review is enough
- **Always use `writing-files-for-review` skill** for the Files for Review section — never write it manually. The skill enforces correct relative paths (`../../../` prefix from feature directory) and proper markdown link format.
