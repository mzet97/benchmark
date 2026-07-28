plugins {
    kotlin("jvm") version "1.9.25"
    application
    kotlin("plugin.serialization") version "1.9.25"
}

group = "com.benchmark"
version = "1.0.0"

repositories {
    mavenCentral()
}

dependencies {
    // Ktor Core
    implementation("io.ktor:ktor-server-core:2.3.12")
    implementation("io.ktor:ktor-server-netty:2.3.12")
    implementation("io.ktor:ktor-server-content-negotiation:2.3.12")
    implementation("io.ktor:ktor-serialization-kotlinx-json:2.3.12")
    implementation("io.ktor:ktor-server-cors:2.3.12")
    implementation("io.ktor:ktor-server-status-pages:2.3.12")

    // Database
    implementation("org.postgresql:postgresql:42.7.4")
    implementation("com.zaxxer:HikariCP:5.1.0")

    // Redis
    implementation("io.lettuce:lettuce-core:6.2.6.RELEASE")

    // Logging
    implementation("org.slf4j:slf4j-simple:2.0.13")

    // Serialization
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.3")
}

application {
    mainClass.set("com.benchmark.ApplicationKt")
}

kotlin {
    jvmToolchain(21)
}

tasks.register<Jar>("fatJar") {
    manifest {
        attributes["Main-Class"] = "com.benchmark.ApplicationKt"
    }
    archiveFileName.set("benchmark-ktor.jar")
    duplicatesStrategy = DuplicatesStrategy.EXCLUDE
    from(sourceSets.main.get().output)
    dependsOn(configurations.runtimeClasspath)
    from({
        configurations.runtimeClasspath.get().filter { it.exists() }.map { if (it.isDirectory) it else zipTree(it) }
    })
}

tasks.build {
    dependsOn("fatJar")
}
