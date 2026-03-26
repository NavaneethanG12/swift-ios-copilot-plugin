---
name: design-system
description: >
  Build design systems — color tokens, typography, spacing, dark/light
  theming, component library, structured logging (OSLog), error handling.
argument-hint: "[design token type, theming, logging, or error handling question]"
user-invocable: true
---

# Design System & Foundations

## Color Tokens

```swift
extension Color {
    static let brand = Color("Brand", bundle: .main)          // Asset Catalog
    static let surfacePrimary = Color("SurfacePrimary")
}
extension ShapeStyle where Self == Color {
    static var brandAccent: Color { Color("BrandAccent") }
}
```

Use Asset Catalog with **Any/Dark** appearance variants. Never hard-code hex in views.

## Typography Scale

```swift
extension Font {
    static let heading1 = Font.system(.largeTitle, weight: .bold)
    static let bodyRegular = Font.system(.body)
    static let caption = Font.system(.caption)
    // Custom: .custom("FontName", size: 17, relativeTo: .body) for Dynamic Type
}
```

## Spacing

```swift
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}
```

## Component Library

Reusable views in a `DesignSystem` SPM package:
`PrimaryButton`, `Card`, `Avatar`, `LoadingView`, `ErrorView`, `EmptyStateView`.
Consistent spacing, colors, typography across all components.

---

## Structured Logging

```swift
import os
private let logger = Logger(subsystem: "com.app", category: "networking")
logger.debug("Request: \(url)")
logger.info("Loaded \(count) items")
logger.error("Failed: \(error.localizedDescription)")
// Never log sensitive data. Use #if DEBUG for verbose output.
```

## Error Handling

```swift
enum AppError: LocalizedError {
    case networkFailure(underlying: Error)
    case invalidData(reason: String)
    var errorDescription: String? { /* user-facing message */ }
}

// View: ErrorView(error: error, retry: { Task { await vm.load() } })
```

## Checklist

- [ ] Colors in Asset Catalog with dark mode variants
- [ ] Typography uses system/scaled fonts (Dynamic Type)
- [ ] Consistent spacing constants used throughout
- [ ] Reusable components in shared package
- [ ] OSLog used instead of print (no sensitive data logged)
- [ ] Errors are typed, user-facing, with retry affordances
