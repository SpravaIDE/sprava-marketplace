---
sprava:
  type: claude
  command: /sprava:section-by-section
  label: Section by Section
  description: Process a document's sections one at a time with a review checkpoint between each
  order: 150
  scope: task,subtask
---

You'll process a document section-by-section, applying the **same task** to each section and pausing after each one for the developer to approve, request changes, or stop.

The task itself comes from one of three places, in priority order:

1. `$ARGUMENTS` — if non-empty, treat the argument string as the per-section task description.
2. **Conversation context** — if the current session has already established what's being done ("we're writing the user guide", "rewrite each section in the new tone", etc.), use that.
3. **Ask** — if neither is clear, use `AskUserQuestion` to ask for a one-line task description before going further.

## Step 1: Identify the Target Document

Resolve the document whose sections will be processed:

- If `$ARGUMENTS` includes a file path, use it.
- Otherwise, look at the conversation context — the document being discussed is usually the target. Common candidates:
  - The `structure.md` in the current feature directory (outline of a doc being written).
  - The `to-do.md` in the current feature directory (when the task is "do each subtask").
  - A specific file the user has been editing.
- If multiple candidates exist or none is obvious, ask via `AskUserQuestion`.

## Step 2: Extract the Section List

Read the target document and extract its sections. Adapt to the document's shape:

- **Markdown outline (`structure.md`-style)** — list the `##` headings (and `###` only when relevant to the task).
- **To-do file** — list the `## N. <title>` subtasks.
- **Existing doc to rewrite** — list its top-level `##` sections.

Number each section starting from 1, in document order. Skip sections the task obviously doesn't apply to (e.g. a frontmatter block, a "Related" footer).

## Step 3: Confirm the Plan

Present the developer with:

1. **The task** (one line) — what you'll do for each section.
2. **The list of sections** — numbered, in order.
3. **The output destination** — where the result for each section will be saved (a file path, a section of a file, or inline in the conversation if the task is purely conversational).

Then use `AskUserQuestion` with options:

- **Proceed** — start with section 1.
- **Edit the list** — let the developer add/remove/reorder before starting.
- **Cancel** — stop without doing anything.

If the developer picks **Edit the list**, accept their changes (free-text), re-present, and ask again.

## Step 4: Process One Section, Then Stop

After approval, process **only the first unprocessed section**:

1. Announce: `Section <N>/<total>: <title>`.
2. Run the task on that section.
3. Save the result to its destination (file write, edit, etc.).
4. Show the developer what changed in one short summary line + the relevant artefact (file path, key snippet — whichever is most reviewable).
5. **Stop and wait.** Do not proceed to the next section automatically.

## Step 5: Handle the Developer's Reply

After your stop in Step 4, the developer will respond. Pattern-match their reply:

- **"approved" / "next" / "ok" / "go"** — move on to the next unprocessed section, repeat Step 4.
- **Specific change requests** — apply them to the current section's output, re-present, and wait again. Stay on the current section until it's approved.
- **"stop" / "pause" / "done for now"** — stop the loop. Report which section was last completed and how many remain.
- **A new direction unrelated to this section** — drop the loop, do what they asked. Don't try to resume the loop on your own.

## Step 6: Completion

When every section has been approved (or the developer stopped early):

- Summarise: number of sections processed, where the outputs live, anything left.
- Do NOT auto-commit. Leave the commit decision to the developer.
