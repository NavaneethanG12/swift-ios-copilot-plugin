# Swift & iOS Developer — Copilot Plugin

Token-efficient VS Code Copilot plugin for **iOS/iPadOS/macOS development**.
Orchestrator agent (`ios-copilot`) classifies your prompt, restructures it
for clarity, and routes to 7 specialist agents backed by 24 compact skills.

## How it Works

```
You type anything → ios-copilot (orchestrator)
                        │
                        ├── 1. Restructures your prompt into a clear format
                        ├── 2. Classifies intent (build/crash/review/test/...)
                        ├── 3. Knowledge check:
                        │      ├── Skills cover it? → Proceed
                        │      └── Gap? → Asks YOU: "May I check the web for [topic]?"
                        │           ├── You say yes → Fetches, gathers key info
                        │           └── You say no  → Proceeds with local skills
                        │
                        └── 4. Routes to the right specialist:
                              ├── app-builder      (build, UI, deploy)
                              ├── ios-architect     (design, refactor)
                              ├── swift-reviewer    (review, debug, fix)
                              ├── test-engineer     (tests, mocks)
                              ├── crash-analyst     (crash logs)
                              ├── memory-profiler   (leaks, OOM)
                              └── security-auditor  (vulnerabilities)
                                     │
                                     ├── Specialist loads relevant skills
                                     ├── Applies Code Integrity Rules (R1–R9)
                                     ├── Applies Memory Leak Prevention (M1–M7)
                                     ├── Verifies integration (Phase 3.5)
                                     ├── Does the work
                                     └── Offers handoff buttons:
                                           [Write Tests] [Review Code] [New Task ↩]
```

## What's included

### Skills (24)

| Category | Name | Purpose |
|---|---|---|
| **Build** | `project-scaffolding` | Project setup, folder structures, SPM, build settings |
| **Build** | `swiftui-development` | State management, navigation, views, animations |
| **Build** | `networking` | API client, endpoints, retry, auth, ATS |
| **Build** | `data-persistence` | SwiftData, Keychain, UserDefaults, file storage |
| **Build** | `architecture-patterns` | MVVM, TCA, DI, Coordinator, SPM modules |
| **Build** | `design-system` | Color tokens, typography, spacing, OSLog, error handling |
| **Quality** | `swift-code-review` | 9-dimension review checklist (incl. compilation safety, wiring completeness) |
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
| **Platform** | `platform-adaptation` | iPadOS sidebar, macOS MenuBarExtra, multi-platform |
| **Platform** | `push-notifications` | APNs, local/remote, categories, rich notifications |
| **Platform** | `storekit` | StoreKit 2 purchases, subscriptions, transaction listener |
| **Platform** | `deep-linking` | Universal Links, URL schemes, App Clips, Spotlight |
| **Platform** | `background-tasks` | BGTaskScheduler, background URLSession |
| **Platform** | `widgets-extensions` | WidgetKit, Share/Action extensions, App Groups |

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

### Hooks (2)

| Hook | Action |
|---|---|
| `PostToolUse` | Auto-formats edited `.swift` files with `swift-format` |
| `SessionStart` | Prints welcome banner with all skills and agents |

## Installation

Add to your VS Code `settings.json`:

```json
"chat.pluginLocations": {
    "/path/to/SwiftCopilotPlugin": true
}
```

Or run **Chat: Install Plugin From Source** from the Command Palette.

### Requirements

- VS Code with GitHub Copilot
- `chat.plugins.enabled: true`
- *(Optional)* [`swift-format`](https://github.com/apple/swift-format) on PATH

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
   - Check if local skills are sufficient — if not, **ask your permission** to search the web
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
→ ios-copilot: "I'd like to check Firebase Auth docs. Shall I?"
→ You: "yes"
→ ios-copilot fetches → routes to app-builder with Firebase knowledge
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
frameworks), the orchestrator and specialists **ask your permission** before
fetching from the web. No silent web access — you always approve first.

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
| 4.4.0 | 24 | 8 | Web knowledge check with user permission gate — orchestrator and specialists ask before fetching |
| 4.3.1 | 24 | 8 | R9 (explicit `self` in closures), `[weak self]` + `guard let self` pattern enforced everywhere |
| 4.3.0 | 24 | 8 | Memory leak prevention (M1–M7), workspace-wide leak audit mode, LeakSanitizer/Instruments guides |
| 4.2.0 | 24 | 8 | Code Integrity Rules (R1–R8), Phase 3.5 integration verification, 9-dimension code review, compiler error tables, complete file templates |
| 4.1.0 | 24 | 8 | +ios-copilot orchestrator (root agent), prompt restructuring, auto-routing, [New Task] handoffs on all specialists |
| 4.0.0 | 24 | 7 | +7 skills (platform, notifications, StoreKit, deep links, bg tasks, widgets, design system), all skills rewritten for token efficiency, all agents trimmed with YAML handoffs |
| 3.0.0 | 17 | 7 | +12 skills, +3 agents, full lifecycle coverage |
| 2.0.0 | 5 | 4 | Memory, crash, concurrency, code review, debugging |
| 1.0.0 | 0 | 2 | Initial architect + reviewer agents |
