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
// Model: struct, Codable, Identifiable
// ViewModel: @Observable, inject deps, expose state + async methods
// View: @State var vm, .task { await vm.load() }

@Observable class TaskListVM {
    private let repo: TaskRepository
    var tasks: [Task] = []; var isLoading = false
    init(repo: TaskRepository) { self.repo = repo }
    func load() async { isLoading = true; defer { isLoading = false }; tasks = (try? await repo.fetchAll()) ?? [] }
}
// View: @State private var vm = TaskListVM(repo: repo)
// body → List(vm.tasks) { ... }.task { await vm.load() }
```

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

---

## Checklist

- [ ] Architecture chosen based on project scale
- [ ] Views contain only UI code
- [ ] ViewModels testable (deps injected via protocols)
- [ ] Navigation managed by Router/Coordinator
- [ ] No circular dependencies between modules
- [ ] Feature modules don't depend on each other
- [ ] Core module has zero framework dependencies
