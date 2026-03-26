---
name: swift-concurrency
description: >
  Audit Swift concurrency — async/await, actors, Sendable, data-race
  detection, MainActor isolation, structured concurrency, GCD migration,
  Swift 6 strict checking.
argument-hint: "[file, class, or concurrency warning]"
user-invocable: true
---

# Swift Concurrency Audit

## Step 1 — Identify concurrency model

| Model | Indicators |
|---|---|
| Structured concurrency | `async`, `await`, `Task {}`, `TaskGroup`, `async let` |
| Actors | `actor`, `@MainActor`, `@globalActor` |
| GCD (legacy) | `DispatchQueue`, `DispatchGroup`, `DispatchSemaphore` |
| Combine | `Publisher`, `sink`, `receive(on:)` |

---

## Concurrency Rules

1. **Actor isolation** — Access actor state only with `await`. Never synchronously read actor properties.
2. **@MainActor for UI** — All UI updates must be `@MainActor`. Use `MainActor.run { }` to hop.
3. **Sendable** — Types crossing actor boundaries must be `Sendable`.
   - Structs with Sendable properties → automatic. Actors → automatic.
   - Mutable classes → use `actor` instead, or `final class: @unchecked Sendable` with lock.
4. **Structured tasks** — Prefer `async let` / `TaskGroup` over `Task { }`. Store `Task` handles for cancellation.
5. **Cancellation** — Check `try Task.checkCancellation()` in loops. Use `withTaskCancellationHandler` for cleanup.
6. **Deadlocks** — Never `semaphore.wait()` on `@MainActor`. Make the function `async` instead.
7. **Actor reentrancy** — Re-check preconditions after every `await` inside an actor (state may have changed).

---

## GCD → async/await Migration

| GCD | Modern |
|---|---|
| `DispatchQueue.main.async` | `@MainActor func` or `MainActor.run` |
| `DispatchQueue.global().async` | `Task { }` or `Task.detached` |
| `DispatchGroup` | `async let` or `TaskGroup` |
| `DispatchSemaphore` | `AsyncStream` or `AsyncSequence` |
| Serial `DispatchQueue` | `actor` |
| `concurrentPerform` | `TaskGroup` with `addTask` |

---

## Swift 6 Warnings

| Warning | Fix |
|---|---|
| `Sending 'x' risks data races` | Make type Sendable or use actor |
| `Capture of 'self' with non-sendable type` | `@Sendable` closure or rearchitect |
| `Main actor-isolated property mutated from non-isolated context` | Add `@MainActor` or `MainActor.run` |
| `Non-sendable type returned by actor-isolated function` | Return Sendable type |
| `Global variable not concurrency-safe` | `nonisolated(unsafe)`, actor-isolate, or make constant |

---

## Thread Sanitizer

Enable: Scheme → Diagnostics → Thread Sanitizer (cannot combine with ASan).
Run tests → TSan shows racing access + conflicting previous access.
Fix with actor, lock, or `@MainActor`.

---

## Output format

```
File: <filename>  Line(s): <range>
Category: [Data Race | Actor Isolation | Sendable | Cancellation | Deadlock | Migration]
Severity: [Critical | Warning | Suggestion]
Issue: <description>
Fix: <code>
```

| Severity | Meaning |
|---|---|
| Critical | Guaranteed data race, deadlock, or crash |
| Warning | Likely race or Swift 6 migration blocker |
| Suggestion | Best-practice improvement |
