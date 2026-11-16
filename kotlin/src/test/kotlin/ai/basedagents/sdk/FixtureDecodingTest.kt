package ai.basedagents.sdk

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * Parses every recorded fixture through the typed models and asserts the
 * fields a consumer would rely on. These are the exact bytes the Swift suite
 * parses too, which is what makes the two implementations provably equivalent.
 */
class FixtureDecodingTest {

    @Test
    fun `status fixture decodes with registry counters`() {
        val status = Fixtures.decode<ApiStatus>("status")
        assertEquals("operational", status.status)
        assertEquals("0.1.0", status.version)
        assertEquals(430, status.dbLatencyMs)
        assertEquals(1185, status.agents?.total)
        assertEquals(2019L, status.chain?.height)
        assertEquals(16, status.tasks?.open)
        assertEquals("43.70", status.tasks?.paidUsdcTotal)
        assertEquals("Jarvis", status.lastRegistration?.name)
    }

    @Test
    fun `health fixture decodes`() {
        val health = Fixtures.decode<Health>("health")
        assertEquals("ok", health.status)
        assertEquals("1.3.9", health.skillVersion)
    }

    @Test
    fun `open tasks envelope decodes all tasks`() {
        val page = Fixtures.decode<TaskListEnvelope>("tasks_open")
        assertTrue(page.ok)
        assertEquals(16, page.tasks.size)
        val first = page.tasks.first()
        assertEquals("task_zFihEF6ij4a3tUP0ENWo1", first.id)
        assertEquals("open", first.status)
        assertEquals("code", first.category)
        assertEquals("BasedAgents_bot", first.creator?.name)
        assertNull(first.claimedByAgentId)
        assertTrue(first.claimable)
    }

    @Test
    fun `second page is the offset slice of the first`() {
        val all = Fixtures.decode<TaskListEnvelope>("tasks_open").tasks.map { it.id }
        val page = Fixtures.decode<TaskListEnvelope>("tasks_open_page").tasks.map { it.id }
        assertEquals(5, page.size)
        assertEquals(all.subList(5, 10), page)
    }

    @Test
    fun `category page contains only that category`() {
        val page = Fixtures.decode<TaskListEnvelope>("tasks_category_code")
        assertEquals(10, page.tasks.size)
        assertTrue(page.tasks.all { it.category == "code" })
    }

    @Test
    fun `task detail envelope decodes nested payment and receipt`() {
        val detail = Fixtures.decode<TaskDetail>("task_detail_sdk")
        assertTrue(detail.ok)
        assertEquals("task_zFihEF6ij4a3tUP0ENWo1", detail.task.id)
        assertTrue(detail.hasSubmission)
        assertEquals(2, detail.receiptsCount)
        val receipt = assertNotNull(detail.deliveryReceipt)
        assertEquals("rcpt_kTFsms4hSzOt7yEgcs0oI", receipt.id)
        assertEquals(1887L, receipt.chainSequence)
        val payment = assertNotNull(detail.payment)
        assertEquals("none", payment.status)
        assertNull(payment.bounty)
        assertNull(payment.escrow)
    }

    @Test
    fun `second task detail decodes`() {
        val detail = Fixtures.decode<TaskDetail>("task_detail_observatory")
        assertEquals("task_LHJPMel3PnqH4aqCwza2c", detail.task.id)
        assertEquals("automation", detail.task.category)
        assertEquals(1, detail.receiptsCount)
    }

    @Test
    fun `settled task detail has a bounty and a released escrow`() {
        val detail = Fixtures.decode<TaskDetail>("task_detail_settled")
        assertEquals("verified", detail.task.status)
        val bounty = assertNotNull(detail.task.bounty)
        assertEquals("100000", bounty.amountAtomic)
        assertEquals("0.10", bounty.amountDisplay)
        assertEquals("USDC", bounty.token)
        assertEquals("released", detail.task.escrow?.status)
        assertEquals("settled", detail.payment?.status)
        assertEquals(3, detail.receiptsCount)
    }

    @Test
    fun `receipts list decodes`() {
        val list = Fixtures.decode<ReceiptListEnvelope>("task_receipts_sdk")
        assertTrue(list.ok)
        assertEquals(2, list.receipts.size)
        assertEquals("rcpt_kTFsms4hSzOt7yEgcs0oI", list.receipts[0].id)
        assertEquals(1887L, list.receipts[0].chainSequence)
        assertEquals(1740L, list.receipts[1].chainSequence)
        assertTrue(list.receipts.all { it.contentPrivate })
    }

    @Test
    fun `single receipt envelope decodes`() {
        val envelope = Fixtures.decode<ReceiptEnvelope>("task_receipt_sdk")
        assertEquals("rcpt_kTFsms4hSzOt7yEgcs0oI", envelope.receipt.id)
        assertEquals("ag_8ZwhSrKjWiggquiC5wtNJj2Vh6WTBNbXxuan6SbDWrkR", envelope.receipt.agentId)
        assertNotNull(envelope.receipt.agentPublicKey)
    }

    @Test
    fun `unpaid payment details decode with unavailable requirements`() {
        val details = Fixtures.decode<PaymentDetails>("task_payment_sdk")
        assertTrue(details.ok)
        assertEquals("none", details.payment.status)
        assertEquals("no_bounty", details.requirementsUnavailableReason)
        assertEquals("POST /v1/tasks/task_zFihEF6ij4a3tUP0ENWo1/accept", details.acceptEndpoint)
        assertTrue(details.events.isEmpty())
    }

    @Test
    fun `settled payment details decode escrow and audit events`() {
        val details = Fixtures.decode<PaymentDetails>("task_payment_settled")
        assertEquals("settled", details.payment.status)
        assertTrue(details.payment.settled)
        assertEquals("100000", details.payment.bounty?.amountAtomic)
        val escrow = assertNotNull(details.payment.escrow)
        assertEquals("released", escrow.status)
        assertNotNull(escrow.depositTxHash)
        assertEquals(6, details.events.size)
        assertEquals("bounty_declared", details.events.first().eventType)
        assertEquals("settled", details.events.last().eventType)
    }

    @Test
    fun `settled envelope decodes stats cursor and summaries`() {
        val page = Fixtures.decode<SettledListEnvelope>("tasks_settled")
        assertTrue(page.ok)
        val stats = assertNotNull(page.stats)
        assertEquals(30, stats.windowDays)
        assertEquals(8, stats.n)
        assertEquals(79L, stats.tasksPaidAllTime)
        assertEquals("43.70", stats.usdcPaidAllTime)
        assertEquals(1160694L, stats.medianTimeToPaidSeconds)
        assertEquals("2026-10-05T23:10:24.247Z|task_oB39BzpFOmlyiWa13zzfT", page.nextCursor)
        assertEquals(10, page.tasks.size)
        val first = page.tasks.first()
        assertEquals("task_8zjlRRChZW7kWIb0Oy6Ai", first.id)
        assertEquals("0.10", first.bounty?.amountDisplay)
        assertEquals("firstdollar-agent05-genesis", first.agent?.name)
        assertNotNull(first.txHash)
    }

    @Test
    fun `agent profile decodes`() {
        val agent = Fixtures.decode<Agent>("agent_jarvis")
        assertEquals("ag_5Mr7gZFJhQRy7nESV86U7zduaoeUh7ss7SLKvH46KUZD", agent.id)
        assertEquals("Jarvis", agent.name)
        assertEquals(5, agent.capabilities.size)
        assertTrue(agent.walletVerified)
        assertEquals("0xd93B19CbBFC56b6Bce661e55D439AAca89328b06", agent.walletAddress)
        assertEquals(0.0, agent.reputationScore)
        assertEquals(0, agent.ratings?.count)
        assertNull(agent.ratings?.average)
    }

    @Test
    fun `agent profile with null wallet decodes`() {
        val agent = Fixtures.decode<Agent>("agent_bot")
        assertEquals("BasedAgents_bot", agent.name)
        assertEquals("BasedAgents", agent.organization)
        assertNull(agent.walletAddress)
    }

    @Test
    fun `reputation decodes score breakdown and weights`() {
        val reputation = Fixtures.decode<Reputation>("agent_reputation_jarvis")
        assertEquals("ag_5Mr7gZFJhQRy7nESV86U7zduaoeUh7ss7SLKvH46KUZD", reputation.agentId)
        assertEquals(0.0, reputation.reputationScore)
        assertEquals(0.35, reputation.weights?.passRate)
        assertEquals(0.0, reputation.breakdown?.taskCompletion)
        assertEquals(0.0, reputation.tasksAccepted)
    }

    @Test
    fun `agent skills decode as objects with name registry and privacy`() {
        val agent = Fixtures.decode<Agent>("agent_skills_object")
        assertEquals("Hans", agent.name)
        assertEquals(8, agent.skills.size)
        val first = agent.skills.first()
        assertEquals("openclaw", first.name)
        assertEquals("clawhub", first.registry)
        assertEquals(false, first.private)
        assertEquals("@anthropic-ai/sdk", agent.skills[1].name)
        assertEquals("npm", agent.skills[1].registry)
    }

    @Test
    fun `fractional reputation tasks accepted decodes`() {
        val reputation = Fixtures.decode<Reputation>("agent_reputation_fractional")
        assertEquals(6.064, reputation.tasksAccepted)
        assertEquals(0.0, reputation.tasksFailed)
    }

    @Test
    fun `task with wallet creator and null creator id decodes`() {
        val detail = Fixtures.decode<TaskDetail>("task_creator_wallet")
        assertEquals("task_ILI16I1DYjTOabbUBRvV9", detail.task.id)
        val creator = assertNotNull(detail.task.creator)
        assertEquals("wallet", creator.kind)
        assertNull(creator.id)
        assertEquals("0x16d4479a4dfbdd6231b5ce686d2eedd04809e7e8", creator.wallet)
    }

    @Test
    fun `chain range decodes every entry in sequence`() {
        val range = Fixtures.decode<ChainRangeEnvelope>("chain_range")
        assertEquals(5, range.entries.size)
        assertEquals(listOf(2015L, 2016L, 2017L, 2018L, 2019L), range.entries.map { it.sequence })
        assertEquals(range.entries[0].entryHash, range.entries[1].previousHash)
    }

    @Test
    fun `single chain entry decodes`() {
        val entry = Fixtures.decode<ChainEntry>("chain_entry")
        assertEquals(2019L, entry.sequence)
        assertEquals("Jarvis", entry.agentName)
        assertEquals("registration", entry.entryType)
        assertEquals("ag_5Mr7gZFJhQRy7nESV86U7zduaoeUh7ss7SLKvH46KUZD", entry.agentId)
    }

    @Test
    fun `wallet decodes with its binding proof`() {
        val wallet = Fixtures.decode<AgentWallet>("agent_wallet_jarvis")
        assertEquals("0xd93B19CbBFC56b6Bce661e55D439AAca89328b06", wallet.walletAddress)
        assertEquals("eip155:8453", wallet.walletNetwork)
        assertTrue(wallet.walletVerified)
        assertEquals("eoa", wallet.walletProof?.signerKind)
        assertNotNull(wallet.walletProof?.signature)
    }

    @Test
    fun `agent search decodes results and pagination`() {
        val search = Fixtures.decode<AgentSearchEnvelope>("agents_search_jarvis")
        assertEquals(5, search.agents.size)
        assertEquals("SANTOS JARVIS AI", search.agents.first().name)
        val pagination = assertNotNull(search.pagination)
        assertEquals(5, pagination.total)
        assertEquals(1, pagination.totalPages)
        assertEquals(20, pagination.limit)
        // Search results omit the profile-only blocks; defaults cover them.
        assertNull(search.agents.first().ratings)
    }

    @Test
    fun `chain latest decodes head entry and checkpoints`() {
        val entry = Fixtures.decode<ChainEntry>("chain_latest")
        assertEquals(2019L, entry.sequence)
        assertEquals("registration", entry.entryType)
        assertEquals("ag_5Mr7gZFJhQRy7nESV86U7zduaoeUh7ss7SLKvH46KUZD", entry.agentId)
        assertEquals(1, entry.checkpoints.size)
        assertEquals(2L, entry.checkpoints.first().sequence)
        assertNotNull(entry.verification)
    }

    @Test
    fun `service descriptor decodes its stable head`() {
        val descriptor = Fixtures.decode<ServiceDescriptor>("service_descriptor")
        assertEquals("BasedAgents", descriptor.name)
        assertEquals("1.3.9", descriptor.skill?.version)
        assertEquals("https://api.basedagents.ai/v1", descriptor.api?.base)
    }

    @Test
    fun `error bodies decode`() {
        val notFound = Fixtures.decode<ApiErrorBody>("error_task_not_found")
        assertEquals("not_found", notFound.error)
        assertEquals("Task not found", notFound.message)
        val unauthorized = Fixtures.decode<ApiErrorBody>("task_submission_sdk")
        assertEquals("unauthorized", unauthorized.error)
    }
}
