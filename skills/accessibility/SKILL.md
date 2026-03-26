---
name: accessibility
description: >
  Implement iOS/macOS accessibility — VoiceOver, Dynamic Type, labels/hints/traits,
  SwiftUI modifiers, colour contrast, Reduce Motion, testing.
argument-hint: "[view, accessibility issue, or audit request]"
user-invocable: true
---

# Accessibility — iOS / macOS

## SwiftUI Modifiers

```swift
.accessibilityLabel("Favourite")
.accessibilityHint("Double-tap to toggle")
.accessibilityValue("\(Int(volume))%")
.accessibilityAddTraits(.isHeader)
.accessibilityHidden(true)                    // decorative elements
.accessibilityElement(children: .combine)     // group related
.accessibilitySortPriority(1)                 // reading order
.accessibilityAction(named: "Delete") { delete() }
```

---

## Dynamic Type

- System fonts scale automatically. Custom: `.font(.custom("Name", size: 17, relativeTo: .body))`.
- Constrained: `.minimumScaleFactor(0.8).lineLimit(2)`.
- UIKit: `preferredFont(forTextStyle:)` + `adjustsFontForContentSizeCategory = true`.
- Adaptive layout: `ViewThatFits { HStack { } VStack { } }` or check `@Environment(\.dynamicTypeSize)`.

---

## Contrast & Motion

| Requirement | Ratio |
|---|---|
| Regular text | 4.5:1 |
| Large text (≥18pt) | 3:1 |
| UI components | 3:1 |

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion
withAnimation(reduceMotion ? nil : .spring()) { flag.toggle() }

@Environment(\.accessibilityReduceTransparency) var reduceTransparency
// Use solid color when reduceTransparency is true
```

Never rely on colour alone — add shapes, patterns, or labels.

---

## Testing

1. **Accessibility Inspector** (Xcode → Open Developer Tool): Audit, inspect labels/traits/actions.
2. **VoiceOver**: Swipe through every screen, verify labels and order.
3. **Xcode Audit**: Debug → Accessibility Audit in simulator.

---

## Checklist

- [ ] Every interactive element has `accessibilityLabel`
- [ ] Decorative images use `accessibilityHidden(true)`
- [ ] All text uses Dynamic Type
- [ ] Contrast meets 4.5:1 / 3:1
- [ ] No info conveyed by colour alone
- [ ] Animations respect `reduceMotion`
- [ ] Minimum touch target: 44×44pt
- [ ] VoiceOver navigation order is logical
- [ ] Accessibility Audit passes
