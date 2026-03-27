---
name: feature-docs
description: >
  Generate feature documentation and QA test reports as Markdown files.
  Use when asked to document features, create test reports, or produce
  documentation for manual testers. Outputs structured .md files.
user-invocable: true
---

# Feature Documentation Skill

Generate clear, structured Markdown documentation that manual testers and
stakeholders can use to understand features, reproduce test scenarios, and
track bug status.

## Output Location

Create documentation files in the user's project at:
- `docs/features/` — feature documentation
- `docs/reports/` — QA and bug reports

Create the `docs/` directory if it does not exist.

## Feature Documentation Template

When asked to **document features**, create one file per feature or screen:

```markdown
# Feature: <Feature Name>

## Overview
<!-- One paragraph: what this feature does, who it's for -->

## Screens
<!-- List every screen/view in this feature -->

| Screen | File | Purpose |
|---|---|---|
| <ScreenName> | `Sources/Features/<path>` | *description* |

## User Flows
<!-- Step-by-step flows a tester would follow -->

### Flow 1: <Name> (Happy Path)
1. Open the app → navigate to <screen>
2. Tap <element>
3. **Expected**: <what should happen>

### Flow 2: <Name> (Error Path)
1. Turn off network → navigate to <screen>
2. Tap <element>
3. **Expected**: <error message / fallback behaviour>

## Data Requirements
<!-- What data/state is needed to test this feature -->
- Logged-in user with <role>
- At least <N> items in <list>
- Network: online / offline / slow

## Edge Cases
<!-- Known edge cases testers should verify -->
- Empty state (no data)
- Maximum input length
- Rapid tap / double submission
- Background/foreground transitions

## Dependencies
<!-- Other features or services this depends on -->
- Authentication module
- <API endpoint>

## Known Limitations
<!-- Current limitations testers should be aware of -->
```

## QA Bug Report Template

When asked to produce a **bug report** or **QA report**, use this format:

```markdown
# QA Report: <Scope>

**Date**: <YYYY-MM-DD>
**Tester**: AI Agent (swift-reviewer + test-engineer)
**Build**: <version if known>

## Summary
- **Total issues found**: <N>
- **Critical**: <N> | **Warning**: <N> | **Info**: <N>
- **Tests run**: <N> | **Passed**: <N> | **Failed**: <N>

## Issues Found

### Issue 1: <Title>
- **Severity**: Critical | Warning | Info
- **Location**: `<FilePath>:<line>`
- **Description**: <what's wrong>
- **Steps to Reproduce**:
  1. <step>
  2. <step>
- **Expected**: <expected behaviour>
- **Actual**: <actual behaviour>
- **Root Cause**: <technical explanation>
- **Fix Status**: ✅ Fixed | ⏳ Pending | ❌ Not Fixed
- **Fix**: <description of the fix applied, or "needs manual fix">

### Issue 2: ...

## Test Results

| Test | Status | Notes |
|---|---|---|
| <test name> | ✅ Pass / ❌ Fail | <notes> |

## Recommendations
<!-- Suggestions for the team -->
1. <recommendation>
2. <recommendation>
```

## Rules

- Use **relative paths** from the project root for all file references.
- Include **steps to reproduce** for every bug — testers need these.
- Link issues to specific files and line numbers when possible.
- Keep language **non-technical** in the Summary and Steps to Reproduce
  sections — manual testers may not be Swift developers.
- Mark fix status clearly so testers know what to re-test.
