---
name: ios-debugging
description: >
  Step-by-step guide for diagnosing and fixing iOS/macOS runtime issues —
  crashes, UI glitches, networking failures, memory leaks, and Xcode build
  errors. Use this when asked to debug an iOS app, investigate a crash report,
  trace a memory leak, or fix a failing Xcode build.
argument-hint: "[error message, crash log, or symptom description]"
user-invocable: true
---

# iOS Debugging Guide

Structured debugging workflow. Use [debug-checklist.md](./debug-checklist.md) to classify, then follow the relevant section.

Follow this structured process to diagnose and resolve iOS/macOS issues.

## Step 1 — Reproduce the issue

1. Identify the exact steps to trigger the problem.
2. Note the iOS/macOS version, device model, and Xcode version.
3. Confirm whether it is a simulator-only or device-only problem.
4. Check if the issue is deterministic or intermittent.

## Step 2 — Classify the failure

Use the [debug checklist](./debug-checklist.md) to classify the failure type,
then jump to the relevant section below.

---

## Crashes & exceptions

- Read the crash log: identify the **exception type**, **signal**, and the
  **top frame** of the crashing thread.
- Common signals:
  - `SIGSEGV` / `SIGBUS` → bad memory access, often a dangling pointer.
  - `EXC_BREAKPOINT` → assertion, precondition failure, or Swift runtime trap.
  - `EXC_BAD_ACCESS` → accessing a deallocated object (check retain cycles / weak refs).
- Enable **Zombie Objects** in the scheme diagnostics to catch use-after-free.
- Run with **Address Sanitizer** enabled to surface memory errors at runtime.
- Symbolicate the crash log: `xcrun atos -arch arm64 -o <dSYM> -l <load-addr> <addr>`.

## UI / layout issues

- Use **Xcode View Debugger** (⌘⌥D) to inspect the view hierarchy.
- Check Auto Layout constraint conflicts in the console (`UIViewAlertForUnsatisfiableConstraints`).
- Run the **Accessibility Inspector** to confirm hit areas and traits.
- Verify `setNeedsLayout` / `layoutIfNeeded` are called on the main thread.
- For SwiftUI: use `.border()` and `.background(Color.red.opacity(0.2))` to
  visualise frame sizing.

## Networking failures

- Log URLSession tasks with `URLSession.shared.configuration.protocolClasses`
  or use Charles/Proxyman.
- Confirm `NSAppTransportSecurity` exceptions if connecting to non-HTTPS endpoints.
- Check `URLError` codes: `.notConnectedToInternet`, `.timedOut`, `.cannotFindHost`.
- Verify JSON decoding: wrap `JSONDecoder().decode` in `do/catch` and print the
  raw `Data` as a string (`String(data:encoding:)`) on failure.

## Memory leaks

1. Run **Instruments → Leaks** or **Allocations** template.
2. In Leaks, look for repeated allocations of the same class that are never freed.
3. In the Memory Graph Debugger (⌥⌘M), look for cycles: the graph will show
   mutual strong references between objects.
4. Common causes:
   - Delegate properties declared `strong` instead of `weak`.
   - Closures capturing `self` strongly inside long-lived objects.
   - `Timer` or `CADisplayLink` retaining the target; use `[weak self]`.

## Xcode build errors

| Error pattern | Likely cause | Fix |
|---|---|---|
| `No such module 'X'` | Missing SPM/CocoaPods dependency | Re-resolve packages or `pod install` |
| `Command CompileSwiftSources failed` | Type mismatch or syntax error | Read the primary error above the generic one |
| `Signing certificate … not found` | Keychain missing cert | Download from Apple Developer portal |
| `Undefined symbol` | Linking failure | Check target membership of the file |
| `Sandbox: rsync … denied` | Build phase script sandbox | Add to "Input Files" or disable sandbox |

For comprehensive compiler error diagnosis and resolution, see the
**compiler-errors** skill — it has 50+ known error patterns with fixes and a
full resolution flow including web search escalation.

## Step 3 — Apply the fix and verify

1. Make the minimal change to fix the root cause (not the symptom).
2. Re-run the failing scenario.
3. Run unit tests: `⌘U`.
4. Check for regressions with Instruments if the fix touched performance paths.

---

## Key debugging commands

- `xcrun atos -arch arm64 -o <dSYM> -l <load-addr> <addr>` — symbolicate
- `codesign -d --entitlements - App.app` — check entitlements
- `otool -L App.app/App` — list linked frameworks
- `plutil -p App.app/Info.plist` — dump Info.plist
- `xcrun simctl spawn booted log stream --predicate 'process == "YourApp"'` — device console

Cross-reference: `/crash-diagnosis` for crash reports, watchdog kills, system terminations. `/memory-management` for leaks and ARC. `/swift-concurrency` for data races and actor issues.
