package ai.basedagents.sdk

import java.io.IOException

/** Loads a recorded API response from the shared fixture corpus on the test classpath. */
object Fixtures {
    fun text(name: String): String =
        Fixtures::class.java.getResourceAsStream("/fixtures/$name.json")?.bufferedReader()?.readText()
            ?: error("Missing test fixture: $name.json")

    inline fun <reified T> decode(name: String): T =
        BasedAgentsJson.decodeFromString<T>(text(name))
}

/**
 * An [HttpTransport] stub driven by a handler over the request URL.
 * Records every requested URL so tests can assert paths and query params.
 */
class FakeTransport(private val handler: (String) -> HttpResponse) : HttpTransport {
    val requestedUrls = mutableListOf<String>()

    override suspend fun get(url: String): HttpResponse {
        requestedUrls += url
        return handler(url)
    }
}

/** Builds a fake transport that always answers with the same status/body. */
fun transportReturning(status: Int, body: String, headers: Map<String, List<String>> = emptyMap()) =
    FakeTransport { HttpResponse(status, headers, body) }

/** Builds a fake transport that serves a fixture body with the given status. */
fun transportServing(fixture: String, status: Int = 200) =
    transportReturning(status, Fixtures.text(fixture))

/** Builds a fake transport whose every request fails at the transport level. */
fun failingTransport() = FakeTransport { throw IOException("connection reset") }
