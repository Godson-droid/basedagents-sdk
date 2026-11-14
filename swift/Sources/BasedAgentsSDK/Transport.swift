import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A raw HTTP response as seen by the client: status, headers and body.
public struct HTTPResponseData: Sendable {
    public let statusCode: Int
    public let headers: [String: String]
    public let body: Data

    public init(statusCode: Int, headers: [String: String] = [:], body: Data) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
    }
}

/// The client's only network dependency: perform a GET and return the raw
/// response. Implementations must not throw for non-2xx statuses (the client
/// maps those to `BasedAgentsError`); they throw only for transport-level
/// failures, which the client maps to `BasedAgentsError.network`.
///
/// Tests substitute a stub implementation, so the whole client is
/// exercisable offline.
public protocol HTTPTransport: Sendable {
    func get(_ url: URL) async throws -> HTTPResponseData
}

/// Production transport backed by `URLSession`.
///
/// Identifies itself with a descriptive `User-Agent` and asks for JSON.
/// Redirects are left to `URLSession`'s defaults; the API answers directly.
public struct URLSessionTransport: HTTPTransport {
    private let session: URLSession
    private let userAgent: String
    private let timeout: TimeInterval

    public init(
        session: URLSession = .shared,
        userAgent: String = "basedagents-sdk-swift/1.0",
        timeout: TimeInterval = 30
    ) {
        self.session = session
        self.userAgent = userAgent
        self.timeout = timeout
    }

    public func get(_ url: URL) async throws -> HTTPResponseData {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = timeout
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        let (data, response): (Data, URLResponse) = try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: request) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let data, let response {
                    continuation.resume(returning: (data, response))
                } else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                }
            }
            task.resume()
        }

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        var headers: [String: String] = [:]
        for (key, value) in http.allHeaderFields {
            headers[String(describing: key)] = String(describing: value)
        }
        return HTTPResponseData(statusCode: http.statusCode, headers: headers, body: data)
    }
}
