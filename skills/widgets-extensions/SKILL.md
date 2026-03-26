---
name: widgets-extensions
description: >
  Build widgets and app extensions — WidgetKit, TimelineProvider,
  Share/Action extensions, App Groups, extension lifecycle.
argument-hint: "[widget type, extension kind, or data sharing question]"
user-invocable: true
---

# Widgets & Extensions

## WidgetKit

```swift
struct MyWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MyWidget", provider: Provider()) { entry in
            MyWidgetView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular])
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry { Entry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) { completion(.init(date: .now)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let timeline = Timeline(entries: [Entry(date: .now)], policy: .after(.now.addingTimeInterval(3600)))
        completion(timeline)
    }
}
```

**Lock Screen**: `.accessoryCircular`, `.accessoryRectangular`, `.accessoryInline`.
**Interactive** (iOS 17+): `Button` and `Toggle` with `AppIntent`.

## App Groups (Data Sharing)

```swift
let shared = UserDefaults(suiteName: "group.com.company.app")
let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.company.app")
```

## Extension Types

| Extension | Purpose |
|---|---|
| Share | Share content to your app |
| Action | Transform content in-place |
| Notification Content | Custom notification UI |
| Notification Service | Modify notifications before display |
| App Intents | Siri, Shortcuts, widgets |

## Lifecycle

- **Limited memory** (~120MB) and **short runtime**.
- No direct communication with host app — use App Groups, shared Keychain.
- Refresh: `WidgetCenter.shared.reloadTimelines(ofKind:)`.

## Checklist

- [ ] App Group configured for data sharing
- [ ] Timeline refresh policy matches data frequency
- [ ] Widget supports all relevant families
- [ ] Extension memory budget respected
- [ ] Shared data accessed safely (file coordination if needed)
