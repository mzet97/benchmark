FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

COPY ["magiconion.csproj", "."]
RUN dotnet restore

COPY . .
RUN dotnet publish -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app

RUN adduser --disabled-password --no-create-home appuser
USER appuser

EXPOSE 50051

COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "magiconion.dll"]
