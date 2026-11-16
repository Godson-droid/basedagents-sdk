plugins {
    kotlin("jvm") version "2.0.21"
    kotlin("plugin.serialization") version "2.0.21"
    application
}

// A fresh consumer of the published SDK artifact. Publish it once from
// ../ (the SDK project) with `gradle publishToMavenLocal` or `mvn install`,
// then this project builds as-is against the documented coordinates.
repositories {
    mavenLocal()
    mavenCentral()
}

dependencies {
    implementation("ai.basedagents:basedagents-sdk:1.0.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.9.0")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.7.3")
}

kotlin {
    jvmToolchain(17)
}

application {
    mainClass.set("ConsumerMainKt")
}
