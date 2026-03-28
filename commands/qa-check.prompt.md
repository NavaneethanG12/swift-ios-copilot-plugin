---
description: "Full QA pipeline — code review, test, generate report, fix issues"
agent: ios-copilot
---

Run the full QA workflow on this project:

1. **Review** — Load swift-code-review skill. Scan target files for code issues across all 9 dimensions (correctness, memory safety, concurrency, etc.).
2. **Test** — Load testing skill. Run existing tests and write new tests for uncovered paths. Use Swift Testing framework (@Test, #expect).
3. **Report** — Load feature-docs skill. Generate a QA Bug Report at `docs/reports/qa-report.md` combining all findings from review and tests.
4. **Fix** — Fix all Critical and Warning severity issues found.
5. **Re-test** — Verify fixes pass all tests.
6. **Update report** — Update the QA report with fix statuses (✅ Fixed / ❌ Not Fixed).

Produce a final summary:
```
📋 QA Report: docs/reports/qa-report.md
   Issues: <N> found, <N> fixed, <N> remaining
   Tests: <N> passed, <N> failed
```

${input:scope:Scope — specific screen/module/files to QA, or "all" for full project}
