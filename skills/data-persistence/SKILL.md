---
name: data-persistence
description: >
  Implement data persistence — SwiftData, Core Data, UserDefaults, Keychain,
  file system, iCloud sync. Storage decision guide and patterns.
argument-hint: "[model name, persistence question, or migration issue]"
user-invocable: true
---

# Data Persistence — iOS / macOS

## Storage Decision Guide

| Data type | Storage | Notes |
|---|---|---|
| Preferences (flags, theme) | `UserDefaults` / `@AppStorage` | Simple key-value |
| Passwords, tokens | **Keychain** | Encrypted, hardware-backed |
| Structured app data | **SwiftData** (iOS 17+) | Declarative, Swift-native |
| Complex object graphs | **Core Data** | Mature ORM |
| Large files (images) | **File system** | Never store blobs in DB |
| Cache / temp | `URLCache` / `NSCache` | Auto-evicted |
| Cross-device sync | SwiftData + CloudKit | Automatic |
| Shared with extensions | **App Groups** | Shared container |

---

## SwiftData (iOS 17+)

```swift
import Foundation
import SwiftData

@Model
class Task {
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \SubTask.parent)
    var subtasks: [SubTask]

    init(title: String) {
        self.title = title; isCompleted = false; createdAt = .now; subtasks = []
    }
}

// App entry: .modelContainer(for: [Task.self])
// View query: @Query(sort: \Task.createdAt, order: .reverse) var tasks: [Task]
// Insert: modelContext.insert(Task(title: "New"))
// Delete: modelContext.delete(task)
// Filter: @Query(filter: #Predicate<Task> { !$0.isCompleted }, sort: [SortDescriptor(\.createdAt, order: .reverse)])
```

**Wiring checklist for SwiftData:**
1. Add `.modelContainer(for: [Model.self])` to the App or root view
2. Use `@Query` in the view to fetch data (not manual context queries)
3. Use `@Environment(\.modelContext)` for insert/delete operations
4. Every `@Relationship` must have `deleteRule` and `inverse`

---

## UserDefaults

`@AppStorage("key") var value = default` for SwiftUI.
`UserDefaults(suiteName: "group.com.company.app")` for App Groups.
**Never store**: passwords, tokens, API keys, or large data.

## Keychain

Use `Security` framework: `SecItemAdd` / `SecItemCopyMatching` / `SecItemDelete`.
Set `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` for availability.
Consider a wrapper struct with `save(key:data:)`, `load(key:)`, `delete(key:)`.

## File System

| Directory | Purpose | Backed up? |
|---|---|---|
| `.documentDirectory` | User content | Yes |
| `.cachesDirectory` | Re-downloadable | No |
| `.temporaryDirectory` | Temp files | No |
| App Group container | Shared with extensions | Yes |

Encode/decode with `JSONEncoder`/`JSONDecoder`, write with `.atomic`.

---

## Checklist

- [ ] Sensitive data in Keychain, not UserDefaults
- [ ] SwiftData models have `@Relationship` with delete rules
- [ ] Schema migrations planned for model changes
- [ ] Large binary data on file system, not DB
- [ ] Caches have size limits in Caches directory
- [ ] `@AppStorage` only for simple value types
