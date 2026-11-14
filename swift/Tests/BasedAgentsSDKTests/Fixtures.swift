import Foundation
@testable import BasedAgentsSDK

/// Loads a recorded API response from the shared fixture corpus bundled
/// with the test target.
enum Fixtures {
    static func data(_ name: String) throws -> Data {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json") else {
            throw FixtureError.missingFixture(name)
        }
        return try Data(contentsOf: url)
    }

    static func decode<T: Decodable>(_ name: String, as type: T.Type) throws -> T {
        try JSONDecoder().decode(T.self, from: data(name))
    }

    enum FixtureError: Error { case missingFixture(String) }
}

/// An `HTTPTransport` stub driven by a handler over the request URL.
/// Records every requested URL so tests can assert paths and query params.
final class StubTransport: HTTPTransport, @unchecked Sendable {
    private(set) var requestedURLs: [URL] = []
    private let handler: (URL) throws -> HTTPResponseData

    init(handler: @escaping (URL) throws -> HTTPResponseData) {
        self.handler = handler
    }

    func get(_ url: URL) async throws -> HTTPResponseData {
        requestedURLs.append(url)
        return try handler(url)
    }
}

func transportReturning(status: Int, body: String, headers: [String: String] = [:]) -> StubTransport {
    StubTransport { _ in HTTPResponseData(statusCode: status, headers: headers, body: Data(body.utf8)) }
}

func transportServing(fixture: String, status: Int = 200) throws -> StubTransport {
    let data = try Fixtures.data(fixture)
    return StubTransport { _ in HTTPResponseData(statusCode: status, body: data) }
}

struct StubNetworkError: Error {}

func failingTransport() -> StubTransport {
    StubTransport { _ in throw StubNetworkError() }
}
