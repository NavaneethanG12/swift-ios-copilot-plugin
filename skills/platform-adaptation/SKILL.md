---
name: platform-adaptation
description: >
  Adapt iOS apps for iPadOS, macOS (Catalyst/native), visionOS.
  Multi-window, sidebar, pointer/keyboard, MenuBarExtra, UIKit interop.
argument-hint: "[platform target or adaptation question]"
user-invocable: true
---

# Platform Adaptation

## iPadOS

- **Multitasking**: Support Split View / Slide Over via `UISupportsMultipleWindows` in Info.plist.
- **Sidebar**: `NavigationSplitView { sidebar } content: { } detail: { }` — 3-column layout.
- **Pointer/Keyboard**: `.hoverEffect(.highlight)`, `keyboardShortcut("n", modifiers: .command)`.
- **Stage Manager**: Resizable windows — ensure layout adapts with `GeometryReader` / `ViewThatFits`.
- **Pencil**: `PKCanvasView` for drawing, `.onPencilDoubleTap` for tool switching.

## macOS

- **MenuBarExtra**: `MenuBarExtra("Title", systemImage: "icon") { Content() }` in App scene.
- **Settings**: `Settings { SettingsView() }` as a scene.
- **Toolbar**: `.toolbar { ToolbarItem(placement: .primaryAction) { } }`.
- **NSApplicationDelegateAdaptor**: For AppKit lifecycle events.
- **Window management**: `WindowGroup`, `Window`, `openWindow(id:)` for multi-window.

## Multi-Platform

```swift
#if os(iOS)
// iOS-specific code
#elseif os(macOS)
// macOS-specific code
#endif

// UIKit interop
struct Wrapper: UIViewRepresentable {
    func makeUIView(context: Context) -> SomeUIView { SomeUIView() }
    func updateUIView(_ uiView: SomeUIView, context: Context) { }
}
```

## Checklist

- [ ] iPad sidebar navigation with NavigationSplitView
- [ ] Keyboard shortcuts for common actions
- [ ] Pointer hover effects on interactive elements
- [ ] Resizable window support (no fixed sizes)
- [ ] `#if os()` guards for platform-specific code
