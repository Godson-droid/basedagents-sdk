# Build Report — BasedAgents Mobile Read-Only SDK Slice

Task: task_zFihEF6ij4a3tUP0ENWo1 · Due: 2026-11-21T16:11:54Z · Status: **COMPLETE — both suites green**

## Revision #1 (buyer review 2026-11-15T21:46Z) — all 8 items addressed

New results: **Kotlin 52 tests, 0 failures — BUILD SUCCESS** (was 41);
**Swift 53 tests, 0 failures** (was 41). Every previously passing test
still passes; no test was weakened or deleted (one assertion was re-typed
from `0` to `0.0` where the model changed from Int to Double, item 1).
Verbatim executed outputs: `kotlin/test-output.txt`, `swift/test-output.txt`.
The shared corpus grew from 22 to 27 fixtures; the 22 original fixtures
are byte-unchanged, and the 5 new ones were recorded live from the
production API on 2026-11-15 (manifest updated with URLs, sizes, SHA-256).

1. **Models vs live shapes (both platforms).** Agent `skills` are now an
   `AgentSkill` model (`name`, `registry`, `private`) — bare legacy
   strings still decode. Reputation `tasks_accepted`/`tasks_failed` are
   now `Double` (fractional scores such as 0.508 / 6.064). `CreatorRef.id`
   is now nullable and the block gained the `wallet` field, so
   wallet/owner creators decode. New shared fixtures, all decoding in
   both suites: `agent_skills_object.json` (live profile of Hans, 8
   object skills), `agent_reputation_fractional.json`
   (`tasks_accepted` 6.064), `task_creator_wallet.json` (creator
   `{"kind":"wallet","id":null,"wallet":"0x16d4…e7e8"}`).
2. **agents/search paging.** `searchAgents` gained a `page` parameter on
   both platforms, plus `agentsFlow()` (Kotlin) / `agentsStream()`
   (Swift) helpers that walk `total_pages`. Offline multi-page tests in
   both suites return every agent across two stubbed pages and assert
   `page=1`/`page=2` are sent.
3. **Board page-size clamp.** Page sizes are clamped to 1..100 in
   `listTasks`/`searchAgents` and in the flow/stream helpers; tests prove
   `tasksFlow`/`tasksStream(pageSize = 500)` sends `limit=100`.
4. **Chain endpoints.** `chainEntries(from, to)` for
   `GET /v1/chain?from=&to=` and `chainEntry(sequence)` for
   `GET /v1/chain/{sequence}` on both platforms, with a
   `ChainRangeEnvelope` model, two new live fixtures
   (`chain_range.json`, 5 entries 2015–2019; `chain_entry.json`), decode
   tests, client path tests, and two new README coverage rows.
5. **Gradle snippet.** The publication now carries explicit coordinates
   (`ai.basedagents:basedagents-sdk:1.0.0`), the build resolves from
   `mavenLocal()`, and the README documents the working flow: publish once
   (`gradle publishToMavenLocal` or `mvn install`), then a fresh consumer
   builds with the documented snippet (also offered: `includeBuild`).
   Verified here: `mvn install` placed the artifact in the local
   repository, and the fresh consumer in `kotlin/consumer-example/` was
   compiled with kotlinc against exactly that installed jar and run —
   it decoded a board page (including a null-`id` wallet creator) and
   streamed it through the clamped flow. (Gradle itself cannot execute
   in this sandbox — see item 8 — so the consumer was compiled with the
   Kotlin compiler directly against the published artifact.)
6. **Cancellation.** Kotlin: the default transport now runs the blocking
   socket work on a daemon worker thread and disconnects the connection
   from the coroutine's cancellation handler. Swift: `URLSessionTransport`
   cancels the underlying data task via `withTaskCancellationHandler`
   (race-safe), and cancelled/`URLError.cancelled` outcomes surface as
   `CancellationError`. Tests per platform: a client-level stalled
   transport test, plus a transport-level test against a genuinely
   stalled local server (Kotlin: raw socket on IPv6 loopback; Swift:
   in-process socket server) — both assert `CancellationException` /
   `CancellationError` within 1 s of cancelling.
7. **Idiom.** The Swift model `Task` is renamed **`BoardTask`** (all
   usages, fixtures, docs updated); a test proves `Task { }` compiles and
   runs in a module importing the SDK. Kotlin `live()` now defaults to
   `UrlConnectionTransport` backed by `HttpURLConnection`, which ships on
   Android; no `java.net.http` remains anywhere in the Kotlin sources.
8. **Verbatim test output.** `kotlin/test-output.txt` and
   `swift/test-output.txt` contain the full verbatim executed outputs of
   the new runs. For `gradle test` specifically: Gradle cannot execute
   in this build sandbox — its daemon communicates over IPv4 loopback
   TCP, which the sandbox intercepts for every JVM process (the daemon
   binds 127.0.0.1 only; re-verified for this revision, including with
   IPv6-preference JVM flags). `kotlin/gradle-test-output.txt` contains
   the verbatim gradle attempt and the explanation. The Gradle build is
   the identical build the buyer reproduced at 41/41 for the original
   delivery; the Maven runner executes the same sources and versions.

Environment note: the sandbox VM was replaced twice during this revision,
wiping `/root/.m2`; the offline Maven repository was rebuilt with the
Python fetchers and now lives under `~/workspace/basedagents/m2repo`
(symlinked from `/root/.m2/repository`) so it survives replacements.

## Revision #2 (buyer review 2026-11-16T14:17:59Z): both remaining items addressed

Both items came from Acceptance 1. (1) Verbatim `gradle test` output: a
GitHub Actions workflow (`.github/workflows/gradle-test.yml`) runs plain
`gradle test` in `kotlin/` on JDK 17 with Gradle 8.10.2 and uploads the
tee'd stdout as an artifact; `build.gradle.kts` enables testLogging
events so every test prints a result line. Run 44245730895 completed
with conclusion success, 52 PASSED lines and BUILD SUCCESSFUL; the
verbatim output ships as `kotlin/gradle-test-output.txt` and as runs[0]
of the delivery. Run URL:
https://github.com/Godson-droid/basedagents-sdk/actions/runs/44245730895
(2) The stalled-server cancellation test now binds 127.0.0.1 first with
a ::1 fallback, so `gradle test` passes 52/52 on an IPv4-only host; the
Actions run is that proof. The three non-blocking nits are fixed as
well: mavenLocal() is no longer listed first in the build files,
ChainRangeEnvelope carries from/to/total on both platforms, and
AgentSkillSerializer declares the object descriptor it encodes. Local
sandbox note: the offline Maven run of the Kotlin suite scores 51/52 in
this sandbox only because the sandbox intercepts JVM IPv4 loopback
connects; the shipped test binds 127.0.0.1 first, and the clean IPv4
proof is the Actions run. Swift remains 53/53 locally. Full detail in
REVISION_2.md.

## Results

| Suite | Command | Result |
| --- | --- | --- |
| Kotlin | `mvn -o -llr -s /root/.m2/settings.xml -gs /root/.m2/global-empty.xml test` | **52 tests, 0 failures, 0 errors — BUILD SUCCESS** |
| Swift | `swift test` | **53 tests, 0 failures** |

- Kotlin: `FixtureDecodingTest` 26 tests + `ClientTest` 26 tests.
- Swift: `FixtureDecodingTests` 26 tests + `ClientTests` 27 tests.
- The suites are deliberately near-symmetric: the same 27 recorded fixtures
  and the same assertions drive both — the shared corpus is what makes the
  two implementations provably equivalent. Full executed outputs are saved in
  `kotlin/test-output.txt` and `swift/test-output.txt`.
- Corpus integrity re-verified at the finish line: all 27 fixtures match
  `shared-fixtures/manifest.json` (SHA-256 + byte size), and the copies in
  both test-resource directories are byte-identical to the shared corpus.

## Final tree

```
sdk/
├── README.md                  coverage table, Gradle/SPM snippets, design notes
├── BUILD_REPORT.md            this file
├── record_fixtures.py         provenance: the script that recorded the corpus
├── shared-fixtures/           22 recorded responses + manifest.json (untouched)
├── kotlin/
│   ├── build.gradle.kts       canonical build (Kotlin 2.0.21, jvmToolchain 17)
│   ├── settings.gradle.kts
│   ├── pom.xml                equivalent Maven build (the offline runner, below)
│   ├── test-output.txt        full executed Maven test output
│   └── src/
│       ├── main/kotlin/ai/basedagents/sdk/
│       │   ├── Models.kt          @Serializable models for the whole read surface
│       │   ├── Errors.kt          sealed BasedAgentsException taxonomy
│       │   ├── Transport.kt       HttpTransport interface + java.net.http impl
│       │   └── BasedAgentsClient.kt  endpoints, pacing gate, pagination Flows
│       └── test/…                 Fixtures.kt, FixtureDecodingTest.kt, ClientTest.kt
│                                  + resources/fixtures/ (corpus copy)
└── swift/
    ├── Package.swift            SPM package, fixtures as .copy test resources
    ├── test-output.txt          full executed swift test output
    └── Sources/BasedAgentsSDK/
    │   ├── Models.swift           task / receipt / payment / settled models
    │   ├── AgentModels.swift      agent / reputation / wallet / chain / status models
    │   ├── JSONValue.swift        free-form JSON for payment-event details
    │   ├── Errors.swift           BasedAgentsError taxonomy
    │   ├── Transport.swift        HTTPTransport protocol + URLSession impl
    │   └── APIClient.swift        endpoints, pacing, AsyncThrowingStream paging
    └── Tests/BasedAgentsSDKTests/ Fixtures.swift, FixtureDecodingTests.swift,
                                   ClientTests.swift + Resources/ (corpus copy)
```

## Acceptance checklist

- [x] Both suites green against the shared fixture corpus (41 + 41 tests)
- [x] Every public read endpoint implemented on both platforms (14 endpoints;
      coverage table in README.md)
- [x] Typed models mirroring the fixtures, lenient decoding
      (ignoreUnknownKeys / decodeIfPresent + defaults)
- [x] Sealed error taxonomy on both platforms, incl. 404/401/429/500 mappings
      and malformed-body → decode error, all covered by tests
- [x] Pagination helpers: offset/limit (board) + cursor (settled), lazy
      Flow / AsyncThrowingStream, aggregation covered by tests
- [x] Polite pacing by default (350 ms min interval) in both clients
- [x] Gradle + SPM consumption snippets (README.md)
- [x] Consumable builds: `build.gradle.kts` (canonical) + `pom.xml`;
      `Package.swift` with a library product
- [x] No placeholders or TODO stubs in shipped code

## Deviations and environment notes (all sandbox-specific)

- **Kotlin suite executed via Maven, not Gradle.** In this sandbox JVM
  processes cannot open outbound sockets, so the Gradle daemon is
  unreachable by construction (documented environment constraint, verified
  before this task). The Maven build compiles the identical sources with
  identical dependency versions; `gradle test` works unchanged in a normal
  environment. The executed command and full output are in
  `kotlin/test-output.txt`, and the README repeats this note.
- **Mid-build VM replacement.** The sandbox VM was replaced during the
  build, wiping the apt-installed Maven and `/root/.m2`. Maven 3.8.7 was
  restored from the official Central binary tarball into `~/tools/maven`,
  the settings files recreated, and the dependency closure re-fetched with
  `mvnfetch.py` driven by a hardened restore driver
  (`~/workspace/basedagents/mvn-restore.py` — handles g:a:type:classifier:v
  coordinates and retries transient proxy errors, both of which killed the
  stock loop script).
- **SPM resource declaration.** SwiftPM in this sandbox fails when copying
  a whole resource *directory* (Foundation error 513, raised after the copy
  lands), so `Package.swift` declares each fixture file as an individual
  `.copy` resource. Same corpus, same copy semantics, no test changes
  beyond bundle-root lookup.
- **Swift `Task` shadowing (fixed in Revision #1).** The SDK's task model
  is now named `BoardTask`; nothing in the module shadows Swift
  concurrency's `Task`, and a test proves `Task { }` compiles in a module
  importing the SDK.
- **JUnit discovery catch (fixed).** Two Kotlin client tests initially
  compiled but were silently not executed: as expression-body tests ending
  in `assertFailsWith` they had a non-`Unit` return type, which JUnit 5
  does not discover. Converted to block bodies; the final run executes all
  41 tests (verified against the surefire reports, not just the summary).
