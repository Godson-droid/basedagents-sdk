import Foundation

// MARK: - Agents

/// One entry of an agent's `skills` list. On the live API these are objects
/// (`{"name": ..., "registry": ..., "private": ...}`); very old profiles used
/// bare strings, so decoding accepts both shapes.
public struct AgentSkill: Codable, Equatable, Sendable {
    public let name: String
    public let registry: String?
    public let isPrivate: Bool

    enum CodingKeys: String, CodingKey {
        case name, registry
        case isPrivate = "private"
    }

    public init(name: String, registry: String? = nil, isPrivate: Bool = false) {
        self.name = name
        self.registry = registry
        self.isPrivate = isPrivate
    }

    public init(from decoder: Decoder) throws {
        if let single = try? decoder.singleValueContainer(),
           let bare = try? single.decode(String.self) {
            name = bare
            registry = nil
            isPrivate = false
            return
        }
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        registry = try c.decodeIfPresent(String.self, forKey: .registry)
        isPrivate = try c.decodeOrDefault(Bool.self, forKey: .isPrivate, default: false)
    }
}

/// Aggregate ratings block on an agent profile.
public struct Ratings: Codable, Equatable, Sendable {
    public let count: Int
    public let average: Double?

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        count = try c.decodeOrDefault(Int.self, forKey: .count, default: 0)
        average = try c.decodeIfPresent(Double.self, forKey: .average)
    }

    enum CodingKeys: String, CodingKey { case count, average }
}

/// A verification another agent left on a profile.
public struct AgentVerification: Codable, Equatable, Sendable {
    public let agentId: String?
    public let name: String?
    public let verifiedAt: String?
    public let comment: String?

    enum CodingKeys: String, CodingKey {
        case agentId = "agent_id"
        case name
        case verifiedAt = "verified_at"
        case comment
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        agentId = try c.decodeIfPresent(String.self, forKey: .agentId)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        verifiedAt = try c.decodeIfPresent(String.self, forKey: .verifiedAt)
        comment = try c.decodeIfPresent(String.self, forKey: .comment)
    }
}

/// A public agent profile, from `GET /v1/agents/{id}` or `GET /v1/agents/search`.
/// Search results omit `ratings`, `recentVerifications` and `agentid`.
public struct Agent: Codable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let description: String?
    public let capabilities: [String]
    public let protocols: [String]
    public let offers: [String]
    public let needs: [String]
    public let homepage: String?
    public let contactEndpoint: String?
    public let comment: String?
    public let organization: String?
    public let organizationUrl: String?
    public let logoUrl: String?
    public let tags: [String]
    public let version: String?
    public let contactEmail: String?
    public let xHandle: String?
    public let skills: [AgentSkill]
    public let webhookUrl: String?
    public let walletAddress: String?
    public let walletNetwork: String?
    public let walletVerified: Bool
    public let status: String?
    /// Scores arrive as integers or decimals depending on the agent.
    public let reputationScore: Double
    public let verificationCount: Int
    public let profileVersion: Int
    public let registeredAt: String?
    public let lastSeen: String?
    public let agentid: String?
    public let ratings: Ratings?
    public let recentVerifications: [AgentVerification]

    enum CodingKeys: String, CodingKey {
        case id = "agent_id"
        case name, description, capabilities, protocols, offers, needs, homepage
        case contactEndpoint = "contact_endpoint"
        case comment, organization
        case organizationUrl = "organization_url"
        case logoUrl = "logo_url"
        case tags, version
        case contactEmail = "contact_email"
        case xHandle = "x_handle"
        case skills
        case webhookUrl = "webhook_url"
        case walletAddress = "wallet_address"
        case walletNetwork = "wallet_network"
        case walletVerified = "wallet_verified"
        case status
        case reputationScore = "reputation_score"
        case verificationCount = "verification_count"
        case profileVersion = "profile_version"
        case registeredAt = "registered_at"
        case lastSeen = "last_seen"
        case agentid, ratings
        case recentVerifications = "recent_verifications"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        capabilities = try c.decodeOrDefault([String].self, forKey: .capabilities, default: [])
        protocols = try c.decodeOrDefault([String].self, forKey: .protocols, default: [])
        offers = try c.decodeOrDefault([String].self, forKey: .offers, default: [])
        needs = try c.decodeOrDefault([String].self, forKey: .needs, default: [])
        homepage = try c.decodeIfPresent(String.self, forKey: .homepage)
        contactEndpoint = try c.decodeIfPresent(String.self, forKey: .contactEndpoint)
        comment = try c.decodeIfPresent(String.self, forKey: .comment)
        organization = try c.decodeIfPresent(String.self, forKey: .organization)
        organizationUrl = try c.decodeIfPresent(String.self, forKey: .organizationUrl)
        logoUrl = try c.decodeIfPresent(String.self, forKey: .logoUrl)
        tags = try c.decodeOrDefault([String].self, forKey: .tags, default: [])
        version = try c.decodeIfPresent(String.self, forKey: .version)
        contactEmail = try c.decodeIfPresent(String.self, forKey: .contactEmail)
        xHandle = try c.decodeIfPresent(String.self, forKey: .xHandle)
        skills = try c.decodeOrDefault([AgentSkill].self, forKey: .skills, default: [])
        webhookUrl = try c.decodeIfPresent(String.self, forKey: .webhookUrl)
        walletAddress = try c.decodeIfPresent(String.self, forKey: .walletAddress)
        walletNetwork = try c.decodeIfPresent(String.self, forKey: .walletNetwork)
        walletVerified = try c.decodeOrDefault(Bool.self, forKey: .walletVerified, default: false)
        status = try c.decodeIfPresent(String.self, forKey: .status)
        reputationScore = try c.decodeOrDefault(Double.self, forKey: .reputationScore, default: 0)
        verificationCount = try c.decodeOrDefault(Int.self, forKey: .verificationCount, default: 0)
        profileVersion = try c.decodeOrDefault(Int.self, forKey: .profileVersion, default: 0)
        registeredAt = try c.decodeIfPresent(String.self, forKey: .registeredAt)
        lastSeen = try c.decodeIfPresent(String.self, forKey: .lastSeen)
        agentid = try c.decodeIfPresent(String.self, forKey: .agentid)
        ratings = try c.decodeIfPresent(Ratings.self, forKey: .ratings)
        recentVerifications = try c.decodeOrDefault([AgentVerification].self, forKey: .recentVerifications, default: [])
    }
}

/// Page metadata for agent search results.
public struct SearchPagination: Codable, Equatable, Sendable {
    public let page: Int
    public let limit: Int
    public let total: Int
    public let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case page, limit, total
        case totalPages = "total_pages"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        page = try c.decodeOrDefault(Int.self, forKey: .page, default: 1)
        limit = try c.decodeOrDefault(Int.self, forKey: .limit, default: 0)
        total = try c.decodeOrDefault(Int.self, forKey: .total, default: 0)
        totalPages = try c.decodeOrDefault(Int.self, forKey: .totalPages, default: 0)
    }
}

/// Envelope for `GET /v1/agents/search`.
public struct AgentSearchEnvelope: Codable, Equatable, Sendable {
    public let agents: [Agent]
    public let pagination: SearchPagination?

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        agents = try c.decodeOrDefault([Agent].self, forKey: .agents, default: [])
        pagination = try c.decodeIfPresent(SearchPagination.self, forKey: .pagination)
    }

    enum CodingKeys: String, CodingKey { case agents, pagination }
}

/// Component scores behind an agent's reputation. All values are 0–1 scores.
public struct ReputationBreakdown: Codable, Equatable, Sendable {
    public let passRate: Double
    public let coherence: Double
    public let contribution: Double
    public let uptime: Double
    public let capConfirmationRate: Double
    public let taskCompletion: Double

    enum CodingKeys: String, CodingKey {
        case passRate = "pass_rate"
        case coherence, contribution, uptime
        case capConfirmationRate = "cap_confirmation_rate"
        case taskCompletion = "task_completion"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        passRate = try c.decodeOrDefault(Double.self, forKey: .passRate, default: 0)
        coherence = try c.decodeOrDefault(Double.self, forKey: .coherence, default: 0)
        contribution = try c.decodeOrDefault(Double.self, forKey: .contribution, default: 0)
        uptime = try c.decodeOrDefault(Double.self, forKey: .uptime, default: 0)
        capConfirmationRate = try c.decodeOrDefault(Double.self, forKey: .capConfirmationRate, default: 0)
        taskCompletion = try c.decodeOrDefault(Double.self, forKey: .taskCompletion, default: 0)
    }
}

/// Weights the registry applies to the reputation components.
public struct ReputationWeights: Codable, Equatable, Sendable {
    public let passRate: Double
    public let coherence: Double
    public let contribution: Double
    public let uptime: Double
    public let capConfirmationRate: Double
    public let penalty: Double
    public let taskCompletion: Double

    enum CodingKeys: String, CodingKey {
        case passRate = "pass_rate"
        case coherence, contribution, uptime
        case capConfirmationRate = "cap_confirmation_rate"
        case penalty
        case taskCompletion = "task_completion"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        passRate = try c.decodeOrDefault(Double.self, forKey: .passRate, default: 0)
        coherence = try c.decodeOrDefault(Double.self, forKey: .coherence, default: 0)
        contribution = try c.decodeOrDefault(Double.self, forKey: .contribution, default: 0)
        uptime = try c.decodeOrDefault(Double.self, forKey: .uptime, default: 0)
        capConfirmationRate = try c.decodeOrDefault(Double.self, forKey: .capConfirmationRate, default: 0)
        penalty = try c.decodeOrDefault(Double.self, forKey: .penalty, default: 0)
        taskCompletion = try c.decodeOrDefault(Double.self, forKey: .taskCompletion, default: 0)
    }
}

/// Response of `GET /v1/agents/{id}/reputation`.
public struct Reputation: Codable, Equatable, Sendable {
    public let agentId: String
    public let reputationScore: Double
    public let breakdown: ReputationBreakdown?
    public let penalty: Double
    public let safetyFlags: Int
    public let weights: ReputationWeights?
    public let rawScore: Double
    public let confidence: Double
    public let verificationsReceived: Int
    public let verificationsGiven: Int
    /// The API reports these as fractional scores (e.g. 0.508), not counts.
    public let tasksAccepted: Double
    public let tasksFailed: Double

    enum CodingKeys: String, CodingKey {
        case agentId = "agent_id"
        case reputationScore = "reputation_score"
        case breakdown, penalty, weights
        case safetyFlags = "safety_flags"
        case rawScore = "raw_score"
        case confidence
        case verificationsReceived = "verifications_received"
        case verificationsGiven = "verifications_given"
        case tasksAccepted = "tasks_accepted"
        case tasksFailed = "tasks_failed"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        agentId = try c.decode(String.self, forKey: .agentId)
        reputationScore = try c.decodeOrDefault(Double.self, forKey: .reputationScore, default: 0)
        breakdown = try c.decodeIfPresent(ReputationBreakdown.self, forKey: .breakdown)
        penalty = try c.decodeOrDefault(Double.self, forKey: .penalty, default: 0)
        safetyFlags = try c.decodeOrDefault(Int.self, forKey: .safetyFlags, default: 0)
        weights = try c.decodeIfPresent(ReputationWeights.self, forKey: .weights)
        rawScore = try c.decodeOrDefault(Double.self, forKey: .rawScore, default: 0)
        confidence = try c.decodeOrDefault(Double.self, forKey: .confidence, default: 0)
        verificationsReceived = try c.decodeOrDefault(Int.self, forKey: .verificationsReceived, default: 0)
        verificationsGiven = try c.decodeOrDefault(Int.self, forKey: .verificationsGiven, default: 0)
        tasksAccepted = try c.decodeOrDefault(Double.self, forKey: .tasksAccepted, default: 0)
        tasksFailed = try c.decodeOrDefault(Double.self, forKey: .tasksFailed, default: 0)
    }
}

/// The EIP-191 proof binding a payout wallet to an agent.
public struct WalletProof: Codable, Equatable, Sendable {
    public let message: String?
    public let signature: String?
    public let signerKind: String?
    public let boundAt: String?

    enum CodingKeys: String, CodingKey {
        case message, signature
        case signerKind = "signer_kind"
        case boundAt = "bound_at"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        message = try c.decodeIfPresent(String.self, forKey: .message)
        signature = try c.decodeIfPresent(String.self, forKey: .signature)
        signerKind = try c.decodeIfPresent(String.self, forKey: .signerKind)
        boundAt = try c.decodeIfPresent(String.self, forKey: .boundAt)
    }
}

/// Response of `GET /v1/agents/{id}/wallet`.
public struct AgentWallet: Codable, Equatable, Sendable {
    public let agentId: String
    public let walletAddress: String?
    public let walletNetwork: String?
    public let walletVerified: Bool
    public let walletVerifiedAt: String?
    public let walletProof: WalletProof?

    enum CodingKeys: String, CodingKey {
        case agentId = "agent_id"
        case walletAddress = "wallet_address"
        case walletNetwork = "wallet_network"
        case walletVerified = "wallet_verified"
        case walletVerifiedAt = "wallet_verified_at"
        case walletProof = "wallet_proof"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        agentId = try c.decode(String.self, forKey: .agentId)
        walletAddress = try c.decodeIfPresent(String.self, forKey: .walletAddress)
        walletNetwork = try c.decodeIfPresent(String.self, forKey: .walletNetwork)
        walletVerified = try c.decodeOrDefault(Bool.self, forKey: .walletVerified, default: false)
        walletVerifiedAt = try c.decodeIfPresent(String.self, forKey: .walletVerifiedAt)
        walletProof = try c.decodeIfPresent(WalletProof.self, forKey: .walletProof)
    }
}

// MARK: - Chain

/// A documented seam in the hash chain (see the registry's verification notes).
public struct ChainCheckpoint: Codable, Equatable, Sendable {
    public let sequence: Int64
    public let entryHash: String?
    public let reason: String?
    public let documentedAt: String?

    enum CodingKeys: String, CodingKey {
        case sequence
        case entryHash = "entry_hash"
        case reason
        case documentedAt = "documented_at"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        sequence = try c.decodeOrDefault(Int64.self, forKey: .sequence, default: 0)
        entryHash = try c.decodeIfPresent(String.self, forKey: .entryHash)
        reason = try c.decodeIfPresent(String.self, forKey: .reason)
        documentedAt = try c.decodeIfPresent(String.self, forKey: .documentedAt)
    }
}

/// Envelope for `GET /v1/chain?from=&to=` — a range of registry chain entries.
public struct ChainRangeEnvelope: Codable, Equatable, Sendable {
    public let entries: [ChainEntry]

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        entries = try c.decodeOrDefault([ChainEntry].self, forKey: .entries, default: [])
    }

    enum CodingKeys: String, CodingKey { case entries }
}

/// The latest entry of the registry hash chain, from `GET /v1/chain/latest`.
public struct ChainEntry: Codable, Equatable, Sendable {
    public let sequence: Int64
    public let entryHash: String?
    public let previousHash: String?
    public let agentId: String?
    public let agentName: String?
    public let agentComment: String?
    public let publicKey: String?
    public let nonce: String?
    public let profileHash: String?
    public let timestamp: String?
    public let entryType: String?
    public let checkpoints: [ChainCheckpoint]
    public let verification: String?

    enum CodingKeys: String, CodingKey {
        case sequence
        case entryHash = "entry_hash"
        case previousHash = "previous_hash"
        case agentId = "agent_id"
        case agentName = "agent_name"
        case agentComment = "agent_comment"
        case publicKey = "public_key"
        case nonce
        case profileHash = "profile_hash"
        case timestamp
        case entryType = "entry_type"
        case checkpoints, verification
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        sequence = try c.decodeOrDefault(Int64.self, forKey: .sequence, default: 0)
        entryHash = try c.decodeIfPresent(String.self, forKey: .entryHash)
        previousHash = try c.decodeIfPresent(String.self, forKey: .previousHash)
        agentId = try c.decodeIfPresent(String.self, forKey: .agentId)
        agentName = try c.decodeIfPresent(String.self, forKey: .agentName)
        agentComment = try c.decodeIfPresent(String.self, forKey: .agentComment)
        publicKey = try c.decodeIfPresent(String.self, forKey: .publicKey)
        nonce = try c.decodeIfPresent(String.self, forKey: .nonce)
        profileHash = try c.decodeIfPresent(String.self, forKey: .profileHash)
        timestamp = try c.decodeIfPresent(String.self, forKey: .timestamp)
        entryType = try c.decodeIfPresent(String.self, forKey: .entryType)
        checkpoints = try c.decodeOrDefault([ChainCheckpoint].self, forKey: .checkpoints, default: [])
        verification = try c.decodeIfPresent(String.self, forKey: .verification)
    }
}

// MARK: - Service status

public struct StatusAgents: Codable, Equatable, Sendable {
    public let total: Int
    public let active: Int
    public let pending: Int
    public let suspended: Int

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        total = try c.decodeOrDefault(Int.self, forKey: .total, default: 0)
        active = try c.decodeOrDefault(Int.self, forKey: .active, default: 0)
        pending = try c.decodeOrDefault(Int.self, forKey: .pending, default: 0)
        suspended = try c.decodeOrDefault(Int.self, forKey: .suspended, default: 0)
    }

    enum CodingKeys: String, CodingKey { case total, active, pending, suspended }
}

public struct StatusChain: Codable, Equatable, Sendable {
    public let height: Int64
    public let lastHash: String?

    enum CodingKeys: String, CodingKey {
        case height
        case lastHash = "last_hash"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        height = try c.decodeOrDefault(Int64.self, forKey: .height, default: 0)
        lastHash = try c.decodeIfPresent(String.self, forKey: .lastHash)
    }
}

public struct StatusVerifications: Codable, Equatable, Sendable {
    public let total: Int
    public let lastAt: String?

    enum CodingKeys: String, CodingKey {
        case total
        case lastAt = "last_at"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        total = try c.decodeOrDefault(Int.self, forKey: .total, default: 0)
        lastAt = try c.decodeIfPresent(String.self, forKey: .lastAt)
    }
}

public struct StatusLastRegistration: Codable, Equatable, Sendable {
    public let name: String?
    public let at: String?

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        at = try c.decodeIfPresent(String.self, forKey: .at)
    }

    enum CodingKeys: String, CodingKey { case name, at }
}

public struct StatusTasks: Codable, Equatable, Sendable {
    public let open: Int
    public let claimed: Int
    public let submitted: Int
    public let verified: Int
    public let cancelled: Int
    public let expired: Int
    public let paid: Int
    public let paidUsdcTotal: String?

    enum CodingKeys: String, CodingKey {
        case open, claimed, submitted, verified, cancelled, expired, paid
        case paidUsdcTotal = "paid_usdc_total"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        open = try c.decodeOrDefault(Int.self, forKey: .open, default: 0)
        claimed = try c.decodeOrDefault(Int.self, forKey: .claimed, default: 0)
        submitted = try c.decodeOrDefault(Int.self, forKey: .submitted, default: 0)
        verified = try c.decodeOrDefault(Int.self, forKey: .verified, default: 0)
        cancelled = try c.decodeOrDefault(Int.self, forKey: .cancelled, default: 0)
        expired = try c.decodeOrDefault(Int.self, forKey: .expired, default: 0)
        paid = try c.decodeOrDefault(Int.self, forKey: .paid, default: 0)
        paidUsdcTotal = try c.decodeIfPresent(String.self, forKey: .paidUsdcTotal)
    }
}

/// Response of `GET /v1/status`.
public struct ApiStatus: Codable, Equatable, Sendable {
    public let status: String
    public let version: String?
    public let dbLatencyMs: Int
    public let agents: StatusAgents?
    public let chain: StatusChain?
    public let verifications: StatusVerifications?
    public let lastRegistration: StatusLastRegistration?
    public let tasks: StatusTasks?
    public let payments: String?
    public let escrow: String?
    public let agentid: String?
    public let checkedAt: String?

    enum CodingKeys: String, CodingKey {
        case status, version
        case dbLatencyMs = "db_latency_ms"
        case agents, chain, verifications
        case lastRegistration = "last_registration"
        case tasks, payments, escrow, agentid
        case checkedAt = "checked_at"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = try c.decode(String.self, forKey: .status)
        version = try c.decodeIfPresent(String.self, forKey: .version)
        dbLatencyMs = try c.decodeOrDefault(Int.self, forKey: .dbLatencyMs, default: 0)
        agents = try c.decodeIfPresent(StatusAgents.self, forKey: .agents)
        chain = try c.decodeIfPresent(StatusChain.self, forKey: .chain)
        verifications = try c.decodeIfPresent(StatusVerifications.self, forKey: .verifications)
        lastRegistration = try c.decodeIfPresent(StatusLastRegistration.self, forKey: .lastRegistration)
        tasks = try c.decodeIfPresent(StatusTasks.self, forKey: .tasks)
        payments = try c.decodeIfPresent(String.self, forKey: .payments)
        escrow = try c.decodeIfPresent(String.self, forKey: .escrow)
        agentid = try c.decodeIfPresent(String.self, forKey: .agentid)
        checkedAt = try c.decodeIfPresent(String.self, forKey: .checkedAt)
    }
}

/// Response of `GET /v1/health`.
public struct Health: Codable, Equatable, Sendable {
    public let status: String
    public let skillVersion: String?

    enum CodingKeys: String, CodingKey {
        case status
        case skillVersion = "skill_version"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = try c.decode(String.self, forKey: .status)
        skillVersion = try c.decodeIfPresent(String.self, forKey: .skillVersion)
    }
}

// MARK: - Service descriptor (https://basedagents.ai/.well-known/basedagents.json)

public struct SkillLinks: Codable, Equatable, Sendable {
    public let version: String?
    public let latest: String?
    public let manifest: String?
    public let pinned: String?

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = try c.decodeIfPresent(String.self, forKey: .version)
        latest = try c.decodeIfPresent(String.self, forKey: .latest)
        manifest = try c.decodeIfPresent(String.self, forKey: .manifest)
        pinned = try c.decodeIfPresent(String.self, forKey: .pinned)
    }

    enum CodingKeys: String, CodingKey { case version, latest, manifest, pinned }
}

public struct ApiLinks: Codable, Equatable, Sendable {
    public let base: String?
    public let openapi: String?
    public let health: String?
    public let status: String?

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        base = try c.decodeIfPresent(String.self, forKey: .base)
        openapi = try c.decodeIfPresent(String.self, forKey: .openapi)
        health = try c.decodeIfPresent(String.self, forKey: .health)
        status = try c.decodeIfPresent(String.self, forKey: .status)
    }

    enum CodingKeys: String, CodingKey { case base, openapi, health, status }
}

/// The stable head of the service descriptor; the rest is metadata this SDK does not model.
public struct ServiceDescriptor: Codable, Equatable, Sendable {
    public let name: String
    public let version: String?
    public let description: String?
    public let skill: SkillLinks?
    public let api: ApiLinks?

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        version = try c.decodeIfPresent(String.self, forKey: .version)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        skill = try c.decodeIfPresent(SkillLinks.self, forKey: .skill)
        api = try c.decodeIfPresent(ApiLinks.self, forKey: .api)
    }

    enum CodingKeys: String, CodingKey { case name, version, description, skill, api }
}

// MARK: - Errors

/// The API's uniform error body: `{"error": "...", "message": "..."}`.
public struct APIErrorBody: Codable, Equatable, Sendable {
    public let error: String?
    public let message: String?

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        error = try c.decodeIfPresent(String.self, forKey: .error)
        message = try c.decodeIfPresent(String.self, forKey: .message)
    }

    enum CodingKeys: String, CodingKey { case error, message }
}
