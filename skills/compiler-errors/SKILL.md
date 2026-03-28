---
name: compiler-errors
description: >
  Diagnose and fix Swift/Xcode compiler errors. Covers the full resolution
  flow: run xcodebuild to capture errors, match against known solutions,
  escalate to web search if skills are insufficient, then apply fixes.
argument-hint: "[error message or 'build my project and fix errors']"
user-invocable: true
---

# Compiler Error Resolution

## Resolution Flow (MANDATORY — follow in order)

When the user reports compiler errors, or you need to fix build failures:

### Step 1 — Capture Errors (ALWAYS build first)
Get the actual compiler errors. You MUST actively capture them — do not wait for
the user to paste them.

**ALWAYS run the build script first.** This is mandatory every time.

The build error capture script is included in this skill directory:
[xcode-build-errors.sh](./xcode-build-errors.sh)

Execute this script in the terminal using `bash`. Pass the project directory as
the first argument if it differs from cwd, and the scheme as the second argument
if known. The script auto-detects the workspace/project and scheme.

The script outputs structured errors: file path, line, column, message,
plus linker errors, module errors, warnings, and a summary count.

**Fallback** (only if the script fails or cannot be found):
1. Use VS Code diagnostics — error-checking tool with no file paths (scans all).
2. Run xcodebuild directly:
   ```bash
   xcodebuild -list 2>/dev/null | head -20
   xcodebuild -scheme "<Scheme>" -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E ':\d+:\d+: (error|warning):|error: no such module|Undefined symbol|linker command failed'
   ```

If the user already pasted error messages, STILL run the script — there may be
additional errors the user didn't see.

**CRITICAL**: Do NOT skip this step. Do NOT go straight to fixing without
capturing the full error list first.

### Step 2 — Classify Each Error
For each error, classify it into one of these categories:

| Category | Signals | Primary skill to check |
|---|---|---|
| **Import / Module** | `No such module`, `Cannot find 'X' in scope`, `Cannot find type 'X'` | R1 (imports table in app-builder) |
| **Type Conformance** | `does not conform to protocol`, `missing required conformance` | R2 (conformances in app-builder) |
| **Navigation Wiring** | `Cannot find 'XView' in scope`, missing destination | R3 (navigation in app-builder) |
| **Data Flow** | `Cannot convert value`, `Binding<X>`, `@State` init errors | R4 + swiftui-development skill |
| **Concurrency** | `@MainActor`, `Sendable`, `actor-isolated`, `async` | swift-concurrency skill |
| **Memory / Closures** | `explicit use of self`, `escaping closure captures mutating self` | R8, R9 (closure rules in app-builder) |
| **SwiftData** | `@Model`, `@Query`, `ModelContainer` errors | data-persistence skill |
| **Linker** | `Undefined symbol`, `linker command failed`, `ld:` | Target membership / SPM config |
| **Signing / Config** | `Signing certificate`, `provisioning`, `entitlements` | ci-cd skill |
| **Third-party** | Errors in external library code, unknown API | Web search needed |
| **Unknown** | Cannot classify from known patterns | Web search needed |

### Step 3 — Resolve from Skills (Local Knowledge)
For each classified error, check the **known solutions table below** and the
relevant skill. Apply the fix directly.

### Step 4 — Escalate to Web Search (if skills insufficient)
If an error does NOT match any known pattern, or the known fix doesn't resolve it:

1. **Search the web** for the EXACT error message (in quotes).
2. Prioritize these sources:
   - **Apple Developer Documentation** (developer.apple.com)
   - **Swift Forums** (forums.swift.org)
   - **Stack Overflow** — Swift/iOS tagged answers with high votes
   - **Swift Evolution proposals** — for new language features
   - **GitHub Issues** — for third-party library errors
3. Extract the solution: what change is needed, where, and why.
4. **Verify the solution makes sense** before applying — don't blindly copy.
5. If the web search yields no useful result, ask the user for more context.

### Step 5 — Apply Fixes
1. Apply fixes **one error at a time**, starting with the most fundamental
   (import/module errors first, then type errors, then logic errors).
2. After each fix, re-read the file and check for new/cascading errors.
3. After all fixes applied, **re-run Step 1** to verify the build succeeds.
4. If new errors appear, repeat from Step 2.
5. Maximum 3 fix-verify cycles. If still failing after 3 cycles, report
   remaining errors to the user with your analysis.

---

## Known Swift Compiler Errors & Solutions

### Import & Module Errors

| Error Message | Cause | Fix |
|---|---|---|
| `No such module 'X'` | SPM/CocoaPods dependency missing, or module not built | Re-resolve packages: `File > Packages > Resolve`. Check `Package.swift` for dependency. Check target has the dependency in "Frameworks, Libraries" |
| `Cannot find 'X' in scope` | Missing import, typo, or file not in target | Add correct `import` statement. Check file is in the correct target (File Inspector > Target Membership) |
| `Cannot find type 'X' in scope` | Same as above but for types | Same fix. Also check: is the type defined in a different module? Add `import ModuleName` |
| `Missing required module 'X'` | Transitive dependency not resolved | Clean build folder (⇧⌘K), re-resolve packages |
| `Module 'X' was not compiled with library evolution support` | Binary compatibility issue | Ensure the library supports your Swift version. Update the dependency |

### Type & Conformance Errors

| Error Message | Cause | Fix |
|---|---|---|
| `Type 'X' does not conform to protocol 'Y'` | Missing required method/property | Implement all required members. Use Xcode's "Fix" button or read the protocol definition |
| `Type 'X' does not conform to 'Decodable'` | Non-Codable property or missing keys | Ensure all stored properties are Codable. Add `CodingKeys` enum if names differ from JSON |
| `Type 'X' does not conform to 'Hashable'` | Used in `NavigationStack`/`Set`/`Dictionary` key | Add `: Hashable`. For classes, implement `hash(into:)` and `==` |
| `Type 'X' does not conform to 'Identifiable'` | Used in `ForEach`/`List` without `id:` | Add `: Identifiable` and an `id` property, OR use `ForEach(items, id: \.someProperty)` |
| `Initializer requires that 'X' conform to 'Y'` | Generic constraint not satisfied | Add the conformance to your type, or use a different initializer |

### SwiftUI & View Errors

| Error Message | Cause | Fix |
|---|---|---|
| `Cannot convert value of type 'X' to expected argument type 'Binding<X>'` | Passing value where Binding expected | Use `$property` for @State/@Binding, or `Binding(get:set:)` |
| `Referencing initializer 'init(wrappedValue:)' requires wrapper 'State'` | Wrong @State initialization in init | Use `_propertyName = State(initialValue: value)` |
| `Generic parameter 'Content' could not be inferred` | ViewBuilder can't determine type | Simplify the view body, add `@ViewBuilder`, or use `Group {}` |
| `Immutable value 'self' may only appear on left side` | Mutating struct property in wrong context | Use `@State` for local mutation, `@Binding` for parent-controlled |
| `The compiler is unable to type-check this expression` | Body too complex | Break into sub-views or extracted computed properties |
| `Result of 'X' initializer is unused` | View not returned from body | Ensure view is the return value, not a side-effect statement |

### Closure & Self Errors

| Error Message | Cause | Fix |
|---|---|---|
| `Reference to property 'X' in closure requires explicit use of 'self'` | Escaping closure in class without `self.` | Add `[weak self]` + `guard let self` + `self.property` |
| `Escaping closure captures mutating 'self' parameter` | Struct method has escaping closure capturing self | Refactor to class-based ViewModel, or restructure to avoid escaping |
| `Call to main actor-isolated instance method 'X' in a synchronous nonisolated context` | Threading violation | Add `@MainActor` to the method/class, or wrap in `MainActor.run {}` |
| `Cannot pass immutable value as inout argument` | Trying to pass `let` as `&mutableParam` | Change to `var`, or use `@State`/`@Binding` |

### Concurrency Errors

| Error Message | Cause | Fix |
|---|---|---|
| `Expression is 'async' but is not marked with 'await'` | Missing await | Add `await` before the async call |
| `'async' call in a function that does not support concurrency` | Async call in sync context | Wrap in `Task {}`, or make the function `async` |
| `Sending 'X' risks causing data races` | Non-Sendable type crossing isolation | Make type `Sendable`, use `@unchecked Sendable`, or restructure |
| `Actor-isolated property 'X' can not be referenced from non-isolated context` | Accessing actor property directly | Use `await actor.property` or make the access point `nonisolated` |
| `Task-isolated value of type 'X' passed as a strongly transferred parameter` | Swift 6 strict concurrency | Mark type `Sendable` or use `sending` parameter |

### SwiftData Errors

| Error Message | Cause | Fix |
|---|---|---|
| `@Model requires class type` | @Model on struct | Change to `class` with `@Model` |
| `Cannot find 'ModelContainer' in scope` | Missing import | Add `import SwiftData` |
| `'@Query' property must be declared inside a SwiftUI struct` | @Query in ViewModel | Move @Query to the View, or pass the modelContext to the ViewModel |
| `Persistent model requires stored properties` | Computed property confusion | Ensure @Model class has stored (not computed) properties for persistence |

### Linker Errors

| Error Message | Cause | Fix |
|---|---|---|
| `Undefined symbol: _OBJC_CLASS_$_X` | Framework not linked | Add framework in "Frameworks, Libraries" in target settings |
| `Linker command failed with exit code 1` | Various linking issues | Read the FULL error above this line — it contains the actual cause |
| `ld: framework not found X` | Framework path wrong | Check "Framework Search Paths" in Build Settings |
| `Duplicate symbol` | Same symbol in multiple files/targets | Check target membership — file may be in multiple targets |

### Build System Errors

| Error Message | Cause | Fix |
|---|---|---|
| `Command CompileSwiftSources failed` | Generic wrapper for compile errors | Read the SPECIFIC errors above this line |
| `Sandbox: rsync.samba denied` | Build phase script sandbox violation | Add paths to "Input Files" list, or disable sandbox for the script |
| `Build input file cannot be found` | File deleted but still in project | Remove reference from Xcode project navigator |
| `Multiple commands produce 'X'` | Duplicate output file | Check build phases for duplicate entries, especially "Copy Bundle Resources" |

---

## Error Resolution Priority Order

When multiple errors exist, fix them in this order (earlier fixes often
resolve later errors as cascading effects):

1. **Module/Import errors** — these block everything else
2. **Missing type definitions** — create the types that don't exist yet
3. **Protocol conformance errors** — add required conformances
4. **Type mismatch errors** — fix argument types, generics
5. **Closure/self errors** — add [weak self], explicit self
6. **Concurrency errors** — add @MainActor, await, Sendable
7. **Linker errors** — fix target membership, framework linking
8. **Warnings** — address after all errors are fixed

---

## When to Search the Web

Search the web when you encounter:
- An error message not in the tables above
- An error involving a **third-party library** (Firebase, Realm, Alamofire, etc.)
- An error related to a **new Apple API** (iOS 18+, visionOS)
- An error you've tried to fix but it keeps coming back differently
- A **deprecation warning** where you need the new replacement API
- **Xcode version-specific** build system errors

**Search strategy**:
1. Search for the EXACT error message in quotes
2. Add "Swift" or "Xcode" to narrow results
3. Add the library name if it's a third-party issue
4. Prefer results from the last 12 months for API-related errors
