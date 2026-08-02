package benchmark

import io.grpc.Server
import io.grpc.ServerBuilder
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.GlobalScope

fun main(): Unit = runBlocking {
    val port = (System.getenv("PORT") ?: "8080").toInt()

    val dbService = DatabaseService()
    val cacheService = CacheService()

    val serviceImpl = BenchmarkServiceImpl(dbService, cacheService)

    val server: Server = ServerBuilder
        .forPort(port)
        .addService(serviceImpl)
        .build()

    // Graceful shutdown hook
    Runtime.getRuntime().addShutdownHook(Thread {
        println("Shutting down gRPC server...")
        server.shutdown()
        runBlocking {
            cacheService.close()
        }
        println("Server stopped")
    })

    server.start()
    println("gRPC server listening on port $port")
    println("Version: ${System.getenv("APP_VERSION") ?: "1.0.0"}")

    // Block the main thread
    server.awaitTermination()
}
