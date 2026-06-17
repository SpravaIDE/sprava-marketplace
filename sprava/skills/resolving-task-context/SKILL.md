---
name: resolving-task-context
description: Resolves the current task's issue ID and subtask ID from SPRAVA env vars or session name, and documents the feature-directory conventions (layout, key files, to-do.md shape). Use at the start of any command that needs task context.
---

# Resolving Task Context

Determines the current task's issue ID and subtask ID and documents the feature directory's plugin-level conventions.

## Resolving the Task

1. Check SPRAVA env vars:

   ```bash
   echo "SPRAVA_PORT=${SPRAVA_PORT:-not set}"
   echo "SPRAVA_TASK_ID=${SPRAVA_TASK_ID:-not set}"
   ```

2. If `SPRAVA_TASK_ID` is set, use it as the task identifier.
3. Otherwise, read the current session name to get the task identifier.
4. Extract the issue ID (e.g., `DEVAI-MCP`, `REQ-068`, `FIX-44`) and optional subtask ID (e.g., `P-1`, `P-9.1`) from the identifier. The format is `<ISSUE-ID>:<SUBTASK-ID>` when a subtask is present.
5. Feature directory: `.sprava/features/<ISSUE-ID>/`.

## Feature Directory Conventions

Feature directories live under the host project's config directory in `.sprava/features/`. The directory name matches the issue ID (e.g. `FEAT-001`, `REQ-068`, `RELEASE-TASKS-2`).

### Layout

```
.sprava/features/
└── <ISSUE-ID>/
    ├── implementation-plan.md                        # Issue-level technical approach
    ├── <subtask-id>-implementation-plan.md           # Per-subtask plan (e.g. P-1-implementation-plan.md)
    ├── to-do.md                                      # Subtasks with checklists
    ├── implementation-overview.md                    # Summary of completed work (issue-level)
    └── <subtask-id>-implementation-overview.md       # Per-subtask overview
```

A feature directory may also hold ad-hoc Q&A files, screenshots, and other artefacts produced during implementation.

### Key Files

- **`implementation-plan.md` / `<subtask-id>-implementation-plan.md`** — Technical approach and design decisions. Created by `/sprava:create-implementation-plan`.
- **`to-do.md`** — Subtasks with checklists. See the template below.
- **`implementation-overview.md` / `<subtask-id>-implementation-overview.md`** — Summary written after a (sub)task ships. Must include a `## Files for Review` section with markdown links.

### Subtasks

A **subtask** is a discrete unit of work inside an issue. Subtasks live exclusively in `to-do.md` — each `## ` heading in that file is one subtask, and any `### ` heading nested under it is a sub-subtask. The heading's leading token is the **subtask ID** — `1`, `P-1`, `P-9.1`, `REVIEW-2.1` — and that ID is what ties the rows of the feature directory together:

| Subtask artefact          | File name pattern                                  |
|---------------------------|----------------------------------------------------|
| Entry in `to-do.md`       | `## <subtask-id>. <title>` (with checklist below)  |
| Implementation plan       | `<subtask-id>-implementation-plan.md`              |
| Implementation overview   | `<subtask-id>-implementation-overview.md`          |

Each subtask's body is a checklist (`- [ ]` items) of the concrete steps the implementer takes; the last two items are always the trailing "Wait for review" / "Commit" pair (or the project's override — see below). Working a subtask means ticking those boxes one by one. The subtask is **done** when every checklist item — including the trailing pair — is checked.

Tasks ship subtask-by-subtask: each one gets its own plan, its own overview, and its own commit. The issue-level `implementation-plan.md` / `implementation-overview.md` (no prefix) are used only when the issue has no subtasks.

### `to-do.md` Template

```markdown
# <ISSUE-ID> <Title>

## 1. <First subtask title>

- [ ] <Implementation step>
- [ ] <Implementation step>
- [ ] Wait for review
- [ ] Commit

### 1.1 <Sub-subtask title>

- [ ] <Implementation step>

## 2. <Second subtask title>

- [ ] <Implementation step>
- [ ] Wait for review
- [ ] Commit
```

Subtask IDs may be plain numeric (`1`, `2.1`) or carry a letter-dash prefix (`P-1`, `REVIEW-2.1`). The prefix is whatever the existing file already uses — see `/sprava:create-subtask` for the numbering algorithm.

The trailing items (`Wait for review`, `Commit`) are the DevAI default. Projects may override them via their `CLAUDE.md` § **Subtask Template** — when that section is present, it is authoritative.
