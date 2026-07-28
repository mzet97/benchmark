plugins {
    kotlin("jvm") version "2.0.0"
    application
    kotlin("plugin.serialization") version "2.0.0"
}

group = "com.benchmark"
version = "1.0.0"

repositories {
    mavenCentral()
}

dependencies {
    // Ktor Core
    implementation("io.ktor:ktor-server-core-jvm:3.0.0")
    implementation("io.ktor:ktor-server-netty-jvm:3.0.0")
    implementation("io.ktor:ktor-server-content-negotiation-jvm:3.0.0")
    implementation("io.ktor:ktor-serialization-kotlinx-json-jvm:3.0.0")

    // Ktor Features
    implementation("io.ktor:ktor-server-call-logging-jvm:3.0.0")
    implementation("io.ktor:ktor-server-cors-jvm:3.0.0")
    implementation("io.ktor:ktor-server-auto-head-response-jvm:3.0.0")
    implementation("io.ktor:ktor-server-default-headers-jvm:3.0.0")
    implementation("io.ktor:ktor-server-status-pages-jvm:3.0.0")

    // Database
    implementation("org.postgresql:postgresql:42.7.4")
    implementation("com.zaxxer:HikariCP:5.1.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.8.1")

    // Redis
    implementation("io.lettuce:lettuce-core:6.3.2")

    // Logging
    implementation("org.slf4j:slf4j-simple:2.0.13")
    implementation("io.ktor:ktor-server-logging-jvm:3.0.0")

    // Serialization
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.7.1")

    // Testing
    testImplementation("io.ktor:ktor-server-test-host-jvm:3.0.0")
    testImplementation("org.jetbrains.kotlin:kotlin-test-junit5:2.0.0")
    testImplementation("org.testcontainers:junit-jupiter:10.4.0")
    testImplementation("org.testcontainers:postgresql:10.4.0")
}

tasks.test {
    useJUnitPlatform()
}

application {
    mainClass.set("com.benchmark.ApplicationKt")
}

kotlin {
    jvmToolchain(21)
}

// Fat JAR task
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
