---
sprava:
  type: claude
  command: /sprava:question
  label: Question
  description: Ask a question about selected code
  order: 100
  scope: comment-actions
---

You received a question about code. The arguments contain JSON with `citation` (the selected code) and `note` (the question).

Parse $ARGUMENTS as JSON and extract:
- `citation` — the code the user is asking about
- `note` — the user's question

**Rules:**
- Answer the question clearly and concisely
- Do NOT modify any files
- Do NOT suggest code changes unless explicitly asked
- Focus only on explaining, clarifying, or answering what was asked
