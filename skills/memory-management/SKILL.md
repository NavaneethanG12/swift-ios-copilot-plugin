---
name: memory-management
description: >
  iOS/macOS memory management — ARC, retain cycles, closure captures,
  unsafe pointers, Instruments profiling, memory-access crash diagnosis.
argument-hint: "[file, class, crash log, or symptom]"
user-invocable: true
---

# Memory Management

## ⚠️ Leak-Free Code Generation Rules

When WRITING new code, always apply these rules to prevent introducing leaks.
These rules are mandatory — every class-based type must pass this checklist.

### Rule M1 — Closures stored on `self` MUST capture `[weak self]` + explicit `self.`
```swift
// ❌ COMPILER ERROR: "Reference to property in closure requires explicit use of 'self'"
class ProfileVM {
    var onUpdate: (() -> Void)?
    func setup() {
        onUpdate = { refresh() } // ERROR: implicit self in escaping closure
    }
}

// ❌ COMPILES but LEAKS: strong capture creates reference cycle
class ProfileVM {
    var onUpdate: (() -> Void)?
    func setup() {
        onUpdate = { self.refresh() } // self → closure → self (cycle!)
    }
}

// ✅ CORRECT: [weak self] + guard let self + explicit self.
class ProfileVM {
    var onUpdate: (() -> Void)?
    func setup() {
        onUpdate = { [weak self] in
            guard let self else { return }
            self.refresh()
        }
    }
}
```

**Key rule**: In ANY escaping closure inside a class, you MUST:
1. Add `[weak self]` to the capture list
2. Add `guard let self else { return }` at the top of the closure body
3. Use `self.` prefix on EVERY property and method access inside the closure

**Task {} inside class methods** also requires this pattern:
```swift
func loadData() {
    Task { [weak self] in
        guard let self else { return }
        self.isLoading = true
        self.items = try await self.repo.fetchAll()
        self.isLoading = false
    }
}
```

**Exception — SwiftUI View structs**: `.task {}`, `.onAppear {}`, `Button` actions
on a View struct do NOT need `[weak self]` because Views are value types. But
inside a ViewModel class method, always use the pattern above.

### Rule M2 — Delegates MUST be `weak`
```swift
// ❌ LEAK: owner → delegate → owner
protocol ServiceDelegate: AnyObject { func didUpdate() }
class Service { var delegate: ServiceDelegate? } // strong by default

// ✅ SAFE: weak delegate
class Service { weak var delegate: ServiceDelegate? }
```

### Rule M3 — Timers and display links MUST use weak capture
```swift
// ❌ LEAK: Timer retains target until invalidated
Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(tick), userInfo: nil, repeats: true)

// ✅ SAFE: Block-based timer with [weak self] + guard let self
timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
    guard let self else { return }
    self.tick()
}
// And invalidate in deinit:
deinit { timer?.invalidate() }
```

### Rule M4 — Combine sinks MUST use `[weak self]`
```swift
// ❌ LEAK: sink closure retains self, cancellable stored on self
cancellable = publisher.sink { self.handle($0) }

// ❌ COMPILER ERROR: implicit self in closure
cancellable = publisher.sink { value in handle(value) }

// ✅ SAFE: [weak self] + guard let self + explicit self.
cancellable = publisher.sink { [weak self] value in
    guard let self else { return }
    self.handle(value)
}
```

### Rule M5 — SwiftUI @Observable classes: no stored closures referencing `self`
```swift
// ❌ POTENTIAL LEAK: @Observable class stores closure referencing self
@Observable class VM {
    var handler: (() -> Void)?
    func setup() { handler = { self.load() } } // cycle: VM → handler → VM
}

// ✅ SAFE: use direct method calls, no stored closures
@Observable class VM {
    func load() async { /* ... */ }
    // View calls vm.load() directly via .task — no closure storage needed
}
```

### Rule M6 — Caches MUST have limits
```swift
// ❌ UNBOUNDED: grows until OOM
var imageCache: [URL: UIImage] = [:]

// ✅ BOUNDED: auto-evicts under memory pressure
let imageCache: NSCache<NSURL, UIImage> = {
    let cache = NSCache<NSURL, UIImage>()
    cache.countLimit = 100
    cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    return cache
}()
```

### Rule M7 — Large resources MUST be released when not visible
```swift
// ✅ Release on disappear
.onDisappear { vm.clearLargeData() }

// ✅ Respond to memory warnings
NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification,
    object: nil, queue: .main) { [weak self] _ in self?.imageCache.removeAllObjects() }
```

---

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

**Classic reference cycle** (from Swift.org):
```swift
// This creates a permanent cycle: self → self.closure → self
public class MemoryLeaker {
    var closure: () -> Void = { () }
    public func doSomethingThatLeaks() {
        self.closure = {
            self.doNothing() // strong capture of self
        }
    }
}
// Fix: self.closure = { [weak self] in self?.doNothing() }
```

---

## Retain Cycle Patterns

| Pattern | Problem | Fix |
|---|---|---|
| Stored closure captures `self` | `self → closure → self` | `[weak self] in self?.method()` |
| Strong delegate | `owner → delegate → owner` | `weak var delegate` |
| Timer/CADisplayLink | Timer retains target | Block API + `[weak self]` |
| Combine sink | Sink captures self | `[weak self] in self?.handle($0)` |
| Parent ↔ child VCs | Mutual strong refs | Child holds `weak` parent ref |
| NotificationCenter block observer | Observer closure retains self | `[weak self]` in closure |
| Async callback stored as property | Callback retains caller | `[weak self]` or use async/await instead |
| URLSession completion handler | Completion captures self | `[weak self]` or use async API |
| @Observable with stored closures | VM stores closure that captures self | Avoid stored closures; use direct `.task` calls |

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

| Tool | Use | Platform |
|---|---|---|
| Memory Graph Debugger (⌥⌘M) | Visual cycle detection | macOS/Xcode |
| Instruments — Leaks | Find leaked allocations | macOS/Xcode |
| Instruments — Allocations | Track growth (Mark Generation) | macOS/Xcode |
| Address Sanitizer + LeakSanitizer | Use-after-free, leaked blocks | macOS/Linux |
| Zombie Objects | Messages to deallocated objects | macOS/Xcode |
| Malloc Scribble | Fill freed with 0x55 | macOS/Xcode |
| Malloc Stack Logging | Allocation origin tracking | macOS/Xcode |
| Valgrind (Linux) | Comprehensive leak detection | Linux |
| Heaptrack (Linux) | Heap profiling with diff support | Linux |

### LeakSanitizer quick-start (from Swift.org)
```bash
# Enable Address Sanitizer with leak detection
export ASAN_OPTIONS=detect_leaks=1
swift build --sanitize=address
swift test --sanitize=address

# In Xcode: Edit Scheme → Run → Diagnostics → Address Sanitizer ✓
```

### Symbolicate LeakSanitizer output (Linux)
```bash
# Demangle Swift symbols
swift demangle $s4test12MemoryLeakerCACycfC

# Symbolicate addresses
addr2line -e .build/release/MyApp -a 0xc62ce -ipf | swift demangle
```

---

## Workspace-Wide Leak Audit

When asked to **audit a project for memory leaks**, follow this systematic scan:

### Step 1 — Grep for high-risk patterns
Search the entire project for these patterns:
```
# Closures stored on self without weak capture
grep -rn '= {[^}]*self\.' --include='*.swift' Sources/

# Strong delegates
grep -rn 'var delegate:' --include='*.swift' Sources/ | grep -v 'weak'

# Timer with target:self
grep -rn 'target: self' --include='*.swift' Sources/

# Combine sink without weak self
grep -rn '\.sink' --include='*.swift' Sources/

# Unbounded dictionaries used as caches
grep -rn 'var.*Cache.*\[.*:.*\]' --include='*.swift' Sources/

# NotificationCenter observers without weak
grep -rn 'addObserver.*forName' --include='*.swift' Sources/
```

### Step 2 — Audit each class file
For every class (not struct) in the project:
1. Check all stored closure properties → M1
2. Check all delegate properties → M2
3. Check all Timer/CADisplayLink usage → M3
4. Check all Combine subscriptions → M4
5. Check for deinit with cleanup → is it present?
6. Check cache types → M6

### Step 3 — Report findings using the output format below

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
