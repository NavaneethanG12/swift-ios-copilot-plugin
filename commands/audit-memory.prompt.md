---
description: "Scan the project for memory leaks, retain cycles, and unbounded growth"
agent: memory-profiler
---

Perform a Workspace-Wide Memory Leak Audit (Phase 1–4) on this project.

Load the **memory-management** skill. Scan all Swift source files for:
- Retain cycles (strong self in closures, delegate strong references)
- Strong delegate properties missing `weak`
- Unbounded caches and collections that grow without limits
- Missing `deinit` on classes that hold resources
- Combine/Timer/NotificationCenter subscriptions not cancelled
- Closure capture lists missing `[weak self]` where needed

Produce a full **Memory Audit Report** with:
- Severity (Critical / Warning / Info)
- File path and line range
- Description of the issue
- Recommended fix with before/after code

${input:scope:Scope — specific files/modules to audit, or "all" for full project}
