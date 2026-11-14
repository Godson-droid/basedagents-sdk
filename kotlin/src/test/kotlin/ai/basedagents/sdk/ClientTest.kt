package ai.basedagents.sdk

import java.io.IOException
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.runBlocking

/**
 * Exercises [BasedAgentsClient] end-to-end (minus the wire) through a fake
 * transport serving the recorded fixtures: URL construction, query params,
 * pagination aggregation and the error taxonomy.
 */
class ClientTest {

    private fun client(transport: HttpTransport, baseUrl: String = "https://api.example.test/v1") =
        BasedAgentsClient(
            transport = transport,
            baseUrl = baseUrl,
            descriptorUrl = "https://example.test/.well-known/basedagents.json",
            minRequestIntervalMillis = 0,
        )

    @Test
    fun `listTasks builds the tasks path with query params`() = runBlocking {
        val transport = transportServing("tasks_open")
        val page = client(transport).listTasks(status = "open", limit = 20)
        assertEquals(16, page.tasks.size)
        assertEquals(
            "https://api.example.test/v1/tasks?status=open&limit=20",
            transport.requestedUrls.single(),
        )
    }

    @Test
    fun `listTasks encodes filters and paging params`() = runBlocking {
        val transport = transportServing("tasks_category_code")
        client(transport).listTasks(category = "code", limit = 10, offset = 5)
        assertEquals(
            "https://api.example.test/v1/tasks?category=code&limit=10&offset=5",
            transport.requestedUrls.single(),
        )
    }

    @Test
    fun `getTask hits the detail path`() = runBlocking {
        val transport = transportServing("task_detail_sdk")
        val detail = client(transport).getTask("task_zFihEF6ij4a3tUP0ENWo1")
        assertEquals("task_zFihEF6ij4a3tUP0ENWo1", detail.task.id)
        assertEquals(
            "https://api.example.test/v1/tasks/task_zFihEF6ij4a3tUP0ENWo1",
            transport.requestedUrls.single(),
        )
    }

    @Test
    fun `receipts and payment paths`() = runBlocking {
        val receiptsTransport = transportServing("task_receipts_sdk")
        val receipts = client(receiptsTransport).listReceipts("task_X")
        assertEquals(2, receipts.receipts.size)
        assertEquals(
            "https://api.example.test/v1/tasks/task_X/receipts",
            receiptsTransport.requestedUrls.single(),
        )

        val receiptTransport = transportServing("task_receipt_sdk")
        val receipt = client(receiptTransport).getReceipt("task_X")
        assertEquals("rcpt_kTFsms4hSzOt7yEgcs0oI", receipt.receipt.id)
        assertEquals(
            "https://api.example.test/v1/tasks/task_X/receipt",
            receiptTransport.requestedUrls.single(),
        )

        val paymentTransport = transportServing("task_payment_settled")
        val payment = client(paymentTransport).getPayment("task_X")
        assertEquals("settled", payment.payment.status)
        assertEquals(
            "https://api.example.test/v1/tasks/task_X/payment",
            paymentTransport.requestedUrls.single(),
        )
    }

    @Test
    fun `agent endpoints build expected paths`() = runBlocking {
        val profile = transportServing("agent_jarvis")
        assertEquals("Jarvis", client(profile).getAgent("ag_1").name)
        assertEquals("https://api.example.test/v1/agents/ag_1", profile.requestedUrls.single())

        val reputation = transportServing("agent_reputation_jarvis")
        client(reputation).getReputation("ag_1")
        assertEquals(
            "https://api.example.test/v1/agents/ag_1/reputation",
            reputation.requestedUrls.single(),
        )

        val wallet = transportServing("agent_wallet_jarvis")
        client(wallet).getWallet("ag_1")
        assertEquals("https://api.example.test/v1/agents/ag_1/wallet", wallet.requestedUrls.single())

        val search = transportServing("agents_search_jarvis")
        val results = client(search).searchAgents(query = "Jarvis")
        assertEquals(5, results.agents.size)
        assertEquals(
            "https://api.example.test/v1/agents/search?q=Jarvis",
            search.requestedUrls.single(),
        )
    }

    @Test
    fun `status health chain and descriptor paths`() = runBlocking {
        val status = transportServing("status")
        assertEquals(2019L, client(status).status().chain?.height)
        assertEquals("https://api.example.test/v1/status", status.requestedUrls.single())

        val health = transportServing("health")
        assertEquals("ok", client(health).health().status)
        assertEquals("https://api.example.test/v1/health", health.requestedUrls.single())

        val chain = transportServing("chain_latest")
        assertEquals(2019L, client(chain).chainLatest().sequence)
        assertEquals("https://api.example.test/v1/chain/latest", chain.requestedUrls.single())

        val descriptor = transportServing("service_descriptor")
        assertEquals("BasedAgents", client(descriptor).serviceDescriptor().name)
        assertEquals(
            "https://example.test/.well-known/basedagents.json",
            descriptor.requestedUrls.single(),
        )
    }

    @Test
    fun `tasksFlow aggregates offset pages until a short page`() = runBlocking {
        val all = Fixtures.decode<TaskListEnvelope>("tasks_open").tasks
        val transport = FakeTransport { url ->
            val offset = Regex("""offset=(\d+)""").find(url)?.groupValues?.get(1)?.toInt() ?: 0
            if (offset == 0) HttpResponse(200, emptyMap(), Fixtures.text("tasks_open"))
            else HttpResponse(200, emptyMap(), """{"ok":true,"tasks":[]}""")
        }
        // pageSize 16: first page is full (16), second is empty -> stop.
        val ids = client(transport).tasksFlow(status = "open", pageSize = 16).toList().map { it.id }
        assertEquals(all.map { it.id }, ids)
        assertEquals(2, transport.requestedUrls.size)
        assertTrue(transport.requestedUrls[0].contains("offset=0"))
        assertTrue(transport.requestedUrls[1].contains("offset=16"))
    }

    @Test
    fun `tasksFlow stops after a partial page`() = runBlocking {
        val transport = FakeTransport { url ->
            when {
                url.contains("offset=0") -> HttpResponse(200, emptyMap(), Fixtures.text("tasks_open_page"))
                else -> HttpResponse(200, emptyMap(), """{"ok":true,"tasks":[]}""")
            }
        }
        val tasks = client(transport).tasksFlow(pageSize = 10).toList()
        assertEquals(5, tasks.size) // 5 < pageSize 10 -> exactly one request
        assertEquals(1, transport.requestedUrls.size)
    }

    @Test
    fun `settledFlow follows the cursor to the end`() = runBlocking {
        val firstPage = Fixtures.text("tasks_settled")
        val secondPage = """{"ok":true,"stats":null,"tasks":[],"next_cursor":null}"""
        val transport = FakeTransport { url ->
            if (url.contains("cursor=")) HttpResponse(200, emptyMap(), secondPage)
            else HttpResponse(200, emptyMap(), firstPage)
        }
        val tasks = client(transport).settledFlow(limit = 10).toList()
        assertEquals(10, tasks.size)
        assertEquals(2, transport.requestedUrls.size)
        assertTrue(
            transport.requestedUrls[1].contains(
                "cursor=2026-10-05T23%3A10%3A24.247Z%7Ctask_oB39BzpFOmlyiWa13zzfT",
            ),
        )
    }

    @Test
    fun `settled list request carries limit and window`() = runBlocking {
        val transport = transportServing("tasks_settled")
        client(transport).listSettled(limit = 10, windowDays = 30)
        assertEquals(
            "https://api.example.test/v1/tasks/settled?limit=10&window_days=30",
            transport.requestedUrls.single(),
        )
    }

    // -- Error taxonomy -----------------------------------------------------

    @Test
    fun `404 maps to NotFound carrying the api error`() = runBlocking {
        val transport = transportServing("error_task_not_found", status = 404)
        val error = assertFailsWith<BasedAgentsException.NotFound> {
            client(transport).getTask("task_0000000000000000000000")
        }
        assertEquals("not_found", error.code)
        assertEquals("Task not found", error.apiMessage)
        assertEquals(404, error.statusCode)
    }

    @Test
    fun `401 maps to Unauthorized`() = runBlocking {
        val transport = transportServing("task_submission_sdk", status = 401)
        val error = assertFailsWith<BasedAgentsException.Unauthorized> {
            client(transport).getTask("task_X")
        }
        assertEquals("unauthorized", error.code)
        assertEquals(401, error.statusCode)
    }

    @Test
    fun `403 maps to Unauthorized`() = runBlocking {
        val transport = transportReturning(403, """{"error":"forbidden","message":"No"}""")
        val error = assertFailsWith<BasedAgentsException.Unauthorized> {
            client(transport).status()
        }
        assertEquals(403, error.statusCode)
    }

    @Test
    fun `429 maps to RateLimited with retry-after`() = runBlocking {
        val transport = transportReturning(
            429,
            """{"error":"rate_limited","message":"Slow down"}""",
            headers = mapOf("Retry-After" to listOf("7")),
        )
        val error = assertFailsWith<BasedAgentsException.RateLimited> {
            client(transport).status()
        }
        assertEquals(7L, error.retryAfterSeconds)
        assertEquals("rate_limited", error.code)
    }

    @Test
    fun `500 maps to ServerError`() = runBlocking {
        val transport = transportReturning(500, """{"error":"internal","message":"Boom"}""")
        val error = assertFailsWith<BasedAgentsException.ServerError> {
            client(transport).status()
        }
        assertEquals(500, error.statusCode)
    }

    @Test
    fun `other statuses map to UnexpectedStatus`() = runBlocking {
        val transport = transportReturning(400, """{"error":"bad_request","message":"Nope"}""")
        val error = assertFailsWith<BasedAgentsException.UnexpectedStatus> {
            client(transport).status()
        }
        assertEquals(400, error.statusCode)
    }

    @Test
    fun `error body that is not json still maps by status`() = runBlocking {
        val transport = transportReturning(404, "not json at all")
        val error = assertFailsWith<BasedAgentsException.NotFound> {
            client(transport).getTask("task_X")
        }
        assertEquals(null, error.code)
    }

    @Test
    fun `transport failure maps to NetworkError`() = runBlocking {
        val error = assertFailsWith<BasedAgentsException.NetworkError> {
            client(failingTransport()).status()
        }
        assertTrue(error.cause is IOException)
    }

    @Test
    fun `malformed success body maps to DecodeError`() {
        runBlocking {
            val transport = transportReturning(200, """{"ok":true,"tasks":"not-a-list"}""")
            assertFailsWith<BasedAgentsException.DecodeError> {
                client(transport).listTasks()
            }
        }
    }

    @Test
    fun `truncated success body maps to DecodeError`() {
        runBlocking {
            val transport = transportReturning(200, """{"ok":true,"tasks":[""")
            assertFailsWith<BasedAgentsException.DecodeError> {
                client(transport).listTasks()
            }
        }
    }
}
