---
name: architecture-patterns
description: >
  Design iOS/macOS app architecture — MVVM, TCA, Clean Architecture,
  Coordinator/Router, dependency injection, SPM modularization.
argument-hint: "[pattern name, architecture question, or project scale]"
user-invocable: true
---

# Architecture Patterns — iOS / macOS

## Decision Guide

| Scale | Recommended |
|---|---|
| Solo / prototype | MVVM (vanilla) |
| Small (1–3 devs) | MVVM + Coordinator |
| Medium (3–8) | MVVM + DI + SPM modules |
| Large (8+) | TCA or Clean Architecture |

---

## MVVM (Default for SwiftUI)

```swift
// Model: struct, Codable, Identifiable, Hashable
// ViewModel: @Observable, inject deps, expose state + async methods, @MainActor mutations
// View: @State var vm, .task { await vm.load() }

@Observable class TaskListVM {
    private let repo: TaskRepository
    var tasks: [Task] = []; var isLoading = false
    init(repo: TaskRepository) { self.repo = repo }
    @MainActor func load() async { isLoading = true; defer { isLoading = false }; tasks = (try? await repo.fetchAll()) ?? [] }
}
// View: @State private var vm = TaskListVM(repo: repo)
// body → List(vm.tasks) { ... }.task { await vm.load() }
```

### Complete MVVM Wiring (end-to-end)

This shows how ALL pieces connect. Every new feature should follow this pattern:

```
┌──────────────┐    ┌──────────────┐    ┌──────────────────┐    ┌───────────┐
│ View          │───▶│ ViewModel    │───▶│ Repository       │───▶│ Data      │
│ (@State var vm)    │ (@Observable) │    │ (protocol + impl)│    │ (API/DB)  │
│               │    │              │    │                  │    │           │
│ .task {       │    │ @MainActor   │    │ async throws     │    │           │
│   await vm    │    │ func load()  │    │ func fetchAll()  │    │           │
│   .load()     │    │   async {    │    │   -> [Model]     │    │           │
│ }             │    │   tasks =    │    │                  │    │           │
│               │    │   try await  │    │                  │    │           │
│ List(vm.tasks)│    │   repo       │    │                  │    │           │
│               │    │   .fetchAll()│    │                  │    │           │
└──────────────┘    └──────────────┘    └──────────────────┘    └───────────┘
```

**Wiring rules:**
1. **View → VM**: `@State private var vm = VM(repo: RealRepo())` or injected
2. **VM → Repo**: `private let repo: RepoProtocol` injected via `init`
3. **Repo → Data**: URLSession for API, ModelContext for SwiftData
4. **Async trigger**: View uses `.task { await vm.load() }` — never `onAppear`
5. **Error display**: VM has `var error: Error?`, View has `.alert(isPresented:)`
6. **Loading state**: VM has `var isLoading = false`, View shows `ProgressView()`

**Every feature MUST have**: Model + Protocol + Repo + ViewModel + View + Navigation entry.

---

## Dependency Injection

- **Protocol-based** (preferred): `protocol TaskRepository: Sendable { func fetchAll() async throws -> [Task] }` — production + mock. Inject via `init`.
- **DI container**: `@Observable class Dependencies { let repo: TaskRepository }` → `.environment(deps)`.
- **EnvironmentKey**: For cross-cutting concerns on `EnvironmentValues`.

---

## Coordinator / Router

```swift
@Observable class Router {
    var path = NavigationPath()
    enum Destination: Hashable { case detail(Item), settings }
    func navigate(to d: Destination) { path.append(d) }
    func popToRoot() { path.removeLast(path.count) }
}
// NavigationStack(path: $router.path) { ... .navigationDestination(for: Router.Destination.self) { ... } }
```

---

## Modularization with SPM

```
App → Features → Core, Networking, Persistence, DesignSystem
Networking → Core  |  Persistence → Core  |  DesignSystem → Core
```

**Rule:** Feature modules NEVER depend on each other. Communication goes through Core protocols.

---

## TCA (Large Apps)

```swift
@Reducer struct TaskList {
    @ObservableState struct State: Equatable { var tasks: IdentifiedArrayOf<Task> = [] }
    enum Action { case onAppear, loaded([Task]), delete(Task) }
    @Dependency(\.taskClient) var client
    var body: some ReducerOf<Self> { Reduce { state, action in /* handle actions, return .run for effects */ } }
}
```

---

## Anti-Patterns

| Anti-pattern | Fix |
|---|---|
| Massive ViewController | Extract to MVVM |
| God ViewModel | Split per component |
| Singleton everything | Protocol + DI |
| Direct navigation | Coordinator/Router |
| Business logic in Views | Move to ViewModel/Service |
| Feature coupling | Protocols in Core |
| View created but not navigable | Add to Router/NavigationStack destination |
| ViewModel created but unused | Wire to View with @State and .task |
| Protocol with no implementation | Create concrete type + mock |
| Model without Identifiable/Hashable | Add conformances for List/Navigation |
| Missing imports | Always import SwiftUI/Foundation/Observation per file |
| @Observable without @MainActor | Add @MainActor to methods that update published state |

---

## Checklist

- [ ] Architecture chosen based on project scale
- [ ] Views contain only UI code
- [ ] ViewModels testable (deps injected via protocols)
- [ ] Navigation managed by Router/Coordinator
- [ ] No circular dependencies between modules
- [ ] Feature modules don't depend on each other
- [ ] Core module has zero framework dependencies
