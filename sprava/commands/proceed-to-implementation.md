---
sprava:
  type: claude
  command: /sprava:proceed-to-implementation
  label: Proceed to Implementation
  description: Implement changes, run code review, update checklist, commit
  scope: task-execution
  trigger: plan ready
---

# Proceed to Implementation

## Step 0: Resolve Task Context

Use the `resolving-task-context` skill to resolve the current task (issue ID and subtask ID).

## Step 1: Read Feature Documentation

Read `description.md`, `to-do.md`, implementation-plan files, and all documents starting with the task id from the feature directory. Do NOT create `to-do.md` if it doesn't exist — only read existing files.

## Step 2: Implement Changes

Implement all changes according to the implementation plan.

### Use Skills Proactively
Check all registered skills. Proactively use them while working on tasks.

### Test Implementation Rules

Before implementing tests, consult the project's `CLAUDE.md` § **Automated Test Strategy** (or a similarly named section, e.g. "Testing Strategy", "Test Strategy"). When that section exists, it is authoritative — it documents the project's test layering, frameworks, spec locations, and which layers are required for which kinds of change. Follow that strategy when deciding what to write and where.

- **If tests are explicitly listed in to-do.md**: Implement ONLY the tests specified. Do not add extra tests. If the test list seems incomplete, this should be caught during review, not during implementation.
- **If tests are not specified in to-do.md**: Implement a reasonable but not extensive set of tests covering the main functionality, following the layering and framework conventions documented in the project's `CLAUDE.md` § **Automated Test Strategy**. If no strategy is documented, default to a reasonable mix for the change's surface area.

## Step 3: Update Checklist

If `to-do.md` exists, mark completed items after each step. Do NOT create `to-do.md` if it doesn't exist.

## Step 4: Code Review

Before launching, consult the project's `CLAUDE.md` § **Code Review** (or a similarly named section, e.g. "Code Review Analysis"). When that section exists, it is authoritative — it lists every subagent that must run during this phase: the two standard ones below plus any project-specific subagents triggered by which files changed (e.g., layer-specific pattern checks, security or accessibility review). Launch all applicable subagents **in parallel** — never sequentially.

Standard subagents (always applicable):

1. **Code review** — verify all changes follow project patterns:
   - Read CLAUDE.md for project-specific conventions
   - Code structure, naming, and export patterns
   - Styling conventions (as defined by the project)
   - Testing conventions
   - Import paths and module structure

2. **Duplication check** — find duplicated logic in changed files:
   - Search for existing utilities/helpers that could be reused
   - Detect copy-pasted patterns
   - Flag identical logic in 3+ places

Plus every additional subagent the project's `CLAUDE.md` § Code Review section lists as applicable for the files actually changed in this subtask. If the project's `CLAUDE.md` has no such section, only the two standard subagents above run.

Fix ALL violations and HIGH-severity duplications found before proceeding.

## Step 5: Implementation Overview

After the task is implemented and code review passes, create `<taskId>-implementation-overview.md`. Use the `writing-implementation-overview` skill for the document structure and the `writing-files-for-review` skill for the "Files for Review" section — never write either manually. Both skills are bundled in this plugin.

## Step 6: Final Review

Do not create git commit, wait developer's review. You MUST:

1. Print: `"Please review the changes. <short overview>"`
2. Invoke the `sprava-ide` skill to add a sticky context-panel button — id `approve`, label `Approve changes`, command `/sprava:approve-changes`, color `success` — so the developer can advance with one click. Do NOT print the button-emitter call line in the response; the skill handles the HTTP request directly.
3. STOP and wait for explicit developer approval before proceeding.

## Step 7: Git Commit

After developer approval, create git commit following project conventions.

### Pre-commit Checks
Run the lint, unit-test, and integration-test commands the project documents in `CLAUDE.md` (or in the project's standard tooling — `package.json` scripts, `Makefile`, etc.). If a step is not documented, skip it rather than guessing. All steps that ARE documented must pass before committing.

### Include DevAI Metadata Files
Before committing, check for modified or untracked DevAI metadata files and include them in the commit. These files are often changed as a side effect of working on a feature and must not be left behind:
- `.devai/config.json`
- `features/**/.devai.json`
- `features/**/.dashboard-review-status.json`
- `features/**/implementation-plan.md` and `features/**/*-implementation-plan.md`

Run `git status` and stage any of the above that have changes, alongside the feature files.

### Developer Review Gates
When there is text like "wait for developer review", you need to stop, print:

> "Please review the changes. <short overview>"

Do not proceed to the next checklist item until the developer confirms the changes. All further to-do items must be completed only after developer's review. Do not create a git commit before review.
