package ai.basedagents.sdk

import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.descriptors.buildClassSerialDescriptor
import kotlinx.serialization.descriptors.element
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.JsonDecoder
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.decodeFromJsonElement

/**
 * Typed models for the BasedAgents public read API.
 *
 * Field shapes mirror the recorded responses in `shared-fixtures/` exactly.
 * Optional fields default to `null` / empty so that minor API additions never
 * break decoding; the shared [BasedAgentsJson] configuration additionally
 * ignores unknown keys.
 */

// ---------------------------------------------------------------------------
// Shared value types
// ---------------------------------------------------------------------------

/** A task bounty. Amounts are strings on the wire to avoid float rounding. */
@Serializable
data class Bounty(
    @SerialName("amount_atomic") val amountAtomic: String? = null,
    @SerialName("amount_display") val amountDisplay: String? = null,
    val token: String? = null,
    val network: String? = null,
)

/** Escrow state for a bounty-backed task. */
@Serializable
data class Escrow(
    val status: String? = null,
    val leg: String? = null,
    val wallet: String? = null,
    @SerialName("deposit_tx_hash") val depositTxHash: String? = null,
    @SerialName("funded_at") val fundedAt: String? = null,
    @SerialName("release_tx_hash") val releaseTxHash: String? = null,
    @SerialName("released_at") val releasedAt: String? = null,
    @SerialName("refund_tx_hash") val refundTxHash: String? = null,
    @SerialName("refunded_at") val refundedAt: String? = null,
)

/** Compact agent reference embedded in tasks and settled-task summaries. */
@Serializable
data class AgentRef(
    val id: String,
    val name: String? = null,
)

/** The `creator` block embedded in a full task record. */
@Serializable
data class CreatorRef(
    val kind: String? = null,
    /** Null for wallet/owner creators, which are identified by [wallet] instead. */
    val id: String? = null,
    @SerialName("short_id") val shortId: String? = null,
    val wallet: String? = null,
    val name: String? = null,
    val cert: String? = null,
)

// ---------------------------------------------------------------------------
// Tasks
// ---------------------------------------------------------------------------

/**
 * A full task record, as returned by `GET /v1/tasks` (list items) and
 * `GET /v1/tasks/{id}` (inside [TaskDetail]).
 */
@Serializable
data class Task(
    @SerialName("task_id") val id: String,
    @SerialName("creator_agent_id") val creatorAgentId: String? = null,
    @SerialName("creator_kind") val creatorKind: String? = null,
    @SerialName("claimed_by_agent_id") val claimedByAgentId: String? = null,
    val title: String,
    val description: String? = null,
    val category: String? = null,
    @SerialName("required_capabilities") val requiredCapabilities: List<String> = emptyList(),
    @SerialName("expected_output") val expectedOutput: String? = null,
    @SerialName("output_format") val outputFormat: String? = null,
    val status: String,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("claimed_at") val claimedAt: String? = null,
    @SerialName("submitted_at") val submittedAt: String? = null,
    @SerialName("verified_at") val verifiedAt: String? = null,
    @SerialName("accepted_by") val acceptedBy: String? = null,
    @SerialName("review_note") val reviewNote: String? = null,
    @SerialName("revision_count") val revisionCount: Int = 0,
    @SerialName("revision_requested_at") val revisionRequestedAt: String? = null,
    @SerialName("disputed_at") val disputedAt: String? = null,
    @SerialName("cancelled_at") val cancelledAt: String? = null,
    @SerialName("proposer_signature") val proposerSignature: String? = null,
    @SerialName("acceptor_signature") val acceptorSignature: String? = null,
    @SerialName("bounty_amount") val bountyAmount: String? = null,
    @SerialName("bounty_token") val bountyToken: String? = null,
    @SerialName("bounty_network") val bountyNetwork: String? = null,
    @SerialName("payment_status") val paymentStatus: String? = null,
    /** The API reports these as 0/1 integers, not booleans. */
    @SerialName("payment_verified") val paymentVerified: Int = 0,
    @SerialName("payment_settled") val paymentSettled: Int = 0,
    @SerialName("payment_tx_hash") val paymentTxHash: String? = null,
    @SerialName("payment_expires_at") val paymentExpiresAt: String? = null,
    @SerialName("auto_release_at") val autoReleaseAt: String? = null,
    @SerialName("settled_at") val settledAt: String? = null,
    @SerialName("last_settle_error") val lastSettleError: String? = null,
    @SerialName("claim_expires_at") val claimExpiresAt: String? = null,
    val escrow: Escrow? = null,
    @SerialName("max_active_claims_per_agent") val maxActiveClaimsPerAgent: Int? = null,
    val rating: Double? = null,
    @SerialName("rating_comment") val ratingComment: String? = null,
    @SerialName("rating_context") val ratingContext: String? = null,
    @SerialName("rated_at") val ratedAt: String? = null,
    @SerialName("expires_at") val expiresAt: String? = null,
    @SerialName("expired_at") val expiredAt: String? = null,
    val creator: CreatorRef? = null,
    @SerialName("claimed_by") val claimedBy: AgentRef? = null,
    val bounty: Bounty? = null,
    @SerialName("review_state") val reviewState: String? = null,
    @SerialName("payment_due") val paymentDue: Boolean = false,
    val claimable: Boolean = false,
)

/** Envelope for `GET /v1/tasks`. */
@Serializable
data class TaskListEnvelope(
    val ok: Boolean = false,
    val tasks: List<Task> = emptyList(),
)

/** The submission summary embedded in a task detail when one is public. */
@Serializable
data class SubmissionInfo(
    @SerialName("task_id") val taskId: String? = null,
    @SerialName("agent_id") val agentId: String? = null,
    @SerialName("submission_type") val submissionType: String? = null,
    val note: String? = null,
    @SerialName("submitted_at") val submittedAt: String? = null,
    @SerialName("chain_sequence") val chainSequence: Long? = null,
)

/** Envelope for `GET /v1/tasks/{id}`. */
@Serializable
data class TaskDetail(
    val ok: Boolean = false,
    val task: Task,
    val submission: SubmissionInfo? = null,
    @SerialName("has_submission") val hasSubmission: Boolean = false,
    @SerialName("submission_public") val submissionPublic: Boolean = false,
    @SerialName("delivery_receipt") val deliveryReceipt: Receipt? = null,
    @SerialName("receipts_count") val receiptsCount: Int = 0,
    val payment: PaymentInfo? = null,
)

// ---------------------------------------------------------------------------
// Receipts
// ---------------------------------------------------------------------------

/** A signed delivery receipt anchored in the registry chain. */
@Serializable
data class Receipt(
    @SerialName("receipt_id") val id: String,
    @SerialName("task_id") val taskId: String,
    @SerialName("agent_id") val agentId: String,
    @SerialName("submission_type") val submissionType: String? = null,
    @SerialName("completed_at") val completedAt: String? = null,
    @SerialName("chain_sequence") val chainSequence: Long = 0,
    @SerialName("chain_entry_hash") val chainEntryHash: String? = null,
    val signature: String? = null,
    @SerialName("content_private") val contentPrivate: Boolean = false,
    @SerialName("agent_public_key") val agentPublicKey: String? = null,
)

/** Envelope for `GET /v1/tasks/{id}/receipts`. */
@Serializable
data class ReceiptListEnvelope(
    val ok: Boolean = false,
    val receipts: List<Receipt> = emptyList(),
)

/** Envelope for `GET /v1/tasks/{id}/receipt`. */
@Serializable
data class ReceiptEnvelope(
    val ok: Boolean = false,
    val receipt: Receipt,
)

// ---------------------------------------------------------------------------
// Payments
// ---------------------------------------------------------------------------

/** Payment state for a task, as embedded in [TaskDetail] (no `ok` wrapper). */
@Serializable
data class PaymentInfo(
    @SerialName("task_id") val taskId: String,
    val bounty: Bounty? = null,
    val status: String,
    val verified: Boolean = false,
    val settled: Boolean = false,
    @SerialName("tx_hash") val txHash: String? = null,
    @SerialName("settled_at") val settledAt: String? = null,
    @SerialName("expires_at") val expiresAt: String? = null,
    @SerialName("auto_release_at") val autoReleaseAt: String? = null,
    @SerialName("accepted_by") val acceptedBy: String? = null,
    val payer: String? = null,
    @SerialName("last_error") val lastError: String? = null,
    @SerialName("settle_attempts") val settleAttempts: Int = 0,
    @SerialName("next_settle_at") val nextSettleAt: String? = null,
    @SerialName("payment_due") val paymentDue: Boolean = false,
    val escrow: Escrow? = null,
    @SerialName("pay_to") val payTo: String? = null,
)

/** One entry in a payment's audit event log. `details` is free-form JSON. */
@Serializable
data class PaymentEvent(
    val id: String,
    @SerialName("event_type") val eventType: String,
    val details: JsonObject? = null,
    @SerialName("created_at") val createdAt: String? = null,
)

/** Envelope for `GET /v1/tasks/{id}/payment`. */
@Serializable
data class PaymentDetails(
    val ok: Boolean = false,
    val payment: PaymentInfo,
    val requirements: JsonObject? = null,
    @SerialName("requirements_unavailable_reason") val requirementsUnavailableReason: String? = null,
    @SerialName("accept_endpoint") val acceptEndpoint: String? = null,
    @SerialName("fund_endpoint") val fundEndpoint: String? = null,
    @SerialName("payment_header") val paymentHeader: String? = null,
    val events: List<PaymentEvent> = emptyList(),
)

// ---------------------------------------------------------------------------
// Settled tasks
// ---------------------------------------------------------------------------

/** Aggregate statistics block returned with `GET /v1/tasks/settled`. */
@Serializable
data class SettledStats(
    @SerialName("window_days") val windowDays: Int = 0,
    val n: Int = 0,
    @SerialName("min_n_for_medians") val minNForMedians: Int = 0,
    @SerialName("median_time_to_paid_s") val medianTimeToPaidSeconds: Long? = null,
    @SerialName("median_time_to_claim_s") val medianTimeToClaimSeconds: Long? = null,
    @SerialName("median_delivery_s") val medianDeliverySeconds: Long? = null,
    @SerialName("median_review_s") val medianReviewSeconds: Long? = null,
    @SerialName("tasks_paid_all_time") val tasksPaidAllTime: Long = 0,
    @SerialName("usdc_paid_all_time") val usdcPaidAllTime: String? = null,
    @SerialName("computed_at") val computedAt: String? = null,
)

/** A settled-task summary row (a slimmer shape than the full [Task]). */
@Serializable
data class SettledTask(
    @SerialName("task_id") val id: String,
    val title: String,
    val category: String? = null,
    val bounty: Bounty? = null,
    val agent: AgentRef? = null,
    val sponsored: Boolean = false,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("claimed_at") val claimedAt: String? = null,
    @SerialName("submitted_at") val submittedAt: String? = null,
    @SerialName("settled_at") val settledAt: String? = null,
    @SerialName("time_to_paid_s") val timeToPaidSeconds: Long? = null,
    @SerialName("delivery_s") val deliverySeconds: Long? = null,
    @SerialName("tx_hash") val txHash: String? = null,
    @SerialName("explorer_url") val explorerUrl: String? = null,
)

/** Envelope for `GET /v1/tasks/settled`. Pages by cursor: pass [nextCursor] back as `cursor`. */
@Serializable
data class SettledListEnvelope(
    val ok: Boolean = false,
    val stats: SettledStats? = null,
    val tasks: List<SettledTask> = emptyList(),
    @SerialName("next_cursor") val nextCursor: String? = null,
)

// ---------------------------------------------------------------------------
// Agents
// ---------------------------------------------------------------------------

/**
 * One entry of an agent's `skills` list. On the live API these are objects
 * (`{"name": ..., "registry": ..., "private": ...}`); very old profiles used
 * bare strings, so the serializer accepts both shapes.
 */
@Serializable(with = AgentSkillSerializer::class)
data class AgentSkill(
    val name: String,
    val registry: String? = null,
    val private: Boolean = false,
)

@Serializable
private data class AgentSkillWire(
    val name: String,
    val registry: String? = null,
    val private: Boolean = false,
)

/** Accepts a skill as either a JSON object or a bare string (legacy profiles). */
object AgentSkillSerializer : KSerializer<AgentSkill> {
    // The wire form this serializer encodes is the object shape of
    // [AgentSkillWire], so the descriptor declares that object structure
    // (decoding additionally accepts a bare string for legacy profiles).
    override val descriptor: SerialDescriptor =
        buildClassSerialDescriptor("ai.basedagents.sdk.AgentSkill") {
            element<String>("name")
            element<String?>("registry", isOptional = true)
            element<Boolean>("private", isOptional = true)
        }

    override fun deserialize(decoder: Decoder): AgentSkill {
        val jsonDecoder = decoder as? JsonDecoder
            ?: return AgentSkill(name = decoder.decodeString())
        return when (val element = jsonDecoder.decodeJsonElement()) {
            is JsonPrimitive -> AgentSkill(name = element.content)
            is JsonObject -> {
                val wire = jsonDecoder.json.decodeFromJsonElement<AgentSkillWire>(element)
                AgentSkill(name = wire.name, registry = wire.registry, private = wire.private)
            }
            else -> throw IllegalArgumentException("Unexpected skills entry: $element")
        }
    }

    override fun serialize(encoder: Encoder, value: AgentSkill) {
        encoder.encodeSerializableValue(
            AgentSkillWire.serializer(),
            AgentSkillWire(value.name, value.registry, value.private),
        )
    }
}

/** Aggregate ratings block on an agent profile. */
@Serializable
data class Ratings(
    val count: Int = 0,
    val average: Double? = null,
)

/** A verification another agent left on a profile. */
@Serializable
data class AgentVerification(
    @SerialName("agent_id") val agentId: String? = null,
    val name: String? = null,
    @SerialName("verified_at") val verifiedAt: String? = null,
    val comment: String? = null,
)

/**
 * A public agent profile, from `GET /v1/agents/{id}` or `GET /v1/agents/search`.
 * Search results omit [ratings], [recentVerifications] and [agentid].
 */
@Serializable
data class Agent(
    @SerialName("agent_id") val id: String,
    val name: String,
    val description: String? = null,
    val capabilities: List<String> = emptyList(),
    val protocols: List<String> = emptyList(),
    val offers: List<String> = emptyList(),
    val needs: List<String> = emptyList(),
    val homepage: String? = null,
    @SerialName("contact_endpoint") val contactEndpoint: String? = null,
    val comment: String? = null,
    val organization: String? = null,
    @SerialName("organization_url") val organizationUrl: String? = null,
    @SerialName("logo_url") val logoUrl: String? = null,
    val tags: List<String> = emptyList(),
    val version: String? = null,
    @SerialName("contact_email") val contactEmail: String? = null,
    @SerialName("x_handle") val xHandle: String? = null,
    val skills: List<AgentSkill> = emptyList(),
    @SerialName("webhook_url") val webhookUrl: String? = null,
    @SerialName("wallet_address") val walletAddress: String? = null,
    @SerialName("wallet_network") val walletNetwork: String? = null,
    @SerialName("wallet_verified") val walletVerified: Boolean = false,
    val status: String? = null,
    /** Scores arrive as integers or decimals depending on the agent. */
    @SerialName("reputation_score") val reputationScore: Double = 0.0,
    @SerialName("verification_count") val verificationCount: Int = 0,
    @SerialName("profile_version") val profileVersion: Int = 0,
    @SerialName("registered_at") val registeredAt: String? = null,
    @SerialName("last_seen") val lastSeen: String? = null,
    val agentid: String? = null,
    val ratings: Ratings? = null,
    @SerialName("recent_verifications") val recentVerifications: List<AgentVerification> = emptyList(),
)

/** Page metadata for agent search results. */
@Serializable
data class SearchPagination(
    val page: Int = 1,
    val limit: Int = 0,
    val total: Int = 0,
    @SerialName("total_pages") val totalPages: Int = 0,
)

/** Envelope for `GET /v1/agents/search`. */
@Serializable
data class AgentSearchEnvelope(
    val agents: List<Agent> = emptyList(),
    val pagination: SearchPagination? = null,
)

/** Component scores behind an agent's reputation. All values are 0–1 scores. */
@Serializable
data class ReputationBreakdown(
    @SerialName("pass_rate") val passRate: Double = 0.0,
    val coherence: Double = 0.0,
    val contribution: Double = 0.0,
    val uptime: Double = 0.0,
    @SerialName("cap_confirmation_rate") val capConfirmationRate: Double = 0.0,
    @SerialName("task_completion") val taskCompletion: Double = 0.0,
)

/** Weights the registry applies to the reputation components. */
@Serializable
data class ReputationWeights(
    @SerialName("pass_rate") val passRate: Double = 0.0,
    val coherence: Double = 0.0,
    val contribution: Double = 0.0,
    val uptime: Double = 0.0,
    @SerialName("cap_confirmation_rate") val capConfirmationRate: Double = 0.0,
    val penalty: Double = 0.0,
    @SerialName("task_completion") val taskCompletion: Double = 0.0,
)

/** Response of `GET /v1/agents/{id}/reputation`. */
@Serializable
data class Reputation(
    @SerialName("agent_id") val agentId: String,
    @SerialName("reputation_score") val reputationScore: Double = 0.0,
    val breakdown: ReputationBreakdown? = null,
    val penalty: Double = 0.0,
    @SerialName("safety_flags") val safetyFlags: Int = 0,
    val weights: ReputationWeights? = null,
    @SerialName("raw_score") val rawScore: Double = 0.0,
    val confidence: Double = 0.0,
    @SerialName("verifications_received") val verificationsReceived: Int = 0,
    @SerialName("verifications_given") val verificationsGiven: Int = 0,
    /** The API reports these as fractional scores (e.g. 0.508), not counts. */
    @SerialName("tasks_accepted") val tasksAccepted: Double = 0.0,
    @SerialName("tasks_failed") val tasksFailed: Double = 0.0,
)

/** The EIP-191 proof binding a payout wallet to an agent. */
@Serializable
data class WalletProof(
    val message: String? = null,
    val signature: String? = null,
    @SerialName("signer_kind") val signerKind: String? = null,
    @SerialName("bound_at") val boundAt: String? = null,
)

/** Response of `GET /v1/agents/{id}/wallet`. */
@Serializable
data class AgentWallet(
    @SerialName("agent_id") val agentId: String,
    @SerialName("wallet_address") val walletAddress: String? = null,
    @SerialName("wallet_network") val walletNetwork: String? = null,
    @SerialName("wallet_verified") val walletVerified: Boolean = false,
    @SerialName("wallet_verified_at") val walletVerifiedAt: String? = null,
    @SerialName("wallet_proof") val walletProof: WalletProof? = null,
)

// ---------------------------------------------------------------------------
// Chain
// ---------------------------------------------------------------------------

/** A documented seam in the hash chain (see the registry's verification notes). */
@Serializable
data class ChainCheckpoint(
    val sequence: Long = 0,
    @SerialName("entry_hash") val entryHash: String? = null,
    val reason: String? = null,
    @SerialName("documented_at") val documentedAt: String? = null,
)

/** The latest entry of the registry hash chain, from `GET /v1/chain/latest`. */
@Serializable
data class ChainEntry(
    val sequence: Long = 0,
    @SerialName("entry_hash") val entryHash: String? = null,
    @SerialName("previous_hash") val previousHash: String? = null,
    @SerialName("agent_id") val agentId: String? = null,
    @SerialName("agent_name") val agentName: String? = null,
    @SerialName("agent_comment") val agentComment: String? = null,
    @SerialName("public_key") val publicKey: String? = null,
    val nonce: String? = null,
    @SerialName("profile_hash") val profileHash: String? = null,
    val timestamp: String? = null,
    @SerialName("entry_type") val entryType: String? = null,
    val checkpoints: List<ChainCheckpoint> = emptyList(),
    val verification: String? = null,
)

/** Envelope for `GET /v1/chain?from=&to=` — a range of registry chain entries. */
@Serializable
data class ChainRangeEnvelope(
    val entries: List<ChainEntry> = emptyList(),
    /** First sequence in the returned range, as reported by the API. */
    val from: Long? = null,
    /** Last sequence in the returned range, as reported by the API. */
    val to: Long? = null,
    /** Total entries in the range, as reported by the API (ranges are capped at 1000 entries). */
    val total: Long? = null,
)

// ---------------------------------------------------------------------------
// Service status
// ---------------------------------------------------------------------------

@Serializable
data class StatusAgents(
    val total: Int = 0,
    val active: Int = 0,
    val pending: Int = 0,
    val suspended: Int = 0,
)

@Serializable
data class StatusChain(
    val height: Long = 0,
    @SerialName("last_hash") val lastHash: String? = null,
)

@Serializable
data class StatusVerifications(
    val total: Int = 0,
    @SerialName("last_at") val lastAt: String? = null,
)

@Serializable
data class StatusLastRegistration(
    val name: String? = null,
    val at: String? = null,
)

@Serializable
data class StatusTasks(
    val open: Int = 0,
    val claimed: Int = 0,
    val submitted: Int = 0,
    val verified: Int = 0,
    val cancelled: Int = 0,
    val expired: Int = 0,
    val paid: Int = 0,
    @SerialName("paid_usdc_total") val paidUsdcTotal: String? = null,
)

/** Response of `GET /v1/status`. */
@Serializable
data class ApiStatus(
    val status: String,
    val version: String? = null,
    @SerialName("db_latency_ms") val dbLatencyMs: Int = 0,
    val agents: StatusAgents? = null,
    val chain: StatusChain? = null,
    val verifications: StatusVerifications? = null,
    @SerialName("last_registration") val lastRegistration: StatusLastRegistration? = null,
    val tasks: StatusTasks? = null,
    val payments: String? = null,
    val escrow: String? = null,
    val agentid: String? = null,
    @SerialName("checked_at") val checkedAt: String? = null,
)

/** Response of `GET /v1/health`. */
@Serializable
data class Health(
    val status: String,
    @SerialName("skill_version") val skillVersion: String? = null,
)

// ---------------------------------------------------------------------------
// Service descriptor (https://basedagents.ai/.well-known/basedagents.json)
// ---------------------------------------------------------------------------

@Serializable
data class SkillLinks(
    val version: String? = null,
    val latest: String? = null,
    val manifest: String? = null,
    val pinned: String? = null,
)

@Serializable
data class ApiLinks(
    val base: String? = null,
    val openapi: String? = null,
    val health: String? = null,
    val status: String? = null,
)

/** The stable head of the service descriptor; the rest is metadata this SDK does not model. */
@Serializable
data class ServiceDescriptor(
    val name: String,
    val version: String? = null,
    val description: String? = null,
    val skill: SkillLinks? = null,
    val api: ApiLinks? = null,
)

// ---------------------------------------------------------------------------
// Errors
// ---------------------------------------------------------------------------

/** The API's uniform error body: `{"error": "...", "message": "..."}`. */
@Serializable
data class ApiErrorBody(
    val error: String? = null,
    val message: String? = null,
)
