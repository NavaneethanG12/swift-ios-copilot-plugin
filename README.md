# Swift & iOS Developer — Copilot Plugin

Token-efficient VS Code Copilot plugin for **iOS/iPadOS/macOS development**.
Orchestrator agent (`ios-copilot`) classifies your prompt, restructures it
for clarity, and routes to 7 specialist agents backed by 24 compact skills.

## How it Works

```
You type anything → ios-copilot (orchestrator)
                        │
                        ├── Restructures your prompt into a clear format
                        ├── Classifies intent (build/crash/review/test/...)
                        └── Routes to the right specialist:
                              ├── app-builder      (build, UI, deploy)
                              ├── ios-architect     (design, refactor)
                              ├── swift-reviewer    (review, debug, fix)
                              ├── test-engineer     (tests, mocks)
                              ├── crash-analyst     (crash logs)
                              ├── memory-profiler   (leaks, OOM)
                              └── security-auditor  (vulnerabilities)
                                     │
                                     ├── Specialist loads relevant skills
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
| **Quality** | `swift-code-review` | 7-dimension review checklist |
| **Quality** | `testing` | Swift Testing, XCTest, mocking, coverage strategy |
| **Quality** | `ios-debugging` | Crashes, UI, networking, memory, build errors |
| **Quality** | `crash-diagnosis` | §A–§H crash classification, symbolication |
| **Quality** | `memory-management` | ARC, retain cycles, unsafe pointers, Instruments |
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
| `ios-copilot` **★** | **Root orchestrator** — restructures prompts and routes to specialists |
| `app-builder` | End-to-end app scaffolding and development |
| `ios-architect` | Read-only architecture planning |
| `swift-reviewer` | Code review with structured handoffs |
| `test-engineer` | Test plans, unit/UI tests, mocking |
| `security-auditor` | OWASP vulnerability audit and hardening |
| `crash-analyst` | Crash report diagnosis (§A–§H) |
| `memory-profiler` | Memory audit, Instruments guidance, fixes |

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
   - Route to the right specialist automatically
4. After the specialist finishes, click **[New Task]** to return to the orchestrator.

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

## Token Efficiency

Each skill contains only what the model doesn't already know:
- Decision tables (when to use X vs Y)
- Concise pattern stubs (not full implementations)
- Anti-patterns and checklists
- Cross-references instead of duplication

A typical interaction loads 1 agent + 1–3 skills ≈ 2,000–4,000 tokens of plugin context.

## Version History

| Version | Skills | Agents | Changes |
|---|---|---|---|
| 4.1.0 | 24 | 8 | +ios-copilot orchestrator (root agent), prompt restructuring, auto-routing, [New Task] handoffs on all specialists |
| 4.0.0 | 24 | 7 | +7 skills (platform, notifications, StoreKit, deep links, bg tasks, widgets, design system), all skills rewritten for token efficiency, all agents trimmed with YAML handoffs |
| 3.0.0 | 17 | 7 | +12 skills, +3 agents, full lifecycle coverage |
| 2.0.0 | 5 | 4 | Memory, crash, concurrency, code review, debugging |
| 1.0.0 | 0 | 2 | Initial architect + reviewer agents |
