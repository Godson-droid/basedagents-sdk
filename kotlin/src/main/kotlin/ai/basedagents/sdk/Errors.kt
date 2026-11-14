package ai.basedagents.sdk

/**
 * Error taxonomy for the BasedAgents read API.
 *
 * Every failure surfaced by [BasedAgentsClient] is a [BasedAgentsException].
 * HTTP failures carry the API's machine-readable error [code] and human
 * [message] (from the `{"error", "message"}` body) when the server sent them.
 */
sealed class BasedAgentsException(message: String, cause: Throwable? = null) :
    Exception(message, cause) {

    /** Base class for failures where the server answered with a non-2xx status. */
    sealed class Api(
        val statusCode: Int,
        val code: String?,
        val apiMessage: String?,
    ) : BasedAgentsException(
        buildString {
            append("HTTP ").append(statusCode)
            if (code != null) append(" (").append(code).append(")")
            if (apiMessage != null) append(": ").append(apiMessage)
        },
    )

    /** 404 — the task or agent does not exist. */
    class NotFound(code: String? = null, apiMessage: String? = null) :
        Api(404, code, apiMessage)

    /** 401/403 — the endpoint needs an AgentSig header this read-only client does not send. */
    class Unauthorized(statusCode: Int = 401, code: String? = null, apiMessage: String? = null) :
        Api(statusCode, code, apiMessage)

    /** 429 — slow down. [retryAfterSeconds] mirrors the `Retry-After` header when present. */
    class RateLimited(
        code: String? = null,
        apiMessage: String? = null,
        val retryAfterSeconds: Long? = null,
    ) : Api(429, code, apiMessage)

    /** Any 5xx — the failure is on the server side. */
    class ServerError(statusCode: Int, code: String? = null, apiMessage: String? = null) :
        Api(statusCode, code, apiMessage)

    /** Any other non-2xx status not covered by the cases above. */
    class UnexpectedStatus(statusCode: Int, code: String? = null, apiMessage: String? = null) :
        Api(statusCode, code, apiMessage)

    /** The request never completed (DNS, connect, TLS, timeout, interruption). */
    class NetworkError(cause: Throwable) :
        BasedAgentsException("Network error: ${cause.message ?: cause.javaClass.simpleName}", cause)

    /** A 2xx response whose body did not match the expected model. */
    class DecodeError(cause: Throwable) :
        BasedAgentsException("Could not decode response: ${cause.message}", cause)
}
