---
name: creating-sequence-diagram
description: Create mermaid sequence diagrams in implementation plans showing current vs new flow with color-coded participants.
---

# Creating Sequence Diagrams

Generates two mermaid sequence diagrams for implementation plans: current flow and new (proposed) flow with visual distinction between new, modified, and unchanged components.

## When to Use

- Adding sequence diagrams to an implementation plan
- Visualizing before/after flow for a feature change
- User asks for "diagram", "sequence diagram", or "mermaid diagram" in a plan

## Instructions

### 1. Gather Context

Read the implementation plan and relevant source code to identify:
- The user-triggered action (entry point)
- All components in the call chain (client → server → external)
- Which components are **new**, **modified**, or **unchanged**
- Which specific methods/interfaces change on modified components

### 2. Create Current Flow Diagram

Section heading: `## Current Flow: {short description}`

All participants unboxed (no color). Show the existing call chain with actual method names and payloads from the current codebase.

```
## Current Flow: (+) Button Creates Shell Terminal

```mermaid
sequenceDiagram
    participant User
    participant ComponentA
    participant ComponentB
    ...
```

### 3. Create New Flow Diagram

Section heading: `## New Flow: {short description}`

#### Participant Color Coding

| Category | Box Color | Usage |
|----------|-----------|-------|
| **New** | `rgb(220, 245, 220)` green | Components that don't exist yet |
| **Modified** | `rgb(255, 243, 210)` amber | Existing components with changed methods/interfaces |
| **Unchanged** | No box | Existing components with no code changes |

Group participants using mermaid `box` syntax. Multiple `box` blocks allowed when unchanged components sit between modified ones:

```
    participant User

    box rgb(220, 245, 220) New
        participant Dialog as MyNew<br/>Dialog
    end

    box rgb(255, 243, 210) Modified
        participant CompA as Component<br/>A
        participant CompB as Component<br/>B
    end

    participant Unchanged as Unchanged<br/>Component

    box rgb(255, 243, 210) Modified
        participant CompC as Component<br/>C
    end

    participant External as External<br/>Lib
```

#### Method Annotations on Modified Components

Every modified participant gets a `Note over` immediately before or after its first interaction, listing:
- Method/interface name that changes
- One-line description of the change

Format: `{method}() — {what changed}` or `{interface} — new fields: {fields}`

```
    Note over CompA: handleAction() — opens dialog<br/>instead of direct call
    Note over CompB: create() — new params: command?, args?<br/>uses command instead of default
```

Use `<br/>` for line breaks within notes. Keep to 2 lines max per note.

#### Syntax rules (avoid parse errors)

Mermaid's sequence parser rejects a few characters that read fine to a human. Keep note/message text safe:

- **No `;` in note or message text.** Mermaid treats `;` as a statement separator, so `…provider;<br/>…` ends the note early and the rest parses as garbage (`Parse error … got 'INVALID'`). Use `—`, `,`, or `.` instead.
- **Line breaks** are `<br/>` only. **Colons** are fine *after* the `:` delimiter (in the text), not before.
- Prefer plain ASCII in participant ids; put punctuation and unicode (`→`, `—`, `/`, `()`) in the `as` alias or the text, not the id.

When unsure, **don't guess — verify (Step 5).**

### 4. Add Key Difference Summary

After the new flow diagram, add a brief `### Key difference` section (2-3 sentences) explaining what changed architecturally.

### 5. Verify Every Diagram Renders

A diagram that doesn't render is worse than none — **always validate before presenting the plan.** This skill bundles a headless validator that runs mermaid's own parser over every ```mermaid block:

```bash
# Run from a directory whose node_modules has `mermaid` + `jsdom` (in this repo: ide/)
cd ide && node "$SKILL_DIR/scripts/verify-mermaid.mjs" ../.sprava/features/<ISSUE>/<plan>.md
```

`$SKILL_DIR` is this skill's base directory (printed when the skill loads). Read the output:

- `✓ file:line OK` — the block at that line parses.
- `✗ file:line <error>` — **fix it and re-run** until every block is `✓`. The error names the offending line and token (see Syntax rules above).
- `✗ cannot verify …` (exit 2) — `mermaid`/`jsdom` aren't resolvable from the current directory; run from the app package, or note that the diagram was not machine-verified.

Do not present a plan with a `✗` block.
