import Foundation

// MARK: - Shared value types

/// A task bounty. Amounts are strings on the wire to avoid float rounding.
public struct Bounty: Codable, Equatable, Sendable {
    public let amountAtomic: String?
    public let amountDisplay: String?
    public let token: String?
    public let network: String?

    enum CodingKeys: String, CodingKey {
        case amountAtomic = "amount_atomic"
        case amountDisplay = "amount_display"
        case token, network
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        amountAtomic = try c.decodeIfPresent(String.self, forKey: .amountAtomic)
        amountDisplay = try c.decodeIfPresent(String.self, forKey: .amountDisplay)
        token = try c.decodeIfPresent(String.self, forKey: .token)
        network = try c.decodeIfPresent(String.self, forKey: .network)
    }
}

/// Escrow state for a bounty-backed task.
public struct Escrow: Codable, Equatable, Sendable {
    public let status: String?
    public let leg: String?
    public let wallet: String?
    public let depositTxHash: String?
    public let fundedAt: String?
    public let releaseTxHash: String?
    public let releasedAt: String?
    public let refundTxHash: String?
    public let refundedAt: String?

    enum CodingKeys: String, CodingKey {
        case status, leg, wallet
        case depositTxHash = "deposit_tx_hash"
        case fundedAt = "funded_at"
        case releaseTxHash = "release_tx_hash"
        case releasedAt = "released_at"
        case refundTxHash = "refund_tx_hash"
        case refundedAt = "refunded_at"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = try c.decodeIfPresent(String.self, forKey: .status)
        leg = try c.decodeIfPresent(String.self, forKey: .leg)
        wallet = try c.decodeIfPresent(String.self, forKey: .wallet)
        depositTxHash = try c.decodeIfPresent(String.self, forKey: .depositTxHash)
        fundedAt = try c.decodeIfPresent(String.self, forKey: .fundedAt)
        releaseTxHash = try c.decodeIfPresent(String.self, forKey: .releaseTxHash)
        releasedAt = try c.decodeIfPresent(String.self, forKey: .releasedAt)
        refundTxHash = try c.decodeIfPresent(String.self, forKey: .refundTxHash)
        refundedAt = try c.decodeIfPresent(String.self, forKey: .refundedAt)
    }
}

/// Compact agent reference embedded in tasks and settled-task summaries.
public struct AgentRef: Codable, Equatable, Sendable {
    public let id: String
    public let name: String?

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name)
    }

    enum CodingKeys: String, CodingKey { case id, name }
}

/// The `creator` block embedded in a full task record.
public struct CreatorRef: Codable, Equatable, Sendable {
    public let kind: String?
    public let id: String
    public let shortId: String?
    public let name: String?
    public let cert: String?

    enum CodingKeys: String, CodingKey {
        case kind, id, name, cert
        case shortId = "short_id"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = try c.decodeIfPresent(String.self, forKey: .kind)
        id = try c.decode(String.self, forKey: .id)
        shortId = try c.decodeIfPresent(String.self, forKey: .shortId)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        cert = try c.decodeIfPresent(String.self, forKey: .cert)
    }
}

// MARK: - Tasks

/// A full task record, as returned by `GET /v1/tasks` (list items) and
/// `GET /v1/tasks/{id}` (inside `TaskDetail`).
public struct Task: Codable, Equatable, Sendable {
    public let id: String
    public let creatorAgentId: String?
    public let creatorKind: String?
    public let claimedByAgentId: String?
    public let title: String
    public let description: String?
    public let category: String?
    public let requiredCapabilities: [String]
    public let expectedOutput: String?
    public let outputFormat: String?
    public let status: String
    public let createdAt: String?
    public let claimedAt: String?
    public let submittedAt: String?
    public let verifiedAt: String?
    public let acceptedBy: String?
    public let reviewNote: String?
    public let revisionCount: Int
    public let revisionRequestedAt: String?
    public let disputedAt: String?
    public let cancelledAt: String?
    public let proposerSignature: String?
    public let acceptorSignature: String?
    public let bountyAmount: String?
    public let bountyToken: String?
    public let bountyNetwork: String?
    public let paymentStatus: String?
    /// The API reports these as 0/1 integers, not booleans.
    public let paymentVerified: Int
    public let paymentSettled: Int
    public let paymentTxHash: String?
    public let paymentExpiresAt: String?
    public let autoReleaseAt: String?
    public let settledAt: String?
    public let lastSettleError: String?
    public let claimExpiresAt: String?
    public let escrow: Escrow?
    public let maxActiveClaimsPerAgent: Int?
    public let rating: Double?
    public let ratingComment: String?
    public let ratingContext: String?
    public let ratedAt: String?
    public let expiresAt: String?
    public let expiredAt: String?
    public let creator: CreatorRef?
    public let claimedBy: AgentRef?
    public let bounty: Bounty?
    public let reviewState: String?
    public let paymentDue: Bool
    public let claimable: Bool

    enum CodingKeys: String, CodingKey {
        case id = "task_id"
        case creatorAgentId = "creator_agent_id"
        case creatorKind = "creator_kind"
        case claimedByAgentId = "claimed_by_agent_id"
        case title, description, category
        case requiredCapabilities = "required_capabilities"
        case expectedOutput = "expected_output"
        case outputFormat = "output_format"
        case status
        case createdAt = "created_at"
        case claimedAt = "claimed_at"
        case submittedAt = "submitted_at"
        case verifiedAt = "verified_at"
        case acceptedBy = "accepted_by"
        case reviewNote = "review_note"
        case revisionCount = "revision_count"
        case revisionRequestedAt = "revision_requested_at"
        case disputedAt = "disputed_at"
        case cancelledAt = "cancelled_at"
        case proposerSignature = "proposer_signature"
        case acceptorSignature = "acceptor_signature"
        case bountyAmount = "bounty_amount"
        case bountyToken = "bounty_token"
        case bountyNetwork = "bounty_network"
        case paymentStatus = "payment_status"
        case paymentVerified = "payment_verified"
        case paymentSettled = "payment_settled"
        case paymentTxHash = "payment_tx_hash"
        case paymentExpiresAt = "payment_expires_at"
        case autoReleaseAt = "auto_release_at"
        case settledAt = "settled_at"
        case lastSettleError = "last_settle_error"
        case claimExpiresAt = "claim_expires_at"
        case escrow
        case maxActiveClaimsPerAgent = "max_active_claims_per_agent"
        case rating
        case ratingComment = "rating_comment"
        case ratingContext = "rating_context"
        case ratedAt = "rated_at"
        case expiresAt = "expires_at"
        case expiredAt = "expired_at"
        case creator
        case claimedBy = "claimed_by"
        case bounty
        case reviewState = "review_state"
        case paymentDue = "payment_due"
        case claimable
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        creatorAgentId = try c.decodeIfPresent(String.self, forKey: .creatorAgentId)
        creatorKind = try c.decodeIfPresent(String.self, forKey: .creatorKind)
        claimedByAgentId = try c.decodeIfPresent(String.self, forKey: .claimedByAgentId)
        title = try c.decode(String.self, forKey: .title)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        category = try c.decodeIfPresent(String.self, forKey: .category)
        requiredCapabilities = try c.decodeOrDefault([String].self, forKey: .requiredCapabilities, default: [])
        expectedOutput = try c.decodeIfPresent(String.self, forKey: .expectedOutput)
        outputFormat = try c.decodeIfPresent(String.self, forKey: .outputFormat)
        status = try c.decode(String.self, forKey: .status)
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
        claimedAt = try c.decodeIfPresent(String.self, forKey: .claimedAt)
        submittedAt = try c.decodeIfPresent(String.self, forKey: .submittedAt)
        verifiedAt = try c.decodeIfPresent(String.self, forKey: .verifiedAt)
        acceptedBy = try c.decodeIfPresent(String.self, forKey: .acceptedBy)
        reviewNote = try c.decodeIfPresent(String.self, forKey: .reviewNote)
        revisionCount = try c.decodeOrDefault(Int.self, forKey: .revisionCount, default: 0)
        revisionRequestedAt = try c.decodeIfPresent(String.self, forKey: .revisionRequestedAt)
        disputedAt = try c.decodeIfPresent(String.self, forKey: .disputedAt)
        cancelledAt = try c.decodeIfPresent(String.self, forKey: .cancelledAt)
        proposerSignature = try c.decodeIfPresent(String.self, forKey: .proposerSignature)
        acceptorSignature = try c.decodeIfPresent(String.self, forKey: .acceptorSignature)
        bountyAmount = try c.decodeIfPresent(String.self, forKey: .bountyAmount)
        bountyToken = try c.decodeIfPresent(String.self, forKey: .bountyToken)
        bountyNetwork = try c.decodeIfPresent(String.self, forKey: .bountyNetwork)
        paymentStatus = try c.decodeIfPresent(String.self, forKey: .paymentStatus)
        paymentVerified = try c.decodeOrDefault(Int.self, forKey: .paymentVerified, default: 0)
        paymentSettled = try c.decodeOrDefault(Int.self, forKey: .paymentSettled, default: 0)
        paymentTxHash = try c.decodeIfPresent(String.self, forKey: .paymentTxHash)
        paymentExpiresAt = try c.decodeIfPresent(String.self, forKey: .paymentExpiresAt)
        autoReleaseAt = try c.decodeIfPresent(String.self, forKey: .autoReleaseAt)
        settledAt = try c.decodeIfPresent(String.self, forKey: .settledAt)
        lastSettleError = try c.decodeIfPresent(String.self, forKey: .lastSettleError)
        claimExpiresAt = try c.decodeIfPresent(String.self, forKey: .claimExpiresAt)
        escrow = try c.decodeIfPresent(Escrow.self, forKey: .escrow)
        maxActiveClaimsPerAgent = try c.decodeIfPresent(Int.self, forKey: .maxActiveClaimsPerAgent)
        rating = try c.decodeIfPresent(Double.self, forKey: .rating)
        ratingComment = try c.decodeIfPresent(String.self, forKey: .ratingComment)
        ratingContext = try c.decodeIfPresent(String.self, forKey: .ratingContext)
        ratedAt = try c.decodeIfPresent(String.self, forKey: .ratedAt)
        expiresAt = try c.decodeIfPresent(String.self, forKey: .expiresAt)
        expiredAt = try c.decodeIfPresent(String.self, forKey: .expiredAt)
        creator = try c.decodeIfPresent(CreatorRef.self, forKey: .creator)
        claimedBy = try c.decodeIfPresent(AgentRef.self, forKey: .claimedBy)
        bounty = try c.decodeIfPresent(Bounty.self, forKey: .bounty)
        reviewState = try c.decodeIfPresent(String.self, forKey: .reviewState)
        paymentDue = try c.decodeOrDefault(Bool.self, forKey: .paymentDue, default: false)
        claimable = try c.decodeOrDefault(Bool.self, forKey: .claimable, default: false)
    }
}

/// Envelope for `GET /v1/tasks`.
public struct TaskListEnvelope: Codable, Equatable, Sendable {
    public let ok: Bool
    public let tasks: [Task]

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ok = try c.decodeOrDefault(Bool.self, forKey: .ok, default: false)
        tasks = try c.decodeOrDefault([Task].self, forKey: .tasks, default: [])
    }

    enum CodingKeys: String, CodingKey { case ok, tasks }
}

/// The submission summary embedded in a task detail when one is public.
public struct SubmissionInfo: Codable, Equatable, Sendable {
    public let taskId: String?
    public let agentId: String?
    public let submissionType: String?
    public let note: String?
    public let submittedAt: String?
    public let chainSequence: Int64?

    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case agentId = "agent_id"
        case submissionType = "submission_type"
        case note
        case submittedAt = "submitted_at"
        case chainSequence = "chain_sequence"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        taskId = try c.decodeIfPresent(String.self, forKey: .taskId)
        agentId = try c.decodeIfPresent(String.self, forKey: .agentId)
        submissionType = try c.decodeIfPresent(String.self, forKey: .submissionType)
        note = try c.decodeIfPresent(String.self, forKey: .note)
        submittedAt = try c.decodeIfPresent(String.self, forKey: .submittedAt)
        chainSequence = try c.decodeIfPresent(Int64.self, forKey: .chainSequence)
    }
}

/// Envelope for `GET /v1/tasks/{id}`.
public struct TaskDetail: Codable, Equatable, Sendable {
    public let ok: Bool
    public let task: Task
    public let submission: SubmissionInfo?
    public let hasSubmission: Bool
    public let submissionPublic: Bool
    public let deliveryReceipt: Receipt?
    public let receiptsCount: Int
    public let payment: PaymentInfo?

    enum CodingKeys: String, CodingKey {
        case ok, task, submission, payment
        case hasSubmission = "has_submission"
        case submissionPublic = "submission_public"
        case deliveryReceipt = "delivery_receipt"
        case receiptsCount = "receipts_count"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ok = try c.decodeOrDefault(Bool.self, forKey: .ok, default: false)
        task = try c.decode(Task.self, forKey: .task)
        submission = try c.decodeIfPresent(SubmissionInfo.self, forKey: .submission)
        hasSubmission = try c.decodeOrDefault(Bool.self, forKey: .hasSubmission, default: false)
        submissionPublic = try c.decodeOrDefault(Bool.self, forKey: .submissionPublic, default: false)
        deliveryReceipt = try c.decodeIfPresent(Receipt.self, forKey: .deliveryReceipt)
        receiptsCount = try c.decodeOrDefault(Int.self, forKey: .receiptsCount, default: 0)
        payment = try c.decodeIfPresent(PaymentInfo.self, forKey: .payment)
    }
}

// MARK: - Receipts

/// A signed delivery receipt anchored in the registry chain.
public struct Receipt: Codable, Equatable, Sendable {
    public let id: String
    public let taskId: String
    public let agentId: String
    public let submissionType: String?
    public let completedAt: String?
    public let chainSequence: Int64
    public let chainEntryHash: String?
    public let signature: String?
    public let contentPrivate: Bool
    public let agentPublicKey: String?

    enum CodingKeys: String, CodingKey {
        case id = "receipt_id"
        case taskId = "task_id"
        case agentId = "agent_id"
        case submissionType = "submission_type"
        case completedAt = "completed_at"
        case chainSequence = "chain_sequence"
        case chainEntryHash = "chain_entry_hash"
        case signature
        case contentPrivate = "content_private"
        case agentPublicKey = "agent_public_key"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        taskId = try c.decode(String.self, forKey: .taskId)
        agentId = try c.decode(String.self, forKey: .agentId)
        submissionType = try c.decodeIfPresent(String.self, forKey: .submissionType)
        completedAt = try c.decodeIfPresent(String.self, forKey: .completedAt)
        chainSequence = try c.decodeOrDefault(Int64.self, forKey: .chainSequence, default: 0)
        chainEntryHash = try c.decodeIfPresent(String.self, forKey: .chainEntryHash)
        signature = try c.decodeIfPresent(String.self, forKey: .signature)
        contentPrivate = try c.decodeOrDefault(Bool.self, forKey: .contentPrivate, default: false)
        agentPublicKey = try c.decodeIfPresent(String.self, forKey: .agentPublicKey)
    }
}

/// Envelope for `GET /v1/tasks/{id}/receipts`.
public struct ReceiptListEnvelope: Codable, Equatable, Sendable {
    public let ok: Bool
    public let receipts: [Receipt]

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ok = try c.decodeOrDefault(Bool.self, forKey: .ok, default: false)
        receipts = try c.decodeOrDefault([Receipt].self, forKey: .receipts, default: [])
    }

    enum CodingKeys: String, CodingKey { case ok, receipts }
}

/// Envelope for `GET /v1/tasks/{id}/receipt`.
public struct ReceiptEnvelope: Codable, Equatable, Sendable {
    public let ok: Bool
    public let receipt: Receipt

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ok = try c.decodeOrDefault(Bool.self, forKey: .ok, default: false)
        receipt = try c.decode(Receipt.self, forKey: .receipt)
    }

    enum CodingKeys: String, CodingKey { case ok, receipt }
}

// MARK: - Payments

/// Payment state for a task, as embedded in `TaskDetail` (no `ok` wrapper).
public struct PaymentInfo: Codable, Equatable, Sendable {
    public let taskId: String
    public let bounty: Bounty?
    public let status: String
    public let verified: Bool
    public let settled: Bool
    public let txHash: String?
    public let settledAt: String?
    public let expiresAt: String?
    public let autoReleaseAt: String?
    public let acceptedBy: String?
    public let payer: String?
    public let lastError: String?
    public let settleAttempts: Int
    public let nextSettleAt: String?
    public let paymentDue: Bool
    public let escrow: Escrow?
    public let payTo: String?

    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case bounty, status, verified, settled
        case txHash = "tx_hash"
        case settledAt = "settled_at"
        case expiresAt = "expires_at"
        case autoReleaseAt = "auto_release_at"
        case acceptedBy = "accepted_by"
        case payer
        case lastError = "last_error"
        case settleAttempts = "settle_attempts"
        case nextSettleAt = "next_settle_at"
        case paymentDue = "payment_due"
        case escrow
        case payTo = "pay_to"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        taskId = try c.decode(String.self, forKey: .taskId)
        bounty = try c.decodeIfPresent(Bounty.self, forKey: .bounty)
        status = try c.decode(String.self, forKey: .status)
        verified = try c.decodeOrDefault(Bool.self, forKey: .verified, default: false)
        settled = try c.decodeOrDefault(Bool.self, forKey: .settled, default: false)
        txHash = try c.decodeIfPresent(String.self, forKey: .txHash)
        settledAt = try c.decodeIfPresent(String.self, forKey: .settledAt)
        expiresAt = try c.decodeIfPresent(String.self, forKey: .expiresAt)
        autoReleaseAt = try c.decodeIfPresent(String.self, forKey: .autoReleaseAt)
        acceptedBy = try c.decodeIfPresent(String.self, forKey: .acceptedBy)
        payer = try c.decodeIfPresent(String.self, forKey: .payer)
        lastError = try c.decodeIfPresent(String.self, forKey: .lastError)
        settleAttempts = try c.decodeOrDefault(Int.self, forKey: .settleAttempts, default: 0)
        nextSettleAt = try c.decodeIfPresent(String.self, forKey: .nextSettleAt)
        paymentDue = try c.decodeOrDefault(Bool.self, forKey: .paymentDue, default: false)
        escrow = try c.decodeIfPresent(Escrow.self, forKey: .escrow)
        payTo = try c.decodeIfPresent(String.self, forKey: .payTo)
    }
}

/// One entry in a payment's audit event log. `details` is free-form JSON.
public struct PaymentEvent: Codable, Equatable, Sendable {
    public let id: String
    public let eventType: String
    public let details: [String: JSONValue]?
    public let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case eventType = "event_type"
        case details
        case createdAt = "created_at"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        eventType = try c.decode(String.self, forKey: .eventType)
        details = try c.decodeIfPresent([String: JSONValue].self, forKey: .details)
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
    }
}

/// Envelope for `GET /v1/tasks/{id}/payment`.
public struct PaymentDetails: Codable, Equatable, Sendable {
    public let ok: Bool
    public let payment: PaymentInfo
    public let requirements: JSONValue?
    public let requirementsUnavailableReason: String?
    public let acceptEndpoint: String?
    public let fundEndpoint: String?
    public let paymentHeader: String?
    public let events: [PaymentEvent]

    enum CodingKeys: String, CodingKey {
        case ok, payment, requirements, events
        case requirementsUnavailableReason = "requirements_unavailable_reason"
        case acceptEndpoint = "accept_endpoint"
        case fundEndpoint = "fund_endpoint"
        case paymentHeader = "payment_header"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ok = try c.decodeOrDefault(Bool.self, forKey: .ok, default: false)
        payment = try c.decode(PaymentInfo.self, forKey: .payment)
        requirements = try c.decodeIfPresent(JSONValue.self, forKey: .requirements)
        requirementsUnavailableReason = try c.decodeIfPresent(String.self, forKey: .requirementsUnavailableReason)
        acceptEndpoint = try c.decodeIfPresent(String.self, forKey: .acceptEndpoint)
        fundEndpoint = try c.decodeIfPresent(String.self, forKey: .fundEndpoint)
        paymentHeader = try c.decodeIfPresent(String.self, forKey: .paymentHeader)
        events = try c.decodeOrDefault([PaymentEvent].self, forKey: .events, default: [])
    }
}

// MARK: - Settled tasks

/// Aggregate statistics block returned with `GET /v1/tasks/settled`.
public struct SettledStats: Codable, Equatable, Sendable {
    public let windowDays: Int
    public let n: Int
    public let minNForMedians: Int
    public let medianTimeToPaidSeconds: Int64?
    public let medianTimeToClaimSeconds: Int64?
    public let medianDeliverySeconds: Int64?
    public let medianReviewSeconds: Int64?
    public let tasksPaidAllTime: Int64
    public let usdcPaidAllTime: String?
    public let computedAt: String?

    enum CodingKeys: String, CodingKey {
        case windowDays = "window_days"
        case n
        case minNForMedians = "min_n_for_medians"
        case medianTimeToPaidSeconds = "median_time_to_paid_s"
        case medianTimeToClaimSeconds = "median_time_to_claim_s"
        case medianDeliverySeconds = "median_delivery_s"
        case medianReviewSeconds = "median_review_s"
        case tasksPaidAllTime = "tasks_paid_all_time"
        case usdcPaidAllTime = "usdc_paid_all_time"
        case computedAt = "computed_at"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        windowDays = try c.decodeOrDefault(Int.self, forKey: .windowDays, default: 0)
        n = try c.decodeOrDefault(Int.self, forKey: .n, default: 0)
        minNForMedians = try c.decodeOrDefault(Int.self, forKey: .minNForMedians, default: 0)
        medianTimeToPaidSeconds = try c.decodeIfPresent(Int64.self, forKey: .medianTimeToPaidSeconds)
        medianTimeToClaimSeconds = try c.decodeIfPresent(Int64.self, forKey: .medianTimeToClaimSeconds)
        medianDeliverySeconds = try c.decodeIfPresent(Int64.self, forKey: .medianDeliverySeconds)
        medianReviewSeconds = try c.decodeIfPresent(Int64.self, forKey: .medianReviewSeconds)
        tasksPaidAllTime = try c.decodeOrDefault(Int64.self, forKey: .tasksPaidAllTime, default: 0)
        usdcPaidAllTime = try c.decodeIfPresent(String.self, forKey: .usdcPaidAllTime)
        computedAt = try c.decodeIfPresent(String.self, forKey: .computedAt)
    }
}

/// A settled-task summary row (a slimmer shape than the full `Task`).
public struct SettledTask: Codable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let category: String?
    public let bounty: Bounty?
    public let agent: AgentRef?
    public let sponsored: Bool
    public let createdAt: String?
    public let claimedAt: String?
    public let submittedAt: String?
    public let settledAt: String?
    public let timeToPaidSeconds: Int64?
    public let deliverySeconds: Int64?
    public let txHash: String?
    public let explorerUrl: String?

    enum CodingKeys: String, CodingKey {
        case id = "task_id"
        case title, category, bounty, agent, sponsored
        case createdAt = "created_at"
        case claimedAt = "claimed_at"
        case submittedAt = "submitted_at"
        case settledAt = "settled_at"
        case timeToPaidSeconds = "time_to_paid_s"
        case deliverySeconds = "delivery_s"
        case txHash = "tx_hash"
        case explorerUrl = "explorer_url"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        category = try c.decodeIfPresent(String.self, forKey: .category)
        bounty = try c.decodeIfPresent(Bounty.self, forKey: .bounty)
        agent = try c.decodeIfPresent(AgentRef.self, forKey: .agent)
        sponsored = try c.decodeOrDefault(Bool.self, forKey: .sponsored, default: false)
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
        claimedAt = try c.decodeIfPresent(String.self, forKey: .claimedAt)
        submittedAt = try c.decodeIfPresent(String.self, forKey: .submittedAt)
        settledAt = try c.decodeIfPresent(String.self, forKey: .settledAt)
        timeToPaidSeconds = try c.decodeIfPresent(Int64.self, forKey: .timeToPaidSeconds)
        deliverySeconds = try c.decodeIfPresent(Int64.self, forKey: .deliverySeconds)
        txHash = try c.decodeIfPresent(String.self, forKey: .txHash)
        explorerUrl = try c.decodeIfPresent(String.self, forKey: .explorerUrl)
    }
}

/// Envelope for `GET /v1/tasks/settled`. Pages by cursor: pass `nextCursor` back as `cursor`.
public struct SettledListEnvelope: Codable, Equatable, Sendable {
    public let ok: Bool
    public let stats: SettledStats?
    public let tasks: [SettledTask]
    public let nextCursor: String?

    enum CodingKeys: String, CodingKey {
        case ok, stats, tasks
        case nextCursor = "next_cursor"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ok = try c.decodeOrDefault(Bool.self, forKey: .ok, default: false)
        stats = try c.decodeIfPresent(SettledStats.self, forKey: .stats)
        tasks = try c.decodeOrDefault([SettledTask].self, forKey: .tasks, default: [])
        nextCursor = try c.decodeIfPresent(String.self, forKey: .nextCursor)
    }
}
