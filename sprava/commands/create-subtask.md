---
sprava:
  type: claude
  command: /sprava:create-subtask
  label: Create Subtask
  description: Create a new subtask via the Sprava IDE
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

## Step 3: Seed to-do.md If Missing

This command does **not** read or edit `to-do.md` for numbering or insertion — Steps 4–5 delegate persistence to the IDE.

Check whether `to-do.md` exists in the feature directory (`.sprava/features/<ISSUE_ID>/to-do.md`). If it exists, continue to Step 4.

If it does **not** exist, seed an "already-completed work" subtask *through the IDE* before adding the new one — never write `to-do.md` directly:

1. Read `implementation-overview.md` from the feature directory to understand what was already completed.
2. Compose the seed subtask — title = a short summary of the completed work; body = the completed implementation steps plus the trailing items (per Step 5's "Trailing items" subsection), with **every item checked** (`- [x]`).
3. Add it via the `adding-subtask-via-ide` skill with **no parent** (top-level). The IDE assigns it `1`.
4. Continue to Step 4 to add the new subtask (which the IDE will number `2`).

## Step 4: Determine Subtask Level and Effective Parent

The IDE computes the next id — prefix detection (`P-`, `REVIEW-`, plain numeric), child vs top-level, increment, and tie-break all live server-side now. This command decides only the subtask's **level** and resolves the **effective parent subtask id** to hand to the IDE.

### Pick the level — top-level, child, or sibling

Use the session subtask ID (resolved in Step 1) and the user's description to pick one of three levels:

| Session subtask | Level inference | New subtask is… | Effective parent |
|-----------------|-----------------|-----------------|------------------|
| absent          | n/a             | **top-level**   | none |
| present (e.g. `P-1.2`) | description does not signal follow-up (default) | **child** of session subtask | the session subtask itself (`P-1.2`) |
| present (e.g. `P-1.2`) | description signals follow-up to current work — phrases like "discovered while implementing", "follow-up to", "additional work for", "sibling of", "same level as" | **sibling** of session subtask | the session subtask with its last segment dropped (`P-1.2` → `P-1`) |
| present and **already top-level** (e.g. `P-1`) | sibling branch | **top-level** | none — a sibling of a top-level subtask is itself top-level |

When the session has a subtask context but the signal is genuinely ambiguous, ask via `AskUserQuestion` with two options: "Child (sub-step of `<session-subtask>`)" or "Sibling (follow-up at `<session-subtask>`'s level)". Apply the picked branch.

Remember which branch was picked — the sibling cross-reference rule in Step 5 needs it.

The **effective parent** is the value in the table's last column — it's what you pass to the IDE. Omit it for a top-level subtask; otherwise pass the parent id verbatim, never stripping, swapping, or inventing a prefix. The IDE numbers the new subtask under that parent.

## Step 5: Add Subtask Entry

### Trailing items

Before writing the entry, consult the project's `CLAUDE.md` § **Subtask Template** (or a similarly named section — "To-Do Conventions") for the trailing items each new subtask should contain. When that section exists, it is authoritative — use the items it lists verbatim. Otherwise, fall back to the DevAI default: `Wait for review` then `Commit`.

### Checklist shape

The checklist is **5–9 actionable items max** (excluding the trailing items from the previous subsection). Each item is a concrete step the implementer will take (write code, run test, update doc) — never a design decision or open question.

If the user's description contains background, motivation, or specific decisions that don't fit a one-line action, place them in a short paragraph **above** the checklist (one paragraph, no bullets). The paragraph is optional; omit it when the description maps cleanly to bullets.

### Sibling cross-reference

When Step 4 picked the **sibling** branch, the context paragraph above the checklist MUST include the line `Discovered during work on <SESSION-SUBTASK-ID>.` — even if the user's description didn't otherwise need a paragraph. Captures the provenance link so the new sibling stays connected to the original work. For child and top-level branches, skip this line — parent-child nesting already conveys provenance.

### Compose title and body

The IDE renders the heading (`## <id>. <title>`) and assigns the id — so compose only two pieces, neither containing a heading or id:

- **title** — the subtask description as a single line.
- **body** — the optional context paragraph (per "Checklist shape"; for the sibling branch it MUST contain the "Discovered during work on <SESSION-SUBTASK-ID>." line from "Sibling cross-reference"), then a blank line, then the `- [ ]` checklist including the trailing items.

### Add via the IDE

Using the `adding-subtask-via-ide` skill, persist the subtask. Write the composed body to a temp file and call the bundled script with:

- `--issue` — the issue id from Step 1 (the issue id alone, e.g. `CHECKLIST-MANAGEMENT`; never the composite `$SPRAVA_TASK_ID`).
- `--title` — the composed title.
- `--body-file` — the temp file holding the composed body.
- `--parent` — the effective parent from Step 4; omit the flag for a top-level subtask.

The IDE numbers the subtask, places the block, writes `to-do.md`, and syncs the checklist source of truth. Read `subtaskId` and `content` from the response.

If the script exits non-zero, surface the IDE's error to the user and stop — do **not** fall back to editing `to-do.md` directly.

Present the returned `content` block to the user for review.

After the added subtask is presented, surface the **newly added** subtask as a sticky launch button in the current pane (the seed completed-work subtask from Step 3, if any, is already done — give it no button):

- For each subtask added from the user's description in this run, invoke the `sprava-ide` skill once: `addStickyLaunchButton(<id>, <label>, <ISSUE-ID>, <SUBTASK-ID>, "accent")` where:
  - `<SUBTASK-ID>` is the `subtaskId` from the IDE response; `<id>` is that id lowercased (e.g. `p-2`).
  - `<label>` is `Task: "<Title>"` — quote the composed title from Step 5 with a `Task: ` prefix (e.g. `Task: "Open Website URL"`). Never use the bare subtask identifier (`P-2`) as the label, and never include the prefix inside the quotes (`P-2 Open Website URL`).
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
- [ ] **Step 3** — if `to-do.md` was missing, seed `1` added via the `adding-subtask-via-ide` skill; otherwise left untouched (no direct write)
- [ ] **Step 4** — level decided (top-level / child / sibling), effective parent resolved (no local numbering), sibling cross-reference noted if applicable
- [ ] **Step 5a** — title + body composed (no heading/id; trailing items per the project's `CLAUDE.md` § Subtask Template or DevAI default) and the subtask added via the `adding-subtask-via-ide` skill
- [ ] **Step 5b** — returned `content` block presented to the user
- [ ] **Step 5c** — one `addStickyLaunchButton` emitted for the newly added subtask (label format `Task: "<Title>"`)
- [ ] **Step 5d** — session classified as **empty** or **ongoing**; if empty, terminal tab marked completed via the `sprava-ide` skill; if ongoing, no action taken

If any item is unchecked, perform the missing action now before stopping.

Then STOP.
