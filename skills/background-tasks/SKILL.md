---
name: background-tasks
description: >
  Implement background execution — BGTaskScheduler, app refresh,
  background URLSession, beginBackgroundTask, silent push.
argument-hint: "[background task type or issue]"
user-invocable: true
---

# Background Tasks

## BGTaskScheduler (iOS 13+)

```swift
// Register in didFinishLaunching
BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.app.refresh", using: nil) { task in
    handleAppRefresh(task: task as! BGAppRefreshTask)
}

// Schedule
func scheduleRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: "com.app.refresh")
    request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
    try? BGTaskScheduler.shared.submit(request)
}

// Handle
func handleAppRefresh(task: BGAppRefreshTask) {
    scheduleRefresh() // reschedule
    let op = Task { await fetchLatestData() }
    task.expirationHandler = { op.cancel() }
    await op.value
    task.setTaskCompleted(success: true)
}
```

Info.plist: Add `BGTaskSchedulerPermittedIdentifiers` array.

## Background URLSession

```swift
let config = URLSessionConfiguration.background(withIdentifier: "com.app.upload")
config.isDiscretionary = false // urgent
config.sessionSendsLaunchEvents = true
let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
// Downloads/uploads continue even if app is suspended
```

## Short-Lived Background Work

```swift
var bgTask: UIBackgroundTaskIdentifier = .invalid
bgTask = UIApplication.shared.beginBackgroundTask {
    UIApplication.shared.endBackgroundTask(bgTask) // expiration handler
}
// Do work...
UIApplication.shared.endBackgroundTask(bgTask)
```

## Background Modes (Info.plist)

| Mode | Use |
|---|---|
| `fetch` | BGAppRefreshTask |
| `processing` | BGProcessingTask (long, deferrable) |
| `remote-notification` | Silent push triggers background fetch |
| `audio` | Continuous playback |
| `location` | Continuous location updates |

## Checklist

- [ ] Task identifiers in Info.plist + registered in `didFinishLaunching`
- [ ] Expiration handlers set on all tasks
- [ ] Tasks reschedule themselves
- [ ] Background URLSession for large transfers
- [ ] `beginBackgroundTask` for short work during transitions
