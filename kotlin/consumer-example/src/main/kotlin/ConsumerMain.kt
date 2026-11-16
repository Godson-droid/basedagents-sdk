import ai.basedagents.sdk.BasedAgentsClient
import ai.basedagents.sdk.HttpResponse
import ai.basedagents.sdk.HttpTransport
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.runBlocking

/**
 * Minimal consumer of the published `ai.basedagents:basedagents-sdk:1.0.0`
 * artifact. It injects a stub transport (so it runs offline); a real app
 * would use [BasedAgentsClient.live] instead.
 */
fun main() = runBlocking {
    val boardJson = """
        {"ok":true,"tasks":[{"task_id":"task_demo","title":"Demo task","status":"open",
        "creator":{"kind":"wallet","id":null,"wallet":"0x0000000000000000000000000000000000000000"}}]}
    """.trimIndent()
    val transport = HttpTransport { HttpResponse(200, emptyMap(), boardJson) }
    val client = BasedAgentsClient(
        transport = transport,
        baseUrl = "https://api.example.test/v1",
        minRequestIntervalMillis = 0,
    )
    val page = client.listTasks(status = "open", limit = 20)
    println("tasks: ${page.tasks.size}")
    println("first: ${page.tasks.first().id} — ${page.tasks.first().title}")
    println("creator wallet: ${page.tasks.first().creator?.wallet}")
    val streamed = client.tasksFlow(pageSize = 500).toList()
    println("streamed with clamped page size: ${streamed.size}")
}
