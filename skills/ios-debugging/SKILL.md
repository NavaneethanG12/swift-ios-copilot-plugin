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

## About this skill

This skill provides a structured, repeatable debugging workflow for iOS and
macOS apps. It covers the five most common failure categories and includes
specific Xcode tool references, command-line snippets, and a companion
[debug checklist](./debug-checklist.md) for quick failure classification.

**When to invoke:**
- An app is crashing in development, TestFlight, or production.
- Auto Layout constraint warnings are filling the console.
- A network request is failing or returning unexpected data.
- Memory usage grows unboundedly during a session.
- An Xcode build is failing with compiler, linker, or signing errors.

**What this skill does NOT do:**
- It does not access your Xcode project or run commands automatically.
- It does not symbolicate crash logs for you — it explains how to do so.
- It focuses on native iOS/macOS development (UIKit, SwiftUI, AppKit); it
  does not cover React Native, Flutter, or other cross-platform stacks.

**Companion file:** [debug-checklist.md](./debug-checklist.md) — use this
first to quickly classify which section of the guide applies.

**Key Xcode tools referenced in this guide:**
| Tool | How to open |
|---|---|
| View Debugger | Debug menu → View Debugging → Capture View Hierarchy, or ⌘⌥D |
| Memory Graph Debugger | Debug bar → Memory Graph button (⌥⌘M) |
| Instruments | Xcode menu → Open Developer Tool → Instruments |
| Address Sanitizer | Scheme editor → Diagnostics → Address Sanitizer |
| Zombie Objects | Scheme editor → Diagnostics → Zombie Objects |
| Accessibility Inspector | Xcode menu → Open Developer Tool → Accessibility Inspector |

---

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

## Step 3 — Apply the fix and verify

1. Make the minimal change to fix the root cause (not the symptom).
2. Re-run the failing scenario.
3. Run unit tests: `⌘U`.
4. Check for regressions with Instruments if the fix touched performance paths.

---

## Useful debugging commands — quick reference

```bash
# Symbolicate a crash log on the command line
xcrun atos -arch arm64 -o path/to/App.app.dSYM/Contents/Resources/DWARF/App \
           -l 0x100000000 0x00000001000abc12

# Print entitlements embedded in an app binary
codesign -d --entitlements - path/to/App.app

# List frameworks and libraries linked into a binary
otool -L path/to/App.app/App

# Check which provisioning profile is embedded
security cms -D -i path/to/App.app/embedded.mobileprovision | \
  plutil -convert xml1 - -o -

# Dump the Info.plist of a built app
plutil -p path/to/App.app/Info.plist

# Tail the device console (requires Xcode command-line tools)
xcrun simctl spawn booted log stream --predicate 'process == "YourApp"'
```

## Further reading

- [Understanding and Analyzing Application Crash Reports (Apple)](https://developer.apple.com/documentation/xcode/understanding-the-exception-types-in-a-crash-report)
- [Diagnosing Memory, Thread, and Crash Issues Early (Apple)](https://developer.apple.com/documentation/xcode/diagnosing-memory-thread-and-crash-issues-early)
- [Viewing the Memory Graph (Apple)](https://developer.apple.com/documentation/xcode/gathering-information-about-memory-use)
- [WWDC — Detect and diagnose memory issues](https://developer.apple.com/videos/play/wwdc2021/10180/)
