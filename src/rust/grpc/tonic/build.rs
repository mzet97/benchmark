fn main() -> Result<(), Box<dyn std::error::Error>> {
    let out_dir = std::env::var("OUT_DIR").unwrap();
    let descriptor_path = format!("{}/benchmark_descriptor.bin", out_dir);

    tonic_build::configure()
        .file_descriptor_set_path(&descriptor_path)
        .compile_protos(
            &["contracts/grpc/benchmark.proto"],
            &["contracts/grpc"],
        )?;

    Ok(())
}
