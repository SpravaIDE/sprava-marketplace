---
sprava:
  type: claude
  command: /sprava:create-implementation-plan
  label: Create Implementation Plan
  description: Create implementation plan for a task
  scope: task,subtask
  form:
    fields:
      description:
        type: string
        label: Description
        multiline: true
    optional: true
---

# Create Implementation Plan

Use the `resolving-task-context` skill to resolve the current task (issue ID and subtask ID) and to load the feature-directory conventions. Then read `$ARGUMENTS` for any extra description provided through the command form.

---

## Step 1: Read Feature Documentation

Read `to-do.md`, `implementation-plan.md`, and all documents starting with task id (R-X-*, R-3-* for tasks R-3, R-3.1, R-3.2) from the directory.

## Step 2: Read Related Documentation

Read documents related to other tasks if relevant.

## Step 3: Read Task Requirements

Read the task requirements for the given task ID (check CLAUDE.md for requirements location).

## Step 4: Study Source Code

Read every file the change will touch and the surrounding code on both sides of the call boundary (callers and callees). Note:

- entry points, data models, and integration boundaries the change crosses
- existing patterns (naming, error handling, layering) the new code should follow
- existing utilities, services, hooks, fixture registries that already solve part of the problem — reuse them, do not duplicate

Carry these findings into Step 7 to justify the design decisions in the plan.

## Step 4.1: Analyze UI Components

For any task that involves UI work:

1. **List each UI capability** the feature needs (buttons, dialogs, dropdowns, breadcrumbs, links, etc.)
2. **Search the project's UI module** (location documented in `CLAUDE.md`) for existing components that already provide it
3. **If a match exists** but lacks flexibility, plan to extend it (add props/callbacks)
4. **If no match exists** and the project uses a UI primitive library, wrap a primitive into a new project-level abstraction — do not import primitives directly into feature code
5. **Only build from scratch** if no primitive covers the use case

Include a **UI Components** section in the implementation plan listing:
- Existing project UI components to reuse
- New wrappers to create (specifying which primitive they wrap, if applicable)
- Custom components only if no primitive applies (with justification)

**Styling and component-library conventions are project-specific — follow the rules documented in the project's `CLAUDE.md`.**

## Step 5: Ask Clarification Questions

Prepare the list of clarification questions if needed (only if you cannot find answer in the requirements, in the project documentation, in the source code). Use the `AskUserQuestion` tool ONLY for actual clarification questions about requirements. Do NOT use it for plan approval - just stop and wait for user response.

## Step 6: Save Q&A

Save questions and answers (only questions and answers - without implementation details) to `<TaskId>-<ShortTaskAlias>-questions.md` (TaskID is the id of task in the to-do list, like R-X).

## Step 7: Prepare Implementation Plan

Before writing, consult the **Creating Implementation Plan** section of the project's `CLAUDE.md` (if present). It documents project-specific additions to the standard plan structure — extra sections, additional reviewers, custom analysis steps. Apply those additions to the plan you produce. If the project's `CLAUDE.md` has no such section, use the standard structure.

Prepare implementation plan, save it in the feature directory, and present it to the developer. File name:

- If a subtask ID is in play (i.e., the work is scoped to a `to-do.md` item like `1`, `P-1`, or `P-9.2.2`), save as `<subtask-id>-implementation-plan.md` — use the subtask ID **exactly as it appears in `to-do.md`**, do not add or strip prefixes (e.g. `to-do.md` heading `## 1.` → `1-implementation-plan.md`; heading `## P-9.2.2.` → `P-9.2.2-implementation-plan.md`).
- Otherwise (issue-level plan with no subtask), save as `implementation-plan.md` — no prefix.

### Conciseness Rules

A plan exists to drive a review decision, not to re-derive the change. Keep it short.

- Lead with a 1–3 sentence Summary. Do **not** add a "Plan Summary" at the bottom restating it.
- List each file **once** — in the File Structure table — and reference it by name in other sections. Do not restate full paths in Approach prose, Tests, or Risks.
- Describe test scenarios with one-line bullets ("covers X / Y / boundary case Z"). Do not paste fixtures or numbered I/O tables — those belong in the test file.
- Skip **Risks & Mitigations** entries that don't describe a concrete failure mode (perf regression, breaking change to a consumer, data migration, security implication). If the mitigation is "that's the intended outcome", delete the entry.
- Default to "nothing breaks unless stated". Do not add "no API changes / no migration / no UI changes" disclaimers unless the change actually touches that surface.
- For one-line changes (regex tweaks, string updates), describe what changes in plain English plus the new value. Do not paste before/after code blocks.
- Drop empty sections. If there are no UI changes, omit the UI Components section entirely. Same for Tests, Risks, etc.
- Do not restate backwards-compat guarantees ("existing tests unchanged", "existing fixtures keep working"). The default reader assumption is that nothing else moves.
- **For File Structure, prefer an ASCII tree over a table when 3+ files share a meaningful directory shape** (same module / nested paths). Use a table when the touched files are scattered across unrelated areas. Tree format — lowercase status word, em-dash, short reason, parenthetical at the end of each line:

  ```
  ide/
  ├── src/client/terminal/
  │   ├── TerminalsManagerContext.tsx     (modified — gated closeTerminal)
  │   ├── closeConfirmation.ts            (new — pure predicate)
  │   └── closeConfirmation.test.ts       (new — unit test)
  └── e2e/
      └── terminal.spec.ts                (modified — +1 case)
  ```

  Use exactly three status words: `new` / `modified` / `deleted`. Align the parentheticals with spaces. Do not paste the full repo tree — only show the directories and files this change touches, with any intermediate directories collapsed onto one line (e.g. `src/client/terminal/`).

In the implementation plan provide the details about which Claude Code skills you'll use for implementing specific action. When you describe action item, say:

> Using `skill-name`, I'll implement...

### Diagrams

When the implementation involves non-trivial structure or flow, add a diagram. Pick the type that best fits the change:

| Change shape | Diagram type |
|---|---|
| Multi-component interaction (client → server → external; cross-module call chain; current vs new flow) | **Sequence** — use the `creating-sequence-diagram` skill (handles color-coded current vs new participants) |
| New or reshaped domain types, interfaces, inheritance/composition | Class / structure |
| Entity or UI lifecycle, transitions added/removed | State |
| Schema change touching relationships (new tables, foreign keys) | ER |
| Branching logic with non-trivial decision points | Activity / flowchart |

Include a diagram when:

- 3+ components interact in a non-trivial chain
- An existing flow is modified (show current vs new)
- A new data model or state machine is introduced
- A schema change touches relationships, not just columns

Skip diagrams for simple single-file changes, isolated utility functions, or pure CSS/styling tasks.

Render diagrams in mermaid. For sequence diagrams the `creating-sequence-diagram` skill enforces the recommended structure; for other types, write mermaid directly using the diagram syntax that best models the change.

### Tests

Every implementation plan MUST include a **Tests** section. Before drafting it, consult the project's `CLAUDE.md` § **Automated Test Strategy** (or a similarly named section, e.g. "Testing Strategy", "Test Strategy"). When that section exists, it is authoritative — it documents which test layers the project uses (unit, integration, E2E), which frameworks back each layer, where the spec files live, and which layers are required for which kinds of change. Apply that strategy to the plan:

- List specific test scenarios for each layer the strategy calls for
- Reference existing test patterns in the project (location follows the documented strategy) for consistency
- Specify which test files (existing or new) each scenario will land in
- If the change is purely internal and the strategy permits skipping a layer for that case, explicitly state which layers are skipped and why

If the project's `CLAUDE.md` has no such section, default to: list specific test scenarios (API-level and UI-level), reference existing test patterns in the project's test directory, and explicitly state "No tests needed" with justification when the change is purely internal with no observable API or UI surface.

The developer will add notes and comments directly in this implementation plan. Reread if the plan is not approved, and correct issues.

**CRITICAL: STOP AND WAIT FOR APPROVAL**

After presenting the implementation plan, you MUST:
1. Print a summary of what you're about to implement
2. Invoke the `sprava-ide` skill to add a sticky context-panel button — id `proceed`, label `Proceed to implementation`, command `/sprava:proceed-to-implementation`, color `success` — so the developer can advance with one click. Do NOT print the button-emitter call line in the response; the skill handles the HTTP request directly.
3. **STOP and wait for explicit developer approval** before proceeding
4. Do NOT start implementing — this command only creates the plan

Example output:
> Implementation plan ready for review.
