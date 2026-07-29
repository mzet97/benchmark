plugins {
    kotlin("jvm") version "1.9.22"
    kotlin("plugin.allopen") version "1.9.22"
    id("com.google.protobuf") version "0.9.4"
    application
}

group = "dev.benchmark.grpc"
version = "1.0.0"

application {
    mainClass.set("benchmark.BenchmarkServerKt")
}

repositories {
    mavenCentral()
}

val grpcVersion = "1.61.0"
val grpcKotlinVersion = "1.4.1"
val protobufVersion = "3.25.2"
val coroutinesVersion = "1.7.3"

dependencies {
    // gRPC
    implementation("io.grpc:grpc-kotlin-stub:$grpcKotlinVersion")
    implementation("io.grpc:grpc-netty-shaded:$grpcVersion")
    implementation("io.grpc:grpc-protobuf:$grpcVersion")
    implementation("io.grpc:grpc-stub:$grpcVersion")

    // Protobuf
    implementation("com.google.protobuf:protobuf-kotlin:$protobufVersion")

    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:$coroutinesVersion")

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
        attributes["Main-Class"] = "benchmark.BenchmarkServerKt"
    }
    from(configurations.runtimeClasspath.get().map { if (it.isDirectory) it else zipTree(it) })
    duplicatesStrategy = DuplicatesStrategy.EXCLUDE
}

tasks.register<Exec>("buildDocker") {
    dependsOn("jar")
    commandLine("docker", "build", "-t", "benchmark/grpc-kotlin:latest", ".")
}
