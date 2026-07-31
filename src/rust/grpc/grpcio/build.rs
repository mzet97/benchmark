use std::env;
use std::path::Path;

fn main() {
    let proto_root = Path::new("proto");
    let proto_file = proto_root.join("benchmark.proto");

    let out_dir = env::var("OUT_DIR").unwrap();
    let out_path = Path::new(&out_dir);

    // Generate protobuf code
    protobuf_codegen::Codegen::new()
        .pure()
        .includes(&[proto_root])
        .input(&proto_file)
        .out_dir(out_path)
        .run()
        .expect("protobuf codegen failed");

    // Generate gRPC service code
    protoc_grpcio::compile_protos(
        &[&proto_file],
        &[proto_root],
        &out_path,
        None,
    )
    .expect("grpcio codegen failed");

    println!("cargo:rerun-if-changed=proto/benchmark.proto");
}
