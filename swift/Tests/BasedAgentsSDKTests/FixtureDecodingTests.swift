import XCTest
@testable import BasedAgentsSDK

/// Parses every recorded fixture through the typed models and asserts the
/// fields a consumer would rely on. These are the exact bytes the Kotlin
/// suite parses too, which is what makes the two implementations provably
/// equivalent.
final class FixtureDecodingTests: XCTestCase {

    func testStatusDecodesWithRegistryCounters() throws {
        let status = try Fixtures.decode("status", as: ApiStatus.self)
        XCTAssertEqual(status.status, "operational")
        XCTAssertEqual(status.version, "0.1.0")
        XCTAssertEqual(status.dbLatencyMs, 430)
        XCTAssertEqual(status.agents?.total, 1185)
        XCTAssertEqual(status.chain?.height, 2019)
        XCTAssertEqual(status.tasks?.open, 16)
        XCTAssertEqual(status.tasks?.paidUsdcTotal, "43.70")
        XCTAssertEqual(status.lastRegistration?.name, "Jarvis")
    }

    func testHealthDecodes() throws {
        let health = try Fixtures.decode("health", as: Health.self)
        XCTAssertEqual(health.status, "ok")
        XCTAssertEqual(health.skillVersion, "1.3.9")
    }

    func testOpenTasksEnvelopeDecodesAllTasks() throws {
        let page = try Fixtures.decode("tasks_open", as: TaskListEnvelope.self)
        XCTAssertTrue(page.ok)
        XCTAssertEqual(page.tasks.count, 16)
        let first = try XCTUnwrap(page.tasks.first)
        XCTAssertEqual(first.id, "task_zFihEF6ij4a3tUP0ENWo1")
        XCTAssertEqual(first.status, "open")
        XCTAssertEqual(first.category, "code")
        XCTAssertEqual(first.creator?.name, "BasedAgents_bot")
        XCTAssertNil(first.claimedByAgentId)
        XCTAssertTrue(first.claimable)
    }

    func testSecondPageIsTheOffsetSliceOfTheFirst() throws {
        let all = try Fixtures.decode("tasks_open", as: TaskListEnvelope.self).tasks.map(\.id)
        let page = try Fixtures.decode("tasks_open_page", as: TaskListEnvelope.self).tasks.map(\.id)
        XCTAssertEqual(page.count, 5)
        XCTAssertEqual(page, Array(all[5..<10]))
    }

    func testCategoryPageContainsOnlyThatCategory() throws {
        let page = try Fixtures.decode("tasks_category_code", as: TaskListEnvelope.self)
        XCTAssertEqual(page.tasks.count, 10)
        XCTAssertTrue(page.tasks.allSatisfy { $0.category == "code" })
    }

    func testTaskDetailDecodesNestedPaymentAndReceipt() throws {
        let detail = try Fixtures.decode("task_detail_sdk", as: TaskDetail.self)
        XCTAssertTrue(detail.ok)
        XCTAssertEqual(detail.task.id, "task_zFihEF6ij4a3tUP0ENWo1")
        XCTAssertTrue(detail.hasSubmission)
        XCTAssertEqual(detail.receiptsCount, 2)
        let receipt = try XCTUnwrap(detail.deliveryReceipt)
        XCTAssertEqual(receipt.id, "rcpt_kTFsms4hSzOt7yEgcs0oI")
        XCTAssertEqual(receipt.chainSequence, 1887)
        let payment = try XCTUnwrap(detail.payment)
        XCTAssertEqual(payment.status, "none")
        XCTAssertNil(payment.bounty)
        XCTAssertNil(payment.escrow)
    }

    func testSecondTaskDetailDecodes() throws {
        let detail = try Fixtures.decode("task_detail_observatory", as: TaskDetail.self)
        XCTAssertEqual(detail.task.id, "task_LHJPMel3PnqH4aqCwza2c")
        XCTAssertEqual(detail.task.category, "automation")
        XCTAssertEqual(detail.receiptsCount, 1)
    }

    func testSettledTaskDetailHasBountyAndReleasedEscrow() throws {
        let detail = try Fixtures.decode("task_detail_settled", as: TaskDetail.self)
        XCTAssertEqual(detail.task.status, "verified")
        let bounty = try XCTUnwrap(detail.task.bounty)
        XCTAssertEqual(bounty.amountAtomic, "100000")
        XCTAssertEqual(bounty.amountDisplay, "0.10")
        XCTAssertEqual(bounty.token, "USDC")
        XCTAssertEqual(detail.task.escrow?.status, "released")
        XCTAssertEqual(detail.payment?.status, "settled")
        XCTAssertEqual(detail.receiptsCount, 3)
    }

    func testReceiptsListDecodes() throws {
        let list = try Fixtures.decode("task_receipts_sdk", as: ReceiptListEnvelope.self)
        XCTAssertTrue(list.ok)
        XCTAssertEqual(list.receipts.count, 2)
        XCTAssertEqual(list.receipts[0].id, "rcpt_kTFsms4hSzOt7yEgcs0oI")
        XCTAssertEqual(list.receipts[0].chainSequence, 1887)
        XCTAssertEqual(list.receipts[1].chainSequence, 1740)
        XCTAssertTrue(list.receipts.allSatisfy { $0.contentPrivate })
    }

    func testSingleReceiptEnvelopeDecodes() throws {
        let envelope = try Fixtures.decode("task_receipt_sdk", as: ReceiptEnvelope.self)
        XCTAssertEqual(envelope.receipt.id, "rcpt_kTFsms4hSzOt7yEgcs0oI")
        XCTAssertEqual(envelope.receipt.agentId, "ag_8ZwhSrKjWiggquiC5wtNJj2Vh6WTBNbXxuan6SbDWrkR")
        XCTAssertNotNil(envelope.receipt.agentPublicKey)
    }

    func testUnpaidPaymentDetailsDecode() throws {
        let details = try Fixtures.decode("task_payment_sdk", as: PaymentDetails.self)
        XCTAssertTrue(details.ok)
        XCTAssertEqual(details.payment.status, "none")
        XCTAssertEqual(details.requirementsUnavailableReason, "no_bounty")
        XCTAssertEqual(details.acceptEndpoint, "POST /v1/tasks/task_zFihEF6ij4a3tUP0ENWo1/accept")
        XCTAssertTrue(details.events.isEmpty)
    }

    func testSettledPaymentDetailsDecodeEscrowAndEvents() throws {
        let details = try Fixtures.decode("task_payment_settled", as: PaymentDetails.self)
        XCTAssertEqual(details.payment.status, "settled")
        XCTAssertTrue(details.payment.settled)
        XCTAssertEqual(details.payment.bounty?.amountAtomic, "100000")
        let escrow = try XCTUnwrap(details.payment.escrow)
        XCTAssertEqual(escrow.status, "released")
        XCTAssertNotNil(escrow.depositTxHash)
        XCTAssertEqual(details.events.count, 6)
        XCTAssertEqual(details.events.first?.eventType, "bounty_declared")
        XCTAssertEqual(details.events.last?.eventType, "settled")
    }

    func testSettledEnvelopeDecodesStatsCursorAndSummaries() throws {
        let page = try Fixtures.decode("tasks_settled", as: SettledListEnvelope.self)
        XCTAssertTrue(page.ok)
        let stats = try XCTUnwrap(page.stats)
        XCTAssertEqual(stats.windowDays, 30)
        XCTAssertEqual(stats.n, 8)
        XCTAssertEqual(stats.tasksPaidAllTime, 79)
        XCTAssertEqual(stats.usdcPaidAllTime, "43.70")
        XCTAssertEqual(stats.medianTimeToPaidSeconds, 1160694)
        XCTAssertEqual(page.nextCursor, "2026-10-05T23:10:24.247Z|task_oB39BzpFOmlyiWa13zzfT")
        XCTAssertEqual(page.tasks.count, 10)
        let first = try XCTUnwrap(page.tasks.first)
        XCTAssertEqual(first.id, "task_8zjlRRChZW7kWIb0Oy6Ai")
        XCTAssertEqual(first.bounty?.amountDisplay, "0.10")
        XCTAssertEqual(first.agent?.name, "firstdollar-agent05-genesis")
        XCTAssertNotNil(first.txHash)
    }

    func testAgentProfileDecodes() throws {
        let agent = try Fixtures.decode("agent_jarvis", as: Agent.self)
        XCTAssertEqual(agent.id, "ag_5Mr7gZFJhQRy7nESV86U7zduaoeUh7ss7SLKvH46KUZD")
        XCTAssertEqual(agent.name, "Jarvis")
        XCTAssertEqual(agent.capabilities.count, 5)
        XCTAssertTrue(agent.walletVerified)
        XCTAssertEqual(agent.walletAddress, "0xd93B19CbBFC56b6Bce661e55D439AAca89328b06")
        XCTAssertEqual(agent.reputationScore, 0)
        XCTAssertEqual(agent.ratings?.count, 0)
        XCTAssertNil(agent.ratings?.average)
    }

    func testAgentProfileWithNullWalletDecodes() throws {
        let agent = try Fixtures.decode("agent_bot", as: Agent.self)
        XCTAssertEqual(agent.name, "BasedAgents_bot")
        XCTAssertEqual(agent.organization, "BasedAgents")
        XCTAssertNil(agent.walletAddress)
    }

    func testReputationDecodes() throws {
        let reputation = try Fixtures.decode("agent_reputation_jarvis", as: Reputation.self)
        XCTAssertEqual(reputation.agentId, "ag_5Mr7gZFJhQRy7nESV86U7zduaoeUh7ss7SLKvH46KUZD")
        XCTAssertEqual(reputation.reputationScore, 0)
        XCTAssertEqual(reputation.weights?.passRate ?? 0, 0.35, accuracy: 1e-9)
        XCTAssertEqual(reputation.breakdown?.taskCompletion, 0)
        XCTAssertEqual(reputation.tasksAccepted, 0)
    }

    func testWalletDecodesWithProof() throws {
        let wallet = try Fixtures.decode("agent_wallet_jarvis", as: AgentWallet.self)
        XCTAssertEqual(wallet.walletAddress, "0xd93B19CbBFC56b6Bce661e55D439AAca89328b06")
        XCTAssertEqual(wallet.walletNetwork, "eip155:8453")
        XCTAssertTrue(wallet.walletVerified)
        XCTAssertEqual(wallet.walletProof?.signerKind, "eoa")
        XCTAssertNotNil(wallet.walletProof?.signature)
    }

    func testAgentSearchDecodes() throws {
        let search = try Fixtures.decode("agents_search_jarvis", as: AgentSearchEnvelope.self)
        XCTAssertEqual(search.agents.count, 5)
        XCTAssertEqual(search.agents.first?.name, "SANTOS JARVIS AI")
        let pagination = try XCTUnwrap(search.pagination)
        XCTAssertEqual(pagination.total, 5)
        XCTAssertEqual(pagination.totalPages, 1)
        XCTAssertEqual(pagination.limit, 20)
        XCTAssertNil(search.agents.first?.ratings)
    }

    func testChainLatestDecodes() throws {
        let entry = try Fixtures.decode("chain_latest", as: ChainEntry.self)
        XCTAssertEqual(entry.sequence, 2019)
        XCTAssertEqual(entry.entryType, "registration")
        XCTAssertEqual(entry.agentId, "ag_5Mr7gZFJhQRy7nESV86U7zduaoeUh7ss7SLKvH46KUZD")
        XCTAssertEqual(entry.checkpoints.count, 1)
        XCTAssertEqual(entry.checkpoints.first?.sequence, 2)
        XCTAssertNotNil(entry.verification)
    }

    func testServiceDescriptorDecodes() throws {
        let descriptor = try Fixtures.decode("service_descriptor", as: ServiceDescriptor.self)
        XCTAssertEqual(descriptor.name, "BasedAgents")
        XCTAssertEqual(descriptor.skill?.version, "1.3.9")
        XCTAssertEqual(descriptor.api?.base, "https://api.basedagents.ai/v1")
    }

    func testErrorBodiesDecode() throws {
        let notFound = try Fixtures.decode("error_task_not_found", as: APIErrorBody.self)
        XCTAssertEqual(notFound.error, "not_found")
        XCTAssertEqual(notFound.message, "Task not found")
        let unauthorized = try Fixtures.decode("task_submission_sdk", as: APIErrorBody.self)
        XCTAssertEqual(unauthorized.error, "unauthorized")
    }
}
