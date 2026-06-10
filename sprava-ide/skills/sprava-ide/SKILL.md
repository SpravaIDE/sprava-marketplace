---
name: sprava-ide
description: Interact with Sprava IDE from Claude Code terminals — open files, manage tabs, set the current task's status via setTaskStatus(), read the current task's data via getTaskData(), and add/remove/clear context-panel buttons via the addButton()/addStickyButton()/addLaunchButton()/addStickyLaunchButton()/removeButton()/clearButtons() syntax. Use when SPRAVA_PORT env var is present.
---

# Sprava IDE Actions

Control the Sprava IDE from Claude Code terminals via API endpoints.

## When to Use

- When you want to show a file to the user in the IDE's file viewer
- **When you see `addButton(...)`, `addStickyButton(...)`, `addLaunchButton(...)`, `addStickyLaunchButton(...)`, `removeButton(...)`, or `clearButtons()` in user input — handle it via the "Context Panel Buttons" section below.**
- Only available in terminals spawned by Sprava IDE (SPRAVA_* env vars present)

## Open File

Open a file in the IDE's built-in file viewer (new tab):

```bash
~/.claude/scripts/devai/open-file.sh /absolute/path/to/file.ts
```

Open a file alongside the current terminal (split view):

```bash
~/.claude/scripts/devai/open-file.sh --split /absolute/path/to/file.ts
```

Optional: include line number to highlight a specific line:

```bash
~/.claude/scripts/devai/open-file.sh /absolute/path/to/file.ts 42
```

## Get View State

Query the current IDE layout state (mode, panel count, active panel):

```bash
~/.claude/scripts/devai/get-viewstate.sh
```

Returns JSON with:
- `layoutMode` — effective mode (`normal`, `focus`, or `switcher`); `auto` is resolved before reporting
- `layout` — layout type (e.g., `two-column`, `three-column`)
- `paneCount` — number of visible panels (1–8)
- `activePanel` — index of the active/focused panel

## Update Terminal Tab Label

Rename the current terminal tab:

```bash
~/.claude/scripts/devai/update-terminal-label.sh "New Label"
```

Updates the tab visible in the IDE's tab bar. The target is always the current terminal (derived from `$SPRAVA_TERMINAL_ID`).

## Set Terminal Tab Completed State

Mark the current terminal tab as completed (work is done):

```bash
~/.claude/scripts/devai/set-terminal-completed.sh
```

Clear the completed flag:

```bash
~/.claude/scripts/devai/set-terminal-completed.sh false
```

The tab turns solid green to signal completion. The target is always the current terminal (`$SPRAVA_TERMINAL_ID`).

## Close Terminal Tab

Close the current terminal tab:

```bash
~/.claude/scripts/devai/close-terminal.sh
```

Removes the tab from the IDE and terminates its PTY process. The target is always the current terminal (`$SPRAVA_TERMINAL_ID`). The user-facing close-confirmation dialog is bypassed when closing via the API.

## Set Task Status

Set the status of the current task — `setTaskStatus(<status>)`:

```bash
~/.claude/scripts/devai/set-task-status.sh in-progress
```

The target is always the current task (the issue, derived from `$SPRAVA_TASK_ID`); a `:subtask` suffix is ignored because status is task-level (e.g. `DEV-1942:1` updates `DEV-1942`).

Allowed values are the project's task statuses. The built-in default set is:

- `new`, `preparation`, `in-progress`, `testing`, `released`, `closed`

A project whose tasks are controlled by a task-management plugin (e.g. an external tracker) defines its own status set instead. An unknown value returns a `400` with a clear error.

## Get Task Data

Fetch the current task's data — `getTaskData()`:

```bash
"${CLAUDE_PLUGIN_ROOT}/skills/sprava-ide/scripts/get-task-data.sh"
```

`${CLAUDE_PLUGIN_ROOT}` is substituted by Claude Code with this plugin's installation directory. Unlike the older actions above, this script ships with the plugin — it is not installed under `~/.claude/scripts/devai/`.

The target is always the current task (the issue, derived from `$SPRAVA_TASK_ID`); a `:subtask` suffix is ignored because the data is task-level. Prints the task JSON:

- `id`, `title` — task identifier and title
- `metadata.status` — current status (plus `notes`, `tags`, optional `link`)
- `description` — content of the task's `description.md`, or `null` when the file is absent
- `subtasks[]` — the checklist: each subtask has `id`, `title`, `checkboxes[]` (`{ checked, text }`), nested `children[]`, and associated `files[]`
- `progress` — `{ total, completed, percentage }` across all checklist items
- `files[]` — task-level files (name, path, type)

Example — read the current task's status and remaining checklist:

```bash
"${CLAUDE_PLUGIN_ROOT}/skills/sprava-ide/scripts/get-task-data.sh" | jq '{status: .metadata.status, description, todo: [.subtasks[] | {id, title, open: [.checkboxes[] | select(.checked | not) | .text]}]}'
```

Errors: when `SPRAVA_PORT`, `SPRAVA_PROJECT_ID`, or `SPRAVA_TASK_ID` is unset the script prints a clear message to stderr and exits 1. An unknown task id prints the IDE's 404 body (`{"error": "Task not found"}`) and exits 1; any HTTP error ≥ 400 exits non-zero the same way.

## Context Panel Buttons

Show clickable buttons in the IDE's context-action row at the bottom of the current pane. Clicking a button types the configured command into THIS terminal and submits it. Buttons are scoped to the current terminal (`$SPRAVA_TERMINAL_ID`).

These are runtime context-panel buttons — pure HTTP calls into the IDE. They do NOT create files, do NOT read frontmatter, and do NOT need a matching command file. (Sidebar-row buttons declared in `.claude/commands/*.md` frontmatter are a separate mechanism handled by the run-configuration system, not by this skill.)

### Syntax — fire-and-forget

When the user (or you) write any of the following, **immediately** run the matching Bash script. Do not create any files. Do not validate. Do not check whether the command exists. Do not read frontmatter or any other files. Do not explain. Do not enter any other skill. Just run the script.

| Syntax | Action |
|---|---|
| `addButton("<id>", "<label>", "<command>")` | `~/.claude/scripts/devai/add-context-button.sh <id> <label> <command>` |
| `addButton("<id>", "<label>", "<command>", "<color>")` | `~/.claude/scripts/devai/add-context-button.sh <id> <label> <command> normal <color>` |
| `addStickyButton("<id>", "<label>", "<command>")` | `~/.claude/scripts/devai/add-context-button.sh <id> <label> <command> sticky` |
| `addStickyButton("<id>", "<label>", "<command>", "<color>")` | `~/.claude/scripts/devai/add-context-button.sh <id> <label> <command> sticky <color>` |
| `addLaunchButton("<id>", "<label>", "<taskId>")` | `~/.claude/scripts/devai/add-context-launch-button.sh <id> <label> <taskId> "" normal` |
| `addLaunchButton("<id>", "<label>", "<taskId>", "<subtaskId>")` | `~/.claude/scripts/devai/add-context-launch-button.sh <id> <label> <taskId> <subtaskId> normal` |
| `addLaunchButton("<id>", "<label>", "<taskId>", "<subtaskId>", "<color>")` | `~/.claude/scripts/devai/add-context-launch-button.sh <id> <label> <taskId> <subtaskId> normal <color>` |
| `addStickyLaunchButton("<id>", "<label>", "<taskId>")` | `~/.claude/scripts/devai/add-context-launch-button.sh <id> <label> <taskId> "" sticky` |
| `addStickyLaunchButton("<id>", "<label>", "<taskId>", "<subtaskId>")` | `~/.claude/scripts/devai/add-context-launch-button.sh <id> <label> <taskId> <subtaskId> sticky` |
| `addStickyLaunchButton("<id>", "<label>", "<taskId>", "<subtaskId>", "<color>")` | `~/.claude/scripts/devai/add-context-launch-button.sh <id> <label> <taskId> <subtaskId> sticky <color>` |
| `removeButton("<id>")` | `~/.claude/scripts/devai/remove-context-button.sh <id>` |
| `clearButtons()` | `~/.claude/scripts/devai/clear-context-buttons.sh` |

### Rules

- **No research.** Never look up whether the command exists, whether a similar button is already configured elsewhere (e.g. `.claude/commands/`), or what the command does. Just add the button.
- **No confirmation.** Don't ask "should I do this?" — run the script.
- **No narration beyond one short line** acknowledging the action (e.g. "Added.").
- **Sticky vs normal.** `addButton` creates a normal button that auto-clears when the user submits the next message. `addStickyButton` creates a sticky button that survives user messages — remove it with `removeButton("<id>")` or `clearButtons()`, or let the user click it (clicking auto-hides both modes).
- **Color** is optional and one of `accent` (default), `success`, `warning`, `danger`, `neutral`. Pick based on intent: `success` for confirm/approve/deploy, `danger` for destructive, `warning` for "are you sure", `neutral` for low-emphasis. Omit (or use `accent`) for generic actions.
- **Launch buttons** are split buttons that target a task (and optionally a subtask). The button's main label area fires the project's default run configuration for that scope (same as the tasks-list play button); the chevron opens a menu listing every configured run configuration for the scope with title + description per item (same content as the tasks-list dropdown). The IDE derives the menu items from the run-config context — you do NOT pass an options array. When the current terminal is completed/idle, the launch reuses its pane; otherwise it opens a new terminal.
- **Use one launch button per task/subtask.** Emit several separate `addStickyLaunchButton(...)` calls when you want the developer to be able to start multiple tasks — do NOT pack them under a single button.
- **Label format for launch buttons.** Use `Task: "<Title>"` (e.g. `Task: "Open Website URL"`) — never the bare subtask identifier (`P-2`). The identifier is already encoded in the `taskId`/`subtaskId` payload; the label is what the developer reads.

### Examples

User: `addButton("plan", "Create Plan", "/create-implementation-plan")`
You: *(run the script, reply "Added.")*

User: `addButton("deploy", "Deploy", "/devai:deploy", "success")`
You: *(run `add-context-button.sh deploy "Deploy" "/devai:deploy" normal success`, reply "Added.")*

User: `addStickyButton("approve", "Approve plan", "/devai:approve-changes")`
You: *(run `add-context-button.sh approve "Approve plan" "/devai:approve-changes" sticky`, reply "Added.")*

User: `removeButton("plan")`
You: *(run the script, reply "Removed.")*

User: `addStickyLaunchButton("p-22", "Task: \"Subtask Numbering\"", "RELEASE-TASKS", "P-22")`
You: *(run `add-context-launch-button.sh p-22 'Task: "Subtask Numbering"' RELEASE-TASKS P-22 sticky`, reply "Added.")*

You decide a sticky approve button is useful after presenting a plan (sticky so it survives the user's next message until they pick a path):
*(run `add-context-button.sh approve "Approve plan" "/devai:approve-changes" sticky` and continue your reply.)*

### Automatic cleanup

- **Click** (either mode, simple or dropdown) — clicking a chip submits its command (or fires its first option, for dropdowns' main label) and removes the chip. Clicking any dropdown menu option also fires that option and removes the chip. You don't need to call `removeButton` after the user clicks.
- **Next user message** (normal only) — typing a message + Enter clears every `normal` button on the terminal. Sticky buttons survive.
- **Terminal close** (either mode) — all buttons for a terminal disappear when its tab closes.

Sticky buttons are otherwise removed only by `removeButton("<id>")` or `clearButtons()`. You don't need to call `clearButtons()` for the normal-message and terminal-close cases above.
