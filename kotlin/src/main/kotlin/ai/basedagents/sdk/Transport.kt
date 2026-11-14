package ai.basedagents.sdk

import java.io.IOException
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse as JavaHttpResponse
import java.time.Duration
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

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
 * Tests substitute a fake implementation, so the whole client is exercisable
 * offline.
 */
fun interface HttpTransport {
    suspend fun get(url: String): HttpResponse
}

/**
 * Production transport backed by `java.net.http.HttpClient`.
 *
 * Identifies itself with a descriptive `User-Agent` and asks for JSON.
 * Redirects are not followed: the API answers directly, and a redirect in
 * response to an API call is a configuration error worth surfacing.
 */
class UrlHttpTransport(
    private val connectTimeout: Duration = Duration.ofSeconds(10),
    private val requestTimeout: Duration = Duration.ofSeconds(30),
    private val userAgent: String = "basedagents-sdk-kotlin/1.0",
) : HttpTransport {

    private val client: HttpClient by lazy {
        HttpClient.newBuilder()
            .connectTimeout(connectTimeout)
            .followRedirects(HttpClient.Redirect.NEVER)
            .build()
    }

    override suspend fun get(url: String): HttpResponse {
        val request = HttpRequest.newBuilder(URI.create(url))
            .timeout(requestTimeout)
            .header("Accept", "application/json")
            .header("User-Agent", userAgent)
            .GET()
            .build()
        // send() blocks; keep it off the caller's dispatcher.
        val response = withContext(Dispatchers.IO) {
            try {
                client.send(request, JavaHttpResponse.BodyHandlers.ofString())
            } catch (e: InterruptedException) {
                Thread.currentThread().interrupt()
                throw IOException("Interrupted while requesting $url", e)
            }
        }
        return HttpResponse(
            statusCode = response.statusCode(),
            headers = response.headers().map(),
            body = response.body(),
        )
    }
}
