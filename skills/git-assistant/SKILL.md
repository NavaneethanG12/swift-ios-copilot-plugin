---
name: git-assistant
description: >
  Analyze git changes, generate impact reports, and create conventional commit
  messages. Includes a git-report script for gathering repository state. Use
  when asked about git status, what changed, commit message, or change impact.
argument-hint: "[repo path, commit range, or 'what changed']"
user-invocable: true
---

# Git Assistant Skill

Analyze repository changes, assess impact on the codebase, and generate
ready-to-use commit messages — so developers don't have to manually review
every changed file to write a good commit.

## Scripts

This skill relies on a helper script that gathers raw git data:

The script is included in this skill: [git-report.sh](./git-report.sh)

| Script | Purpose | Usage |
|---|---|---|
| `git-report.sh` | Full change report (staged, unstaged, untracked, recent commits, remote diff) | Run with no args for full report |
| `git-report.sh --staged-only` | Only staged changes + detailed diff | Run when generating a commit message for staged files |

**Run the script first**, then analyze its output using the instructions below.

## Workflow

### 1. Gather — Run the git report script

The script is included in this skill directory:
[git-report.sh](./git-report.sh)

Execute this script in the terminal using `bash`:
- With no arguments for a full report (staged, unstaged, untracked, recent commits, remote diff)
- With `--staged-only` for only staged changes (use when generating a commit message)

### 2. Analyze — Classify every changed file

For each changed file in the report, determine:

| Property | How to determine |
|---|---|
| **Module / Layer** | Read the file path: `Sources/Networking/`, `Sources/Features/`, `Tests/`, etc. |
| **Change type** | Added, Modified, Deleted, Renamed |
| **Change scope** | Model, View, ViewModel, Service, Test, Config, Asset, Docs |
| **Risk level** | 🔴 High (public API, data model, security) · 🟡 Medium (business logic, navigation) · 🟢 Low (tests, docs, formatting) |

### 3. Assess impact — What else might be affected

For modified/deleted files:
- Search for **imports and references** to that file across the codebase
- Flag any callers, conformers, or dependents
- Note if the change touches a **protocol** or **public API** (ripple risk)
- Note if **tests exist** for the changed code and whether they need updating

### 4. Report — Output the Change Impact Report

Use this template:

```markdown
# Change Impact Report

**Branch**: <branch>
**Date**: <YYYY-MM-DD>
**Total files changed**: <N>

## Changes Summary

| # | File | Change | Scope | Risk | Affected By |
|---|---|---|---|---|---|
| 1 | `Sources/Features/Login/LoginView.swift` | Modified | View | 🟡 | LoginViewModel |
| 2 | `Sources/Networking/AuthService.swift` | Modified | Service | 🔴 | LoginVM, SignupVM, TokenRefresh |
| 3 | `Tests/LoginTests.swift` | Added | Test | 🟢 | — |

## Impact Analysis

### 🔴 High Risk
- **AuthService.swift** — Public API change on `authenticate()`. 3 callers
  found: `LoginViewModel`, `SignupViewModel`, `TokenRefreshService`. All must
  be verified.

### 🟡 Medium Risk
- **LoginView.swift** — UI layout change. Verify on multiple screen sizes.

### 🟢 Low Risk
- **LoginTests.swift** — New test file. No downstream impact.

## Recommendations
1. Run `LoginTests` and `AuthServiceTests` before committing.
2. Verify `SignupViewModel` still compiles after the `authenticate()` change.
```

### 5. Commit Message — Generate a conventional commit

After analysis, generate a commit message following **Conventional Commits**:

#### Format

```
<type>(<scope>): <short summary>

<body — what changed and why>

<footer — breaking changes, issue refs>
```

#### Type reference

| Type | When to use |
|---|---|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `refactor` | Code restructuring, no behavior change |
| `test` | Adding or updating tests |
| `docs` | Documentation only |
| `style` | Formatting, whitespace, no logic change |
| `chore` | Build, config, tooling, dependencies |
| `perf` | Performance improvement |
| `ci` | CI/CD pipeline changes |

#### Scope rules
- Use the **primary module** affected: `auth`, `login`, `networking`, `tests`
- If changes span 3+ modules, use the parent: `features`, `core`, or omit scope
- Keep scope lowercase, single word or hyphenated

#### Body rules
- Wrap at 72 characters
- Explain **what** changed and **why**, not how (the diff shows how)
- List all affected modules if cross-cutting
- Reference related files for context

#### Examples

Single-scope change:
```
feat(auth): add biometric login support

Add Face ID / Touch ID authentication flow to LoginView.
BiometricService wraps LocalAuthentication framework with
async/await API. Falls back to password on failure.

Closes #42
```

Multi-scope change:
```
refactor(networking): migrate AuthService to async/await

Replace completion-handler API with async throws across:
- AuthService.authenticate()
- AuthService.refreshToken()
- TokenStore.save()

All 3 callers updated: LoginViewModel, SignupViewModel,
TokenRefreshService. Existing tests updated to use async.

BREAKING CHANGE: AuthService.authenticate() signature changed
from callback to async throws.
```

### 6. Present to user

Always output **both** the impact report and the commit message.
Present the commit message in a fenced code block so the user can copy it
directly.

If the user only asked for a commit message (not a full report), skip the
impact report and go straight to steps 1 → 5 using `--staged-only`.

## Quick-commit shortcut

When the user says "commit message" or "what should I commit":

1. Run `git-report.sh --staged-only`
2. If nothing is staged, run the full report and tell the user to stage first
3. Analyze the staged diff
4. Output just the commit message (skip the full impact report)
