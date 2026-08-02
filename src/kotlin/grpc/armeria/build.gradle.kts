plugins {
    kotlin("jvm") version "1.9.22"
    // The allOpen { } block below configures this plugin. Without it applied,
    // `allOpen` is an unresolved reference and the build script itself fails to
    // compile -- so this project never built.
    kotlin("plugin.allopen") version "1.9.22"
    id("com.google.protobuf") version "0.9.4"
    application
}

group = "dev.benchmark.grpc"
version = "1.0.0"

application {
    mainClass.set("benchmark.ServerKt")
}

repositories {
    mavenCentral()
}

val armeriaVersion = "1.27.3"
val grpcVersion = "1.61.0"
val grpcKotlinVersion = "1.4.1"
val protobufVersion = "3.25.2"

dependencies {
    // Armeria gRPC
    implementation("com.linecorp.armeria:armeria-grpc:$armeriaVersion")
    implementation("com.linecorp.armeria:armeria:$armeriaVersion")

    // gRPC Kotlin
    implementation("io.grpc:grpc-kotlin-stub:$grpcKotlinVersion")
    implementation("io.grpc:grpc-protobuf:$grpcVersion")
    implementation("io.grpc:grpc-stub:$grpcVersion")

    // Protobuf
    implementation("com.google.protobuf:protobuf-kotlin:$protobufVersion")

    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")

    // PostgreSQL
    implementation("org.postgresql:postgresql:42.7.1")

    // Redis (Lettuce)
    implementation("io.lettuce:lettuce-core:6.3.2.RELEASE")

    // Logging
    implementation("org.slf4j:slf4j-api:2.0.11")
    implementation("ch.qos.logback:logback-classic:1.4.14")
}

protobuf {
    protoc {
        artifact = "com.google.protobuf:protoc:$protobufVersion"
    }
    plugins {
        create("grpc") {
            artifact = "io.grpc:protoc-gen-grpc-java:$grpcVersion"
        }
        create("grpckt") {
            artifact = "io.grpc:protoc-gen-grpc-kotlin:$grpcKotlinVersion:jdk8@jar"
        }
    }
    generateProtoTasks {
        all().forEach {
            it.plugins {
                create("grpc")
                create("grpckt")
            }
            it.builtins {
                create("kotlin")
            }
        }
    }
}

kotlin {
    jvmToolchain(17)
}

allOpen {
    annotation("io.grpc.kotlin.stub.annotations.MultipleImplementations")
}

tasks.jar {
    manifest {
        attributes["Main-Class"] = "benchmark.ServerKt"
    }
    from(configurations.runtimeClasspath.get().map { if (it.isDirectory) it else zipTree(it) })
    duplicatesStrategy = DuplicatesStrategy.EXCLUDE
}

tasks.register<Exec>("buildDocker") {
    dependsOn("jar")
    commandLine("docker", "build", "-t", "benchmark/grpc-kotlin-armeria:latest", ".")
}
