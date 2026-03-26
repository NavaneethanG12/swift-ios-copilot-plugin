---
name: memory-management
description: >
  iOS/macOS memory management — ARC, retain cycles, closure captures,
  unsafe pointers, Instruments profiling, memory-access crash diagnosis.
argument-hint: "[file, class, crash log, or symptom]"
user-invocable: true
---

# Memory Management

## Classify

| Category | Symptoms |
|---|---|
| Retain cycle | `deinit` never called, growing footprint |
| Unbounded growth | Memory warning, jettisoned, OOM |
| Bad access | `EXC_BAD_ACCESS`, dangling pointer → use `/crash-diagnosis` §D–§E |
| Unsafe pointer | `UnsafePointer`, `withUnsafeBytes`, `Unmanaged` |

---

## ARC Quick Reference

Strong refs increment count. `weak` → optional, nils on dealloc. `unowned` → crashes if accessed after dealloc.
Prefer `weak` unless lifetime is provably guaranteed.

---

## Retain Cycle Patterns

| Pattern | Problem | Fix |
|---|---|---|
| Stored closure captures `self` | `self → closure → self` | `[weak self] in self?.method()` |
| Strong delegate | `owner → delegate → owner` | `weak var delegate` |
| Timer/CADisplayLink | Timer retains target | Block API + `[weak self]` |
| Combine sink | Sink captures self | `[weak self] in self?.handle($0)` |
| Parent ↔ child VCs | Mutual strong refs | Child holds `weak` parent ref |

---

## Unsafe Pointer Rules

| API | Safety |
|---|---|
| `withUnsafePointer(to:)` | Pointer valid only inside closure — never escape |
| `withUnsafeBytes(of:)` | Never escape buffer pointer |
| `Span<T>` (Swift 6+) | Compiler-checked lifetime |

**Anti-patterns**: Escaping pointer from `withUnsafe*` closure (UB), allocating without `deallocate()`, `assumingMemoryBound` without prior `bindMemory`.

**Unmanaged bridging**: `Unmanaged.passRetained(obj).toOpaque()` → later `fromOpaque(ptr).takeRetainedValue()`.

---

## Diagnostic Tools

| Tool | Use |
|---|---|
| Memory Graph Debugger (⌥⌘M) | Visual cycle detection |
| Instruments — Leaks | Find leaked allocations |
| Instruments — Allocations | Track growth (Mark Generation) |
| Address Sanitizer | Use-after-free, buffer overflow |
| Zombie Objects | Messages to deallocated objects |
| Malloc Scribble | Fill freed with 0x55 |

---

## Output format

```
File: <name>  Line(s): <range>
Category: [Retain Cycle | Growth | Bad Access | Unsafe Pointer]
Severity: [Critical | Warning | Suggestion]
Issue: <description>
Fix: <code>
Diagnostic: <tool to verify>
```

| Severity | Meaning |
|---|---|
| Critical | Guaranteed leak, crash, or UB |
| Warning | Likely leak under load |
| Suggestion | Best-practice improvement |
