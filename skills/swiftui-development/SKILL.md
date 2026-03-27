---
name: swiftui-development
description: >
  Build iOS/macOS UIs with SwiftUI — state management, navigation,
  lists, forms, animations. Covers @State, @Observable, NavigationStack,
  NavigationSplitView, and common view patterns.
argument-hint: "[view name, UI requirement, or layout issue]"
user-invocable: true
---

# SwiftUI Development

## Complete File Templates

Always use these as the starting skeleton. Never write a SwiftUI file without the import line.

### View with ViewModel
```swift
import SwiftUI

struct TaskListView: View {
    @State private var vm: TaskListViewModel

    init(repo: TaskRepository) {
        _vm = State(initialValue: TaskListViewModel(repo: repo))
    }

    var body: some View {
        List(vm.tasks) { task in
            TaskRow(task: task)
        }
        .navigationTitle("Tasks")
        .task { await vm.load() }
        .refreshable { await vm.load() }
        .overlay { if vm.isLoading { ProgressView() } }
        .alert("Error", isPresented: .constant(vm.error != nil)) {
            Button("OK") { vm.error = nil }
        } message: {
            Text(vm.error?.localizedDescription ?? "")
        }
    }
}
```

### ViewModel (@Observable)
```swift
import Foundation
import Observation

@Observable
class TaskListViewModel {
    private let repo: TaskRepository
    var tasks: [TaskItem] = []
    var isLoading = false
    var error: Error?

    init(repo: TaskRepository) { self.repo = repo }

    @MainActor
    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            tasks = try await repo.fetchAll()
        } catch {
            self.error = error
        }
    }
}
```

### Model
```swift
import Foundation

struct TaskItem: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var isCompleted: Bool

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id; self.title = title; self.isCompleted = isCompleted
    }
}
```

### SwiftData Model
```swift
import Foundation
import SwiftData

@Model
class TaskItem {
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \SubTask.parent)
    var subtasks: [SubTask]

    init(title: String) {
        self.title = title; isCompleted = false; createdAt = .now; subtasks = []
    }
}
```

---

## State Management

| Wrapper | Use when |
|---|---|
| `@State` | Local value types (Bool, String) owned by view |
| `@Binding` | Child needs read/write to parent's state |
| `@Observable` | Reference-type model (iOS 17+, replaces ObservableObject) |
| `@Bindable` | Create bindings to @Observable properties |
| `@Environment` | Shared data via view hierarchy |
| `@AppStorage` | Persist small values to UserDefaults |
| `@Query` | Fetch SwiftData models in views |

**Pattern**: `@Observable class VM { }` → `@State private var vm = VM()` → `.task { await vm.load() }`

---

## Navigation

| Pattern | API |
|---|---|
| Tab bar | `TabView { Tab("...", systemImage:) { View() } }` |
| Stack | `NavigationStack(path:) { ... .navigationDestination(for:) }` |
| Split (iPad/Mac) | `NavigationSplitView { sidebar } content: { } detail: { }` |
| Sheet | `.sheet(isPresented:) { }` |
| Full screen | `.fullScreenCover(isPresented:) { }` |
| Alert | `.alert("Title", isPresented:) { } message: { }` |
| Dismiss | `@Environment(\.dismiss) var dismiss` |

Use `NavigationPath` for programmatic push/pop. Pop to root: `path = NavigationPath()`.

### Navigation Wiring Checklist
When creating a new view that should be navigable:
1. **Destination type**: Make the data type `Hashable` (e.g., `struct Item: Hashable`)
2. **Register destination**: Add `.navigationDestination(for: Item.self) { item in DetailView(item: item) }` to the NavigationStack
3. **Create trigger**: Add `NavigationLink(value: item) { RowView(item: item) }` in the parent
4. **Verify path**: Test that tapping the trigger pushes the correct view
5. **Tab entry**: If top-level screen, add a `Tab` in `TabView` with `systemImage`

**Common miss**: Creating `DetailView` but never adding the `navigationDestination` registration. Every view must be reachable.

---

## Common Patterns

- **Search + refresh**: `.searchable(text:)` + `.refreshable { await reload() }`
- **Form + validation**: `Form { Section { TextField(...) } }` + toolbar Save/Cancel + `isValid` computed property
- **Async image**: `AsyncImage(url:) { phase in switch phase { .empty → ProgressView, .success → image, .failure → placeholder } }`
- **Lazy lists**: `ScrollView { LazyVStack { ForEach(...) } }` for 50+ items
- **Empty state**: `ContentUnavailableView("No Items", systemImage: "tray", description: Text("Add an item to get started."))`

---

## Animations

```swift
// Implicit: .animation(.spring, value: flag)
// Explicit: withAnimation(.easeInOut) { flag.toggle() }
// Transition: .transition(.move(edge:).combined(with: .opacity))
// Hero: .matchedGeometryEffect(id:, in: namespace)
// Respect accessibility: guard !reduceMotion else { flag.toggle(); return }
```

---

## Common Compiler Errors & Fixes

| Error | Cause | Fix |
|---|---|---|
| `Cannot find 'X' in scope` | Missing import or typo | Add `import SwiftUI` / `import Foundation` / check spelling |
| `Type 'X' does not conform to 'Hashable'` | Used in NavigationLink/navigationDestination | Add `: Hashable` conformance |
| `Type 'X' does not conform to 'Identifiable'` | Used in `ForEach` / `List` | Add `: Identifiable` and `let id: UUID` or `var id` property |
| `Cannot convert value of type 'X' to expected argument type 'Binding<X>'` | Passing value where binding expected | Use `$property` or `Binding(get:set:)` |
| `Referencing initializer requires wrapper 'State'` | Wrong @State init | Use `_vm = State(initialValue: ...)` in init |
| `Call to main-actor-isolated function in async context` | Missing @MainActor | Add `@MainActor` to the function or class |
| `Result of call to async function is unused` | Missing await | Add `await` before async call |
| `Immutable value may only appear on left side of assignment` | Mutating `let` or struct property | Use `@State`, `@Binding`, or make property `var` |
| `Generic parameter 'Content' could not be inferred` | Missing return type in ViewBuilder | Add explicit `some View` return or check braces |
| `Cannot find type 'X' in scope` | File not in target or missing import | Check target membership and imports |
| `Reference to property 'X' in closure requires explicit use of 'self'` | Closure captures instance property without `self.` | Use `[weak self]` + `guard let self` + `self.property` (classes) or `[self]` capture |
| `Escaping closure captures mutating 'self' parameter` | Struct method assigns closure that captures self | Use class-based ViewModel instead, or restructure to avoid escaping closure |

---

## Do / Don't

**Do**: `@State` for local, `@Observable` for models, `NavigationStack` over `NavigationView`,
`.task {}` for async, extract reusable views, `.sensoryFeedback()` for haptics.

**Don't**: Heavy computation in `body`, `@ObservedObject` to create objects, force-unwrap in views,
ignore `@MainActor`, use `onAppear` for async (use `.task`).

---

## Output format

Provide: complete view code (with imports), navigation integration showing
how the view is wired into the navigation hierarchy, Preview with sample data,
accessibility labels. Every file must compile independently.
