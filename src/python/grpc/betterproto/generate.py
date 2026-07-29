#!/usr/bin/env python3
"""Generate Python gRPC stubs from benchmark.proto using betterproto."""

import os
import subprocess
import sys


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    proto_file = os.path.join(script_dir, "proto", "benchmark.proto")
    output_dir = os.path.join(script_dir, "generated")

    os.makedirs(output_dir, exist_ok=True)

    # Create __init__.py for the generated package
    init_file = os.path.join(output_dir, "__init__.py")
    if not os.path.exists(init_file):
        with open(init_file, "w") as f:
            f.write("")

    # betterproto uses its own protoc plugin
    cmd = [
        "protoc",
        f"--proto_path={os.path.join(script_dir, 'proto')}",
        f"--python_betterproto_out={output_dir}",
        proto_file,
    ]

    print(f"Generating betterproto stubs from {proto_file}")
    print(f"Output directory: {output_dir}")
    print(f"Command: {' '.join(cmd)}")

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error: {result.stderr}", file=sys.stderr)
        sys.exit(1)

    print("Successfully generated betterproto stubs:")
    for f in sorted(os.listdir(output_dir)):
        if f.endswith(".py") and f != "__init__.py":
            print(f"  - {f}")


if __name__ == "__main__":
    main()
