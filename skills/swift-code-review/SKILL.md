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

## About this skill

This skill turns Copilot into a senior Swift engineer performing a structured
code review. It covers five review dimensions — safety, correctness, Swift
idioms, performance, and API naming — and produces actionable, line-level
feedback in a consistent format.

**When to invoke:**
- You want a thorough audit of a Swift file before opening a pull request.
- You need help spotting memory-management or concurrency bugs.
- You are onboarding to an existing Swift codebase and want a quality overview.
- You want to enforce the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
  across a module.

**What this skill does NOT do:**
- It does not run the compiler or static analyser; it reviews the source text.
- It does not refactor the entire file — it identifies and explains issues and
  provides targeted fix snippets.
- It does not enforce project-specific style beyond the Swift community standard.

**Related resources:**
- [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- [SE-0310 Effectful Read-only Properties](https://github.com/apple/swift-evolution/blob/main/proposals/0310-effectful-readonly-properties.md)
- [Swift Concurrency documentation](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)

---

You are a senior Swift engineer performing a thorough code review. Follow
these steps whenever this skill is invoked.

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

### 4. Performance
- Spot unnecessary `Array` copies where `Sequence` or `Collection` slices suffice.
- Flag synchronous work on the main thread that should move to a background task.
- Identify repeated string-to-type conversions that should be cached.

### 5. API Design Guidelines
- Types, protocols, and enum cases: UpperCamelCase.
- Methods, properties, local variables: lowerCamelCase.
- Boolean properties should read as assertions (`isLoading`, `hasError`).
- Method labels should make call sites read as English prose.

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

---

## Severity definitions

| Severity | Meaning | Must fix before merge? |
|---|---|---|
| **Critical** | Bug, crash risk, data loss, or serious security issue | Yes |
| **Warning** | Bad practice, likely bug, or clear maintainability problem | Strongly recommended |
| **Suggestion** | Style, naming, or minor improvement | Optional |

## Common Swift pitfalls — quick reference

### Retain cycles
```swift
// ❌ Strong capture of self in a long-lived closure
class ViewModel {
    var onUpdate: (() -> Void)?
    func setup() {
        onUpdate = { self.refresh() }  // retains self
    }
}

// ✅ Weak capture
onUpdate = { [weak self] in self?.refresh() }
```

### Force-unwrap
```swift
// ❌ Crashes if nil
let url = URL(string: userInput)!

// ✅ Safe with a fallback
guard let url = URL(string: userInput) else { return }
```

### Main-actor isolation
```swift
// ❌ Mutates UI state from a background task
Task.detached { self.label.text = result }

// ✅ Explicitly hop to the main actor
Task { @MainActor in self.label.text = result }
```

### Codable key mismatch
```swift
// ❌ JSON key "user_name" won't decode into `userName` by default
struct User: Codable { var userName: String }

// ✅ Provide a CodingKeys enum or set keyDecodingStrategy
let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase
```
