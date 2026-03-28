---
name: data-persistence
description: >
  Implement data persistence — SwiftData, Core Data, database architecture,
  relationships, migrations, UserDefaults, Keychain, file system, iCloud sync.
argument-hint: "[model name, persistence question, relationship design, or migration issue]"
user-invocable: true
---

# Data Persistence & Database Architecture — iOS / macOS

## Storage Decision Guide

| Data type | Storage | Notes |
|---|---|---|
| Preferences (flags, theme) | `UserDefaults` / `@AppStorage` | Simple key-value |
| Passwords, tokens | **Keychain** | Encrypted, hardware-backed |
| Structured app data (iOS 17+) | **SwiftData** | Declarative, Swift-native |
| Complex object graphs / legacy | **Core Data** | Mature ORM, full control |
| Large files (images, video) | **File system** | Never store blobs in DB |
| Cache / temp | `URLCache` / `NSCache` | Auto-evicted |
| Cross-device sync | SwiftData/CoreData + CloudKit | Automatic mirroring |
| Shared with extensions | **App Groups** | Shared container |

### When to use SwiftData vs Core Data

| Criteria | SwiftData | Core Data |
|---|---|---|
| Min deployment | iOS 17+ | iOS 3+ |
| Model definition | `@Model` macro on classes | `.xcdatamodeld` visual editor |
| Query syntax | `@Query`, `#Predicate` | `NSFetchRequest`, `NSPredicate` |
| Concurrency | `@ModelActor` (native Swift actor) | `performBackgroundTask`, child contexts |
| Migration | `SchemaMigrationPlan` + `VersionedSchema` | Lightweight / Staged / Manual |
| Custom stores | `DataStore` protocol (iOS 18+) | Limited (custom `NSAtomicStore`) |
| Use when | New projects, iOS 17+ target | Legacy codebases, pre-iOS 17, advanced CD features |

---

## SwiftData (iOS 17+)

### Basic Model & Wiring

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

**Wiring checklist:**
1. Add `.modelContainer(for: [Model.self])` to the App or root view
2. Use `@Query` in the view to fetch data (not manual context queries)
3. Use `@Environment(\.modelContext)` for insert/delete operations
4. Every `@Relationship` must have `deleteRule` and `inverse`

### @Attribute Options

```swift
@Model class User {
    @Attribute(.unique) var email: String                    // Enforces uniqueness (upsert on conflict)
    @Attribute(.externalStorage) var avatarData: Data?       // Large data stored outside SQLite
    @Attribute(.spotlight) var name: String                  // Indexed for Spotlight search
    @Attribute(.preserveValueOnDeletion) var externalId: String // Retained in history tombstone after delete
    @Attribute(.encrypt) var sensitiveNote: String?          // Encrypted at rest
    @Transient var cachedDisplayName: String?                // Not persisted
}
```

### @Unique (Compound Uniqueness — iOS 18+)

```swift
@Model
@Unique([\.firstName, \.lastName])    // Compound unique constraint
class Contact {
    var firstName: String
    var lastName: String
    var phone: String
    init(firstName: String, lastName: String, phone: String) {
        self.firstName = firstName; self.lastName = lastName; self.phone = phone
    }
}
```

### #Index (Performance)

```swift
@Model
@Index([\.email])                           // Single-column index
@Index([\.lastName, \.firstName])           // Compound index for sorted queries
class Customer {
    var email: String
    var firstName: String
    var lastName: String
    // ...
}
```

**When to index:** Columns used in `#Predicate` filters, sort descriptors, or join-like relationship traversals. Don't over-index — each index costs write performance.

### ModelConfiguration

```swift
// Default (on-disk, auto-save)
let config = ModelConfiguration()

// In-memory (previews, tests)
let config = ModelConfiguration(isStoredInMemoryOnly: true)

// Custom file location
let config = ModelConfiguration("MyStore", url: storeURL)

// Read-only store
let config = ModelConfiguration(allowsSave: false)

// App Group shared store (with extensions/widgets)
let config = ModelConfiguration(groupContainer: .identifier("group.com.company.app"))

// CloudKit sync
let config = ModelConfiguration(cloudKitDatabase: .automatic)

// Multiple stores — split models across different databases
let userConfig = ModelConfiguration(for: User.self)
let analyticsConfig = ModelConfiguration("Analytics", for: Event.self, url: analyticsURL)
let container = try ModelContainer(for: Schema([User.self, Event.self]), configurations: [userConfig, analyticsConfig])
```

### FetchDescriptor (Programmatic Queries)

```swift
let context = ModelContext(container)

// Basic fetch with predicate + sort
var descriptor = FetchDescriptor<Task>(
    predicate: #Predicate { !$0.isCompleted },
    sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
)

// Pagination
descriptor.fetchLimit = 20
descriptor.fetchOffset = 40

// Count without loading objects
let count = try context.fetchCount(descriptor)

// Fetch identifiers only (lightweight)
let ids = try context.fetchIdentifiers(descriptor)

let tasks = try context.fetch(descriptor)
```

### ModelActor (Background Processing)

```swift
import SwiftData

@ModelActor
actor DataImporter {
    // modelContainer and modelContext are auto-synthesized

    func importRecords(_ records: [RecordDTO]) throws {
        for record in records {
            let model = Item(name: record.name, value: record.value)
            modelContext.insert(model)
        }
        try modelContext.save()
    }

    func fetchItem(id: PersistentIdentifier) -> Item? {
        self[id, as: Item.self]     // Safe cross-actor access by ID
    }
}

// Usage from MainActor:
let importer = DataImporter(modelContainer: container)
try await importer.importRecords(dtos)

// Pass PersistentIdentifier (Sendable) across actor boundaries — NEVER pass @Model objects directly
```

**Concurrency rules:**
- `@Model` objects are NOT `Sendable` — pass `PersistentIdentifier` between actors
- Use `self[id, as: Type.self]` inside `@ModelActor` to resolve identifiers
- Each `@ModelActor` gets its own `ModelContext` — no shared mutable state

---

## Database Architecture & Relationships

### Relationship Types

```
┌──────────────────────────────────────────────────────────────────┐
│  RELATIONSHIP PATTERNS                                           │
├──────────────┬───────────────────────────────────────────────────┤
│ One-to-One   │ User ──── Profile                                │
│ One-to-Many  │ Category ───< Item                               │
│ Many-to-Many │ Student >──< Course  (via intermediate or array) │
│ Self-ref     │ Employee ──── Employee (manager)                  │
│ Enum/Static  │ Model ──── Codable enum (no relationship macro)  │
└──────────────┴───────────────────────────────────────────────────┘
```

### SwiftData Relationships

```swift
// ═══════════ ONE-TO-ONE ═══════════
@Model class User {
    var name: String
    @Relationship(deleteRule: .cascade, inverse: \Profile.user)
    var profile: Profile?
    init(name: String) { self.name = name }
}
@Model class Profile {
    var bio: String
    var user: User?
    init(bio: String) { self.bio = bio }
}

// ═══════════ ONE-TO-MANY ═══════════
@Model class Category {
    var name: String
    @Relationship(deleteRule: .cascade, inverse: \Item.category)
    var items: [Item]
    init(name: String) { self.name = name; items = [] }
}
@Model class Item {
    var title: String
    var category: Category?
    init(title: String) { self.title = title }
}

// ═══════════ MANY-TO-MANY ═══════════
@Model class Student {
    var name: String
    @Relationship(inverse: \Course.students)
    var courses: [Course]
    init(name: String) { self.name = name; courses = [] }
}
@Model class Course {
    var title: String
    var students: [Student]
    init(title: String) { self.title = title; students = [] }
}

// ═══════════ SELF-REFERENTIAL ═══════════
@Model class Employee {
    var name: String
    @Relationship(inverse: \Employee.reports)
    var manager: Employee?
    var reports: [Employee]
    init(name: String) { self.name = name; reports = [] }
}

// ═══════════ ENUM / STATIC DATA ═══════════
// Use Codable enums — NO @Relationship needed
@Model class Animal {
    var name: String
    var diet: Diet        // Stored as raw value
    enum Diet: String, Codable, CaseIterable {
        case herbivore, carnivore, omnivore
    }
    init(name: String, diet: Diet) { self.name = name; self.diet = diet }
}
```

### Delete Rules Reference

| Rule | Behavior | Use when |
|---|---|---|
| `.cascade` | Deleting parent deletes all children | Parent owns children exclusively (e.g., Order → LineItems) |
| `.nullify` (default) | Sets child's reference to `nil` | Children can exist independently (e.g., Category → Items) |
| `.deny` | Prevents deletion if children exist | Referential integrity required (e.g., Department with employees) |
| `.noAction` | Does nothing — leaves orphans | Manual cleanup, rare |

**Rule of thumb:** Use `.cascade` for composition ("has-a"), `.nullify` for association ("belongs-to").

### Relationship Constraints

```swift
@Relationship(deleteRule: .cascade,
              minimumModelCount: 1,      // Must have at least 1 child
              maximumModelCount: 10,     // Cannot exceed 10 children
              inverse: \Item.category)
var items: [Item]
```

### Object Graph Design Rules

1. **Identify root aggregates** — top-level entities the UI navigates from (e.g., `Project`, `User`)
2. **Always set `inverse`** — SwiftData infers if omitted, but explicit is safer and clearer
3. **Choose delete rules deliberately** — think "what happens when I delete this?"
4. **Avoid deep nesting** — 3+ levels of `.cascade` chains are hard to debug
5. **Use `@Attribute(.externalStorage)` for blobs** — images, PDFs, etc.
6. **Enums for fixed categories** — don't create a model class for data that never changes
7. **`Identifiable` + `Hashable`** — needed for `List`, `ForEach`, `NavigationDestination`
8. **One `ModelContainer` per app** — use `ModelConfiguration` to split models across stores

---

## Core Data (Full Reference)

### Stack Setup

```swift
import CoreData

class CoreDataStack {
    static let shared = CoreDataStack()

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "AppModel") // matches .xcdatamodeld file name
        container.loadPersistentStores { description, error in
            if let error { fatalError("Core Data load failed: \(error)") }
        }
        // Automatic merge from background contexts
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()

    var viewContext: NSManagedObjectContext { persistentContainer.viewContext }

    func newBackgroundContext() -> NSManagedObjectContext {
        persistentContainer.newBackgroundContext()
    }

    func save(context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        do { try context.save() }
        catch { assertionFailure("Core Data save error: \(error)") }
    }
}
```

### Core Data Relationships (.xcdatamodeld)

Define in the visual editor:

| Relationship | Source | Destination | Type | Inverse | Delete Rule |
|---|---|---|---|---|---|
| One-to-One | `User` → `profile` | `Profile` | To One | `user` | Cascade |
| One-to-Many | `Category` → `items` | `Item` | To Many | `category` | Cascade |
| Many-to-Many | `Student` → `courses` | `Course` | To Many | `students` | Nullify |

**Always set inverses in the model editor.** Core Data uses inverses to maintain referential integrity.

### NSManagedObject Subclass

```swift
// Generated or manual — prefer "Codegen: Class Definition" in model editor
@objc(TaskEntity)
public class TaskEntity: NSManagedObject {
    @NSManaged public var title: String
    @NSManaged public var isCompleted: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var category: CategoryEntity?   // To-One
    @NSManaged public var tags: NSSet?                 // To-Many (unordered)
}

// Type-safe accessors for To-Many
extension TaskEntity {
    @objc(addTagsObject:) @NSManaged func addToTags(_ value: TagEntity)
    @objc(removeTagsObject:) @NSManaged func removeFromTags(_ value: TagEntity)
    @objc(addTags:) @NSManaged func addToTags(_ values: NSSet)
    @objc(removeTags:) @NSManaged func removeFromTags(_ values: NSSet)
}
```

### Fetch Requests

```swift
// Basic
let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
request.predicate = NSPredicate(format: "isCompleted == %@", NSNumber(value: false))
request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.createdAt, ascending: false)]
request.fetchLimit = 20
request.fetchBatchSize = 20  // Memory-efficient batch loading

let results = try context.fetch(request)

// Count only (no objects loaded)
let count = try context.count(for: request)

// Fetch with relationship traversal
request.predicate = NSPredicate(format: "category.name == %@", "Work")

// Compound predicates
let compound = NSCompoundPredicate(andPredicateWithSubpredicates: [
    NSPredicate(format: "isCompleted == NO"),
    NSPredicate(format: "createdAt > %@", oneWeekAgo as NSDate)
])
request.predicate = compound
```

### NSFetchedResultsController (UIKit)

```swift
lazy var fetchedResultsController: NSFetchedResultsController<TaskEntity> = {
    let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
    request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.createdAt, ascending: false)]
    request.fetchBatchSize = 20

    let frc = NSFetchedResultsController(
        fetchRequest: request,
        managedObjectContext: CoreDataStack.shared.viewContext,
        sectionNameKeyPath: nil,
        cacheName: nil     // Use cache name for stable, large datasets
    )
    frc.delegate = self
    return frc
}()

// In viewDidLoad:
try fetchedResultsController.performFetch()

// Implement NSFetchedResultsControllerDelegate for automatic table/collection updates
```

### Core Data in SwiftUI

```swift
// @FetchRequest replaces NSFetchedResultsController in SwiftUI
struct TaskListView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.createdAt, order: .reverse)],
        predicate: NSPredicate(format: "isCompleted == NO"),
        animation: .default
    )
    private var tasks: FetchedResults<TaskEntity>

    var body: some View {
        List(tasks) { task in
            Text(task.title)
        }
    }
}

// Inject context at App level:
// .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
```

### Background Processing

```swift
// Option 1: performBackgroundTask (ephemeral context)
CoreDataStack.shared.persistentContainer.performBackgroundTask { context in
    // context is a private-queue context — auto-released after closure
    for dto in records {
        let entity = TaskEntity(context: context)
        entity.title = dto.title
    }
    try? context.save()
}

// Option 2: async/await (iOS 15+)
let bgContext = CoreDataStack.shared.newBackgroundContext()
try await bgContext.perform {
    // All work here runs on bgContext's private queue
    for dto in records {
        let entity = TaskEntity(context: bgContext)
        entity.title = dto.title
    }
    try bgContext.save()
}
```

**Concurrency rules:**
- **NEVER** pass `NSManagedObject` across threads — use `NSManagedObjectID` instead
- Use `context.object(with: objectID)` to resolve on the correct context
- `viewContext` is main-queue only; `newBackgroundContext()` is private-queue only

### Batch Operations (Performance)

```swift
// Batch delete — bypasses context, executes directly on store
let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "TaskEntity")
fetchRequest.predicate = NSPredicate(format: "isCompleted == YES")
let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
deleteRequest.resultType = .resultTypeObjectIDs

let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
let objectIDs = result?.result as? [NSManagedObjectID] ?? []

// Merge batch changes into viewContext
NSManagedObjectContext.mergeChanges(
    fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs],
    into: [CoreDataStack.shared.viewContext]
)

// Batch update
let updateRequest = NSBatchUpdateRequest(entityName: "TaskEntity")
updateRequest.propertiesToUpdate = ["isCompleted": true]
updateRequest.predicate = NSPredicate(format: "createdAt < %@", cutoffDate as NSDate)
updateRequest.resultType = .updatedObjectIDsResultType
try context.execute(updateRequest)

// Batch insert (iOS 13+)
let insertRequest = NSBatchInsertRequest(entity: TaskEntity.entity(), objects: arrayOfDicts)
try context.execute(insertRequest)
```

---

## Schema Migrations

### SwiftData Migrations

```swift
// Step 1: Define versioned schemas
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [Task.self] }

    @Model class Task {
        var title: String
        var isCompleted: Bool
        init(title: String) { self.title = title; isCompleted = false }
    }
}

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] { [Task.self] }

    @Model class Task {
        var title: String
        var isCompleted: Bool
        var priority: Int          // NEW: added field
        init(title: String) { self.title = title; isCompleted = false; priority = 0 }
    }
}

// Step 2: Define migration plan
enum TaskMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self, SchemaV2.self] }

    static var stages: [MigrationStage] {[
        // Lightweight: SwiftData infers the diff automatically
        .lightweight(from: SchemaV1.self, to: SchemaV2.self)
    ]}
}

// Step 3: Wire to container
let container = try ModelContainer(
    for: SchemaV2.Task.self,
    migrationPlan: TaskMigrationPlan.self
)
```

**Custom migration (when lightweight isn't enough):**

```swift
static var stages: [MigrationStage] {[
    .custom(
        from: SchemaV1.self,
        to: SchemaV2.self,
        willMigrate: { context in
            // Runs BEFORE schema change — fix data for the old schema
            // e.g., set default values for soon-to-be-nonoptional fields
        },
        didMigrate: { context in
            // Runs AFTER schema change — populate new fields
            let tasks = try context.fetch(FetchDescriptor<SchemaV2.Task>())
            for task in tasks where task.priority == 0 {
                task.priority = 1   // Default priority
            }
            try context.save()
        }
    )
]}
```

### Lightweight Migration Compatibility (SwiftData & Core Data)

These changes are auto-migratable:
| Change | Auto? |
|---|---|
| Add a new attribute with default | Yes |
| Remove an attribute | Yes |
| Make optional → non-optional (with default) | Yes |
| Make non-optional → optional | Yes |
| Rename entity/attribute (with `originalName:`) | Yes |
| Add a new entity | Yes |
| Add a new relationship | Yes |
| Change relationship from to-one to to-many | Yes |
| Change attribute type (e.g., String → Int) | **No** — custom |
| Split/merge entities | **No** — custom |
| Change relationship topology | **No** — custom |

### Core Data Staged Migrations (iOS 17+)

```swift
// For Core Data apps needing staged migrations:
let stages: [NSMigrationStage] = [
    NSLightweightMigrationStage(["AppModel_v1", "AppModel_v2"]),
    NSCustomMigrationStage(
        migratingFrom: "AppModel_v2",
        to: "AppModel_v3"
    ) { context in
        // willMigrate — clean up data before schema change
    } didMigrateHandler: { context in
        // didMigrate — populate new fields after schema change
    }
]

let manager = NSStagedMigrationManager(stages)
let description = container.persistentStoreDescriptions.first!
description.setOption(manager, forKey: NSPersistentStoreStagedMigrationManagerOptionKey)
```

### Core Data Legacy Lightweight Migration

```swift
// Pre-iOS 17: enable in store description
let description = NSPersistentStoreDescription()
description.shouldInferMappingModelAutomatically = true
description.shouldMigrateStoreAutomatically = true
container.persistentStoreDescriptions = [description]
```

---

## SwiftData History Tracking (iOS 18+)

```swift
// Track inserts, updates, deletes across processes (widgets, app intents)
func fetchRecentChanges(after tokenData: Data?) throws -> [DefaultHistoryTransaction] {
    let context = ModelContext(container)

    var descriptor = HistoryDescriptor<DefaultHistoryTransaction>()
    if let tokenData {
        let token = try JSONDecoder().decode(DefaultHistoryToken.self, from: tokenData)
        descriptor.predicate = #Predicate { $0.token > token }
    }

    return try context.fetchHistory(descriptor)
}

// Process changes
for txn in transactions {
    for change in txn.changes {
        switch change {
        case let insert as DefaultHistoryInsert<Task>:
            print("Inserted: \(insert.changedModelID)")
        case let update as DefaultHistoryUpdate<Task>:
            print("Updated attrs: \(update.updatedAttributes)")
        case let delete as DefaultHistoryDelete<Task>:
            let ref = delete.tombstone[\.externalId]   // Preserved value
            print("Deleted: \(ref ?? "unknown")")
        default: break
        }
    }
}

// Clean up old transactions
func deleteOldTransactions(before token: DefaultHistoryToken) throws {
    let context = ModelContext(container)
    var descriptor = HistoryDescriptor<DefaultHistoryTransaction>()
    descriptor.predicate = #Predicate { $0.token < token }
    try context.deleteHistory(descriptor)
}
```

---

## CloudKit Sync

### SwiftData + CloudKit

```swift
// 1. Enable CloudKit capability in Xcode
// 2. Configure ModelConfiguration
let config = ModelConfiguration(cloudKitDatabase: .automatic)
let container = try ModelContainer(for: Task.self, configurations: config)
```

**CloudKit schema requirements:**
- All attributes must be **optional** or have defaults
- No `@Attribute(.unique)` — CloudKit doesn't support unique constraints
- Relationships must be **optional**
- Use `@Attribute(.preserveValueOnDeletion)` for cross-device delete tracking

### Core Data + CloudKit

```swift
let container = NSPersistentCloudKitContainer(name: "AppModel")
container.loadPersistentStores { _, error in /* ... */ }

// Enable automatic schema initialization (development only)
do {
    try container.initializeCloudKitSchema()
} catch { print("Schema init failed: \(error)") }
```

---

## UserDefaults

`@AppStorage("key") var value = default` for SwiftUI.
`UserDefaults(suiteName: "group.com.company.app")` for App Groups.
**Never store**: passwords, tokens, API keys, or large data (> ~100KB).

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

## Repository Pattern (Connects Architecture ↔ Persistence)

```swift
// Protocol in Core module
protocol TaskRepository: Sendable {
    func fetchAll() async throws -> [Task]
    func fetch(id: PersistentIdentifier) async throws -> Task?
    func save(_ task: Task) async throws
    func delete(_ task: Task) async throws
}

// SwiftData implementation
@ModelActor
actor SwiftDataTaskRepository: TaskRepository {
    func fetchAll() async throws -> [Task] {
        try modelContext.fetch(FetchDescriptor<Task>(sortBy: [SortDescriptor(\.createdAt)]))
    }
    func fetch(id: PersistentIdentifier) -> Task? {
        self[id, as: Task.self]
    }
    func save(_ task: Task) async throws {
        modelContext.insert(task)
        try modelContext.save()
    }
    func delete(_ task: Task) async throws {
        modelContext.delete(task)
        try modelContext.save()
    }
}
```

---

## Anti-Patterns

| Anti-pattern | Fix |
|---|---|
| Storing images/videos in SwiftData/Core Data | Use `@Attribute(.externalStorage)` or file system |
| No delete rules on relationships | Always set `deleteRule` — default `.nullify` may leave orphans |
| Missing `inverse` on relationships | Always set explicit inverse |
| Passing `@Model`/`NSManagedObject` across threads | Pass `PersistentIdentifier`/`NSManagedObjectID` instead |
| Fetching all objects when you need a count | Use `fetchCount()` / `context.count(for:)` |
| No indexes on frequently filtered columns | Add `#Index` / indexed attributes |
| Storing secrets in UserDefaults | Use Keychain |
| Multiple ModelContainers for same schema | One container, multiple `ModelConfiguration` |
| Forgetting `automaticallyMergesChangesFromParent` | Set on `viewContext` for background save visibility |
| No migration plan for shipped app | Ship `SchemaMigrationPlan` from v1 — adding later is painful |
| Manual `onAppear` data loading | Use `@Query` / `@FetchRequest` for automatic updates |

---

## Checklist

- [ ] Storage type chosen based on data sensitivity and size
- [ ] Sensitive data in Keychain, not UserDefaults
- [ ] All relationships have explicit `deleteRule` and `inverse`
- [ ] Relationship types match domain (one-to-one, one-to-many, many-to-many)
- [ ] `@Attribute(.unique)` or `@Unique` for natural keys
- [ ] `#Index` on columns used in predicates and sort descriptors
- [ ] Schema migration plan defined from v1 onward
- [ ] Migration stages tested (lightweight and custom)
- [ ] Large binary data on file system, not DB
- [ ] `@Attribute(.externalStorage)` for image/file data kept in model
- [ ] Caches have size limits in Caches directory
- [ ] `@AppStorage` only for simple value types
- [ ] Background work uses `@ModelActor` or `performBackgroundTask`
- [ ] `PersistentIdentifier` / `NSManagedObjectID` used for cross-thread references
- [ ] CloudKit-synced models have optional attributes and no unique constraints
- [ ] Repository protocol abstracts persistence for testability
