# ARC & Memory — Quick Audit Checklist

Use this checklist to quickly audit a Swift file for memory management issues.

## Retain-cycle risks
- [ ] All stored closures use `[weak self]` or `[unowned self]` where `self` owns the closure.
- [ ] All delegate properties are declared `weak`.
- [ ] `Timer`, `CADisplayLink`, `DispatchSourceTimer` targets use weak capture.
- [ ] Combine `sink` / `assign` closures use `[weak self]`.
- [ ] Parent ↔ child object pairs do not hold mutual strong references.
- [ ] `NotificationCenter.addObserver` block API uses `[weak self]`.

## Deallocation verification
- [ ] Classes with significant resources implement `deinit` with cleanup logic.
- [ ] `deinit` is confirmed to execute (add a temporary print/log to verify).
- [ ] `invalidate()` is called on timers before the owning object is deallocated.
- [ ] `cancel()` is called on Combine subscriptions / URLSession tasks.

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

## Crash-proofing
- [ ] No force-unwrap of `weak` references outside a `guard let` / `if let`.
- [ ] `unowned` is used only when lifetime guarantee is provably correct.
- [ ] `withExtendedLifetime` wraps sequences where ARC could optimise away a needed object.
