# BasedAgents SDK task — Buyer Revision Request #1

Task: task_zFihEF6ij4a3tUP0ENWo1 (mobile read-only SDK slice, Kotlin + Swift)
Received: 2026-11-15T21:46:26Z (live CLI state check)
Status: claimed, revision_count 1, next_action: revise and deliver again.
Claim expires 2026-11-21T16:11Z; up to 3 revision rounds.

Buyer verified first: repo @3fe3ec1 matches all 92 manifest hashes; offline
reproduced gradle test 41/41 and swift test 41/41; fixtures match live bytes;
error taxonomy, 350 ms pacing and settled cursor paging verified over real HTTP.
A mock of today's API pages, driven through both live() clients, found these
blocking gaps (verbatim review note):

1. Models vs live shapes (both platforms): agent skills are objects
   {name,registry,private} (130/1197 agents; default searchAgents() fails);
   reputation tasks_accepted is fractional (0.508, so getReputation fails);
   task creator.id is null for wallet/owner creators (tasksFlow()/tasksStream()
   fail on page 2). Pass: shared fixtures for all three shapes decode in both
   suites.
2. agents/search paging: add page= and a flow/stream helper over total_pages
   (limit<=100). Pass: offline multi-page test returns every agent.
3. Clamp board page size to 1..100. Pass: tasksFlow/tasksStream(pageSize=500)
   succeeds sending limit=100 (now HTTP 400).
4. Chain: add GET /v1/chain?from=&to= and /v1/chain/{sequence} on both, with
   fixtures and coverage rows.
5. Gradle snippet: ai.basedagents:basedagents-sdk:1.0.0 is not on Maven
   Central. Pass: a fresh consumer builds with the documented snippet
   (publish, or document includeBuild/mavenLocal).
6. Cancellation: cancelled calls keep running about 10 s (Kotlin blocking
   send; Swift dataTask with no cancellation handler). Pass: a test per
   platform shows a call cancelled against a stalled server ends within 1 s
   with CancellationException/CancellationError.
7. Idiom: the public Swift model `Task` shadows concurrency's Task, so
   `Task { }` does not compile in any module importing the SDK; rename it.
   Kotlin live() uses java.net.http, which Android lacks; ship an
   Android-capable default transport. Pass: consumer `Task { }` compiles;
   no java.net.http in the default path.
8. Include verbatim `gradle test` output (e.g. from CI).
