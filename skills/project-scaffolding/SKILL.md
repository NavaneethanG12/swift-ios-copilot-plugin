---
name: project-scaffolding
description: >
  Generate new iOS/macOS Xcode projects — folder structure, SPM setup,
  target configuration, build settings, capabilities, schemes.
argument-hint: "[app name, platform, or architecture style]"
user-invocable: true
---

# Project Scaffolding — iOS / macOS

## Template Selection

| Template | When |
|---|---|
| App (SwiftUI) | Modern declarative UI (iOS 15+) |
| App (UIKit) | Legacy or complex UIKit |
| Swift Package | Reusable library / multi-module |
| Framework | Distributable binary |
| Widget Extension | Home screen widgets |

---

## Folder Structure (MVVM)

```
MyApp/
├── Sources/
│   ├── App/           # @main, ContentView
│   ├── Features/      # Home/, Settings/ (View + ViewModel + Models per feature)
│   ├── Core/          # Networking/, Persistence/, Services/
│   ├── Shared/        # Components/, Extensions/, Models/, Utilities/
│   └── Resources/     # Localizable.xcstrings, Fonts/
├── MyAppTests/        # Feature tests, Core tests, Mocks/
└── MyAppUITests/
```

Multi-module: `Packages/Core/`, `Packages/Networking/`, `Packages/Features/` — each with `Package.swift`.

---

## Build Settings

| Setting | Value | Why |
|---|---|---|
| `SWIFT_VERSION` | 6.0 | Strict concurrency |
| `IPHONEOS_DEPLOYMENT_TARGET` | 17.0+ | SwiftData, @Observable |
| `SWIFT_STRICT_CONCURRENCY` | complete | Catch data races |
| `CODE_SIGN_STYLE` | Automatic | Managed signing |
| `ENABLE_PREVIEWS` | YES | SwiftUI previews |

---

## Capabilities

| Capability | When needed |
|---|---|
| Push Notifications | Remote notifications |
| Background Modes | Fetch, audio, location |
| App Groups | Widget, extension shared data |
| iCloud | CloudKit sync |
| In-App Purchase | StoreKit |

---

## Output format

Provide: template selection, folder structure diagram, Package.swift (if SPM),
app entry point, build settings, capabilities needed.

---

## Codebase Map Templates

When an agent needs to generate a codebase map for a user's project, use the
templates below. These are created inside the **user's project**, not the plugin.

### Template: `.github/copilot-instructions.md`

```markdown
# Project Copilot Instructions

This project uses the **Swift & iOS Developer Plugin** — a multi-agent system
with an orchestrator (`ios-copilot`) and 7 specialist agents.

## Codebase Navigation Rules

**Before reading source files, always consult the codebase map first.**

1. Read `.github/instructions/codebase-map.instructions.md` to understand the
   full module structure.
2. Identify which module(s) are relevant to the current task.
3. Read ONLY the files listed under those modules — do not scan the entire project.
4. If a module has its own `.instructions.md` file, read it for module-specific
   conventions before editing any file in that module.

## When to do a full scan

Only scan all files when:
- The user asks to "suggest features" or "what's missing" (Feature Discovery)
- The codebase map does not exist yet or is out of date
- The user explicitly asks to "scan everything" or "reindex"

## After major changes

When you create a new module, add a new screen, or significantly restructure:
- Update the codebase map (`codebase-map.instructions.md`)
- Create or update the module's `.instructions.md` if one exists
```

### Template: `.github/instructions/codebase-map.instructions.md`

Use this YAML frontmatter and fill the tables from the architect's scan results.

```markdown
---
name: "Codebase Map"
description: >
  Module-to-file mapping for the entire project. Agents read this FIRST to
  know which files to open for any task, avoiding full-project scans.
applyTo: "**"
---

# Codebase Map

> **This file is the single source of truth for project structure.**
> Agents: read this BEFORE opening any source files. Only read files listed
> under the module relevant to your current task.

## How to use this map

1. Match the user's task to a **Module** below.
2. Read only the **Key Files** listed for that module.
3. Note the **Depends On** column — read those modules only if you need to
   trace a dependency.
4. If no module matches, check **Shared / Foundation** first.

---

## App Structure

| Module | Purpose | Key Files | Depends On |
|---|---|---|---|

## Navigation Structure

(describe the nav hierarchy)

## Data Flow

(describe the data flow)

## Tech Stack

- **UI**:
- **Architecture**:
- **Persistence**:
- **Networking**:
- **DI**:
- **Min target**:
```

### Template: `.github/instructions/<module-name>.instructions.md`

Create one of these per module when adding new modules.

```markdown
---
name: "Module Template"
description: >
  Conventions and file listing for the <MODULE_NAME> module.
applyTo: "Sources/<MODULE_NAME>/**"
---

# Module: <MODULE_NAME>

## Purpose
<!-- One sentence: what does this module do? -->

## Key Files
| File | Role |
|---|---|
| `<Path/File.swift>` | *description* |

## Public API
- `<ProtocolName>` — *what it does*
- `<ClassName>` — *what it does*

## Dependencies
- `Shared` — utilities
- `Networking` — API calls

## Conventions
- *e.g. All ViewModels use @Observable macro*
- *e.g. Repository methods are async throws*

## Test Coverage
- Tests in: `Tests/<Module>Tests/`
- Coverage gaps: *list any*
```
