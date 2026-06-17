---
name: writing-files-for-review
description: Creates the Files for Review section in implementation overviews using grouped vertical-slice format with markdown links.
---

# Writing Files for Review

Creates the `## Files for Review` section for implementation overview documents.

## When to Use

- After completing implementation of a subtask
- When creating or updating an implementation overview
- Referenced by `writing-implementation-overview` skill

## Format

Group files by **vertical slice** (feature/concern), not by architectural layer. Each group has:
1. `### H3` header — short group name
2. Description — one or two short sentences max. Keep it brief: what changed and why. Descriptions render in a compact sidebar.
3. One file per line: `[FileName.ext](path) - what it does`

**Tests always come after the code they test** — never put tests in a separate group. Place each test file immediately after the source file it covers, within the same group.

### Template

```markdown
## Files for Review

### Group name
Brief description of what changed and why.
[SourceFile.ts](../../../src/module/source-file.ts) - What it does
[SourceFile.test.ts](../../../src/module/source-file.test.ts) - Tests for SourceFile
[AnotherFile.ts](../../../src/module/another-file.ts) - What it does
```

### Example

```markdown
## Files for Review

### Portal repository
DB query enforcing access control. Sorted by project name.
[PortalRepository.ts](../../../src/portals/repository.ts) - Repository interface + implementation
[PortalRepository.test.ts](../../../src/portals/repository.test.ts) - Unit tests

### Portal service
Orchestrates portal retrieval. Title falls back to project name.
[PortalService.ts](../../../src/portals/service.ts) - Domain service
[PortalService.test.ts](../../../src/portals/service.test.ts) - Unit tests
[PortalDto.ts](../../../src/portals/dto.ts) - Response DTO

### API endpoint
GET /portals?status=ACTIVE endpoint. Requires X-AUTH-TOKEN header.
[PortalsController.ts](../../../src/api/portals-controller.ts) - Controller
[PortalsApi.test.ts](../../../tests/integration/portals-api.test.ts) - Integration tests
```

## Rules

- Links must use `../../../` prefix (relative to `.sprava/features/<issue-id>/` directory)
- Use `[FileName.ext](relative-path)` markdown link format — plain text paths break the dashboard
- Line numbers are optional: `[File.php](path#L24-L50)`
- Before finalizing, verify ALL linked files exist
- Group by what the files do together, not by which layer they belong to
- Each group should have at least 3 files. If a change is small and files don't form natural groups, list all files in a single flat group without subgroups
