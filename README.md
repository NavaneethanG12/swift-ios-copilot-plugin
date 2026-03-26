# Swift & iOS Developer — Copilot Plugin

A VS Code Copilot agent plugin for Swift and iOS/macOS development.

## What's included

| Type | Name | What it does |
|---|---|---|
| Skill | `swift-code-review` | Reviews Swift files for safety, idioms, memory, and API design |
| Skill | `ios-debugging` | Step-by-step guide for crashes, leaks, UI issues, and build errors |
| Agent | `ios-architect` | Read-only planning agent — produces architecture plans with handoff |
| Agent | `swift-reviewer` | Code review agent with handoffs to architect or auto-fix |
| Hook | `PostToolUse` | Auto-formats edited `.swift` files with `swift-format` (if installed) |
| Hook | `SessionStart` | Prints a plugin welcome banner listing available skills and agents |

## Plugin structure

```
SwiftCopilotPlugin/
  plugin.json                              # Plugin metadata
  skills/
    swift-code-review/
      SKILL.md                             # Swift review checklist & output format
    ios-debugging/
      SKILL.md                             # Debugging guide
      debug-checklist.md                   # Quick classification checklist
  agents/
    ios-architect.agent.md                 # Architecture planning agent
    swift-reviewer.agent.md                # Code review agent
  hooks/
    hooks.json                             # Hook configuration
  scripts/
    post-edit.sh                           # Formats .swift files after edits
    session-start.sh                       # Prints welcome banner on session start
  README.md
```

## Installation

### Option A — Install from local path (VS Code settings)

Add to your `settings.json`:

```json
"chat.pluginLocations": {
    "/path/to/SwiftCopilotPlugin": true
}
```

### Option B — Install from Git

Run **Chat: Install Plugin From Source** from the VS Code Command Palette and
enter the Git repository URL.

## Requirements

- VS Code with GitHub Copilot extension
- `chat.plugins.enabled` set to `true` in VS Code settings
- *(Optional)* [`swift-format`](https://github.com/apple/swift-format) on your
  PATH for automatic formatting on file save

## Usage

### Skills

Type `/` in the Copilot Chat input to see available skills:

- `/swift-code-review [file or symbol]` — run a full Swift code review
- `/ios-debugging [error or symptom]` — get a structured debugging guide

### Agents

Open the agent picker in Copilot Chat and select:

- **ios-architect** — describe a feature or refactor; receive a detailed plan
  with an option to hand off to implementation
- **swift-reviewer** — point at a file or paste a diff; receive prioritised
  review feedback with options to plan or auto-fix

### Workflow example

1. Switch to **ios-architect** → describe the feature you want to build.
2. Review the architecture plan.
3. Select **Start Implementation** to hand off to `swift-reviewer`.
4. After implementation, run `/swift-code-review` on the new files.
5. Select **Apply Suggested Fixes** to let Copilot apply Critical/Warning fixes.
