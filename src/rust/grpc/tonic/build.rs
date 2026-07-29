fn main() -> Result<(), Box<dyn std::error::Error>> {
    let proto_file = "contracts/grpc/benchmark.proto";

    tonic_build::configure()
        .file_descriptor_set_path("src/benchmark_descriptor.bin")
        .compile(&[proto_file], &["contracts/grpc"])?;

    Ok(())
}
