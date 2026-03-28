---
description: "Detect main thread hangs, hitches, and responsiveness issues"
agent: app-builder
---

Audit this project for main thread hangs and UI hitches.

Load the **performance-optimization** and **swift-concurrency** skills. Scan all Swift source files for:

1. **Main thread blocking** — synchronous network calls, file I/O, JSON parsing, or database queries on the main thread
2. **Missing async/await** — heavy work that should be dispatched off-main but isn't
3. **DispatchQueue.main.sync** — deadlock risks and unnecessary sync dispatches
4. **Long-running @MainActor work** — actor-isolated methods doing CPU-intensive computation
5. **Hitch-causing layout** — excessive `layoutSubviews` / `body` recomputation, complex Auto Layout constraint updates, large diffable data source updates without batching
6. **Animation hitches** — non-layer-backed animations, heavy work in animation blocks
7. **Core Data / SwiftData on main** — fetch requests without background contexts
8. **Image decoding on main** — large images decoded synchronously during scroll
9. **Notification/timer handlers** — heavy observers running on main thread

For each issue produce:
- Severity (Critical: >250ms hang / Warning: >100ms / Info: potential hitch)
- File path and line range
- Description of the hang/hitch risk
- Recommended fix (dispatch to background, use async/await, batch updates, etc.)

${input:scope:Scope — specific files/modules to audit, or "all" for full project}
