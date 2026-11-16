import Foundation
#if canImport(Glibc)
import Glibc
#else
import Darwin
#endif
@testable import BasedAgentsSDK

/// A minimal in-process HTTP server that accepts one connection and then
/// stalls for 30 seconds without answering, used to prove that cancelling
/// a call against a stalled server returns promptly. Implemented on raw
/// sockets so tests need no external processes.
final class StalledServer: @unchecked Sendable {
    private var listenFD: Int32 = -1
    private(set) var port: UInt16 = 0

    func start() throws {
        #if canImport(Glibc)
        listenFD = socket(AF_INET, Int32(SOCK_STREAM.rawValue), 0)
        #else
        listenFD = socket(AF_INET, SOCK_STREAM, 0)
        #endif
        guard listenFD >= 0 else { throw StubNetworkError() }
        var reuse: Int32 = 1
        setsockopt(listenFD, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int32>.size))
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = 0
        addr.sin_addr = in_addr(s_addr: inet_addr("127.0.0.1"))
        let bound = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                bind(listenFD, sa, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bound == 0, listen(listenFD, 4) == 0 else { throw StubNetworkError() }
        var actual = sockaddr_in()
        var length = socklen_t(MemoryLayout<sockaddr_in>.size)
        withUnsafeMutablePointer(to: &actual) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                _ = getsockname(listenFD, sa, &length)
            }
        }
        port = UInt16(bigEndian: actual.sin_port)
        Thread.detachNewThread { [listenFD] in
            let conn = accept(listenFD, nil, nil)
            if conn >= 0 {
                Thread.sleep(forTimeInterval: 30)
                close(conn)
            }
        }
    }

    func stop() {
        if listenFD >= 0 { close(listenFD); listenFD = -1 }
    }
}

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

/// A transport that stalls for 30 seconds unless cancelled, used to prove
/// cancellation propagates promptly through the client.
struct StallingTransport: HTTPTransport {
    func get(_ url: URL) async throws -> HTTPResponseData {
        try await Task.sleep(nanoseconds: 30_000_000_000)
        return HTTPResponseData(statusCode: 200, body: Data("{}".utf8))
    }
}

struct StubNetworkError: Error {}

func failingTransport() -> StubTransport {
    StubTransport { _ in throw StubNetworkError() }
}
