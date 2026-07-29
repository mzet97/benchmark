fn main() {
    volo_build::Config::new("contracts/grpc/benchmark.proto")
        .compile()
        .expect("failed to compile proto");
}
