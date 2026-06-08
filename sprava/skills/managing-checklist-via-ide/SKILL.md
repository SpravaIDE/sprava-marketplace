---
name: managing-checklist-via-ide
description: Check/uncheck checklist items, rewrite a subtask's content, or replace a whole task checklist by calling the Sprava IDE checklist-write endpoints. Use instead of editing to-do.md directly — the IDE persists and syncs the checklist source of truth.
---

# Managing a Checklist via the IDE

Routes checklist writes through the Sprava IDE so the IDE owns persistence. For each write the IDE
rewrites the `to-do.md` cache under a per-task lock and — when a checklist-source plugin owns the
task — pushes the whole checklist to the source of truth (the YouTrack issue description) and
reconciles the cache. Editing `to-do.md` directly is wrong: on a synced task the next pull clobbers
the local edit.

## When to Use

- A command (e.g. `/sprava:approve-changes`) needs to **check / uncheck** specific checklist items.
- You need to **rewrite a single subtask's** content (its body / item states / title) in place.
- You need to **create or fully replace** a whole task checklist.
- Available only in Sprava IDE terminals (`$SPRAVA_PORT` and `$SPRAVA_PROJECT_ID` are set).

Do **not** edit `to-do.md` yourself — always go through this skill.

## Operations

The bundled `manage-checklist.sh` takes a leading subcommand. `$SKILL_DIR` is this skill's base
directory (printed when the skill loads). `--issue` is the **issue id alone** (e.g.
`CHECKLIST-MANAGEMENT`) — never the composite `$SPRAVA_TASK_ID` (`…:P-9`). All write the same way
(cache + source-of-truth sync); they differ only in scope.

### toggle — check / uncheck one item

```bash
bash "$SKILL_DIR/scripts/manage-checklist.sh" toggle \
  --issue "<ISSUE_ID>" \
  --subtask "<SUBTASK_ID>" \
  --item-text "<ITEM TEXT>" \
  --item-index <N> \
  --checked <true|false>
```

The IDE re-finds the item server-side and flips that one box (idempotent — re-checking a checked box
is a no-op). `--item-text` is the text exactly as written after the checkbox (e.g. `Wait for review`).
`--item-index` is the item's **0-based position among the subtask's direct checkboxes** — it only
disambiguates duplicate item texts within the subtask, so when the text is unique any value resolves,
but pass the real position for safety.

### update-subtask — rewrite a subtask's block

```bash
bash "$SKILL_DIR/scripts/manage-checklist.sh" update-subtask \
  --issue "<ISSUE_ID>" \
  --subtask "<SUBTASK_ID>" \
  --content-file /tmp/sprava-subtask-block.md
```

Replaces the subtask's whole block — heading + body + every nested child — with the file's content.
The content **is** the new block, so include the heading line (`## <id>. <title>`) and the full
checklist; nested children you omit are dropped. Prefer `toggle` when you only need to flip a box —
it can't accidentally drop an item or a child the way reproducing a whole block can.

### set-checklist — create or fully replace the whole checklist

```bash
bash "$SKILL_DIR/scripts/manage-checklist.sh" set-checklist \
  --issue "<ISSUE_ID>" \
  --content-file /tmp/sprava-checklist.md
```

Writes the file as the task's entire `to-do.md` (creating it when the task has none). Empty content
is rejected — use `update-subtask` to rewrite a block or remove a subtask via the IDE to delete one.

## How to Call

1. Resolve the **issue id** (from `resolving-task-context`).
2. For `update-subtask` / `set-checklist`, write the markdown to a temp file (preserves it verbatim;
   the script encodes it with `jq --rawfile`, so no escaping is needed).
3. Run the matching subcommand above.

## Response

On success the script prints the IDE response JSON and exits 0:

```json
{ "content": "# <ISSUE-ID>\n\n## P-9. …\n\n- [x] Wait for review\n…" }
```

`content` is the resulting `to-do.md` (reconciled from the source of truth when the task is owned).
On an HTTP error (404 unknown task / subtask, 400 missing or empty content / bad locator) the script
prints the IDE's error body and exits non-zero — surface it; do not fall back to editing `to-do.md`.
