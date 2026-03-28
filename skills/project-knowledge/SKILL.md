---
name: project-knowledge
description: >
  Auto-generate project knowledge context (AGENTS.md, codebase map,
  architecture, conventions, glossary). Works for new, ongoing, and
  completed projects.
argument-hint: "[bootstrap, update docs, or regenerate]"
user-invocable: true
---

# Project Knowledge Context — Generation & Maintenance

> **Audience:** AI coding agents
> **Load when:** Bootstrapping project knowledge, creating docs, updating project context.

Generate and maintain a structured knowledge context so every agent understands
the project without full-codebase scans. Works for **new**, **ongoing**, and
**completed** projects.

---

## 1. Knowledge Context Structure

Every project gets this doc tree. **AGENTS.md** at root is the lightweight
index (auto-read by VS Code). Detailed docs live under `docs/`.

```
AGENTS.md                              ← Auto-read by VS Code every prompt
docs/
  ai-agents/
    README.md                          ← Index: what docs exist, reading guide
    CODEBASE_MAP.md                    ← "I want to do X → look in file Y"
    GLOSSARY.md                        ← Domain terms + code references
    PLAN_EXECUTION_CONTRACT.md         ← Rules for multi-stage plans
    DOC_TEMPLATE.md                    ← Template for adding new docs
    DOC_UPDATE_PROTOCOL.md             ← When/how to update these docs
  architecture/
    ARCHITECTURE.md                    ← Patterns, layers, modules, data flow
  development/
    CONVENTIONS.md                     ← Naming, style, project-specific patterns
```

---

## 2. Project Discovery — What to Scan

Scan in this order. Stop as soon as you have enough.

### Step 1 — Project Type Detection

| Signal | Project Type |
|--------|-------------|
| `Package.swift` exists | Swift Package (SPM) |
| `*.xcworkspace` exists | Xcode workspace (likely CocoaPods) |
| `*.xcodeproj` exists (no workspace) | Xcode project |
| `Podfile` exists | CocoaPods dependencies |
| `Cartfile` exists | Carthage dependencies |
| `*.playground` files | Swift Playground |
| Multiple targets in xcodeproj | Multi-target app (extensions, widgets, etc.) |

### Step 2 — Project State Detection

| Signal | State | Approach |
|--------|-------|----------|
| Only Package.swift or empty xcodeproj, < 5 Swift files | **New** | Scaffold-appropriate docs, fill as project grows |
| 5–50 Swift files, active git history | **Ongoing** | Deep scan, document existing patterns |
| 50+ Swift files, stable git history | **Completed/Mature** | Full analysis, domain glossary, architecture deep-dive |

### Step 3 — Key Files to Read

Read these (if they exist) to understand the project:

1. **Project manifest**: `Package.swift`, `*.xcodeproj/project.pbxproj` (for targets/deps)
2. **App entry**: `*App.swift`, `AppDelegate.swift`, `SceneDelegate.swift`
3. **README.md** or any existing docs
4. **Top-level directories**: `ls` the root and each major directory
5. **Key source files** (first 2–3 in each directory to detect patterns):
   - View files → detect SwiftUI vs UIKit vs mixed
   - Model files → detect persistence (SwiftData, Core Data, plain)
   - Network files → detect API patterns
   - Any `Router`, `Coordinator`, `Container`, `DI` files → detect architecture
6. **Config files**: `.swiftlint.yml`, `.swift-format`, `.gitignore`, `Gemfile`, `Fastfile`
7. **Existing AGENTS.md** or any `.instructions.md` files
8. **Podfile.lock** or `Package.resolved` → actual dependency versions

---

## 3. AGENTS.md Template (Root — auto-read)

Keep under 80 lines. This is injected into EVERY prompt, so brevity matters.

```markdown
<!-- audience: ai-agents -->
<!-- doc-type: index -->
<!-- last-updated: YYYY-MM-DD -->

# [Project Name]

> **What:** [1-2 sentences: what the app does]
> **Platform:** iOS [version]+ / macOS [version]+
> **Language:** Swift [version]

## Architecture
[Pattern name] — [1 sentence: how layers connect]

## Module Map
| Module | Purpose |
|--------|---------|
| `ModuleName/` | Brief purpose |

## Key Conventions
- [Top 5 rules that agents MUST follow]

## Dependencies
| Library | Purpose |
|---------|---------|
| Name | What it does |

## Detailed Docs
- Architecture details → `docs/architecture/ARCHITECTURE.md`
- Codebase navigation → `docs/ai-agents/CODEBASE_MAP.md`
- Code conventions → `docs/development/CONVENTIONS.md`
- Domain glossary → `docs/ai-agents/GLOSSARY.md`
- Multi-stage plans → `docs/ai-agents/PLAN_EXECUTION_CONTRACT.md`

## Restricted Files
<!-- Paths agents should NEVER read or modify -->
```

---

## 4. CODEBASE_MAP.md Template

Task-oriented lookup table: "I want to do X" → "Look in file Y".

```markdown
<!-- audience: ai-agents -->
<!-- doc-type: reference -->
<!-- last-updated: YYYY-MM-DD -->

# Codebase Map

> **Audience:** AI coding agents
> **Skip if:** You already know exactly which files to modify.

Task-oriented lookup: "I want to do X" → "Look in file Y".

---

## Project Root Structure

| Directory | Purpose |
|-----------|---------|
| `ModuleName/` | Brief description |

---

## Task → File Lookup

### Add/modify a screen or view
| Task | File(s) |
|------|---------|
| Add a new screen | `Module/Views/NewScreen.swift` + wire in Router |
| Modify the home screen | `Module/Views/HomeView.swift` |

### Add/modify data models
| Task | File(s) |
|------|---------|
| Add a new entity | `Module/Models/EntityName.swift` |
| Modify API response | `Module/Networking/Endpoints/...` |

### Add/modify a feature
| Task | File(s) |
|------|---------|
| Feature name | ViewModel: `path`, View: `path`, Model: `path` |

### App configuration / lifecycle
| Task | File(s) |
|------|---------|
| Change app entry | `App.swift` or `AppDelegate.swift` |
| Modify navigation | `Router.swift` or navigation container |

### Build / CI / deploy
| Task | File(s) |
|------|---------|
| Update dependencies | `Package.swift` or `Podfile` |
| Change build settings | `*.xcodeproj` or build config files |
```

---

## 5. ARCHITECTURE.md Template

```markdown
<!-- audience: ai-agents -->
<!-- doc-type: reference -->
<!-- last-updated: YYYY-MM-DD -->

# Architecture

> **Audience:** AI coding agents
> **Load when:** Planning features, refactoring, or understanding data flow.

---

## Pattern
[MVVM / TCA / Clean / MVC / custom] — [why this was chosen or detected]

## Layer Diagram
```
View Layer (SwiftUI / UIKit)
    ↓ observes
ViewModel / Store Layer (@Observable / ObservableObject / Reducer)
    ↓ calls
Service / Repository Layer (protocols)
    ↓ uses
Data Layer (Network / Persistence / Cache)
```

## Navigation
[NavigationStack / Coordinator / UINavigationController / Router pattern]
- Entry point: `[file]`
- Route definitions: `[file]`
- Deep linking: `[file or "not implemented"]`

## Data Flow
- **State management**: [@Observable / @ObservableObject / TCA Store / other]
- **Persistence**: [SwiftData / Core Data / UserDefaults / Keychain / none]
- **Networking**: [URLSession / Alamofire / custom / none]
- **Dependency injection**: [Protocol-based / Container / Environment / none]

## Module Relationships
| Module | Depends On | Depended By |
|--------|-----------|-------------|
| `Name` | `Dep1`, `Dep2` | `Consumer1` |

## Key Decisions
- [Decision 1: what and why]
- [Decision 2: what and why]
```

---

## 6. CONVENTIONS.md Template

```markdown
<!-- audience: both -->
<!-- doc-type: reference -->
<!-- last-updated: YYYY-MM-DD -->

# Code Conventions

> **Audience:** AI agents and human developers
> **Skip if:** You are reading code, not writing it.

---

## 1. Naming Conventions

### File Naming
| Type | Convention | Examples |
|------|-----------|----------|
| View | `<Name>View.swift` | `HomeView.swift` |
| ViewModel | `<Name>ViewModel.swift` | `HomeViewModel.swift` |
| Model | `<Name>.swift` or `<Name>Model.swift` | `User.swift` |
| Service | `<Name>Service.swift` | `AuthService.swift` |
| Protocol | `<Name>Protocol.swift` | `NetworkProtocol.swift` |
| Extension | `<Type>+<Feature>.swift` | `String+Validation.swift` |

### Symbol Naming
- Types: `UpperCamelCase` — `UserProfile`, `HomeViewModel`
- Properties/methods: `lowerCamelCase` — `userName`, `fetchData()`
- Constants: `lowerCamelCase` — `let maxRetryCount = 3`
- Enum cases: `lowerCamelCase` — `case loading`, `case error(Error)`
- Boolean properties: `is`/`has`/`should` prefix — `isLoading`, `hasAccess`

## 2. File Organization

Standard file structure order:
1. Import statements (sorted: Apple frameworks first, then third-party, then local)
2. Type definition (class/struct/enum)
3. Properties (stored, then computed)
4. Init
5. Public/internal methods
6. Private methods
7. Extensions (protocol conformances in separate extensions)

## 3. Patterns Used in This Project
- [List actual patterns detected: e.g., "All ViewModels are @Observable classes"]
- [e.g., "Network calls use async/await, NOT Combine"]
- [e.g., "Error handling uses Result type, NOT throws"]
- [e.g., "Navigation uses NavigationStack with enum-based destinations"]

## 4. Anti-Patterns to Avoid
- [List project-specific things NOT to do]
- [e.g., "Do NOT use UserDefaults for anything except simple preferences"]
- [e.g., "Do NOT create God ViewModels — split by feature"]

## 5. Error Handling
[Describe the project's error handling approach]

## 6. Concurrency
[Describe: async/await, actors, @MainActor usage, GCD usage if any]

## 7. Testing
[Describe: framework (Swift Testing / XCTest), mock approach, naming convention]
```

---

## 7. GLOSSARY.md Template

```markdown
<!-- audience: ai-agents -->
<!-- doc-type: reference -->
<!-- last-updated: YYYY-MM-DD -->

# Glossary

> **Audience:** AI coding agents
> **Skip if:** You already understand all domain terms in this project.

Domain-specific term definitions with code references.

---

### [Term]
[Definition: 1-2 sentences explaining what this means in THIS project]

**Code References:**
- `Path/To/File.swift` → `ClassName` (type/role)
- `Path/To/Other.swift` → `methodName()` (purpose)

---

### [Next Term]
...
```

**How to discover domain terms:**
1. Read app name, README, and any user-facing strings
2. Look at model names — these are usually domain objects
3. Look at enum cases — these often represent domain states
4. Look at API endpoint names — these map to domain operations
5. Look for terms that are NOT standard programming terms
6. Any term that a new developer would need explained

---

## 8. PLAN_EXECUTION_CONTRACT.md Template

```markdown
<!-- audience: ai-agents -->
<!-- doc-type: guide -->
<!-- last-updated: YYYY-MM-DD -->

# Plan Execution Contract

> **Audience:** AI coding agents
> **Read when:** Executing or creating a multi-stage refactoring plan.

Mandatory process for multi-stage work: plan creation, stage structure,
execution rules, and reporting.

---

## 1. Plan File Structure

Every plan file (`docs/plans/plan-{taskName}-{date}.md`) must contain:

1. **Stage Summary Table** — with emoji status tracking
2. **Stage Execution Details** — one section per stage
3. **Completion Reports** — appended after each stage finishes
4. **Plan Update Log** — records of scope changes

---

## 2. Stage Summary Table Format

| Stage | Description | Status |
|-------|-------------|--------|
| 1 | Description | ✅ Completed |
| 2 | Description | 🟡 In Progress |
| 3 | Description | ⬜ Not Started |

---

## 3. Execution Rules

1. **One stage at a time** — complete and verify before moving on
2. **No skipping** — stages are ordered for a reason
3. **Verify after each stage** — run tests, check compilation, review wiring
4. **Report after each stage** — append a completion report to the plan file
5. **Scope changes require approval** — if a stage needs more work than planned,
   update the plan and note the change before proceeding

## 4. Completion Report Format

For each completed stage, append:
```
### Stage N — Completion Report
- **Files created:** [list]
- **Files modified:** [list]
- **Tests:** [pass/fail count]
- **Verification:** [what was checked]
- **Issues found:** [any problems and how they were resolved]
- **Next stage ready:** [yes/no + any prerequisites]
```
```

---

## 9. DOC_TEMPLATE.md Template

```markdown
<!-- audience: ai-agents -->
<!-- doc-type: template -->
<!-- last-updated: YYYY-MM-DD -->

# Documentation Template

Use this template when adding new docs to the `docs/` folder.

---

## Required Header

Every doc MUST start with this metadata block:
\```
<!-- audience: ai-agents | both | human -->
<!-- doc-type: reference | guide | template -->
<!-- last-updated: YYYY-MM-DD -->
\```

- **audience**: `ai-agents` (only for agents), `both` (agents + humans), `human` (only humans)
- **doc-type**: `reference` (lookup), `guide` (workflow), `template` (copy+modify)
- **last-updated**: ISO date of last meaningful update

## Required Sections

1. **Title** — `# Document Name`
2. **Context block** — audience, skip-if/load-when
3. **Content** — the actual documentation
4. **Code References** — link to actual files where relevant
```

---

## 10. DOC_UPDATE_PROTOCOL.md Template

```markdown
<!-- audience: ai-agents -->
<!-- doc-type: guide -->
<!-- last-updated: YYYY-MM-DD -->

# Documentation Update Protocol

> **Audience:** AI coding agents
> **Read when:** Deciding whether to update project docs after a code change.

---

## When to Update

| Change Type | Update Required | Which Docs |
|-------------|----------------|------------|
| New module/target added | **Yes** | AGENTS.md, CODEBASE_MAP, ARCHITECTURE |
| New file added to existing module | Only if > 3 files | CODEBASE_MAP |
| Major refactor (architecture change) | **Yes** | AGENTS.md, ARCHITECTURE, CONVENTIONS |
| New dependency added | **Yes** | AGENTS.md (Dependencies table) |
| New domain concept introduced | **Yes** | GLOSSARY |
| Bug fix or minor edit | **No** | — |
| New third-party API integration | **Yes** | GLOSSARY, CODEBASE_MAP |
| Naming/style convention change | **Yes** | CONVENTIONS |

## How to Update

1. Read the existing doc
2. Make minimal, targeted edits — do NOT rewrite entire docs
3. Update the `last-updated` date in the metadata header
4. If adding a new section, follow the existing format and style

## Do NOT
- Rewrite docs that are still accurate
- Add project docs as part of every code-writing task
- Update docs for trivial changes (typo fixes, log message changes)
```

---

## 11. README.md Template (for docs/ai-agents/)

```markdown
<!-- audience: ai-agents -->
<!-- doc-type: guide -->
<!-- last-updated: YYYY-MM-DD -->

# AI Agent Documentation

> **Audience:** AI coding agents
> **Read when:** First interaction with this project.

## What's Here

| Document | Purpose | Read When |
|----------|---------|-----------|
| [CODEBASE_MAP.md](./CODEBASE_MAP.md) | "I want to do X → look in file Y" | Before reading source files |
| [GLOSSARY.md](./GLOSSARY.md) | Domain terms + code references | When encountering unfamiliar terms |
| [PLAN_EXECUTION_CONTRACT.md](./PLAN_EXECUTION_CONTRACT.md) | Rules for multi-stage work | Before starting a multi-milestone plan |
| [DOC_TEMPLATE.md](./DOC_TEMPLATE.md) | Template for new docs | When creating new documentation |
| [DOC_UPDATE_PROTOCOL.md](./DOC_UPDATE_PROTOCOL.md) | When/how to update docs | After making structural code changes |

## Also See
- `AGENTS.md` (workspace root) — Project overview, auto-read by VS Code
- `docs/architecture/ARCHITECTURE.md` — Detailed architecture
- `docs/development/CONVENTIONS.md` — Code conventions and style
```

---

## 12. Generation Rules

### For New Projects (< 5 Swift files)
- Generate all docs with placeholder/minimal content
- ARCHITECTURE.md: record the chosen pattern, leave module relationships empty
- CODEBASE_MAP.md: list existing files, add sections as groups are created
- CONVENTIONS.md: set project defaults (can be customized by user)
- GLOSSARY.md: empty with header — fill as domain grows
- Mark placeholders with `<!-- TODO: fill when more code exists -->`

### For Ongoing Projects (5–50 Swift files)
- Do a full scan per Step 2–3 above
- Detect patterns from actual code (don't assume)
- Populate all docs with real content
- GLOSSARY: identify model names, enum states, API terms

### For Mature/Completed Projects (50+ Swift files)
- Do a thorough scan — read more representative files per module
- ARCHITECTURE.md: document all layers, cross-module dependencies
- GLOSSARY.md: comprehensive domain vocabulary
- CONVENTIONS.md: detect from actual code patterns, not assumptions
- CODEBASE_MAP.md: task-oriented for ALL major features

### Universal Rules
- **Never assume — always detect.** Read actual code before writing docs.
- **Project-specific over generic.** Don't write "uses MVVM" if the code is MVC.
- **Include code references.** Every doc should link to actual files.
- **Date everything.** The `last-updated` header matters for staleness detection.
- **Keep AGENTS.md under 80 lines.** It's read on EVERY prompt.
