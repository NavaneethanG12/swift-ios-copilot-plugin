---
name: performance-optimization
description: >
  Optimize iOS/macOS performance — launch time, scroll, memory, app size,
  Instruments profiling (Time Profiler, Allocations, Energy Log).
argument-hint: "[performance issue, profiling question, or area to optimize]"
user-invocable: true
---

# Performance Optimization

## Budgets

| Metric | Target |
|---|---|
| Cold launch | < 400ms to first frame |
| Warm launch | < 200ms |
| Scroll hitch rate | < 5ms/s |
| Frame render | < 16.67ms (60fps) |
| Memory (typical) | < 150MB |
| App download | < 200MB (cellular limit) |

---

## Launch Time

**Pre-main (dyld):** Reduce frameworks (merge/static link), eliminate `+load`/initializers, dead code stripping.

**Post-main:** No blocking work in `didFinishLaunching`. Defer non-critical init to `applicationDidBecomeActive` or `Task.detached(priority: .background)`. Show placeholder UI while loading.

---

## Scroll Performance

- **UIKit**: Register + dequeue cells. Prefetch with `UITableViewDataSourcePrefetching`.
- **SwiftUI**: Use `LazyVStack` (not `VStack`) for 50+ items. Explicit `.id(item.id)`.
- **Images**: Downsample to display size via `CGImageSourceCreateThumbnailAtIndex`. Never load full-res into cells.

---

## Instruments Workflows

| Template | Purpose | Key action |
|---|---|---|
| Time Profiler | CPU hotspots | Sort by Weight, check main thread |
| Allocations | Memory growth | Mark Generation to diff |
| Leaks | Retained objects | Check persistent allocations |
| App Launch | Startup phases | Profile cold + warm |
| Energy Log | Battery impact | Identify GPS, network, background |
| Network Link Conditioner | Poor network | Test on "3G" and "100% Loss" |

---

## App Size

| Technique | Impact |
|---|---|
| Asset Catalogs | Enables app thinning |
| On-Demand Resources | Defer large assets |
| SF Symbols vs custom icons | ~50–200KB each |
| WebP/HEIF images | 30–50% vs PNG |
| Dead Code Stripping | Build Settings = YES |
| Remove unused assets | Use Periphery |

---

## Checklist

- [ ] Cold launch < 400ms
- [ ] No sync I/O on main thread at launch
- [ ] Lists use LazyVStack / cell reuse
- [ ] Images downsampled to display size
- [ ] No retain cycles (Leaks clean)
- [ ] App download < 200MB
- [ ] Tested on oldest supported device
