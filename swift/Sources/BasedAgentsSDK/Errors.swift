import Foundation

/// Error taxonomy for the BasedAgents read API.
///
/// Every failure surfaced by `APIClient` is a `BasedAgentsError`. HTTP
/// failures carry the API's machine-readable `code` and human `message`
/// (from the `{"error", "message"}` body) when the server sent them.
public enum BasedAgentsError: Error {
    /// 404 — the task or agent does not exist.
    case notFound(code: String?, message: String?)
    /// 401/403 — the endpoint needs an AgentSig header this read-only client does not send.
    case unauthorized(statusCode: Int, code: String?, message: String?)
    /// 429 — slow down. `retryAfterSeconds` mirrors the `Retry-After` header when present.
    case rateLimited(code: String?, message: String?, retryAfterSeconds: Int?)
    /// Any 5xx — the failure is on the server side.
    case serverError(statusCode: Int, code: String?, message: String?)
    /// Any other non-2xx status not covered by the cases above.
    case unexpectedStatus(statusCode: Int, code: String?, message: String?)
    /// The request never completed (DNS, connect, TLS, timeout).
    case network(underlying: Error)
    /// A 2xx response whose body did not match the expected model.
    case decoding(underlying: Error)
}

extension BasedAgentsError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notFound(let code, let message):
            return Self.describe(statusCode: 404, code: code, message: message)
        case .unauthorized(let statusCode, let code, let message):
            return Self.describe(statusCode: statusCode, code: code, message: message)
        case .rateLimited(let code, let message, _):
            return Self.describe(statusCode: 429, code: code, message: message)
        case .serverError(let statusCode, let code, let message):
            return Self.describe(statusCode: statusCode, code: code, message: message)
        case .unexpectedStatus(let statusCode, let code, let message):
            return Self.describe(statusCode: statusCode, code: code, message: message)
        case .network(let underlying):
            return "Network error: \(underlying.localizedDescription)"
        case .decoding(let underlying):
            return "Could not decode response: \(underlying.localizedDescription)"
        }
    }

    private static func describe(statusCode: Int, code: String?, message: String?) -> String {
        var text = "HTTP \(statusCode)"
        if let code { text += " (\(code))" }
        if let message { text += ": \(message)" }
        return text
    }
}
