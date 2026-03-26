---
name: testing
description: >
  Write tests for iOS/macOS — Swift Testing (@Test, #expect), XCTest,
  mocking with protocols, async testing, test architecture, coverage.
argument-hint: "[class to test, test type, or testing question]"
user-invocable: true
---

# Testing — iOS / macOS

## Framework Choice

| Framework | When |
|---|---|
| **Swift Testing** (`@Test`) | New unit tests (Xcode 16+), preferred |
| **XCTest** | UI tests, performance tests, legacy suites |

Both coexist in the same target. Don't mix APIs in a single test.

---

## Swift Testing Patterns

```swift
@Suite("ViewModelTests")
struct VMTests {
    @Test("loads items") func load() async {
        let vm = VM(repo: MockRepo()); await vm.load()
        #expect(!vm.items.isEmpty)
    }
}

// Parameterized
@Test("validate email", arguments: [("a@b.com", true), ("bad", false)])
func email(addr: String, valid: Bool) { #expect(Validator.isValid(addr) == valid) }

// Error
@Test func throws404() async {
    await #expect(throws: NetworkError.httpError(404, Data())) { try await client.fetch("x") }
}

// Tags: extension Tag { @Tag static var networking: Self }
// @Test(.tags(.networking)) func ...
```

---

## Mocking

```swift
protocol TaskRepository: Sendable {
    func fetchAll() async throws -> [Task]
}

final class MockTaskRepository: TaskRepository {
    var tasks: [Task] = []; var shouldThrow = false
    func fetchAll() async throws -> [Task] { if shouldThrow { throw Err() }; return tasks }
}
// Inject via init: VM(repo: MockTaskRepository())
```

---

## UI Tests (XCTest)

```swift
let app = XCUIApplication()
app.launchArguments = ["--uitesting"]
app.launch()
XCTAssertTrue(app.staticTexts["Welcome"].waitForExistence(timeout: 3))
app.buttons["Next"].tap()
```

---

## Strategy

| Layer | What | Framework |
|---|---|---|
| Models | Codable, validation | Swift Testing |
| ViewModels | State, async, errors | Swift Testing |
| Services | API, persistence | Swift Testing |
| User flows | E2E interaction | XCTest (UI) |

---

## Checklist

- [ ] Every VM has unit tests
- [ ] Dependencies injected via protocols
- [ ] Async tests use `async/await`
- [ ] Error paths tested
- [ ] UI tests cover critical flows
- [ ] Tests run in isolation
- [ ] Coverage: ≥80% business logic, ≥60% overall
