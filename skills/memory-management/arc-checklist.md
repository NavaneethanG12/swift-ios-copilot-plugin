# ARC & Memory — Quick Audit Checklist

Use this checklist to quickly audit a Swift file for memory management issues.

## Retain-cycle risks
- [ ] All stored closures use `[weak self]` or `[unowned self]` where `self` owns the closure.
- [ ] All delegate properties are declared `weak`.
- [ ] `Timer`, `CADisplayLink`, `DispatchSourceTimer` targets use weak capture.
- [ ] Combine `sink` / `assign` closures use `[weak self]`.
- [ ] Parent ↔ child object pairs do not hold mutual strong references.
- [ ] `NotificationCenter.addObserver` block API uses `[weak self]`.
- [ ] URLSession completion handlers use `[weak self]`.
- [ ] Closures passed to `DispatchQueue.async` or `Task {}` that are stored long-term use `[weak self]`.
- [ ] No `@Observable` class stores a closure property that captures `self`.

## Deallocation verification
- [ ] Classes with significant resources implement `deinit` with cleanup logic.
- [ ] `deinit` is confirmed to execute (add a temporary print/log to verify).
- [ ] `invalidate()` is called on timers before the owning object is deallocated.
- [ ] `cancel()` is called on Combine subscriptions / URLSession tasks.
- [ ] NotificationCenter observers removed (or using token-based API that auto-removes).

## Unsafe pointer audit
- [ ] No `UnsafePointer` escapes the closure it was provided in.
- [ ] Every `allocate(capacity:)` has a corresponding `deallocate()`.
- [ ] `bindMemory(to:capacity:)` is used before `assumingMemoryBound(to:)`.
- [ ] `Unmanaged.passRetained` is balanced with `takeRetainedValue`.
- [ ] `Unmanaged.passUnretained` callers ensure the object's lifetime.

## Objective-C bridging
- [ ] `__bridge` casts do not transfer ownership unexpectedly.
- [ ] `CFRelease` / `CFRetain` calls are balanced for CF types.
- [ ] `autoreleasepool` blocks wrap tight loops that create many temporary ObjC objects.

## Growth prevention
- [ ] Image caches have size limits and eviction (e.g. `NSCache`, `countLimit`).
- [ ] Collections that accumulate items have a bounded size or cleanup policy.
- [ ] Large data buffers are released when no longer visible (e.g. on `viewDidDisappear`).
- [ ] Image loading uses downsampling to display size (not full-resolution UIImage).
- [ ] Memory warning notifications are observed and caches cleared in response.

## Crash-proofing
- [ ] No force-unwrap of `weak` references outside a `guard let` / `if let`.
- [ ] `unowned` is used only when lifetime guarantee is provably correct.
- [ ] `withExtendedLifetime` wraps sequences where ARC could optimise away a needed object.

---

## Project-Wide Audit Quick Commands

Run these from the project root to find all high-risk patterns at once:

```bash
# Find all classes (audit targets — structs don't have reference cycles)
grep -rn '^class \|^final class \|^public class \|^internal class ' --include='*.swift' Sources/

# Find stored closures that may capture self strongly
grep -rn 'var.*: .*(\(.*\) -> \|(() ->)' --include='*.swift' Sources/

# Find strong delegates
grep -rn 'var delegate' --include='*.swift' Sources/ | grep -v 'weak'

# Find Timer target:self (old retain-target API)
grep -rn 'scheduledTimer.*target.*self' --include='*.swift' Sources/

# Find Combine sinks without weak self
grep -rn '\.sink' --include='*.swift' Sources/ | grep -v 'weak self'

# Find NotificationCenter without weak self
grep -rn 'addObserver.*forName' --include='*.swift' Sources/ | grep -v 'weak self'

# Find unbounded caches (Dictionary used as cache)
grep -rn 'var.*[Cc]ache.*:.*\[' --include='*.swift' Sources/

# Verify deinit exists for classes with resources
for f in $(grep -rln '^class \|^final class ' --include='*.swift' Sources/); do
    if ! grep -q 'deinit' "$f"; then
        echo "MISSING deinit: $f"
    fi
done
```

### Xcode / Build-time leak detection
```bash
# Build with Address Sanitizer (catches use-after-free + leaks)
xcodebuild -scheme <SchemaName> -destination 'platform=iOS Simulator,name=iPhone 16' \
    -enableAddressSanitizer YES build-for-testing

# SPM projects with LeakSanitizer
export ASAN_OPTIONS=detect_leaks=1
swift build --sanitize=address
swift test --sanitize=address

# Xcode GUI path:
# Edit Scheme → Run → Diagnostics → ✓ Address Sanitizer
# Edit Scheme → Run → Diagnostics → ✓ Malloc Stack Logging (Live Allocations Only)
```

### Instruments templates for memory profiling
| Template | Detects | When to use |
|---|---|---|
| **Leaks** | Reference cycles, leaked allocations | After UI interactions (navigate, scroll) |
| **Allocations** | Heap growth, transient allocs | Mark Generation before/after actions |
| **VM Tracker** | Virtual memory, dirty pages | High-memory apps, image-heavy |
| **Memory Graph** (⌥⌘M) | Visual reference cycles | When deinit doesn't fire |
