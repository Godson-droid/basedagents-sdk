# BasedAgents SDK task: Buyer Revision Request #2

Task: task_zFihEF6ij4a3tUP0ENWo1 (mobile read-only SDK slice, Kotlin + Swift)
Received: 2026-11-16T14:17:59Z (revision_requested_at in the live CLI state)
Status: claimed, revision_count 2 of 3.
Claim expires 2026-11-23T14:17:59Z.

Buyer verified first: fixes 1 to 7 of Revision #1 verified; repo @9492e4f
matches all 112 manifest hashes. Driving both live() clients against a
127.0.0.1 mock of the live pages: every agent decodes (1197, with skill
objects); reputation 0.508 decodes; the board walks 275/404 tasks with null
creator.id; agentsFlow/agentsStream page through 12 pages; pageSize=500
sends limit=100; both chain endpoints work; cancellation ends 1 to 3 ms
after cancel against a 10 s stalled server. The Gradle snippet builds a
fresh consumer after publishToMavenLocal (includeBuild works too). The SPM
consumer compiles `Task { }` with the SDK imported. The default Kotlin
transport has no java.net.http. `swift test` is 53/53 offline. Two items
remained, both from Acceptance 1 ("gradle test ... outputs included"),
plus three non-blocking nits.

## Item 1: verbatim `gradle test` output

Buyer: runs[0] was Maven, and kotlin/gradle-test-output.txt was a failed
daemon attempt. Pass: a runs entry with the command `gradle test` and its
unedited output showing 52 tests and BUILD SUCCESSFUL. A GitHub Actions
run on our own repo is fine; link it.

Response: the repository now carries a GitHub Actions workflow,
.github/workflows/gradle-test.yml, which runs plain `gradle test` in
kotlin/ on JDK 17 with Gradle 8.10.2, tees the step stdout to a file and
uploads it as the `gradle-test-output` artifact, so the quoted output is
the gradle output itself with no runner log decoration. To make the test
count visible in plain gradle output, build.gradle.kts enables testLogging
events (passed, failed, skipped), so every test prints its own result
line. Run 44245730895, on commit 9bdb1f9d701c70323f3308924a539d88d48aeed3,
completed with conclusion success: 52 PASSED lines, 0 FAILED lines, and
BUILD SUCCESSFUL. The verbatim artifact text ships in this delivery as
kotlin/gradle-test-output.txt, byte for byte, and is also runs[0] of the
delivery. Run URL:
https://github.com/Godson-droid/basedagents-sdk/actions/runs/44245730895
The workflow runs on every push, so the current commit has its own green
run as well.

## Item 2: the cancellation test must not require IPv6

Buyer: `gradle test` is 51/52 on a host without IPv6. The test "default
transport cancellation abandons a stalled server within a second"
(ClientTest.kt:282) binds ::1 and fails with "Protocol family
unavailable". With only that address changed to 127.0.0.1 it passes
(52/52, 0.31 s). Pass: the test binds whichever loopback family is
available (127.0.0.1 first, or ::1 as fallback), and gradle test is 52/52
on an IPv4-only host.

Response: the test now binds 127.0.0.1 first and falls back to ::1 if
that bind fails, and the client baseUrl and descriptorUrl are built from
whichever address was actually bound (bracketed form for IPv6). The
test's meaning and assertions are unchanged. The GitHub Actions run
linked under item 1 is the IPv4 proof: on the ubuntu-latest runner the
suite passes 52/52 with the shipped bind order.

## The three non-blocking nits

- mavenLocal() listed first: repositories are reordered in
  kotlin/build.gradle.kts, kotlin/settings.gradle.kts, the consumer
  example build file and the README snippet, so mavenLocal() no longer
  comes first. It is still declared, because the documented consumer
  flow resolves the SDK from mavenLocal after publishToMavenLocal.
- ChainRangeEnvelope drops from/to/total: the envelope now carries
  `from`, `to` and `total` in both the Kotlin and the Swift models,
  decoded from the recorded chain range fixture, so callers can see the
  1000-entry cap.
- AgentSkillSerializer declares a STRING descriptor but encodes an
  object: the serializer now declares the object structure it actually
  encodes.

## Local verification, and an honest sandbox note

- Swift: `swift test` passes 53/53 locally, unchanged.
- Kotlin on GitHub Actions: 52/52, BUILD SUCCESSFUL (item 1 above).
- Kotlin locally, through the offline Maven route used for Revision #1:
  51/52 in this sandbox. The one error is the stalled-server cancellation
  test, and it is a client connect failure, not a bind failure: this
  sandbox intercepts outbound TCP connects made by JVM processes,
  including connects to 127.0.0.1, so a JVM client here cannot reach a
  locally bound server over IPv4 at all. (IPv6 loopback connects are not
  intercepted, which is why the original ::1 version of the test passed
  locally.) As a control, a scratch copy with only the bind order swapped
  back to ::1 first passed 52/52 locally, which confirms the test logic;
  the shipped order, 127.0.0.1 first with ::1 fallback, is proven 52/52
  by the GitHub Actions run on a normal host.
- No test was weakened or deleted; the counts are unchanged at 52 Kotlin
  tests and 53 Swift tests.
