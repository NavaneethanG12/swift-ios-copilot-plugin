---
description: "Review the codebase for quality, correctness, and best practices"
agent: swift-reviewer
---

Perform a comprehensive code review on this project.

Load the **swift-code-review** skill and check all 9 dimensions. For each issue produce:
- File path and line range
- Severity (Critical / Warning / Info)
- Description of the issue
- Corrected code

Focus on: correctness, memory safety, concurrency, API misuse, force-unwraps, retain cycles, error handling, naming conventions, and Swift idioms.

${input:scope:Scope — specific files/modules to review, or "all" for full project}
