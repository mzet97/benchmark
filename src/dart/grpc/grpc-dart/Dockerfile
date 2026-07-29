FROM dart:3.6-sdk AS builder

RUN apt-get update && apt-get install -y protobuf-compiler && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY pubspec.yaml .
RUN dart pub get

COPY protos/ protos/
COPY lib/ lib/
COPY bin/ bin/

# Generate protobuf stubs
RUN dart pub global activate protoc_plugin
RUN export PATH="$PATH:$HOME/.pub-cache/bin" && \
    protoc \
      --dart_out=grpc:lib/src \
      --proto_path=protos \
      protos/benchmark.proto

RUN dart compile exe bin/server.dart -o bin/server

FROM scratch

COPY --from=builder /runtime/ /
COPY --from=builder /app/bin/server /app/bin/server

ENV GRPC_PORT=50051

EXPOSE 50051

ENTRYPOINT ["/app/bin/server"]
