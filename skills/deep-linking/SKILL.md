---
name: deep-linking
description: >
  Implement deep linking — Universal Links, custom URL schemes, onOpenURL,
  App Clips, Spotlight/Handoff with NSUserActivity.
argument-hint: "[link type or deep link issue]"
user-invocable: true
---

# Deep Linking

## Universal Links (Preferred)

1. Add Associated Domains capability: `applinks:yourdomain.com`.
2. Host `apple-app-site-association` at `https://yourdomain.com/.well-known/`:

```json
{
  "applinks": {
    "details": [{ "appID": "TEAMID.com.app.bundle", "paths": ["/item/*", "/profile/*"] }]
  }
}
```

3. Handle in SwiftUI:

```swift
.onOpenURL { url in router.handle(url) }
```

## Custom URL Schemes

Info.plist → URL Types → `myapp://`. Handle with `.onOpenURL { }`.
Use only as fallback — Universal Links are more secure (HTTPS verified).

## NSUserActivity (Spotlight + Handoff)

```swift
let activity = NSUserActivity(activityType: "com.app.viewItem")
activity.title = item.name
activity.isEligibleForSearch = true      // Spotlight
activity.isEligibleForHandoff = true     // Handoff
activity.webpageURL = URL(string: "https://app.com/item/\(item.id)")
```

## App Clips

Lightweight (<15MB). Triggered by URL, NFC, QR, App Clip Code.
Entry: `@main struct MyAppClip: App { }` → handle invocation URL.

## Checklist

- [ ] Universal Links configured with AASA file
- [ ] All deep link URLs parsed safely (validate path components)
- [ ] `.onOpenURL` handler routes to correct view
- [ ] Spotlight indexing for searchable content
- [ ] App Clip under 15MB, focused on single task
