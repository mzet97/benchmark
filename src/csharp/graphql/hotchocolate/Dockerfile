FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

COPY hotchocolate.csproj ./
RUN dotnet restore

COPY . .
RUN dotnet publish -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:9.0
WORKDIR /app

COPY --from=build /app/publish .

EXPOSE 3000

ENV ASPNETCORE_URLS=http://+:3000
ENV DOTNET_EnableDiagnostics=0

ENTRYPOINT ["dotnet", "hotchocolate.dll"]
