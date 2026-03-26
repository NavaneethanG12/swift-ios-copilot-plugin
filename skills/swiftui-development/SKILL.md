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

---

## Common Patterns

- **Search + refresh**: `.searchable(text:)` + `.refreshable { await reload() }`
- **Form + validation**: `Form { Section { TextField(...) } }` + toolbar Save/Cancel + `isValid` computed property
- **Async image**: `AsyncImage(url:) { phase in switch phase { .empty → ProgressView, .success → image, .failure → placeholder } }`
- **Lazy lists**: `ScrollView { LazyVStack { ForEach(...) } }` for 50+ items

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

## Do / Don't

**Do**: `@State` for local, `@Observable` for models, `NavigationStack` over `NavigationView`,
`.task {}` for async, extract reusable views, `.sensoryFeedback()` for haptics.

**Don't**: Heavy computation in `body`, `@ObservedObject` to create objects, force-unwrap in views,
ignore `@MainActor`, use `onAppear` for async (use `.task`).

---

## Output format

Provide: complete view code, navigation integration, Preview, accessibility labels.
