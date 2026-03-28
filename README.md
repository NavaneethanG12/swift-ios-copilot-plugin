# Swift & iOS Developer — Copilot Plugin

Token-efficient VS Code Copilot plugin for **iOS/iPadOS/macOS development**.
Orchestrator agent (`ios-copilot`) classifies your prompt, restructures it
for clarity, and routes to 7 specialist agents backed by 29 compact skills.
Includes 8 slash commands for common workflows.

## How it Works

```
You type anything → ios-copilot (orchestrator)
                        │
                        ├── 1. Restructures your prompt into a clear format
                        ├── 2. Classifies intent (build/crash/review/test/...)
                        ├── 3. Knowledge check:
                        │      ├── Skills cover it? → Proceed
                        │      └── Gap? → Searches web automatically for undocumented topics
                        │
                        └── 4. Routes to the right specialist:
                              ├── app-builder      (build, UI, deploy, fix, perf)
                              ├── ios-architect     (design, refactor, plan)
                              ├── swift-reviewer    (review, code quality)
                              ├── test-engineer     (tests, mocks, coverage)
                              ├── crash-analyst     (crash logs, diagnosis)
                              ├── memory-profiler   (leaks, OOM, retain cycles)
                              └── security-auditor  (vulnerabilities, OWASP)
                                     │
                                     ├── Specialist loads 1–3 relevant skills (28 available)
                                     ├── Applies Code Integrity Rules (R1–R9)
                                     ├── Applies Memory Leak Prevention (M1–M7)
                                     ├── Verifies integration (Phase 3.5)
                                     ├── Does the work
                                     └── Offers handoff buttons:
                                           [Write Tests] [Review Code] [New Task ↩]

Slash commands (skip orchestrator):
  /audit-code  /audit-memory  /audit-security  /audit-performance
  /audit-hangs  /fix-build  /qa-check
```

## What's included

### Skills (28)

| Category | Name | Purpose |
|---|---|---|
| **Build** | `project-scaffolding` | Project setup, folder structures, SPM, build settings |
| **Build** | `swiftui-development` | State management, navigation, views, animations |
| **Build** | `uikit-development` | UIViewController lifecycle, programmatic Auto Layout, UITableView, UICollectionView |
| **Build** | `networking` | API client, endpoints, retry, auth, ATS |
| **Build** | `data-persistence` | SwiftData, Core Data, DB architecture, relationships, migrations, Keychain, UserDefaults, CloudKit sync |
| **Build** | `architecture-patterns` | MVVM, TCA, DI, Coordinator, SPM modules |
| **Build** | `design-system` | Color tokens, typography, spacing, OSLog, error handling |
| **Quality** | `swift-code-review` | 9-dimension review checklist (incl. compilation safety, wiring completeness) |
| **Quality** | `compiler-errors` | Diagnose and fix Swift/Xcode build errors with xcodebuild capture + known solution matching |
| **Quality** | `testing` | Swift Testing, XCTest, mocking, coverage strategy |
| **Quality** | `ios-debugging` | Crashes, UI, networking, memory, build errors |
| **Quality** | `crash-diagnosis` | §A–§H crash classification, symbolication |
| **Quality** | `memory-management` | ARC, retain cycles, leak prevention rules (M1–M7), workspace-wide audit, Instruments |
| **Quality** | `swift-concurrency` | Actors, Sendable, data races, GCD migration, Swift 6 |
| **Quality** | `performance-optimization` | Launch time, scroll perf, app size, profiling |
| **Ship** | `ios-security` | Keychain, SSL pinning, biometrics, OWASP Top 10 |
| **Ship** | `accessibility` | VoiceOver, Dynamic Type, contrast, Reduce Motion |
| **Ship** | `localization` | String Catalogs, formatters, RTL, plural rules |
| **Ship** | `ci-cd` | Xcode Cloud, GitHub Actions, Fastlane |
| **Ship** | `app-store-submission` | Code signing, TestFlight, App Review, metadata |
| **Workflow** | `feature-docs` | Generate feature documentation and QA test reports as Markdown |
| **Workflow** | `git-assistant` | Analyze git changes, impact reports, conventional commit messages |
| **Platform** | `platform-adaptation` | iPadOS sidebar, macOS MenuBarExtra, multi-platform |
| **Platform** | `push-notifications` | APNs, local/remote, categories, rich notifications |
| **Platform** | `storekit` | StoreKit 2 purchases, subscriptions, transaction listener |
| **Platform** | `deep-linking` | Universal Links, URL schemes, App Clips, Spotlight |
| **Platform** | `background-tasks` | BGTaskScheduler, background URLSession |
| **Platform** | `widgets-extensions` | WidgetKit, Share/Action extensions, App Groups |
| **Context** | `project-knowledge` | Auto-generate project knowledge context (AGENTS.md, codebase map, architecture, conventions, glossary) |

### Agents (8)

| Name | Role |
|---|---|
| `ios-copilot` **★** | **Root orchestrator** — restructures prompts, knowledge check with web permission, routes to specialists |
| `app-builder` | End-to-end app scaffolding with Code Integrity Rules (R1–R9), memory leak prevention, integration verification |
| `ios-architect` | Read-only architecture planning with wiring maps |
| `swift-reviewer` | 9-dimension code review (incl. compilation safety, wiring, memory leaks) |
| `test-engineer` | Test plans, unit/UI tests, mocking with compile verification |
| `security-auditor` | OWASP vulnerability audit and hardening |
| `crash-analyst` | Crash report diagnosis (§A–§H) |
| `memory-profiler` | Memory audit, workspace-wide leak scan, Instruments guidance, fixes |

All specialists have a **[New Task]** handoff button that returns to the orchestrator.

### Slash Commands (8)

| Command | Agent | Purpose |
|---|---|---|
| `/bootstrap-project` | app-builder | Generate full project knowledge context (AGENTS.md + docs/) for the workspace |
| `/audit-code` | swift-reviewer | Review codebase for quality, correctness, best practices (all 9 dimensions) |
| `/audit-hangs` | app-builder | Detect main thread hangs, hitches, UI responsiveness issues |
| `/audit-memory` | memory-profiler | Scan project for memory leaks, retain cycles, unbounded growth (Phases 1–4) |
| `/audit-performance` | app-builder | Full performance audit — launch time, scroll, memory, app size |
| `/audit-security` | security-auditor | Audit for OWASP Mobile Top 10 vulnerabilities |
| `/fix-build` | app-builder | Fix all compiler/build errors (Phase 0.75 with compiler-errors skill) |
| `/qa-check` | ios-copilot | Full QA pipeline — code review, tests, generate report at `docs/reports/qa-report.md` |

### Hooks (3)

| Hook | Trigger | Action |
|---|---|---|
| `SessionStart` | New agent session begins | Runs project discovery, shows knowledge context status, prints welcome banner |
| `PostToolUse` | After file write/edit | Auto-formats edited `.swift` files with `swift-format` |
| `PreCompact` | Before context compaction | Extracts session state (files, decisions, errors) to `.github/session-context.md` |

### Scripts & Utilities

| Script | Location | Purpose |
|---|---|---|
| `session-start.sh` | `scripts/` | Runs project-discover.sh, shows knowledge context status, welcome banner |
| `project-discover.sh` | `scripts/` | Detects project type, state, UI framework, and existing knowledge docs — returns JSON |
| `post-edit.sh` | `scripts/` | Parses tool output, runs `swift-format --in-place` on edited `.swift` files |
| `pre-compact.sh` | `scripts/` | Extracts key context from transcript JSON for context survival across compaction |
| `xcode-build-errors.sh` | `skills/compiler-errors/` | Runs xcodebuild, captures and structures compiler errors for Phase 0.75 |
| `git-report.sh` | `skills/git-assistant/` | Gathers git status, diffs, commit log for change analysis |
| `debug-checklist.md` | `skills/ios-debugging/` | Quick failure-type classification reference |
| `arc-checklist.md` | `skills/memory-management/` | Quick memory audit reference for retain cycles and growth |

## Installation

### Project Knowledge Context

When you open any project with this plugin, it automatically detects whether
project knowledge docs exist. If they don't, it nudges you to generate them
(one-time setup). This works for **new**, **ongoing**, and **completed** projects.

```
Your project workspace:
├── AGENTS.md                              ← Auto-read by VS Code every prompt
├── docs/
│   ├── ai-agents/
│   │   ├── README.md                      ← Index of all docs
│   │   ├── CODEBASE_MAP.md                ← "I want to do X → look in file Y"
│   │   ├── GLOSSARY.md                    ← Domain terms + code references
│   │   ├── PLAN_EXECUTION_CONTRACT.md     ← Rules for multi-stage plans
│   │   ├── DOC_TEMPLATE.md                ← Template for adding new docs
│   │   └── DOC_UPDATE_PROTOCOL.md         ← When/how to update docs
│   ├── architecture/
│   │   └── ARCHITECTURE.md                ← Patterns, layers, data flow
│   └── development/
│       └── CONVENTIONS.md                 ← Naming, style, project-specific patterns
└── (your source code)
```

**How to generate:** Tell ios-copilot "bootstrap the project knowledge" or use
the `/bootstrap-project` slash command.

**How it works:**
1. The `SessionStart` hook runs `project-discover.sh` which detects your project
   type (SPM/Xcode), state (new/ongoing/mature), UI framework, and which docs exist.
2. If docs are missing, you're prompted to generate them.
3. The `project-knowledge` skill guides the app-builder agent through scanning your
   project and generating all docs with real data from your code.
4. Once generated, all agents automatically read these docs to understand your
   project before working on it.

**When docs get updated:** Only on structural changes (new module, major refactor,
architecture change). See `docs/ai-agents/DOC_UPDATE_PROTOCOL.md`.

### Option 1: Local Install via VS Code Settings (Recommended)

1. Clone or download this repository to your machine:
   ```bash
   git clone https://github.com/<your-org>/SwiftCopilotPlugin.git ~/SwiftCopilotPlugin
   ```

2. Open VS Code **Settings (JSON)** — press `⌘⇧P` → **Preferences: Open User Settings (JSON)**.

3. Add these two entries:
   ```jsonc
   {
     "chat.plugins.enabled": true,
     "chat.pluginLocations": {
       "/Users/<you>/SwiftCopilotPlugin": true   // ← full path to the cloned folder
     }
   }
   ```
   Replace `/Users/<you>/SwiftCopilotPlugin` with the **absolute path** where you cloned the repo.

4. Reload VS Code (`⌘⇧P` → **Developer: Reload Window**).

5. Open Copilot Chat — you should see the plugin's agents (`ios-copilot`, `app-builder`, etc.) in the agent picker.

### Option 2: Install From Source via Command Palette

1. Press `⌘⇧P` and run **Chat: Install Chat Plugin from Source…**
2. Browse to the folder containing `plugin.json` (the root of this repo).
3. VS Code registers the plugin automatically — no `settings.json` edit needed.

> **Tip:** Option 2 does the same thing as Option 1 but through a UI dialog. The resulting entry still appears in `chat.pluginLocations` in your settings.

### Requirements

- VS Code with **GitHub Copilot** extension installed
- `chat.plugins.enabled` set to `true` in settings
- *(Optional)* [`swift-format`](https://github.com/apple/swift-format) on PATH — enables the auto-format hook

### Getting Started (after install)

1. Open your iOS/macOS project in VS Code.
2. Open Copilot Chat and select **ios-copilot** from the agent picker.
3. **Run `/bootstrap-project` once** — this scans your project and generates the
   knowledge context (`AGENTS.md` + `docs/`). It's a one-time setup per project.
4. Start working — type any prompt and the orchestrator handles the rest.

> If you skip step 3, the orchestrator will detect the missing context on your
> first prompt and offer to generate it automatically.

## Usage

### Recommended: Use the Orchestrator

1. Select **ios-copilot** from the agent picker.
2. Type anything — plain English is fine:
   - "my app crashes when I tap profile"
   - "build me a todo app with SwiftData"
   - "review HomeViewModel.swift"
   - "is my keychain code secure?"
3. The orchestrator will:
   - Show you a **Structured Prompt** (so you see what it understood)
   - Check if local skills are sufficient — if not, **search the web automatically**
   - Route to the right specialist automatically
4. The specialist applies **Code Integrity Rules** (R1–R9) and **Memory Leak Prevention** (M1–M7) to every file.
5. After the specialist finishes, click **[New Task]** to return to the orchestrator.

### Direct Skill Invocation

For quick lookups, skip the agents entirely:

```
/architecture-patterns MVVM for a 3-developer team
/crash-diagnosis [paste crash log]
/storekit auto-renewable subscription setup
/platform-adaptation adapt my app for iPadOS sidebar
/uikit-development compositional layout for a photo grid
/compiler-errors fix linker errors in my project
```

### Slash Commands

Run common workflows directly without going through the orchestrator:

```
/audit-code         → Full 9-dimension code review
/audit-memory       → Workspace-wide memory leak scan
/audit-security     → OWASP Mobile Top 10 audit
/audit-performance  → Launch time, scroll, app size audit
/audit-hangs        → Main thread hang detection
/fix-build          → Capture and fix all compiler errors
/qa-check           → Full QA pipeline with report
```

### Agents

Select from the agent picker:

- **app-builder** — describe your app → guided lifecycle
- **ios-architect** — feature description → architecture plan
- **swift-reviewer** — file path → prioritised review with handoffs
- **crash-analyst** — crash log → structured diagnosis

### Workflow examples

**Any prompt** (orchestrator auto-routes):
```
You: "add push notifications to my app"
→ ios-copilot restructures → routes to app-builder → loads push-notifications skill
```

**Crash investigation chain**:
```
You: "EXC_BAD_ACCESS on profile screen"
→ ios-copilot → crash-analyst diagnoses → [Fix] → swift-reviewer → [Test] → test-engineer
```

**Full app build**:
```
You: "build a habit tracker with SwiftUI and SwiftData"
→ ios-copilot → app-builder (phases 1-5) → [Review] → swift-reviewer → [Tests] → test-engineer
```

**Memory leak audit** (existing project):
```
You: "scan this project for memory leaks"
→ ios-copilot → memory-profiler (workspace-wide audit phases 1-4) → report + fixes
```

**Third-party library** (web knowledge needed):
```
You: "integrate Firebase Auth into my app"
→ ios-copilot searches web for Firebase Auth docs → routes to app-builder with Firebase knowledge
```

## Code Quality Guarantees

Every file the plugin writes is checked against these rules:

### Code Integrity Rules (R1–R9)

| Rule | What it prevents |
|---|---|
| R1 — Complete Imports | `Cannot find 'X' in scope` errors |
| R2 — Type Conformances | Missing `Hashable`, `Identifiable`, `Codable` |
| R3 — Wire Navigation | Views created but unreachable |
| R4 — Connect Data Flow | ViewModels created but never used |
| R5 — Verify After Write | Errors left in files |
| R6 — No Orphan Types | Types without usage sites |
| R7 — Compile-Check | Mental compilation before finishing |
| R8 — Memory Leak Prevention | Retain cycles, strong delegates, unbounded caches |
| R9 — Explicit `self` in Closures | `Reference to property in closure requires explicit self` errors |

### Memory Leak Prevention (M1–M7)

| Rule | Pattern |
|---|---|
| M1 | Stored closures → `[weak self]` + `guard let self` + `self.` |
| M2 | Delegates → `weak var` |
| M3 | Timers → block API + `[weak self]` + `deinit` invalidation |
| M4 | Combine sinks → `[weak self]` + `guard let self` |
| M5 | `@Observable` classes → no stored closures referencing self |
| M6 | Caches → `NSCache` with `countLimit`/`totalCostLimit` |
| M7 | Large resources → release on disappear + memory warning |

### Integration Verification (Phase 3.5)

After building views and data types, the app-builder traces every user journey
and data flow end-to-end before moving forward.

### Web Knowledge Check

When skills don't cover a topic (third-party libraries, new APIs, specific
frameworks), the orchestrator automatically searches the web to gather
relevant context before routing to a specialist.

## Token Efficiency

Each skill contains only what the model doesn't already know:
- Decision tables (when to use X vs Y)
- Concise pattern stubs (not full implementations)
- Anti-patterns and checklists
- Cross-references instead of duplication

A typical interaction loads 1 agent + 1–3 skills ≈ 3,000–5,000 tokens of plugin context.

## Version History

| Version | Skills | Agents | Changes |
|---|---|---|---|
| 4.11.0 | 28 | 8 | Expanded `data-persistence` skill: full Core Data stack (NSPersistentContainer, NSFetchRequest, NSFetchedResultsController, batch ops), SwiftData advanced (@Attribute options, @Unique, #Index, ModelConfiguration, FetchDescriptor, ModelActor), DB architecture & relationship patterns (1:1, 1:N, M:N, self-ref, enums), delete rules reference, schema migrations (VersionedSchema, SchemaMigrationPlan, Core Data staged), history tracking, CloudKit sync, repository pattern |
| 4.10.0 | 28 | 8 | +4 skills (uikit-development, compiler-errors, feature-docs, git-assistant), +7 slash commands, +PreCompact hook, auto web search (no permission gate), utility scripts |
| 4.4.0 | 24 | 8 | Web knowledge check with user permission gate — orchestrator and specialists ask before fetching |
| 4.3.1 | 24 | 8 | R9 (explicit `self` in closures), `[weak self]` + `guard let self` pattern enforced everywhere |
| 4.3.0 | 24 | 8 | Memory leak prevention (M1–M7), workspace-wide leak audit mode, LeakSanitizer/Instruments guides |
| 4.2.0 | 24 | 8 | Code Integrity Rules (R1–R8), Phase 3.5 integration verification, 9-dimension code review, compiler error tables, complete file templates |
| 4.1.0 | 24 | 8 | +ios-copilot orchestrator (root agent), prompt restructuring, auto-routing, [New Task] handoffs on all specialists |
| 4.0.0 | 24 | 7 | +7 skills (platform, notifications, StoreKit, deep links, bg tasks, widgets, design system), all skills rewritten for token efficiency, all agents trimmed with YAML handoffs |
| 3.0.0 | 17 | 7 | +12 skills, +3 agents, full lifecycle coverage |
| 2.0.0 | 5 | 4 | Memory, crash, concurrency, code review, debugging |
| 1.0.0 | 0 | 2 | Initial architect + reviewer agents |
