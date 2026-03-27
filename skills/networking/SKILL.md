---
name: networking
description: >
  Build networking layers for iOS/macOS — URLSession, async/await API clients,
  endpoint design, error handling, authentication, retry logic, ATS.
argument-hint: "[API endpoint, network error, or architecture question]"
user-invocable: true
---

# Networking — iOS / macOS

## Complete File Templates

Always include imports. Every networking file needs at minimum `import Foundation`.

### Endpoint + APIClient (copy-ready)
```swift
import Foundation

// MARK: - HTTP Method
enum HTTPMethod: String { case GET, POST, PUT, PATCH, DELETE }

// MARK: - Endpoint Protocol
protocol Endpoint {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var queryItems: [URLQueryItem]? { get }
    var body: (any Encodable)? { get }
}

extension Endpoint {
    var urlRequest: URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true)!
        components.queryItems = queryItems
        var request = URLRequest(url: components.url!)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        if let body { request.httpBody = try? JSONEncoder().encode(body) }
        return request
    }
}

// MARK: - Network Error
enum NetworkError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int, data: Data)
    case decodingFailed(Error)
    case noConnection
    case timeout

    var isRetryable: Bool {
        switch self {
        case .httpError(let code, _): return code >= 500 || code == 429
        case .noConnection, .timeout: return true
        default: return false
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid server response"
        case .httpError(let code, _): return "Server error (\(code))"
        case .decodingFailed(let error): return "Data format error: \(error.localizedDescription)"
        case .noConnection: return "No internet connection"
        case .timeout: return "Request timed out"
        }
    }
}

// MARK: - HTTP Client Protocol (for mocking)
protocol HTTPClient: Sendable {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}

// MARK: - API Client
actor APIClient: HTTPClient {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared, decoder: JSONDecoder = {
        let d = JSONDecoder(); d.keyDecodingStrategy = .convertFromSnakeCase; d.dateDecodingStrategy = .iso8601; return d
    }()) {
        self.session = session; self.decoder = decoder
    }

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let (data, response) = try await session.data(for: endpoint.urlRequest)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
        guard (200...299).contains(http.statusCode) else {
            throw NetworkError.httpError(statusCode: http.statusCode, data: data)
        }
        do { return try decoder.decode(T.self, from: data) }
        catch { throw NetworkError.decodingFailed(error) }
    }
}
```

---

## API Client Architecture

```swift
// Endpoint protocol — defines requests declaratively
protocol Endpoint {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var queryItems: [URLQueryItem]? { get }
    var body: Encodable? { get }
    var urlRequest: URLRequest { get } // computed from above
}

// Generic async client
actor APIClient {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let (data, response) = try await session.data(for: endpoint.urlRequest)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NetworkError.httpError(statusCode: http.statusCode, data: data)
        }
        return try decoder.decode(T.self, from: data)
    }
}

// Error type with retryable classification
enum NetworkError: LocalizedError {
    case invalidResponse, httpError(statusCode: Int, data: Data), decodingFailed(Error), noConnection, timeout
    var isRetryable: Bool { /* 5xx, 429, noConnection, timeout → true */ }
}
```

---

## Authentication

Token refresh pattern: attempt request → on 401 → `tokenProvider.refreshToken()` → retry once.
Store tokens in **Keychain** (never UserDefaults).

## Retry Logic

Exponential backoff: `delay * (attempt + 1)`, retry only `.isRetryable` errors, max 3 attempts.
Handle `URLError` codes: `.notConnectedToInternet`, `.timedOut`, `.cancelled`.
HTTP: 401 → refresh token, 429/5xx → retry, 4xx → client error (don't retry).

## App Transport Security

All connections HTTPS. Never ship `NSAllowsArbitraryLoads = YES`.
Per-domain exceptions for development only via `NSExceptionDomains`.

## Testing

Protocol-based: `protocol HTTPClient: Sendable { func request<T: Decodable>(...) async throws -> T }`.
Mock returns preset `Data` or `Error`. Inject via init.

---

## Checklist

- [ ] All requests use HTTPS (no blanket ATS exceptions)
- [ ] Error handling covers all URLError cases
- [ ] JSONDecoder uses `.convertFromSnakeCase` if API uses snake_case
- [ ] Auth tokens stored in Keychain
- [ ] Retry with exponential backoff and jitter
- [ ] Requests cancellable via `Task` handles
- [ ] Large downloads use `URLSession.download`
- [ ] Response models are `Sendable`
