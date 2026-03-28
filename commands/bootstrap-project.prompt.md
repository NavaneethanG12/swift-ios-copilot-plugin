---
description: "Generate the full project knowledge context (AGENTS.md + docs/) for this workspace. Works for new, ongoing, or completed projects."
agent: app-builder
---

Bootstrap the project knowledge context for this workspace. Load the **project-knowledge** skill, then:

1. **Scan the project** — detect project type (SPM/Xcode/workspace), project state (new/ongoing/mature), frameworks (SwiftUI/UIKit/mixed), architecture patterns, dependencies, and domain terms.

2. **Generate the full docs structure:**
   - `AGENTS.md` at workspace root (lightweight index, under 80 lines)
   - `docs/ai-agents/README.md` (doc index)
   - `docs/ai-agents/CODEBASE_MAP.md` (task → file lookup)
   - `docs/ai-agents/GLOSSARY.md` (domain terms + code refs)
   - `docs/ai-agents/PLAN_EXECUTION_CONTRACT.md` (multi-stage plan rules)
   - `docs/ai-agents/DOC_TEMPLATE.md` (template for new docs)
   - `docs/ai-agents/DOC_UPDATE_PROTOCOL.md` (when/how to update)
   - `docs/architecture/ARCHITECTURE.md` (patterns, layers, data flow)
   - `docs/development/CONVENTIONS.md` (naming, style, project patterns)

3. **Populate with real data** — never use placeholder content if the project has actual code. Read source files, detect patterns, extract domain terms.

4. **Report** what was generated. Do NOT proceed to any build phase — this is a documentation-only task.
