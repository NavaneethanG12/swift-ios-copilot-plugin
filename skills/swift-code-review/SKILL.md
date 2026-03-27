---
name: swift-code-review
description: >
  Reviews Swift source files for correctness, idioms, memory safety, and
  Swift/iOS best practices. Use this when asked to review, audit, or improve
  Swift code, or when looking for bugs, retain-cycle risks, force-unwraps, or
  violations of the Swift API Design Guidelines.
argument-hint: "[file or symbol to review]"
user-invocable: true
---

# Swift Code Review

Perform a structured code review across 9 dimensions. Produce actionable, line-level feedback.

## Review checklist

### 1. Safety
- Flag every force-unwrap (`!`) that is not provably safe; suggest `guard let`,
  `if let`, or a safe default instead.
- Identify retain cycles in closures; suggest `[weak self]` or `[unowned self]`
  where appropriate.
- Check that `@escaping` closures capture the minimum required scope.
- Look for unhandled `throws` or ignored `Result` values.

### 2. Correctness
- Verify that `Codable` implementations match the expected JSON shape.
- Confirm that `async/await` call sites are on the right actor (main vs background).
- Ensure `@MainActor` is applied wherever UI state is mutated.
- Check that `NotificationCenter` observers are deregistered (or use
  Combine/async sequences instead).

### 3. Swift idioms
- Prefer `struct` over `class` unless reference semantics are required.
- Use `enum` with associated values rather than stringly-typed flags.
- Replace `NSObject` subclasses with pure Swift types where possible.
- Favour `guard` for early exits over nested `if` chains.
- Use `defer` for balanced resource cleanup.

### 4. Memory management
- Identify retain cycles: stored closures capturing `self` strongly, strong
  delegate properties, `Timer` / `CADisplayLink` retaining targets.
- Flag `unowned` references where the lifetime guarantee is not provably
  correct — prefer `weak` in ambiguous cases.
- Check that `deinit` cleans up observers, timers, and subscriptions.
- Flag unsafe pointer escapes: `UnsafePointer` must not outlive its scoped
  closure (`withUnsafePointer`, `withUnsafeBytes`, etc.).
- Verify `Unmanaged.passRetained` is balanced with `takeRetainedValue`.
- Look for tight loops creating Objective-C objects without `autoreleasepool`.

### 5. Performance
- Spot unnecessary `Array` copies where `Sequence` or `Collection` slices suffice.
- Flag synchronous work on the main thread that should move to a background task.
- Identify repeated string-to-type conversions that should be cached.
- Check for unbounded caches (image caches, data caches) without eviction.

### 6. Concurrency
- Verify `@MainActor` on all types/methods that mutate UI state.
- Check that non-`Sendable` types are not sent across actor boundaries.
- Flag `DispatchSemaphore.wait()` or blocking calls on the main thread.
- Verify actor reentrancy: state must be re-checked after `await` suspension.
- Ensure `Task` handles are stored for cancellation when appropriate.
- Flag fire-and-forget `Task {}` blocks that ignore errors silently.

### 7. API Design Guidelines
- Types, protocols, and enum cases: UpperCamelCase.
- Methods, properties, local variables: lowerCamelCase.
- Boolean properties should read as assertions (`isLoading`, `hasError`).
- Method labels should make call sites read as English prose.

### 8. Compilation Safety
- **Missing imports**: Every file must have correct `import` statements.
  Flag any file missing `import SwiftUI`, `import Foundation`, etc.
- **Missing conformances**: Types used in `ForEach` need `Identifiable`.
  Types used in `NavigationLink(value:)` need `Hashable`. Codable models
  need `Codable`. Flag missing conformances.
- **Type mismatches**: Check that function parameters match calling types.
  Check that `@Binding` parameters receive `$property` at call sites.
- **Missing implementations**: If a protocol is declared, check that at
  least one concrete type implements it. Flag protocols with zero conformers.
- **Unresolved references**: Flag any type or function used but not
  defined in the visible codebase (may indicate missing file or import).

### 9. Wiring Completeness
- **Navigation**: Every view should be reachable from the navigation
  hierarchy. Flag views that are defined but never used in a
  `NavigationLink`, `navigationDestination`, `TabView`, `sheet`, or
  `fullScreenCover`.
- **Data binding**: Every `@Observable` ViewModel should be instantiated
  in at least one view via `@State` or `@Environment`. Flag ViewModels
  with no usage site.
- **Async loading**: Every ViewModel with `load()` or `fetch()` methods
  should be called from `.task {}` in a view. Flag async methods that
  are never called.
- **Error handling**: If a ViewModel has an `error` property, the view
  should display it (`.alert`, `Text`, etc.). Flag undisplayed errors.
- **User actions**: Every button/tap gesture should call a ViewModel
  method. Flag buttons with empty or placeholder actions.

## Output format

For each issue found, report:
```
File: <filename>  Line(s): <range>
Severity: [Critical | Warning | Suggestion]
Issue: <concise description>
Fix:
<corrected Swift snippet>
```

End with a one-paragraph summary of overall code quality and the top three
improvements the author should prioritise.

Compilation Safety (§8) and Wiring Completeness (§9) issues that would prevent
the app from building or functioning should always be reported as **Critical**.

---

## Severity definitions

| Severity | Meaning | Must fix before merge? |
|---|---|---|
| **Critical** | Bug, crash risk, data loss, or serious security issue | Yes |
| **Warning** | Bad practice, likely bug, or clear maintainability problem | Strongly recommended |
| **Suggestion** | Style, naming, or minor improvement | Optional |

Cross-reference: `/memory-management` for ARC/retain-cycle details, `/crash-diagnosis` for crash analysis, `/swift-concurrency` for async/actor patterns.
