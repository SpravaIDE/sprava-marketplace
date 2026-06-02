---
sprava:
  type: claude
  command: /sprava:create-subtask
  label: Create Subtask
  description: Create a new subtask in to-do.md
  order: 15
  scope: task,subtask
  form:
    fields:
      description:
        type: string
        label: Subtask Description
        multiline: true
---

# Create Subtask

## Step 1: Resolve Task Context

1. Use `resolving-task-context` skill to resolve the current task (issue ID and subtask ID)

## Step 2: Get Subtask Description

Read the `description` form field from `$ARGUMENTS` for the subtask description. If empty, use `AskUserQuestion` to ask for a description.

## Step 3: Read or Create to-do.md

Read `to-do.md` from the feature directory (`features/<ISSUE_ID>/to-do.md`). The `to-do.md` shape and template come from the `resolving-task-context` skill loaded in Step 1.

If the file does not exist, create it:
1. Read `implementation-overview.md` from the feature directory to understand what was already completed
2. Create `to-do.md` with a title header (`# <ISSUE_ID> <Title from overview>`) and a `1` subtask representing the already-completed work, with all items checked. The trailing items follow the same rule as Step 5 ("Trailing items" subsection) — consult the project's `CLAUDE.md` § **Subtask Template** when present, otherwise fall back to the DevAI default (`Wait for review`, `Commit`). Mark every item — implementation steps and trailing items — as checked:

```markdown
# <ISSUE_ID> <Title>

## 1. <Summary of completed work>

- [x] <Completed implementation steps derived from overview>
- [x] <trailing items per the rule above, all checked>
```

3. Then continue to Step 4 to add the new subtask (which will become `2`)

## Step 4: Determine Subtask Level and Number

Subtask IDs in `to-do.md` may be plain numeric (`1`, `2.1`) or carry a letter-dash prefix (`P-1`, `REVIEW-2`). The numbering scheme is derived from the existing file — do not assume `P-`.

### Parsing existing IDs

For each `## ` or `### ` heading, the leading token follows the shape
`<optional letter-dash prefix><dotted numeric>`, where the prefix is `[A-Za-z]+-` (e.g. `P-`, `REVIEW-`) and may be empty. Split each ID into:

- `prefix` — everything up to and including the last `-` before the first digit, or empty string for plain-numeric IDs
- `numericPath` — the dotted-numeric portion (e.g. `1`, `1.1`, `2.1.3`)

### Pick the level — top-level, child, or sibling

Use the session subtask ID (resolved in Step 1) and the user's description to pick one of three levels:

| Session subtask | Level inference | New subtask is… | Effective parent for numbering |
|-----------------|-----------------|-----------------|--------------------------------|
| absent          | n/a             | **top-level**   | none — apply the top-level rule below |
| present (e.g. `P-1.2`) | description does not signal follow-up (default) | **child** of session subtask | session subtask itself (`P-1.2`) → `P-1.2.<K>` |
| present (e.g. `P-1.2`) | description signals follow-up to current work — phrases like "discovered while implementing", "follow-up to", "additional work for", "sibling of", "same level as" | **sibling** of session subtask | session subtask's parent (drop last segment → `P-1`) → `P-1.<K>` |
| present and **already top-level** (e.g. `P-1`) | sibling branch | **top-level** | none — sibling of a top-level subtask IS a top-level subtask; apply the top-level rule below |

When the session has a subtask context but the signal is genuinely ambiguous, ask via `AskUserQuestion` with two options: "Child (sub-step of `<session-subtask>`)" or "Sibling (follow-up at `<session-subtask>`'s level)". Apply the picked branch.

Remember which branch was picked — the sibling cross-reference rule in Step 5 needs it.

### Top-level subtask (no parent subtask ID)

1. Scan all `## ` headers and parse each ID.
2. If no IDs are found, consult the project's `CLAUDE.md` § **Subtask Template** (or a similarly named section — "To-Do Conventions") for a documented default prefix. If documented, use `<prefix>1`. Otherwise, fall back to plain numeric `1` — the DevAI default.
3. Otherwise:
   - Group IDs by `prefix`. Pick the most common prefix. On a tie, pick the prefix of the highest-numbered subtask (the user's most recent choice).
   - Among headings that use the chosen prefix, find the highest first numeric segment and increment by 1.
   - The new ID is `<prefix><N+1>`.

### Child subtask (parent subtask ID present, e.g. parent is `P-3` or `1`)

1. Find the parent subtask section by its full ID (e.g. `## P-3.` or `## 1.`).
2. Scan `### ` headers inside that section. Each child ID begins with the parent's full ID followed by `.<K>`.
3. If no existing children, use `<PARENT>.1` (e.g. `P-3.1` or `1.1`).
4. Otherwise, find the highest trailing segment and increment by 1 — `<PARENT>.<K+1>`.

The child inherits the parent's full ID verbatim; never strip, swap, or invent a prefix.

For the **sibling** branch, use the "Effective parent for numbering" value from the table above (drop the last segment of the session subtask ID — e.g. session `P-1.2` → effective parent `P-1`). Apply the child-subtask logic to that effective parent.

## Step 5: Add Subtask Entry

### Trailing items

Before writing the entry, consult the project's `CLAUDE.md` § **Subtask Template** (or a similarly named section — "To-Do Conventions") for the trailing items each new subtask should contain. When that section exists, it is authoritative — use the items it lists verbatim. Otherwise, fall back to the DevAI default: `Wait for review` then `Commit`.

### Checklist shape

The checklist is **5–9 actionable items max** (excluding the trailing items from the previous subsection). Each item is a concrete step the implementer will take (write code, run test, update doc) — never a design decision or open question.

If the user's description contains background, motivation, or specific decisions that don't fit a one-line action, place them in a short paragraph **above** the checklist (one paragraph, no bullets). The paragraph is optional; omit it when the description maps cleanly to bullets.

### Sibling cross-reference

When Step 4 picked the **sibling** branch, the context paragraph above the checklist MUST include the line `Discovered during work on <SESSION-SUBTASK-ID>.` — even if the user's description didn't otherwise need a paragraph. Captures the provenance link so the new sibling stays connected to the original work. For child and top-level branches, skip this line — parent-child nesting already conveys provenance.

### Templates

**Top-level subtask** — append at the end of `to-do.md`:

```markdown

## <ID>. <Description>

<optional context paragraph per "Checklist shape"; for the sibling branch the paragraph MUST contain the "Discovered during work on <SESSION-SUBTASK-ID>." line from "Sibling cross-reference">

- [ ] <Implementation step>
- [ ] <Implementation step>
- [ ] <…>
- [ ] <trailing items per the rule above>
```

**Child subtask** — insert at the end of the parent subtask section (before the next `## ` header):

```markdown

### <ID> <Description>

<optional context paragraph per "Checklist shape"; for the sibling branch the paragraph MUST contain the "Discovered during work on <SESSION-SUBTASK-ID>." line from "Sibling cross-reference">

- [ ] <Implementation step>
- [ ] <Implementation step>
- [ ] <…>
- [ ] <trailing items per the rule above>
```

`<ID>` is the value computed in Step 4 — plain numeric (`1`, `2.1`) or prefixed (`P-1`, `REVIEW-3.2`) depending on the existing file's numbering scheme.

Present the added subtask to the user for review.

After the added subtask is presented, surface each new subtask as its own sticky launch button in the current pane:

- For every subtask created in this command run, invoke the `sprava-ide` skill once: `addStickyLaunchButton(<id>, <label>, <ISSUE-ID>, <SUBTASK-ID>, "accent")` where:
  - `<id>` is the subtask id lowercased (e.g. `p-2`).
  - `<label>` is `Task: "<Title>"` — quote the subtask title from Step 5 with a `Task: ` prefix (e.g. `Task: "Open Website URL"`). Never use the bare subtask identifier (`P-2`) as the label, and never include the prefix inside the quotes (`P-2 Open Website URL`).
- Emit a **separate button per subtask** — never pack multiple subtasks into one button.
- Do NOT print the script-call lines; the `sprava-ide` skill runs them directly.
- The button is a split button: the main label area launches the project's default run configuration for that subtask (matching the tasks-list play button), and the chevron lists every configured run configuration with title + description. When the developer clicks, the IDE reuses the current tab if it is already completed/idle, otherwise opens a new tab.

Then decide whether to close out the terminal:

- **Empty session** (the terminal was spawned just to run this command — no other implementation, review, or commit work happened before `/sprava:create-subtask` in this session) — invoke the `sprava-ide` skill to mark the current terminal tab as completed. The session's job is done; the developer can close the tab. Do NOT print the script call line; the skill runs it directly.
- **Ongoing session** (subtask was added mid-implementation, mid-review, or alongside other work) — do nothing more. Return control to the developer without further actions.

## Step 6: Verify All Steps Completed

Before stopping, mentally walk this checklist and confirm each item out loud in a one-line summary to the user. Do NOT skip this step — it is what catches missed actions (e.g., forgetting to mark an empty session completed).

- [ ] **Step 1** — task context resolved (issue ID, and subtask ID if present)
- [ ] **Step 2** — subtask description obtained (form field or `AskUserQuestion`)
- [ ] **Step 3** — `to-do.md` read (or created with the seed `1` subtask if missing)
- [ ] **Step 4** — level decided (top-level / child / sibling), prefix and number computed from existing IDs, sibling cross-reference noted if applicable
- [ ] **Step 5a** — subtask entry written to `to-do.md` with trailing items per the project's `CLAUDE.md` § Subtask Template (or DevAI default)
- [ ] **Step 5b** — added subtask presented to the user
- [ ] **Step 5c** — one `addStickyLaunchButton` emitted per newly created subtask (label format `Task: "<Title>"`)
- [ ] **Step 5d** — session classified as **empty** or **ongoing**; if empty, terminal tab marked completed via `set-terminal-completed.sh`; if ongoing, no action taken

If any item is unchecked, perform the missing action now before stopping.

Then STOP.
