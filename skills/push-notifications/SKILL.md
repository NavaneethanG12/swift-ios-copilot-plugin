---
name: push-notifications
description: >
  Implement push notifications — APNs registration, UNUserNotificationCenter,
  remote/local notifications, categories, rich notifications, extensions.
argument-hint: "[notification type or push issue]"
user-invocable: true
---

# Push Notifications

## Registration

```swift
// Request permission
let center = UNUserNotificationCenter.current()
let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])

// Register for remote
UIApplication.shared.registerForRemoteNotifications()

// AppDelegate callback
func application(_ app: UIApplication,
                 didRegisterForRemoteNotificationsWithDeviceToken token: Data) {
    let tokenString = token.map { String(format: "%02x", $0) }.joined()
    // Send tokenString to your server securely
}
```

## Local Notifications

```swift
let content = UNMutableNotificationContent()
content.title = "Reminder"; content.body = "Task due"; content.sound = .default
let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
try await center.add(request)
```

## Categories & Actions

```swift
let action = UNNotificationAction(identifier: "COMPLETE", title: "Complete", options: [])
let category = UNNotificationCategory(identifier: "TASK", actions: [action], intentIdentifiers: [])
center.setNotificationCategories([category])
// Handle: UNUserNotificationCenterDelegate → didReceive response.actionIdentifier
```

## Rich Notifications

Add **Notification Service Extension** target for:
- Downloading image/video attachments before display
- Decrypting encrypted payloads
- Modifying content (`UNNotificationServiceExtension.didReceive`)

## Checklist

- [ ] Permission requested before scheduling/registering
- [ ] Device token sent to server securely
- [ ] Foreground handling via `UNUserNotificationCenterDelegate`
- [ ] Categories defined for actionable notifications
- [ ] Notification Service Extension for rich media
