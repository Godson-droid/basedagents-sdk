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
/// Implementations must also honour Swift task cancellation: when the
/// calling task is cancelled, the in-flight request must be abandoned
/// promptly and a `CancellationError` must surface.
public protocol HTTPTransport: Sendable {
    func get(_ url: URL) async throws -> HTTPResponseData
}

/// Holds the in-flight data task so a cancellation arriving before, during
/// or after task creation still cancels it exactly once.
private final class DataTaskBox: @unchecked Sendable {
    private let lock = NSLock()
    private var task: URLSessionDataTask?
    private var cancelled = false

    func set(_ task: URLSessionDataTask) {
        lock.lock()
        self.task = task
        let wasCancelled = cancelled
        lock.unlock()
        if wasCancelled { task.cancel() }
    }

    func cancel() {
        lock.lock()
        cancelled = true
        let task = self.task
        lock.unlock()
        task?.cancel()
    }
}

/// Production transport backed by `URLSession`.
///
/// Identifies itself with a descriptive `User-Agent` and asks for JSON.
/// Redirects are left to `URLSession`'s defaults; the API answers directly.
///
/// Cancellation: the underlying `URLSessionDataTask` is cancelled as soon
/// as the awaiting Swift task is cancelled, so a call against a stalled
/// server ends immediately with `CancellationError` instead of running
/// until the request timeout.
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

        let box = DataTaskBox()
        let (data, response): (Data, URLResponse) = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(Data, URLResponse), Error>) in
                let task = session.dataTask(with: request) { data, response, error in
                    if let error {
                        if let urlError = error as? URLError, urlError.code == .cancelled {
                            continuation.resume(throwing: CancellationError())
                        } else {
                            continuation.resume(throwing: error)
                        }
                    } else if let data, let response {
                        continuation.resume(returning: (data, response))
                    } else {
                        continuation.resume(throwing: URLError(.badServerResponse))
                    }
                }
                box.set(task)
                task.resume()
            }
        } onCancel: {
            box.cancel()
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
