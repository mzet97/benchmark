#!/usr/bin/env python3
"""Generate Python gRPC stubs from benchmark.proto using grpclib/protobuf."""

import os
import subprocess
import sys


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    proto_file = os.path.join(script_dir, "benchmark.proto")
    output_dir = os.path.join(script_dir, "generated")

    os.makedirs(output_dir, exist_ok=True)

    # Create __init__.py for the generated package
    init_file = os.path.join(output_dir, "__init__.py")
    if not os.path.exists(init_file):
        with open(init_file, "w") as f:
            f.write("")

    # Generate protobuf stubs
    cmd_protoc = [
        sys.executable,
        "-m",
        "grpc_tools.protoc",
        f"--proto_path={script_dir}",
        f"--python_out={output_dir}",
        f"--grpclib_python_out={output_dir}",
        proto_file,
    ]

    print(f"Generating stubs from {proto_file}")
    print(f"Output directory: {output_dir}")
    print(f"Command: {' '.join(cmd_protoc)}")

    result = subprocess.run(cmd_protoc, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error: {result.stderr}", file=sys.stderr)
        sys.exit(1)

    print("Successfully generated gRPC stubs:")
    for f in sorted(os.listdir(output_dir)):
        if f.endswith(".py") and f != "__init__.py":
            print(f"  - {f}")


if __name__ == "__main__":
    main()
