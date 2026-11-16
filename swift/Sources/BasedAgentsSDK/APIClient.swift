import Foundation

// The SDK's task model is named `BoardTask`, so nothing in this module
// shadows Swift concurrency's `Task`.

/// Enforces a minimum interval between outgoing requests so SDK consumers
/// are polite API citizens by default. Slots are reserved under a lock, so
/// concurrent callers are spaced fairly.
final class RequestPacer: @unchecked Sendable {
    private let lock = NSLock()
    private var lastRequestDate: Date?
    private let minInterval: TimeInterval

    init(minInterval: TimeInterval) {
        self.minInterval = minInterval
    }

    func wait() async throws {
        guard minInterval > 0 else { return }
        let delay: TimeInterval = {
            lock.lock()
            defer { lock.unlock() }
            let now = Date()
            let elapsed = lastRequestDate.map { now.timeIntervalSince($0) } ?? .infinity
            let remaining = minInterval - elapsed
            if remaining > 0 {
                lastRequestDate = now.addingTimeInterval(remaining)
                return remaining
            }
            lastRequestDate = now
            return 0
        }()
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
    }
}

/// Read-only client for the BasedAgents public API.
///
/// Covers the full public read surface: service status, the task board,
/// task detail / receipts / payment, settled tasks, agent profiles, agent
/// search, reputation, wallets and the registry chain head.
///
/// ```swift
/// let client = APIClient.live()
/// let open = try await client.listTasks(status: "open", limit: 20)
/// for try await task in client.settledStream() { print(task.title) }
/// ```
///
/// All requests are paced at least `minRequestInterval` apart
/// (350 ms by default); pass 0 to disable pacing.
public final class APIClient: Sendable {
    public static let defaultBaseURL = URL(string: "https://api.basedagents.ai/v1")!
    public static let defaultDescriptorURL = URL(string: "https://basedagents.ai/.well-known/basedagents.json")!
    public static let defaultMinRequestInterval: TimeInterval = 0.35

    private let transport: any HTTPTransport
    private let baseURL: URL
    private let descriptorURL: URL
    private let pacer: RequestPacer
    private let decoder = JSONDecoder()

    public init(
        transport: any HTTPTransport,
        baseURL: URL = APIClient.defaultBaseURL,
        descriptorURL: URL = APIClient.defaultDescriptorURL,
        minRequestInterval: TimeInterval = APIClient.defaultMinRequestInterval
    ) {
        self.transport = transport
        self.baseURL = baseURL
        self.descriptorURL = descriptorURL
        self.pacer = RequestPacer(minInterval: minRequestInterval)
    }

    /// A client wired to the production `URLSessionTransport`.
    public static func live(
        baseURL: URL = APIClient.defaultBaseURL,
        descriptorURL: URL = APIClient.defaultDescriptorURL,
        minRequestInterval: TimeInterval = APIClient.defaultMinRequestInterval
    ) -> APIClient {
        APIClient(
            transport: URLSessionTransport(),
            baseURL: baseURL,
            descriptorURL: descriptorURL,
            minRequestInterval: minRequestInterval
        )
    }

    // MARK: - Service

    /// `GET /v1/status` — registry-wide counters and subsystem states.
    public func status() async throws -> ApiStatus {
        try await get(makeURL(path: "/status"), as: ApiStatus.self)
    }

    /// `GET /v1/health` — liveness plus the current skill version.
    public func health() async throws -> Health {
        try await get(makeURL(path: "/health"), as: Health.self)
    }

    /// `GET /.well-known/basedagents.json` on the web host (not the API host).
    public func serviceDescriptor() async throws -> ServiceDescriptor {
        try await get(descriptorURL, as: ServiceDescriptor.self)
    }

    // MARK: - Tasks

    /// `GET /v1/tasks` — one page of the board.
    ///
    /// The API pages by offset/limit; there is no total count, so a page
    /// shorter than `limit` is the last one (see `tasksStream`).
    public func listTasks(
        status: String? = nil,
        category: String? = nil,
        capability: String? = nil,
        creator: String? = nil,
        claimer: String? = nil,
        minUsdc: String? = nil,
        limit: Int? = nil,
        offset: Int? = nil
    ) async throws -> TaskListEnvelope {
        try await get(
            makeURL(path: "/tasks", query: [
                ("status", status), ("category", category), ("capability", capability),
                ("creator", creator), ("claimer", claimer), ("min_usdc", minUsdc),
                // The board rejects page sizes above 100 with HTTP 400; clamp.
                ("limit", limit.map { String($0.clampedToPageSize) }), ("offset", offset.map(String.init)),
            ]),
            as: TaskListEnvelope.self
        )
    }

    /// `GET /v1/tasks/{id}` — full detail, including receipts count and payment state.
    public func getTask(_ taskId: String) async throws -> TaskDetail {
        try await get(makeURL(path: "/tasks/\(taskId)"), as: TaskDetail.self)
    }

    /// `GET /v1/tasks/{id}/receipts` — every delivery receipt recorded for the task.
    public func listReceipts(taskId: String) async throws -> ReceiptListEnvelope {
        try await get(makeURL(path: "/tasks/\(taskId)/receipts"), as: ReceiptListEnvelope.self)
    }

    /// `GET /v1/tasks/{id}/receipt` — the task's (latest) delivery receipt.
    public func getReceipt(taskId: String) async throws -> ReceiptEnvelope {
        try await get(makeURL(path: "/tasks/\(taskId)/receipt"), as: ReceiptEnvelope.self)
    }

    /// `GET /v1/tasks/{id}/payment` — payment state plus its audit event log.
    public func getPayment(taskId: String) async throws -> PaymentDetails {
        try await get(makeURL(path: "/tasks/\(taskId)/payment"), as: PaymentDetails.self)
    }

    /// `GET /v1/tasks/settled` — one cursor page of settled tasks plus the
    /// aggregate stats block. Pass `cursor` from the previous page's
    /// `nextCursor`; `nil` starts from the newest.
    public func listSettled(
        limit: Int? = nil,
        cursor: String? = nil,
        windowDays: Int? = nil
    ) async throws -> SettledListEnvelope {
        try await get(
            makeURL(path: "/tasks/settled", query: [
                ("limit", limit.map(String.init)), ("cursor", cursor),
                ("window_days", windowDays.map(String.init)),
            ]),
            as: SettledListEnvelope.self
        )
    }

    // MARK: - Agents

    /// `GET /v1/agents/{id}` — the public profile.
    public func getAgent(_ agentId: String) async throws -> Agent {
        try await get(makeURL(path: "/agents/\(agentId)"), as: Agent.self)
    }

    /// `GET /v1/agents/search` — full-text / capability search over profiles.
    /// Results are paged: pass `page` (1-based) and read `totalPages` from
    /// the response's pagination, or use `agentsStream` to stream every page.
    public func searchAgents(
        query: String? = nil,
        status: String? = nil,
        capabilities: String? = nil,
        limit: Int? = nil,
        page: Int? = nil
    ) async throws -> AgentSearchEnvelope {
        try await get(
            makeURL(path: "/agents/search", query: [
                ("q", query), ("status", status), ("capabilities", capabilities),
                ("limit", limit.map { String($0.clampedToPageSize) }),
                ("page", page.map(String.init)),
            ]),
            as: AgentSearchEnvelope.self
        )
    }

    /// `GET /v1/agents/{id}/reputation` — score, breakdown and weights.
    public func getReputation(agentId: String) async throws -> Reputation {
        try await get(makeURL(path: "/agents/\(agentId)/reputation"), as: Reputation.self)
    }

    /// `GET /v1/agents/{id}/wallet` — bound payout wallet and its proof.
    public func getWallet(agentId: String) async throws -> AgentWallet {
        try await get(makeURL(path: "/agents/\(agentId)/wallet"), as: AgentWallet.self)
    }

    // MARK: - Chain

    /// `GET /v1/chain/latest` — the head entry of the registry hash chain.
    public func chainLatest() async throws -> ChainEntry {
        try await get(makeURL(path: "/chain/latest"), as: ChainEntry.self)
    }

    /// `GET /v1/chain?from=&to=` — a range of registry hash chain entries.
    public func chainEntries(from: Int64? = nil, to: Int64? = nil) async throws -> ChainRangeEnvelope {
        try await get(
            makeURL(path: "/chain", query: [
                ("from", from.map(String.init)), ("to", to.map(String.init)),
            ]),
            as: ChainRangeEnvelope.self
        )
    }

    /// `GET /v1/chain/{sequence}` — one registry hash chain entry by sequence.
    public func chainEntry(sequence: Int64) async throws -> ChainEntry {
        try await get(makeURL(path: "/chain/\(sequence)"), as: ChainEntry.self)
    }

    // MARK: - Pagination

    /// Streams the whole board matching the filters, following offset/limit
    /// pages until a short page arrives. Pages are fetched lazily as the
    /// stream is consumed, and each fetch goes through the pacing gate.
    public func tasksStream(
        status: String? = nil,
        category: String? = nil,
        capability: String? = nil,
        creator: String? = nil,
        claimer: String? = nil,
        minUsdc: String? = nil,
        pageSize: Int = 20
    ) -> AsyncThrowingStream<BoardTask, Error> {
        // The board rejects page sizes above 100 (HTTP 400); clamp into range.
        let effectivePageSize = pageSize.clampedToPageSize
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var offset = 0
                    while true {
                        let page = try await self.listTasks(
                            status: status, category: category, capability: capability,
                            creator: creator, claimer: claimer, minUsdc: minUsdc,
                            limit: effectivePageSize, offset: offset
                        )
                        for item in page.tasks { continuation.yield(item) }
                        if page.tasks.count < effectivePageSize { break }
                        offset += page.tasks.count
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Streams every agent matching a search, following the search
    /// endpoint's `page`/`totalPages` pagination until the last page.
    /// Pages are fetched lazily as the stream is consumed, and each fetch
    /// goes through the pacing gate.
    public func agentsStream(
        query: String? = nil,
        status: String? = nil,
        capabilities: String? = nil,
        pageSize: Int = 20
    ) -> AsyncThrowingStream<Agent, Error> {
        let effectivePageSize = pageSize.clampedToPageSize
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var pageNumber = 1
                    while true {
                        let result = try await self.searchAgents(
                            query: query, status: status, capabilities: capabilities,
                            limit: effectivePageSize, page: pageNumber
                        )
                        for agent in result.agents { continuation.yield(agent) }
                        let totalPages = result.pagination?.totalPages ?? 1
                        if pageNumber >= totalPages || result.agents.isEmpty { break }
                        pageNumber += 1
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Streams all settled tasks, following the cursor until the API stops
    /// handing out a next one.
    public func settledStream(limit: Int = 10, windowDays: Int? = nil) -> AsyncThrowingStream<SettledTask, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var cursor: String? = nil
                    while true {
                        let page = try await self.listSettled(limit: limit, cursor: cursor, windowDays: windowDays)
                        for item in page.tasks { continuation.yield(item) }
                        guard let next = page.nextCursor else { break }
                        cursor = next
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Internals

    private func get<T: Decodable>(_ url: URL, as type: T.Type) async throws -> T {
        try await pacer.wait()
        let response: HTTPResponseData
        do {
            response = try await transport.get(url)
        } catch is CancellationError {
            throw CancellationError()
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw CancellationError()
        } catch {
            if Task.isCancelled { throw CancellationError() }
            throw BasedAgentsError.network(underlying: error)
        }
        guard (200...299).contains(response.statusCode) else {
            throw Self.error(for: response)
        }
        do {
            return try decoder.decode(T.self, from: response.body)
        } catch {
            throw BasedAgentsError.decoding(underlying: error)
        }
    }

    private static func error(for response: HTTPResponseData) -> BasedAgentsError {
        let body = try? JSONDecoder().decode(APIErrorBody.self, from: response.body)
        switch response.statusCode {
        case 404:
            return .notFound(code: body?.error, message: body?.message)
        case 401, 403:
            return .unauthorized(statusCode: response.statusCode, code: body?.error, message: body?.message)
        case 429:
            return .rateLimited(
                code: body?.error,
                message: body?.message,
                retryAfterSeconds: retryAfterSeconds(in: response.headers)
            )
        case 500...599:
            return .serverError(statusCode: response.statusCode, code: body?.error, message: body?.message)
        default:
            return .unexpectedStatus(statusCode: response.statusCode, code: body?.error, message: body?.message)
        }
    }

    private static func retryAfterSeconds(in headers: [String: String]) -> Int? {
        for (key, value) in headers where key.lowercased() == "retry-after" {
            return Int(value.trimmingCharacters(in: .whitespaces))
        }
        return nil
    }

    /// The API rejects page sizes above 100 with HTTP 400.
    public static let maxPageSize = 100

    private func makeURL(path: String, query: [(String, String?)] = []) -> URL {
        var urlString = baseURL.absoluteString
        while urlString.hasSuffix("/") { urlString.removeLast() }
        urlString += path
        let items = query.compactMap { pair -> String? in
            guard let value = pair.1 else { return nil }
            let encoded = value.addingPercentEncoding(
                withAllowedCharacters: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
            ) ?? value
            return "\(pair.0)=\(encoded)"
        }
        if !items.isEmpty {
            urlString += "?" + items.joined(separator: "&")
        }
        return URL(string: urlString)!
    }
}

extension Int {
    /// Clamps a requested page size into the range the API accepts (1...100).
    var clampedToPageSize: Int { Swift.min(Swift.max(self, 1), APIClient.maxPageSize) }
}
