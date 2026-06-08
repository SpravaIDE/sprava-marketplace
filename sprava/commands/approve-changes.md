---
sprava:
  type: claude
  command: /sprava:approve-changes
  label: Approve Changes
  description: Commit approved changes and mark the terminal completed
  order: 20
  scope: task-execution
  trigger: '*'
---

# Approve Changes

The developer has approved all changes. Commit them, push to the remote, then mark the DevAI terminal tab as completed.

## Step 1: Resolve Task Context

Use `resolving-task-context` skill to resolve the current task (issue ID and subtask ID) and to load the feature-directory conventions referenced in the steps below.

## Step 2: Check Implementation Overview

Read `features/<ISSUE-ID>/<SUBTASK-ID>-implementation-overview.md` (or `features/<ISSUE-ID>/implementation-overview.md` when there is no subtask).

If the overview is missing or its "Files for Review" section is incomplete or out of date, **stop**. Update it (or ask the user to update it), then re-run this command. Do NOT proceed to the commit steps without an accurate overview.

## Step 3: Mark the Checklist Items Complete

Mark the current subtask's "Wait for review" and "Commit" items complete **through the IDE** — do NOT
edit `to-do.md` directly (a direct edit is clobbered by the next source-of-truth pull on a synced
task).

Read `features/<ISSUE-ID>/to-do.md` to find, under the current subtask (`<SUBTASK-ID>` from Step 1),
the exact text of the two trailing items (the DevAI default is `Wait for review` / `Commit`; a
project may override them via its `CLAUDE.md` § Subtask Template — use whatever the file actually
shows). Then, using the `managing-checklist-via-ide` skill, run its `toggle` op once per item to
check each one (`--issue` the issue id from Step 1, `--subtask` the current subtask id, `--checked
true`). The IDE rewrites the cache and, on an owned task, the issue description. If `toggle` exits
non-zero, surface the IDE's error and stop — do not fall back to editing `to-do.md`.

When there is no subtask in play (an issue-level approval with no `<SUBTASK-ID>`), skip this step —
there are no per-subtask trailing items to mark.

## Step 4: Identify Touched Components

Consult the project's `CLAUDE.md` § **Project Layout** (or a similarly named section, e.g. "Project Structure", "Repository Layout"). When that section exists, it is authoritative — it documents which directories are separate git repos / gitlinks and which is the wrapper. Do not re-discover the layout at runtime.

You already know which files you changed in this session — group them by component. Each component that is its own git repo (or gitlink) and has files you modified will get its own commit and push in Step 5. The wrapper is committed and pushed last in Step 6 so its gitlinks point at commits the remote already knows.

## Step 5: Commit and Push Each Touched Component

Before pushing anything, consult the project's `CLAUDE.md` § **Branch Workflow** (or a similarly named section, e.g. "Git Commit Rules"). When that section exists, it is authoritative — it may disable push entirely (e.g. PR-only flows), pick a different remote, or specify a different push command (e.g. `git push -u origin HEAD` for first-time, `git push gerrit HEAD:refs/for/main` for Gerrit). When absent, default to `git push` on the current branch.

For each touched component identified in Step 4:

```bash
cd <component-path>
git status --short
# stage explicit paths (no `git add -A`)
git commit -m "<ISSUE-ID>:<SUBTASK-ID>: <one-line summary>"
git push   # or whatever the project's CLAUDE.md § Branch Workflow specifies
```

If a push fails, **stop**. Do not proceed to the wrapper commit — its gitlinks would point at commits the remote does not have. Report the failure and let the developer resolve.

## Step 6: Commit and Push the Wrapper

Return to the wrapper root.

```bash
git status --short
```

Stage explicit paths covering: the feature directory under `features/<ISSUE-ID>/`, any project-level config touched (e.g. `.claude/`, `.devai/`), and any component gitlinks updated in Step 5.

```bash
git commit -m "<ISSUE-ID>:<SUBTASK-ID>: <one-line summary>"
git push   # or whatever the project's CLAUDE.md § Branch Workflow specifies
```

Skip this step if `git status --short` is empty.

## Step 7: Mark Terminal Completed

```bash
~/.claude/scripts/devai/set-terminal-completed.sh
```

If `$SPRAVA_TERMINAL_ID` is not set (running outside Sprava), skip silently — the tab indicator does not apply.

After the terminal is marked completed, invoke the `sprava-ide` skill to clear all context-panel buttons so the closed tab carries no stale CTAs from earlier turns. Do NOT print the button-emitter call line in the response; the skill handles the HTTP request directly.

## Step 8: Final Report

Print:

- Subtask ID and short summary.
- Each commit's short hash + subject (one line per component + wrapper).
- Push status per commit (pushed / skipped per project conventions / failed).
- Terminal-completed status (set / skipped).
