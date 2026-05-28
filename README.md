# Sprava Marketplace

Claude Code marketplace shipping two plugins for working inside the [Sprava IDE](https://gitlab.com/d.karviga/claude-ide):

- **`sprava-ide`** — the `sprava-ide` skill (HTTP API helpers for talking to the IDE from inside a terminal: open files, manage tabs, context-panel buttons). Required for the IDE to work end-to-end.
- **`sprava`** — slash commands (`/sprava:create-implementation-plan`, `/sprava:create-subtask`, `/sprava:approve-changes`, `/sprava:proceed-to-implementation`, `/sprava:question`) and authoring skills (`writing-implementation-overview`, `writing-files-for-review`, `resolving-task-context`, `creating-sequence-diagram`).

The IDE detects whether each plugin is installed on start and shows install instructions if either is missing.

## Install

```
/plugin marketplace add git@gitlab.com:d.karviga/sprava-marketplace.git
/plugin install sprava-ide@sprava-marketplace
/plugin install sprava@sprava-marketplace
```

Local development install:

```
/plugin marketplace add file:///path/to/sprava-marketplace
/plugin install sprava-ide@sprava-marketplace
/plugin install sprava@sprava-marketplace
```

## Runtime requirements

The IDE-action commands and the `sprava-ide` skill rely on these environment variables, set by the IDE when it spawns a terminal:

- `SPRAVA_PORT` — IDE server port (used to reach the local HTTP API)
- `SPRAVA_PROJECT_ID` — active project id
- `SPRAVA_TASK_ID` — current task id (optional; set when the terminal is task-scoped)
- `SPRAVA_TERMINAL_ID` — current terminal id (used by `/approve-changes` to mark the tab completed)

The IDE also installs companion shell scripts under `~/.claude/scripts/devai/` (e.g. `set-terminal-completed.sh`) — those stay in the IDE's bootstrap path and are not packaged here.
