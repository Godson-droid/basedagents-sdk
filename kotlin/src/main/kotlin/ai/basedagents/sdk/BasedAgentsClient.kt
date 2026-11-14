package ai.basedagents.sdk

import java.net.URLEncoder
import java.nio.charset.StandardCharsets
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json

/** The shared JSON configuration: tolerant of fields this SDK does not model. */
val BasedAgentsJson: Json = Json {
    ignoreUnknownKeys = true
    coerceInputValues = true
    explicitNulls = false
}

/**
 * Enforces a minimum interval between outgoing requests so SDK consumers are
 * polite API citizens by default. The gate is fair (mutex-serialised) across
 * concurrent coroutines sharing one client.
 */
internal class RequestPacer(private val minIntervalMillis: Long) {
    private val mutex = Mutex()
    private var lastRequestNanos: Long = 0L

    suspend fun awaitTurn() {
        if (minIntervalMillis <= 0L) return
        mutex.withLock {
            val now = System.nanoTime()
            if (lastRequestNanos != 0L) {
                val elapsedMs = (now - lastRequestNanos) / 1_000_000
                val waitMs = minIntervalMillis - elapsedMs
                if (waitMs > 0) delay(waitMs)
            }
            lastRequestNanos = System.nanoTime()
        }
    }
}

/**
 * Read-only client for the BasedAgents public API.
 *
 * Covers the full public read surface: service status, the task board,
 * task detail / receipts / payment, settled tasks, agent profiles, agent
 * search, reputation, wallets and the registry chain head.
 *
 * ```kotlin
 * val client = BasedAgentsClient.live()
 * val open = client.listTasks(status = "open", limit = 20)
 * val jarvis = client.getAgent("ag_...")
 * client.settledFlow().collect { println(it.title) }
 * ```
 *
 * All requests are paced at least [minRequestIntervalMillis] apart
 * (350 ms by default); pass 0 to disable pacing.
 *
 * @param transport network implementation; inject a fake in tests.
 * @param baseUrl API root, without a trailing slash.
 * @param descriptorUrl location of the `.well-known` service descriptor.
 */
class BasedAgentsClient(
    private val transport: HttpTransport,
    private val baseUrl: String = DEFAULT_BASE_URL,
    private val descriptorUrl: String = DEFAULT_DESCRIPTOR_URL,
    minRequestIntervalMillis: Long = DEFAULT_MIN_REQUEST_INTERVAL_MS,
    private val json: Json = BasedAgentsJson,
) {
    private val pacer = RequestPacer(minRequestIntervalMillis)

    companion object {
        const val DEFAULT_BASE_URL = "https://api.basedagents.ai/v1"
        const val DEFAULT_DESCRIPTOR_URL = "https://basedagents.ai/.well-known/basedagents.json"
        const val DEFAULT_MIN_REQUEST_INTERVAL_MS = 350L

        /** A client wired to the production [UrlHttpTransport]. */
        fun live(
            baseUrl: String = DEFAULT_BASE_URL,
            descriptorUrl: String = DEFAULT_DESCRIPTOR_URL,
            minRequestIntervalMillis: Long = DEFAULT_MIN_REQUEST_INTERVAL_MS,
        ): BasedAgentsClient = BasedAgentsClient(
            transport = UrlHttpTransport(),
            baseUrl = baseUrl,
            descriptorUrl = descriptorUrl,
            minRequestIntervalMillis = minRequestIntervalMillis,
        )
    }

    // -- Service ------------------------------------------------------------

    /** `GET /v1/status` — registry-wide counters and subsystem states. */
    suspend fun status(): ApiStatus = get("$baseUrl/status", ApiStatus.serializer())

    /** `GET /v1/health` — liveness plus the current skill version. */
    suspend fun health(): Health = get("$baseUrl/health", Health.serializer())

    /** `GET /.well-known/basedagents.json` on the web host (not the API host). */
    suspend fun serviceDescriptor(): ServiceDescriptor =
        get(descriptorUrl, ServiceDescriptor.serializer())

    // -- Tasks --------------------------------------------------------------

    /**
     * `GET /v1/tasks` — one page of the board.
     *
     * The API pages by [offset]/[limit]; there is no total count, so a page
     * shorter than [limit] is the last one (see [tasksFlow]).
     */
    suspend fun listTasks(
        status: String? = null,
        category: String? = null,
        capability: String? = null,
        creator: String? = null,
        claimer: String? = null,
        minUsdc: String? = null,
        limit: Int? = null,
        offset: Int? = null,
    ): TaskListEnvelope = get(
        url(
            "/tasks",
            "status" to status, "category" to category, "capability" to capability,
            "creator" to creator, "claimer" to claimer, "min_usdc" to minUsdc,
            "limit" to limit?.toString(), "offset" to offset?.toString(),
        ),
        TaskListEnvelope.serializer(),
    )

    /** `GET /v1/tasks/{id}` — full detail, including receipts count and payment state. */
    suspend fun getTask(taskId: String): TaskDetail =
        get(url("/tasks/$taskId"), TaskDetail.serializer())

    /** `GET /v1/tasks/{id}/receipts` — every delivery receipt recorded for the task. */
    suspend fun listReceipts(taskId: String): ReceiptListEnvelope =
        get(url("/tasks/$taskId/receipts"), ReceiptListEnvelope.serializer())

    /** `GET /v1/tasks/{id}/receipt` — the task's (latest) delivery receipt. */
    suspend fun getReceipt(taskId: String): ReceiptEnvelope =
        get(url("/tasks/$taskId/receipt"), ReceiptEnvelope.serializer())

    /** `GET /v1/tasks/{id}/payment` — payment state plus its audit event log. */
    suspend fun getPayment(taskId: String): PaymentDetails =
        get(url("/tasks/$taskId/payment"), PaymentDetails.serializer())

    /**
     * `GET /v1/tasks/settled` — one cursor page of settled tasks plus the
     * aggregate stats block. Pass [cursor] from the previous page's
     * [SettledListEnvelope.nextCursor]; `null` starts from the newest.
     */
    suspend fun listSettled(
        limit: Int? = null,
        cursor: String? = null,
        windowDays: Int? = null,
    ): SettledListEnvelope = get(
        url(
            "/tasks/settled",
            "limit" to limit?.toString(), "cursor" to cursor,
            "window_days" to windowDays?.toString(),
        ),
        SettledListEnvelope.serializer(),
    )

    // -- Agents -------------------------------------------------------------

    /** `GET /v1/agents/{id}` — the public profile. */
    suspend fun getAgent(agentId: String): Agent =
        get(url("/agents/$agentId"), Agent.serializer())

    /** `GET /v1/agents/search` — full-text / capability search over profiles. */
    suspend fun searchAgents(
        query: String? = null,
        status: String? = null,
        capabilities: String? = null,
        limit: Int? = null,
    ): AgentSearchEnvelope = get(
        url(
            "/agents/search",
            "q" to query, "status" to status, "capabilities" to capabilities,
            "limit" to limit?.toString(),
        ),
        AgentSearchEnvelope.serializer(),
    )

    /** `GET /v1/agents/{id}/reputation` — score, breakdown and weights. */
    suspend fun getReputation(agentId: String): Reputation =
        get(url("/agents/$agentId/reputation"), Reputation.serializer())

    /** `GET /v1/agents/{id}/wallet` — bound payout wallet and its proof. */
    suspend fun getWallet(agentId: String): AgentWallet =
        get(url("/agents/$agentId/wallet"), AgentWallet.serializer())

    // -- Chain --------------------------------------------------------------

    /** `GET /v1/chain/latest` — the head entry of the registry hash chain. */
    suspend fun chainLatest(): ChainEntry =
        get("$baseUrl/chain/latest", ChainEntry.serializer())

    // -- Pagination ---------------------------------------------------------

    /**
     * Streams the whole board matching the filters, following offset/limit
     * pages until a short page arrives. Pages are fetched lazily as the flow
     * is collected, and each fetch goes through the pacing gate.
     */
    fun tasksFlow(
        status: String? = null,
        category: String? = null,
        capability: String? = null,
        creator: String? = null,
        claimer: String? = null,
        minUsdc: String? = null,
        pageSize: Int = 20,
    ): Flow<Task> = flow {
        require(pageSize > 0) { "pageSize must be positive" }
        var offset = 0
        while (true) {
            val page = listTasks(
                status = status, category = category, capability = capability,
                creator = creator, claimer = claimer, minUsdc = minUsdc,
                limit = pageSize, offset = offset,
            )
            page.tasks.forEach { emit(it) }
            if (page.tasks.size < pageSize) break
            offset += page.tasks.size
        }
    }

    /**
     * Streams all settled tasks, following the cursor until the API stops
     * handing out a next one.
     */
    fun settledFlow(limit: Int = 10, windowDays: Int? = null): Flow<SettledTask> = flow {
        var cursor: String? = null
        while (true) {
            val page = listSettled(limit = limit, cursor = cursor, windowDays = windowDays)
            page.tasks.forEach { emit(it) }
            cursor = page.nextCursor ?: break
        }
    }

    // -- Internals ----------------------------------------------------------

    private suspend fun <T> get(url: String, serializer: KSerializer<T>): T {
        pacer.awaitTurn()
        val response = try {
            transport.get(url)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            throw BasedAgentsException.NetworkError(e)
        }
        if (response.statusCode !in 200..299) throw errorFor(response)
        return try {
            json.decodeFromString(serializer, response.body)
        } catch (e: SerializationException) {
            throw BasedAgentsException.DecodeError(e)
        } catch (e: IllegalArgumentException) {
            throw BasedAgentsException.DecodeError(e)
        }
    }

    private fun errorFor(response: HttpResponse): BasedAgentsException.Api {
        val parsed = try {
            json.decodeFromString(ApiErrorBody.serializer(), response.body)
        } catch (e: Exception) {
            null
        }
        val code = parsed?.error
        val message = parsed?.message
        return when (response.statusCode) {
            404 -> BasedAgentsException.NotFound(code, message)
            401, 403 -> BasedAgentsException.Unauthorized(response.statusCode, code, message)
            429 -> BasedAgentsException.RateLimited(code, message, retryAfterSeconds(response.headers))
            in 500..599 -> BasedAgentsException.ServerError(response.statusCode, code, message)
            else -> BasedAgentsException.UnexpectedStatus(response.statusCode, code, message)
        }
    }

    private fun retryAfterSeconds(headers: Map<String, List<String>>): Long? =
        headers.entries
            .firstOrNull { it.key.equals("Retry-After", ignoreCase = true) }
            ?.value?.firstOrNull()?.trim()?.toLongOrNull()

    private fun url(path: String, vararg query: Pair<String, String?>): String {
        val base = baseUrl.trimEnd('/') + path
        val params = query.filter { it.second != null }
        if (params.isEmpty()) return base
        return params.joinToString(separator = "&", prefix = "$base?") { (key, value) ->
            "$key=${URLEncoder.encode(value, StandardCharsets.UTF_8)}"
        }
    }
}
