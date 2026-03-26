---
name: project-scaffolding
description: >
  Generate new iOS/macOS Xcode projects — folder structure, SPM setup,
  target configuration, build settings, capabilities, schemes.
argument-hint: "[app name, platform, or architecture style]"
user-invocable: true
---

# Project Scaffolding — iOS / macOS

## Template Selection

| Template | When |
|---|---|
| App (SwiftUI) | Modern declarative UI (iOS 15+) |
| App (UIKit) | Legacy or complex UIKit |
| Swift Package | Reusable library / multi-module |
| Framework | Distributable binary |
| Widget Extension | Home screen widgets |

---

## Folder Structure (MVVM)

```
MyApp/
├── Sources/
│   ├── App/           # @main, ContentView
│   ├── Features/      # Home/, Settings/ (View + ViewModel + Models per feature)
│   ├── Core/          # Networking/, Persistence/, Services/
│   ├── Shared/        # Components/, Extensions/, Models/, Utilities/
│   └── Resources/     # Localizable.xcstrings, Fonts/
├── MyAppTests/        # Feature tests, Core tests, Mocks/
└── MyAppUITests/
```

Multi-module: `Packages/Core/`, `Packages/Networking/`, `Packages/Features/` — each with `Package.swift`.

---

## Build Settings

| Setting | Value | Why |
|---|---|---|
| `SWIFT_VERSION` | 6.0 | Strict concurrency |
| `IPHONEOS_DEPLOYMENT_TARGET` | 17.0+ | SwiftData, @Observable |
| `SWIFT_STRICT_CONCURRENCY` | complete | Catch data races |
| `CODE_SIGN_STYLE` | Automatic | Managed signing |
| `ENABLE_PREVIEWS` | YES | SwiftUI previews |

---

## Capabilities

| Capability | When needed |
|---|---|
| Push Notifications | Remote notifications |
| Background Modes | Fetch, audio, location |
| App Groups | Widget, extension shared data |
| iCloud | CloudKit sync |
| In-App Purchase | StoreKit |

---

## Output format

Provide: template selection, folder structure diagram, Package.swift (if SPM),
app entry point, build settings, capabilities needed.
