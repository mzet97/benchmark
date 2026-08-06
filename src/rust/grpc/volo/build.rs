fn main() {
    // In volo-build 0.10 the `Config` type was removed; codegen is driven by
    // the `Builder` API. `Builder::protobuf()` registers the proto, and
    // `write()` emits the generated module to `$OUT_DIR/<filename>`.
    // service.rs includes `$OUT_DIR/benchmark.rs`, so we name it accordingly.
    volo_build::Builder::protobuf()
        .add_service("proto/benchmark.proto")
        .include_dirs(vec!["proto".into()])
        .filename("benchmark.rs".into())
        .write()
        .expect("failed to compile proto");
}
