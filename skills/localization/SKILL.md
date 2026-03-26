---
name: localization
description: >
  Localize iOS/macOS apps — String Catalogs (.xcstrings), formatters
  (dates, currency, numbers), RTL layout, plural rules, translator workflow.
argument-hint: "[language, localization issue, or format question]"
user-invocable: true
---

# Localization — iOS / macOS

## String Catalogs (Xcode 15+)

1. File → New → String Catalog → `Localizable.xcstrings`.
2. Add languages in Project → Info → Localizations.
3. Build — Xcode auto-discovers `Text("...")`, `Button("...")`, `Label("...")`.

SwiftUI strings are automatically extracted. Use `Text("key_name")` for explicit keys.
Plurals handled automatically: set zero/one/other forms in the catalog.

---

## Formatters

```swift
Text(date, format: .dateTime.month().day().year()) // locale-aware
Text(price, format: .currency(code: "USD"))        // $9.99 / 9,99 $
Text(ratio, format: .percent)                      // 42% / 42 %
Text(distance, format: .measurement(width: .wide)) // adapts to locale units
Text(date, style: .relative)                       // "2 hours ago"
```

---

## RTL Support

- Use `.leading/.trailing`, never `.left/.right`.
- `HStack` auto-flips. Flip directional images: `.flipsForRightToLeftLayoutDirection(true)`.
- Test: scheme option → Right-to-Left Pseudolanguage.

---

## Testing

1. **Pseudo-localization** (Scheme → Options): Double-Length, RTL, Accented.
2. **Preview**: `.environment(\.locale, Locale(identifier: "ar"))`.
3. **Export**: Product → Export Localizations → `.xcloc` for translators.

---

## Checklist

- [ ] All user strings via String Catalog
- [ ] Dates/numbers/currency use system formatters
- [ ] Plural forms for countable strings
- [ ] Layout uses `.leading/.trailing`
- [ ] Directional images flip for RTL
- [ ] Pseudo-localization passes (no truncation)
- [ ] Privacy descriptions localized in `InfoPlist.xcstrings`
