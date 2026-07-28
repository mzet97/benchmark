# Multi-stage Dockerfile for .NET 9
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS builder

WORKDIR /src
COPY *.csproj ./
RUN dotnet restore benchmark-api.csproj

COPY . .
RUN dotnet publish benchmark-api.csproj -c Release -o /app/publish

# Runtime
FROM mcr.microsoft.com/dotnet/aspnet:9.0

WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/publish .

RUN addgroup --system --gid 1001 dotnet && adduser --system --uid 1001 --gid 1001 --shell /bin/false dotnet
RUN chown -R dotnet:dotnet /app
USER dotnet

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

ENTRYPOINT ["dotnet", "benchmark-api.dll"]
