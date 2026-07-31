fn main() {
    volo_build::Config::new("proto/benchmark.proto")
        .compile()
        .expect("failed to compile proto");
}
