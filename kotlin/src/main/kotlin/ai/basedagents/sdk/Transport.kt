package ai.basedagents.sdk

import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors
import java.util.concurrent.Future
import java.util.concurrent.atomic.AtomicReference
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/** A raw HTTP response as seen by the client: status, headers and body text. */
data class HttpResponse(
    val statusCode: Int,
    val headers: Map<String, List<String>>,
    val body: String,
)

/**
 * The client's only network dependency: perform a GET and return the raw
 * response. Implementations must not throw for non-2xx statuses (the client
 * maps those to [BasedAgentsException.Api]); they may throw [IOException]
 * for transport-level failures, which the client maps to
 * [BasedAgentsException.NetworkError].
 *
 * Implementations must also honour coroutine cancellation: when the calling
 * coroutine is cancelled, the in-flight request must be abandoned promptly
 * and a [kotlinx.coroutines.CancellationException] must surface.
 *
 * Tests substitute a fake implementation, so the whole client is exercisable
 * offline.
 */
fun interface HttpTransport {
    suspend fun get(url: String): HttpResponse
}

/**
 * Production transport backed by [HttpURLConnection].
 *
 * `HttpURLConnection` is part of both the JDK and Android, so this default
 * transport works on Android as well as the JVM — unlike the desktop-only
 * HttpClient API, which Android does not ship. The blocking socket work runs on a daemon
 * worker thread; cancelling the calling coroutine disconnects the
 * connection, which unblocks the read immediately, and the coroutine
 * resumes with [kotlinx.coroutines.CancellationException].
 *
 * Identifies itself with a descriptive `User-Agent` and asks for JSON.
 * Redirects are not followed: the API answers directly, and a redirect in
 * response to an API call is a configuration error worth surfacing.
 */
class UrlConnectionTransport(
    private val connectTimeoutMillis: Int = 10_000,
    private val readTimeoutMillis: Int = 30_000,
    private val userAgent: String = "basedagents-sdk-kotlin/1.0",
) : HttpTransport {

    private val executor = Executors.newCachedThreadPool { runnable ->
        Thread(runnable, "basedagents-http").apply { isDaemon = true }
    }

    override suspend fun get(url: String): HttpResponse =
        suspendCancellableCoroutine { continuation ->
            val connection = AtomicReference<HttpURLConnection?>(null)
            val future: Future<*> = executor.submit {
                try {
                    val conn = (URL(url).openConnection() as HttpURLConnection).apply {
                        requestMethod = "GET"
                        connectTimeout = connectTimeoutMillis
                        readTimeout = readTimeoutMillis
                        instanceFollowRedirects = false
                        setRequestProperty("Accept", "application/json")
                        setRequestProperty("User-Agent", userAgent)
                    }
                    connection.set(conn)
                    if (continuation.isCancelled) {
                        conn.disconnect()
                        return@submit
                    }
                    val status = conn.responseCode
                    val stream = if (status in 200..299) conn.inputStream else conn.errorStream
                    val body = stream?.bufferedReader(Charsets.UTF_8)?.use { it.readText() } ?: ""
                    val headers = conn.headerFields
                        .filterKeys { it != null }
                        .mapKeys { it.key!! }
                    conn.disconnect()
                    if (continuation.isActive) {
                        continuation.resume(HttpResponse(status, headers, body))
                    }
                } catch (e: Exception) {
                    if (continuation.isActive) {
                        continuation.resumeWithException(
                            if (e is IOException) e
                            else IOException("Request to $url failed: ${e.message}", e),
                        )
                    }
                }
            }
            continuation.invokeOnCancellation {
                future.cancel(true)
                try {
                    connection.get()?.disconnect()
                } catch (_: Exception) {
                    // Best effort: the worker thread also checks isCancelled.
                }
            }
        }
}
