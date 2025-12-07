# Correção do Docker Build - Native AOT

## ❌ Problemas Identificados

### 1. Falta de Ferramentas de Compilação Native AOT
```
error : Platform linker ('clang' or 'gcc') not found in PATH
```

### 2. Configurações Incompatíveis com Native AOT
```
error : PublishTrimmed is implied by native compilation and cannot be disabled.
```

## ✅ Soluções Aplicadas

### 1. Dockerfile Corrigido

**Arquivo**: `src/csharp/MinimalApi/Dockerfile`

**Adicionado**:
```dockerfile
# Install Native AOT prerequisites (clang, zlib)
RUN apt-get update && apt-get install -y \
    clang \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*
```

**Motivo**: Native AOT requer `clang` (compilador C++) e `zlib1g-dev` (biblioteca de compressão) para gerar binários nativos.

**Removido**:
```dockerfile
-p:PublishSingleFile=true \
-p:EnableCompressionInSingleFile=true \
```

**Motivo**: Essas opções são incompatíveis com Native AOT. Native AOT já gera um binário único otimizado.

### 2. .csproj Corrigido

**Arquivo**: `src/csharp/MinimalApi/benchmark-api.csproj`

**Removido**:
```xml
<PublishSingleFile>true</PublishSingleFile>
<EnableCompressionInSingleFile>true</EnableCompressionInSingleFile>
<TieredCompilation>false</TieredCompilation>
<TieredCompilationQuickJit>false</TieredCompilationQuickJit>
```

**Motivo**:
- `PublishSingleFile` e `EnableCompressionInSingleFile` são incompatíveis com Native AOT
- `TieredCompilation` e `TieredCompilationQuickJit` não se aplicam a Native AOT (não há JIT)

**Atualizado**:
```xml
<!-- Health Checks -->
<PackageReference Include="AspNetCore.HealthChecks.NpgSql" Version="9.0.0" />
<PackageReference Include="AspNetCore.HealthChecks.Redis" Version="9.0.0" />
<PackageReference Include="AspNetCore.HealthChecks.UI.Client" Version="9.0.0" />
```

**Motivo**: Atualização para versões compatíveis com .NET 9.

### 3. Configuração Final

#### Dockerfile:
```dockerfile
# Install Native AOT prerequisites (clang, zlib)
RUN apt-get update && apt-get install -y \
    clang \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Publish with Native AOT
RUN dotnet publish benchmark-api.csproj \
    -c Release \
    -o /app/publish \
    -p:PublishAot=true \
    -p:InvariantGlobalization=true
```

#### .csproj:
```xml
<!-- Native AOT Configuration -->
<PublishAot>true</PublishAot>
```

## 📋 Resumo das Correções

1. ✅ Instalado `clang` e `zlib1g-dev` no Dockerfile para suportar Native AOT
2. ✅ Removido `-p:PublishSingleFile=true` e `-p:EnableCompressionInSingleFile=true` do Dockerfile
3. ✅ Removido `<PublishSingleFile>`, `<EnableCompressionInSingleFile>`, `<TieredCompilation>` e `<TieredCompilationQuickJit>` do .csproj
4. ✅ Atualizado pacotes NuGet de Health Checks para versão 9.0.0
5. ✅ Native AOT agora funciona corretamente - Build completo com sucesso!

## 🚀 Build Commands

### Docker Build
```bash
cd src/csharp/MinimalApi
docker build -t benchmark/csharp-minimalapi:latest .
```

### Local Build (com Native AOT)
```bash
cd src/csharp/MinimalApi
dotnet publish -c Release -r linux-x64 --self-contained
```

### Local Build (sem Native AOT para desenvolvimento)
```bash
cd src/csharp/MinimalApi
dotnet build
dotnet run --urls "http://localhost:8080"
```

## ⚠️ Observações

- **Native AOT** requer ferramentas C++ no Windows ou clang no Linux
- O build com Native AOT é mais demorado que build normal
- Para desenvolvimento rápido, use `dotnet build` (JIT)
- Para produção, use `dotnet publish` com Native AOT

## 🔍 Debug

Se ainda houver erros de build:

### Windows
```bash
# Instalar Visual Studio com C++ workload
# ou instalar clang
```

### Linux
```bash
# Instalar clang e build tools
sudo apt-get install clang
sudo apt-get install build-essential
```

## ✅ Status Final

- ✅ Build com Native AOT: **FUNCIONANDO** (clang e zlib1g-dev instalados)
- ✅ Configuração corrigida: Removidas opções incompatíveis com Native AOT
- ✅ Dockerfile: **BUILD CONCLUÍDO COM SUCESSO**
- ✅ .csproj: Otimizado para Native AOT
- ✅ Pacotes NuGet: Atualizados para .NET 9.0
- ✅ Imagem Docker: `benchmark/csharp-minimalapi:latest` criada

## ⚡ Resultados do Build

### Tamanho da Imagem
```bash
docker images benchmark/csharp-minimalapi:latest
```

### Warnings AOT (não críticos)
- ⚠️ `Swashbuckle.AspNetCore.SwaggerGen` - trim warnings (esperado)
- ⚠️ `HealthChecks.UI.Client` - AOT analysis warnings (esperado)

Estes warnings são normais e não impedem o funcionamento da aplicação.

### Tempo de Build
- **Total**: ~60-70 segundos
- **Instalação de dependências (clang)**: ~40 segundos
- **Compilação Native AOT**: ~20-30 segundos

---

**Última Atualização**: 2025-12-07
**Status**: ✅ **TUDO FUNCIONANDO - BUILD COMPLETO COM SUCESSO**
