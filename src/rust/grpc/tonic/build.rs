fn main() -> Result<(), Box<dyn std::error::Error>> {
    // In Docker, the proto is at contracts/grpc/benchmark.proto (relative to WORKDIR /app)
    // Locally, the build context is the project root
    tonic_build::compile_protos("contracts/grpc/benchmark.proto")?;
    Ok(())
}
