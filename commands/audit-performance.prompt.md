---
description: "Audit the project for performance issues — launch time, scroll, memory, app size"
agent: app-builder
---

Perform a performance audit on this project.

Load the **performance-optimization** skill. Check against these budgets:
- Cold launch: < 400ms to first frame
- Warm launch: < 200ms
- Scroll hitch rate: < 5ms/s
- Frame render: < 16.67ms (60fps)
- Memory (typical): < 150MB
- App download: < 200MB

Scan for:
1. **Launch time** — blocking work in `didFinishLaunching` / `@main` App init, heavy `+load` / initializers, excessive framework count
2. **Scroll performance** — VStack instead of LazyVStack for large lists, full-res images in cells, missing cell reuse, heavy cell layouts
3. **Memory** — large image allocations, unbounded caches, view controller leaks
4. **App size** — unused assets, unoptimized images, unnecessary embedded frameworks
5. **CPU hotspots** — synchronous work on main thread, redundant computations, inefficient algorithms
6. **Energy** — excessive location/network/timer usage in background

Produce a **Performance Audit Report** with:
- Category (Launch / Scroll / Memory / Size / CPU / Energy)
- Severity (Critical / Warning / Info)
- File path and line range
- Description
- Recommended fix

${input:scope:Scope — specific files/modules to audit, or "all" for full project}
