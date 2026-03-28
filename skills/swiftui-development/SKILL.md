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
// Phase animator (iOS 17+): .phaseAnimator([false, true]) { content, phase in content.opacity(phase ? 1 : 0) }
// Respect accessibility: guard !reduceMotion else { flag.toggle(); return }
```

---

## Gestures

```swift
// Tap
.onTapGesture { action() }
.onTapGesture(count: 2) { doubleTap() }

// Long press
.onLongPressGesture(minimumDuration: 0.5) { longPress() }

// Drag
.gesture(
    DragGesture()
        .onChanged { value in offset = value.translation }
        .onEnded { value in withAnimation { offset = .zero } }
)

// Magnify (pinch)
.gesture(
    MagnifyGesture()
        .onChanged { value in scale = value.magnification }
)

// Simultaneous / Sequential / Exclusive
.gesture(drag.simultaneously(with: rotate))
.gesture(longPress.sequenced(before: drag))
.highPriorityGesture(swipe)  // takes precedence over child gestures
```

---

## Grids

```swift
// Fixed columns
let columns = [GridItem(.fixed(100)), GridItem(.fixed(100))]

// Flexible (equal-width)
let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

// Adaptive (auto-fill based on minimum size)
let columns = [GridItem(.adaptive(minimum: 80))]

LazyVGrid(columns: columns, spacing: 16) {
    ForEach(items) { item in
        CardView(item: item)
    }
}
.padding(.horizontal, 16)

// Horizontal grid
LazyHGrid(rows: [GridItem(.fixed(100)), GridItem(.fixed(100))]) {
    ForEach(items) { item in ItemView(item: item) }
}
```

---

## Scroll Views

```swift
// Basic scroll with lazy loading
ScrollView {
    LazyVStack(spacing: 12) {
        ForEach(items) { item in RowView(item: item) }
    }
    .padding(.horizontal, 16)
}

// Scroll to specific item (iOS 17+)
ScrollView {
    LazyVStack {
        ForEach(items) { item in
            RowView(item: item).id(item.id)
        }
    }
    .scrollTargetLayout()
}
.scrollPosition(id: $selectedID)

// ScrollViewReader (iOS 14+)
ScrollViewReader { proxy in
    ScrollView {
        ForEach(messages) { msg in MessageView(msg: msg).id(msg.id) }
    }
    .onChange(of: messages.count) { proxy.scrollTo(messages.last?.id, anchor: .bottom) }
}

// Dismiss keyboard
.scrollDismissesKeyboard(.interactively)

// Paging
.scrollTargetBehavior(.paging)
```

---

## Custom Components

### ButtonStyle
```swift
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(configuration.isPressed ? Color.accentColor.opacity(0.8) : Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
// Usage: Button("Save") { }.buttonStyle(PrimaryButtonStyle())
```

### ViewModifier
```swift
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
}
extension View { func card() -> some View { modifier(CardModifier()) } }
// Usage: Text("Hello").card()
```

### Custom Shape
```swift
struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
```

---

## SwiftUI ↔ UIKit Interop

### Wrap a UIKit view in SwiftUI (UIViewRepresentable)
```swift
struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        init(_ parent: MapView) { self.parent = parent }
    }
}
```

### Wrap a UIKit ViewController in SwiftUI (UIViewControllerRepresentable)
```swift
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController,
            didFinishPickingMediaWith info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
        }
    }
}
```

### Host SwiftUI inside UIKit
```swift
let hostingController = UIHostingController(rootView: MySwiftUIView())
addChild(hostingController)
view.addSubview(hostingController.view)
hostingController.view.translatesAutoresizingMaskIntoConstraints = false
NSLayoutConstraint.activate([
    hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
    hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
    hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
])
hostingController.didMove(toParent: self)
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

## Layout, Spacing & Alignment (Apple HIG)

### System Spacing Values
Use these standard values from Apple Human Interface Guidelines. Never use arbitrary magic numbers.

```swift
enum Spacing {
    static let xs: CGFloat = 4     // tight element gaps
    static let sm: CGFloat = 8     // between related items
    static let md: CGFloat = 16    // section padding, standard insets
    static let lg: CGFloat = 24    // between sections
    static let xl: CGFloat = 32    // major section breaks
}
```

### Standard Padding & Margins
- **System default padding**: `.padding()` = 16pt on each side (use this as your base)
- **List row insets**: leading 20pt (system default)
- **Safe area**: Always respect `.safeAreaInset()` — never hardcode status bar or home indicator offsets
- **Full-width buttons**: Inset from screen edges, never truly edge-to-edge. Use `.padding(.horizontal, Spacing.md)`
- **Touch targets**: Minimum 44×44pt for all tappable elements (Apple HIG requirement)

### Alignment Patterns
```swift
// ❌ BAD: Misaligned — mixing leading/center in same column
VStack {
    Text("Title").frame(maxWidth: .infinity, alignment: .leading)
    Text("Subtitle").frame(maxWidth: .infinity, alignment: .center)
}

// ✅ GOOD: Consistent leading alignment
VStack(alignment: .leading, spacing: Spacing.sm) {
    Text("Title").font(.headline)
    Text("Subtitle").font(.subheadline).foregroundStyle(.secondary)
}

// ✅ GOOD: HStack with spacer for leading label + trailing value
HStack {
    Text("Label")
    Spacer()
    Text("Value").foregroundStyle(.secondary)
}

// ✅ GOOD: Baseline alignment for mixed-size text
HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
    Text("$99").font(.largeTitle)
    Text("/month").font(.subheadline).foregroundStyle(.secondary)
}
```

### Common Layout Fixes (Screenshot → Code)

| Visual Issue | Root Cause | Fix |
|---|---|---|
| Text or icon not vertically centered | Wrong VStack/HStack alignment | Set `alignment:` parameter on stack |
| Uneven spacing between items | Missing or inconsistent `spacing:` | Set explicit `spacing:` on VStack/HStack |
| Content too close to edges | Missing padding | Add `.padding(.horizontal, Spacing.md)` |
| Element not filling width | Missing `frame` modifier | Add `.frame(maxWidth: .infinity, alignment:)` |
| Items overlapping on small screens | Fixed sizes instead of flexible | Use `Spacer()`, `.frame(minWidth:)`, `ViewThatFits` |
| Text truncating unexpectedly | Fixed `lineLimit` or small frame | Use `.lineLimit(nil)` or `.fixedSize(horizontal: false, vertical: true)` |
| Image stretching or cropping | Wrong content mode | Use `.resizable().aspectRatio(contentMode: .fit)` or `.fill` with `.clipped()` |
| Button too small to tap | No minimum frame | Add `.frame(minWidth: 44, minHeight: 44)` |
| Uneven card heights in grid | Content-dependent sizing | Use `LazyVGrid` with fixed-size items or `.frame(minHeight:)` |
| Content hidden behind keyboard | No keyboard avoidance | Wrap in `ScrollView` or use `.scrollDismissesKeyboard(.interactively)` |
| List separator misaligned | Custom insets wrong | Use `.listRowSeparatorTint()` and `.alignmentGuide(.listRowSeparatorLeading)` |

### Typography — iOS HIG Text Styles

Always use semantic text styles for hierarchy. Never hardcode font sizes.

| Text Style | Default Size (iOS) | Weight | Use For |
|---|---|---|---|
| `.largeTitle` | 34pt | Regular | Screen titles, hero text |
| `.title` | 28pt | Regular | Section headers |
| `.title2` | 22pt | Regular | Sub-section headers |
| `.title3` | 20pt | Regular | Tertiary headers |
| `.headline` | 17pt | Semibold | Emphasized labels, row titles |
| `.body` | 17pt | Regular | Main content text |
| `.callout` | 16pt | Regular | Secondary descriptive text |
| `.subheadline` | 15pt | Regular | Below headlines, metadata |
| `.footnote` | 13pt | Regular | Timestamps, minor info |
| `.caption` | 12pt | Regular | Image captions, badges |
| `.caption2` | 11pt | Regular | Legal text, smallest labels |

**Rules**: Use `.font(.body)` not `.font(.system(size: 17))`. Support Dynamic Type
by default. Avoid `Ultralight`/`Thin` weights — prefer `Regular`/`Medium`/`Semibold`/`Bold`.
Minimum readable size: 11pt. Custom fonts: `.custom("Name", size: 17, relativeTo: .body)`.

### Color & Contrast
- Use semantic colors: `.primary`, `.secondary`, `.accent`, `Color("BrandName")` from Asset Catalog
- **WCAG contrast ratios**: Regular text ≥ 4.5:1, Large text (≥18pt) ≥ 3:1, UI controls ≥ 3:1
- Never rely on color alone — add shapes, icons, or labels
- Dark mode: Test both appearances. Use `Color("Name")` with Any/Dark variants in Asset Catalog

### Adaptive Layout
```swift
// Detect size class for layout adaptation
@Environment(\.horizontalSizeClass) var hSizeClass
var body: some View {
    if hSizeClass == .compact {
        VStack { content }  // iPhone portrait
    } else {
        HStack { content }  // iPad / landscape
    }
}

// Better: ViewThatFits (iOS 16+)
ViewThatFits {
    HStack { label; value }  // Use if it fits
    VStack { label; value }  // Fallback
}

// Dynamic Type adaptation
@Environment(\.dynamicTypeSize) var typeSize
var body: some View {
    if typeSize.isAccessibilitySize {
        VStack { content }  // Stack vertically for large text
    } else {
        HStack { content }
    }
}
```

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
