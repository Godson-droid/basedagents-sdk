import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import BasedAgentsSDK

/// Exercises `APIClient` end-to-end (minus the wire) through a stub
/// transport serving the recorded fixtures: URL construction, query
/// params, pagination aggregation and the error taxonomy.
final class ClientTests: XCTestCase {

    private func makeClient(_ transport: HTTPTransport) -> APIClient {
        APIClient(
            transport: transport,
            baseURL: URL(string: "https://api.example.test/v1")!,
            descriptorURL: URL(string: "https://example.test/.well-known/basedagents.json")!,
            minRequestInterval: 0
        )
    }

    func testListTasksBuildsPathWithQueryParams() async throws {
        let transport = try transportServing(fixture: "tasks_open")
        let page = try await makeClient(transport).listTasks(status: "open", limit: 20)
        XCTAssertEqual(page.tasks.count, 16)
        XCTAssertEqual(
            transport.requestedURLs.map(\.absoluteString),
            ["https://api.example.test/v1/tasks?status=open&limit=20"]
        )
    }

    func testListTasksEncodesFiltersAndPaging() async throws {
        let transport = try transportServing(fixture: "tasks_category_code")
        _ = try await makeClient(transport).listTasks(category: "code", limit: 10, offset: 5)
        XCTAssertEqual(
            transport.requestedURLs.map(\.absoluteString),
            ["https://api.example.test/v1/tasks?category=code&limit=10&offset=5"]
        )
    }

    func testGetTaskHitsDetailPath() async throws {
        let transport = try transportServing(fixture: "task_detail_sdk")
        let detail = try await makeClient(transport).getTask("task_zFihEF6ij4a3tUP0ENWo1")
        XCTAssertEqual(detail.task.id, "task_zFihEF6ij4a3tUP0ENWo1")
        XCTAssertEqual(
            transport.requestedURLs.map(\.absoluteString),
            ["https://api.example.test/v1/tasks/task_zFihEF6ij4a3tUP0ENWo1"]
        )
    }

    func testReceiptsAndPaymentPaths() async throws {
        let receiptsTransport = try transportServing(fixture: "task_receipts_sdk")
        let receipts = try await makeClient(receiptsTransport).listReceipts(taskId: "task_X")
        XCTAssertEqual(receipts.receipts.count, 2)
        XCTAssertEqual(
            receiptsTransport.requestedURLs.map(\.absoluteString),
            ["https://api.example.test/v1/tasks/task_X/receipts"]
        )

        let receiptTransport = try transportServing(fixture: "task_receipt_sdk")
        let receipt = try await makeClient(receiptTransport).getReceipt(taskId: "task_X")
        XCTAssertEqual(receipt.receipt.id, "rcpt_kTFsms4hSzOt7yEgcs0oI")
        XCTAssertEqual(
            receiptTransport.requestedURLs.map(\.absoluteString),
            ["https://api.example.test/v1/tasks/task_X/receipt"]
        )

        let paymentTransport = try transportServing(fixture: "task_payment_settled")
        let payment = try await makeClient(paymentTransport).getPayment(taskId: "task_X")
        XCTAssertEqual(payment.payment.status, "settled")
        XCTAssertEqual(
            paymentTransport.requestedURLs.map(\.absoluteString),
            ["https://api.example.test/v1/tasks/task_X/payment"]
        )
    }

    func testAgentEndpointsBuildExpectedPaths() async throws {
        let profile = try transportServing(fixture: "agent_jarvis")
        let agent = try await makeClient(profile).getAgent("ag_1")
        XCTAssertEqual(agent.name, "Jarvis")
        XCTAssertEqual(profile.requestedURLs.map(\.absoluteString), ["https://api.example.test/v1/agents/ag_1"])

        let reputation = try transportServing(fixture: "agent_reputation_jarvis")
        _ = try await makeClient(reputation).getReputation(agentId: "ag_1")
        XCTAssertEqual(
            reputation.requestedURLs.map(\.absoluteString),
            ["https://api.example.test/v1/agents/ag_1/reputation"]
        )

        let wallet = try transportServing(fixture: "agent_wallet_jarvis")
        _ = try await makeClient(wallet).getWallet(agentId: "ag_1")
        XCTAssertEqual(
            wallet.requestedURLs.map(\.absoluteString),
            ["https://api.example.test/v1/agents/ag_1/wallet"]
        )

        let search = try transportServing(fixture: "agents_search_jarvis")
        let results = try await makeClient(search).searchAgents(query: "Jarvis")
        XCTAssertEqual(results.agents.count, 5)
        XCTAssertEqual(
            search.requestedURLs.map(\.absoluteString),
            ["https://api.example.test/v1/agents/search?q=Jarvis"]
        )
    }

    func testServiceEndpointsBuildExpectedPaths() async throws {
        let status = try transportServing(fixture: "status")
        let statusValue = try await makeClient(status).status()
        XCTAssertEqual(statusValue.chain?.height, 2019)
        XCTAssertEqual(status.requestedURLs.map(\.absoluteString), ["https://api.example.test/v1/status"])

        let health = try transportServing(fixture: "health")
        let healthValue = try await makeClient(health).health()
        XCTAssertEqual(healthValue.status, "ok")
        XCTAssertEqual(health.requestedURLs.map(\.absoluteString), ["https://api.example.test/v1/health"])

        let chain = try transportServing(fixture: "chain_latest")
        let entry = try await makeClient(chain).chainLatest()
        XCTAssertEqual(entry.sequence, 2019)
        XCTAssertEqual(chain.requestedURLs.map(\.absoluteString), ["https://api.example.test/v1/chain/latest"])

        let descriptor = try transportServing(fixture: "service_descriptor")
        let descriptorValue = try await makeClient(descriptor).serviceDescriptor()
        XCTAssertEqual(descriptorValue.name, "BasedAgents")
        XCTAssertEqual(
            descriptor.requestedURLs.map(\.absoluteString),
            ["https://example.test/.well-known/basedagents.json"]
        )
    }

    func testTasksStreamAggregatesPagesUntilShortPage() async throws {
        let all = try Fixtures.decode("tasks_open", as: TaskListEnvelope.self).tasks
        let fullPage = try Fixtures.data("tasks_open")
        let transport = StubTransport { url in
            let offset = url.query?.components(separatedBy: "&")
                .first(where: { $0.hasPrefix("offset=") })?
                .replacingOccurrences(of: "offset=", with: "") ?? "0"
            if offset == "0" {
                return HTTPResponseData(statusCode: 200, body: fullPage)
            }
            return HTTPResponseData(statusCode: 200, body: Data(#"{"ok":true,"tasks":[]}"#.utf8))
        }
        var ids: [String] = []
        for try await task in makeClient(transport).tasksStream(status: "open", pageSize: 16) {
            ids.append(task.id)
        }
        XCTAssertEqual(ids, all.map(\.id))
        XCTAssertEqual(transport.requestedURLs.count, 2)
        XCTAssertTrue(transport.requestedURLs[0].absoluteString.contains("offset=0"))
        XCTAssertTrue(transport.requestedURLs[1].absoluteString.contains("offset=16"))
    }

    func testTasksStreamStopsAfterPartialPage() async throws {
        let pageData = try Fixtures.data("tasks_open_page")
        let transport = StubTransport { _ in HTTPResponseData(statusCode: 200, body: pageData) }
        var count = 0
        for try await _ in makeClient(transport).tasksStream(pageSize: 10) { count += 1 }
        XCTAssertEqual(count, 5)
        XCTAssertEqual(transport.requestedURLs.count, 1)
    }

    func testSettledStreamFollowsCursorToTheEnd() async throws {
        let firstPage = try Fixtures.data("tasks_settled")
        let transport = StubTransport { url in
            if url.absoluteString.contains("cursor=") {
                return HTTPResponseData(statusCode: 200, body: Data(#"{"ok":true,"tasks":[],"next_cursor":null}"#.utf8))
            }
            return HTTPResponseData(statusCode: 200, body: firstPage)
        }
        var count = 0
        for try await _ in makeClient(transport).settledStream(limit: 10) { count += 1 }
        XCTAssertEqual(count, 10)
        XCTAssertEqual(transport.requestedURLs.count, 2)
        XCTAssertTrue(
            transport.requestedURLs[1].absoluteString.contains(
                "cursor=2026-10-05T23%3A10%3A24.247Z%7Ctask_oB39BzpFOmlyiWa13zzfT"
            )
        )
    }

    func testSettledListCarriesLimitAndWindow() async throws {
        let transport = try transportServing(fixture: "tasks_settled")
        _ = try await makeClient(transport).listSettled(limit: 10, windowDays: 30)
        XCTAssertEqual(
            transport.requestedURLs.map(\.absoluteString),
            ["https://api.example.test/v1/tasks/settled?limit=10&window_days=30"]
        )
    }

    func testSearchAgentsSendsPageParameter() async throws {
        let transport = try transportServing(fixture: "agents_search_jarvis")
        _ = try await makeClient(transport).searchAgents(query: "Jarvis", limit: 20, page: 2)
        XCTAssertEqual(
            transport.requestedURLs.map(\.absoluteString),
            ["https://api.example.test/v1/agents/search?q=Jarvis&limit=20&page=2"]
        )
    }

    func testAgentsStreamAggregatesEverySearchPage() async throws {
        func pageJSON(ids: [String], page: Int, totalPages: Int) -> Data {
            let agents = ids.map { #"{"agent_id":"\#($0)","name":"Agent \#($0)"}"# }.joined(separator: ",")
            return Data(#"{"agents":[\#(agents)],"pagination":{"page":\#(page),"limit":2,"total":3,"total_pages":\#(totalPages)}}"#.utf8)
        }
        let transport = StubTransport { url in
            if url.absoluteString.contains("page=2") {
                return HTTPResponseData(statusCode: 200, body: pageJSON(ids: ["ag_3"], page: 2, totalPages: 2))
            }
            return HTTPResponseData(statusCode: 200, body: pageJSON(ids: ["ag_1", "ag_2"], page: 1, totalPages: 2))
        }
        var ids: [String] = []
        for try await agent in makeClient(transport).agentsStream(query: "a", pageSize: 2) {
            ids.append(agent.id)
        }
        XCTAssertEqual(ids, ["ag_1", "ag_2", "ag_3"])
        XCTAssertEqual(transport.requestedURLs.count, 2)
        XCTAssertTrue(transport.requestedURLs[0].absoluteString.contains("page=1"))
        XCTAssertTrue(transport.requestedURLs[1].absoluteString.contains("page=2"))
    }

    func testTasksStreamClampsOversizedPageSizeToAPIMaximum() async throws {
        let transport = transportReturning(status: 200, body: #"{"ok":true,"tasks":[]}"#)
        var count = 0
        for try await _ in makeClient(transport).tasksStream(pageSize: 500) { count += 1 }
        XCTAssertEqual(count, 0)
        XCTAssertEqual(transport.requestedURLs.count, 1)
        let url = try XCTUnwrap(transport.requestedURLs.first?.absoluteString)
        XCTAssertTrue(url.contains("limit=100"), "expected limit=100 in \(url)")
    }

    func testChainRangeAndEntryPaths() async throws {
        let range = try transportServing(fixture: "chain_range")
        let entries = try await makeClient(range).chainEntries(from: 2015, to: 2019)
        XCTAssertEqual(entries.entries.count, 5)
        XCTAssertEqual(
            range.requestedURLs.map(\.absoluteString),
            ["https://api.example.test/v1/chain?from=2015&to=2019"]
        )

        let single = try transportServing(fixture: "chain_entry")
        let entry = try await makeClient(single).chainEntry(sequence: 2019)
        XCTAssertEqual(entry.sequence, 2019)
        XCTAssertEqual(
            single.requestedURLs.map(\.absoluteString),
            ["https://api.example.test/v1/chain/2019"]
        )
    }

    func testConsumerTaskCompilesAlongsideSDKImport() async {
        // This would not compile if the SDK still exported a `Task` model
        // shadowing Swift concurrency's `Task`.
        let task = Task { 42 }
        let value = await task.value
        XCTAssertEqual(value, 42)
    }

    func testCancelledCallAgainstStalledTransportEndsPromptly() async {
        let client = makeClient(StallingTransport())
        let task = Task { try await client.status() }
        try? await Task.sleep(nanoseconds: 100_000_000)
        let start = Date()
        task.cancel()
        do {
            _ = try await task.value
            XCTFail("expected CancellationError")
        } catch is CancellationError {
            XCTAssertLessThan(Date().timeIntervalSince(start), 1.0)
        } catch {
            XCTFail("expected CancellationError, got \(error)")
        }
    }

    func testURLSessionTransportCancellationAgainstStalledServer() async throws {
        // An in-process server that accepts the connection and then stalls
        // for 30 s: the request is genuinely in flight when cancelled.
        let server = StalledServer()
        try server.start()
        defer { server.stop() }

        let client = APIClient(
            transport: URLSessionTransport(session: URLSession(configuration: .ephemeral)),
            baseURL: URL(string: "http://127.0.0.1:\(server.port)/v1")!,
            minRequestInterval: 0
        )
        let task = Task { try await client.status() }
        try await Task.sleep(nanoseconds: 200_000_000)
        let start = Date()
        task.cancel()
        do {
            _ = try await task.value
            XCTFail("expected CancellationError")
        } catch is CancellationError {
            XCTAssertLessThan(Date().timeIntervalSince(start), 1.0)
        } catch {
            XCTFail("expected CancellationError, got \(error)")
        }
    }

    // MARK: - Error taxonomy

    func testNotFoundMapsWithAPIError() async throws {
        let transport = try transportServing(fixture: "error_task_not_found", status: 404)
        do {
            _ = try await makeClient(transport).getTask("task_0000000000000000000000")
            XCTFail("expected NotFound")
        } catch let BasedAgentsError.notFound(code, message) {
            XCTAssertEqual(code, "not_found")
            XCTAssertEqual(message, "Task not found")
        }
    }

    func testUnauthorizedMapsFrom401() async throws {
        let transport = try transportServing(fixture: "task_submission_sdk", status: 401)
        do {
            _ = try await makeClient(transport).getTask("task_X")
            XCTFail("expected Unauthorized")
        } catch let BasedAgentsError.unauthorized(statusCode, code, _) {
            XCTAssertEqual(statusCode, 401)
            XCTAssertEqual(code, "unauthorized")
        }
    }

    func testUnauthorizedMapsFrom403() async throws {
        let transport = transportReturning(status: 403, body: #"{"error":"forbidden","message":"No"}"#)
        do {
            _ = try await makeClient(transport).status()
            XCTFail("expected Unauthorized")
        } catch let BasedAgentsError.unauthorized(statusCode, code, _) {
            XCTAssertEqual(statusCode, 403)
            XCTAssertEqual(code, "forbidden")
        }
    }

    func testRateLimitedMapsWithRetryAfter() async throws {
        let transport = transportReturning(
            status: 429,
            body: #"{"error":"rate_limited","message":"Slow down"}"#,
            headers: ["Retry-After": "7"]
        )
        do {
            _ = try await makeClient(transport).status()
            XCTFail("expected RateLimited")
        } catch let BasedAgentsError.rateLimited(code, _, retryAfterSeconds) {
            XCTAssertEqual(code, "rate_limited")
            XCTAssertEqual(retryAfterSeconds, 7)
        }
    }

    func testServerErrorMaps() async throws {
        let transport = transportReturning(status: 500, body: #"{"error":"internal","message":"Boom"}"#)
        do {
            _ = try await makeClient(transport).status()
            XCTFail("expected ServerError")
        } catch let BasedAgentsError.serverError(statusCode, code, _) {
            XCTAssertEqual(statusCode, 500)
            XCTAssertEqual(code, "internal")
        }
    }

    func testUnexpectedStatusMaps() async throws {
        let transport = transportReturning(status: 400, body: #"{"error":"bad_request","message":"Nope"}"#)
        do {
            _ = try await makeClient(transport).status()
            XCTFail("expected UnexpectedStatus")
        } catch let BasedAgentsError.unexpectedStatus(statusCode, _, _) {
            XCTAssertEqual(statusCode, 400)
        }
    }

    func testNonJSONErrorBodyStillMapsByStatus() async throws {
        let transport = transportReturning(status: 404, body: "not json at all")
        do {
            _ = try await makeClient(transport).getTask("task_X")
            XCTFail("expected NotFound")
        } catch let BasedAgentsError.notFound(code, message) {
            XCTAssertNil(code)
            XCTAssertNil(message)
        }
    }

    func testTransportFailureMapsToNetworkError() async throws {
        do {
            _ = try await makeClient(failingTransport()).status()
            XCTFail("expected NetworkError")
        } catch BasedAgentsError.network {
            // expected
        }
    }

    func testMalformedSuccessBodyMapsToDecodingError() async throws {
        let transport = transportReturning(status: 200, body: #"{"ok":true,"tasks":"not-a-list"}"#)
        do {
            _ = try await makeClient(transport).listTasks()
            XCTFail("expected DecodingError")
        } catch BasedAgentsError.decoding {
            // expected
        }
    }

    func testTruncatedSuccessBodyMapsToDecodingError() async throws {
        let transport = transportReturning(status: 200, body: #"{"ok":true,"tasks":["#)
        do {
            _ = try await makeClient(transport).listTasks()
            XCTFail("expected DecodingError")
        } catch BasedAgentsError.decoding {
            // expected
        }
    }
}
