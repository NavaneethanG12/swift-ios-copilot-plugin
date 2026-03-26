---
name: app-store-submission
description: >
  Prepare and submit iOS/macOS apps — archiving, code signing, App Store
  Connect, TestFlight, App Review guidelines, metadata, release management.
argument-hint: "[submission issue, signing error, or review question]"
user-invocable: true
---

# App Store Submission

## Workflow

`Prepare → Archive → Validate → Upload → TestFlight → Submit → Release`

### Prepare

| Item | Check |
|---|---|
| Bundle ID | Registered in Developer portal |
| App icon | 1024×1024, no alpha |
| Version | Semantic (1.0.0) |
| Build number | Incremented each build |
| Info.plist | All privacy usage descriptions |
| Capabilities | Correct entitlements |

### Archive & Upload

1. Destination: "Any iOS Device" → Product → Archive.
2. Organizer → Validate App → fix any issues.
3. Distribute App → TestFlight & App Store.

### TestFlight

Internal: up to 100 testers, no review. External: up to 10,000, needs Beta App Review.

### Release Options

Manual (you control go-live) | Automatic (after approval) | Phased (1%→100% over 7 days).

---

## Code Signing

| Concept | Purpose |
|---|---|
| Certificate | Identifies developer/team |
| Provisioning profile | Links cert + app ID + devices |
| Entitlements | Declares system API access |

Profiles: Development, Ad Hoc (100 devices), App Store, Enterprise.
Use automatic signing or Fastlane `match`.

---

## Privacy Keys (Info.plist)

| Key | When |
|---|---|
| `NSCameraUsageDescription` | Camera |
| `NSPhotoLibraryUsageDescription` | Photos read |
| `NSLocationWhenInUseUsageDescription` | Location |
| `NSMicrophoneUsageDescription` | Microphone |
| `NSFaceIDUsageDescription` | Face ID |
| `NSUserTrackingUsageDescription` | ATT |

---

## Common Rejections

| Guideline | Fix |
|---|---|
| 2.1 Crashes | Test thoroughly |
| 2.3 Bad metadata | Match screenshots to app |
| 3.1.1 External payment | Use StoreKit for digital goods |
| 5.1.1 Missing privacy policy | Add policy + Info.plist keys |
| 5.1.2 No ATT | Add ATT prompt for tracking |

---

## Metadata Checklist

- [ ] App name (30 chars), subtitle (30 chars)
- [ ] Description (4000 chars), keywords (100 chars)
- [ ] Screenshots for each device size
- [ ] Privacy policy URL, support URL
- [ ] Category, age rating, pricing
- [ ] App Review contact info
