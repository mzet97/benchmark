package benchmark

import com.linecorp.armeria.common.grpc.GrpcSerializationFormats
import com.linecorp.armeria.server.Server
import com.linecorp.armeria.server.grpc.GrpcService
import io.grpc.protobuf.services.ProtoReflectionService
import kotlinx.coroutines.runBlocking

fun main(): Unit = runBlocking {
    val port = (System.getenv("PORT") ?: "8080").toInt()

    val dbService = DatabaseService()
    val cacheService = CacheService()

    val serviceImpl = BenchmarkServiceImpl(dbService, cacheService)

    val grpcService = GrpcService.builder()
        .addService(serviceImpl)
        .addService(ProtoReflectionService.newInstance())
        .supportedSerializationFormats(GrpcSerializationFormats.values())
        .enableUnframedRequests(true)
        .build()

    val server = Server.builder()
        .http(port)
        .service(grpcService)
        .build()

    // Graceful shutdown hook
    Runtime.getRuntime().addShutdownHook(Thread {
        println("Shutting down Armeria gRPC server...")
        runBlocking {
            cacheService.close()
        }
        println("Server stopped")
    })

    server.start()
    println("Armeria gRPC server listening on port $port")
    println("Version: ${System.getenv("APP_VERSION") ?: "1.0.0"}")

    // Block the main thread
    server.blockUntilShutdown()
}
