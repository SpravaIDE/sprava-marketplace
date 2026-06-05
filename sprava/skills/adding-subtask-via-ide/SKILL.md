---
name: adding-subtask-via-ide
description: Adds a composed subtask to a task's checklist by POSTing to the Sprava IDE add-subtask endpoint. Use from /sprava:create-subtask — the IDE numbers, places, persists to-do.md, and syncs the checklist source of truth.
---

# Adding a Subtask via the IDE

POSTs a composed subtask to the Sprava IDE so the IDE owns persistence. The IDE computes the next
id, picks the heading level, inserts the block into the `to-do.md` cache, and — when a
checklist-source plugin owns the task — pushes the change to the source of truth (the YouTrack
issue description) and reconciles the cache.

## When to Use

- A command (today only `/sprava:create-subtask`) has decided a subtask's **level** and **content**
  and needs it persisted.
- Available only in Sprava IDE terminals (`$SPRAVA_PORT` and `$SPRAVA_PROJECT_ID` are set).

## Contract — who decides what

The **caller** decides and supplies:

- **title** — one line, no `##` and no id. The IDE renders the heading (`## <id>. <title>`).
- **body** — the subtask body: an optional context paragraph, then the `- [ ]` checklist
  (including the trailing items). No heading, no id.
- **parent** — the *effective parent subtask id* (child → the session subtask; sibling → the
  session subtask with its last segment dropped; top-level → omit).

The **IDE** computes the next id under that parent, the heading level, the insertion point, the
cache write, and the source-of-truth sync. Do **not** number the subtask or edit `to-do.md`
yourself.

## How to Call

1. Resolve the **issue id** (from `resolving-task-context`). Pass the issue id alone (e.g.
   `CHECKLIST-MANAGEMENT`) — never the composite `$SPRAVA_TASK_ID` (`…:P-3`).
2. Write the composed body to a temp file (preserves the multi-line markdown verbatim).
3. Run the bundled script:

```bash
bash "$SKILL_DIR/scripts/add-subtask.sh" \
  --issue "<ISSUE_ID>" \
  --title "<TITLE>" \
  --body-file /tmp/sprava-subtask-body.md \
  --parent "<PARENT_SUBTASK_ID>"   # omit the flag for a top-level subtask
```

`$SKILL_DIR` is this skill's base directory (printed when the skill loads). The script encodes the
JSON with `jq --rawfile`, so the body needs no escaping. It reads `$SPRAVA_PORT` /
`$SPRAVA_PROJECT_ID` from the environment.

## Response

On success the script prints the IDE response JSON and exits 0:

```json
{ "subtaskId": "P-4", "content": "## P-4. <title>\n\n<body>" }
```

- **`subtaskId`** — the id the IDE assigned. Use it (lowercased) as the launch-button id.
- **`content`** — the rendered block. Present this to the user.

On an HTTP error (e.g. 404 unknown task, 400 missing title / unknown parent) the script prints the
IDE's error body and exits non-zero — surface it; do not fall back to editing `to-do.md`.
