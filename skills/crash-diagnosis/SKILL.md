---
name: crash-diagnosis
description: >
  Analyse iOS/macOS crash reports — Swift runtime errors, language exceptions,
  memory access, watchdog terminations, zombie objects, symbolication.
argument-hint: "[crash log, .ips file content, or crash description]"
user-invocable: true
---

# Crash Diagnosis

## Decision Tree

```
Exception Type?
├── EXC_BREAKPOINT (SIGTRAP) → Swift runtime error → §A
├── EXC_BAD_INSTRUCTION (SIGILL) → Swift runtime error (Intel) → §A
├── EXC_CRASH (SIGABRT)
│   ├── Has "Last Exception Backtrace"? → Language exception → §B
│   ├── 0x8badf00d? → Watchdog → §C
│   └── DYLD? → Missing framework → §F
├── EXC_BAD_ACCESS (SIGSEGV / SIGBUS)
│   ├── objc_msgSend at top? → Zombie → §D
│   └── Other → Memory access → §E
├── EXC_CRASH (SIGKILL) → 0x8badf00d=Watchdog §C / Other=System kill §G
└── EXC_RESOURCE → Resource limit → §H
```

---

## §A — Swift Runtime Errors

| Pattern | Cause | Fix |
|---|---|---|
| Force-unwrap of nil | `value!` | `guard let` / `if let` |
| Index out of bounds | `array[i]` | Check bounds |
| `fatalError`/`preconditionFailure` | Explicit trap | Fix invariant |
| Forced `as!` cast | Type mismatch | Use `as?` |
| Integer overflow | Arithmetic | Overflow operators or wider type |

Frame 0 shows exact line → fix the safety check.

## §B — Language Exceptions (NSException)

| Name | Meaning | Fix |
|---|---|---|
| `NSRangeException` | Index OOB | Validate indices |
| `NSInvalidArgumentException` | Bad API argument | Check contract |
| `NSInternalInconsistencyException` | Framework invariant | Fix state |
| `NSUnknownKeyException` | Stale IB outlet | Fix storyboard |

Read `Last Exception Backtrace` → frame after `objc_exception_throw`.

## §C — Watchdog (0x8badf00d)

App unresponsive during launch/background transition. Check `WatchdogEvent` field.
**Causes**: Sync network on main thread, heavy Core Data migration, deadlock.
**Fix**: Move work off main thread, profile with Time Profiler → main thread filter.

## §D — Zombie Objects

`objc_msgSend`/`objc_retain` at frame 0 = message to deallocated object.
Enable **Zombie Objects** (Scheme → Diagnostics) → reproduce → log shows original class.
**Fix**: `unowned` → `weak`, invalidate timers in `deinit`, remove KVO observers.

## §E — Memory Access (EXC_BAD_ACCESS)

| Subtype | Meaning |
|---|---|
| `KERN_INVALID_ADDRESS` | NULL deref, dangling pointer, use-after-free |
| `KERN_PROTECTION_FAILURE` | Stack overflow (check VM Region = STACK GUARD) |
| Pointer auth failure | Memory corruption |

`pc` ≠ exception address = bad pointer deref. `pc` = address = bad function pointer.
**Tools**: Address Sanitizer, Malloc Scribble (0x55), Guard Malloc.

## §F — Missing Framework

`DYLD, dependent dylib not found` → Add to **Embed Frameworks** build phase. Verify `@rpath`.

## §G — System Kills

| Code | Meaning |
|---|---|
| `0xdead10cc` | Held file lock while suspended |
| `0xc51bad01` | CPU too high while backgrounded |
| `JETSAM` | Exceeded memory limit (OOM) |

## §H — Resource Limit

`EXC_RESOURCE` / `WAKEUPS` → Reduce timer frequency, coalesce wake-ups.

---

## Symbolication

```bash
xcrun atos -arch arm64 -o App.dSYM/Contents/Resources/DWARF/App -l 0x100000000 0x1000abc12
dwarfdump --uuid App.dSYM  # verify UUID match
```

---

## Output format

```
Crash Type: [§A–§H]
Exception: <type and subtype>
Root Cause: <description>
Evidence: <crash report fields>
Remediation: 1. <fix> 2. <prevention> 3. <verification tool>
Confidence: High / Medium / Low
```
