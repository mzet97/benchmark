# scripts/measure-ceilings.ps1
#
# Fase 0 do plano de acao: mede os tetos de infraestrutura a partir da
# workstation Windows, que e o gerador de carga oficial deste benchmark.
#
# Nenhum resultado de framework tem significado antes destes numeros: a rede
# de 1 GbE impoe um teto por cenario, e um resultado que encoste nele mede a
# rede, nao o framework.
#
# Uso:
#   .\scripts\measure-ceilings.ps1 -Server 192.168.1.51
#   .\scripts\measure-ceilings.ps1 -Server 192.168.1.51 -SkipIperf
#
# Pre-requisitos na workstation (instalar com winget ou scoop):
#   winget install iperf3
#   scoop install bombardier
#   winget install k6
# No servidor .51:
#   iperf3 -s                       (durante a medicao de banda)
#   kubectl run ceiling-nginx --image=nginx --port=80
#   kubectl expose pod ceiling-nginx --type=NodePort --port=80

[CmdletBinding()]
param(
    [string]$Server = "192.168.1.51",
    [int]$NginxNodePort = 30080,
    [string]$OutFile = "docs/BASELINE_CEILINGS.md",
    [switch]$SkipIperf
)

$ErrorActionPreference = "Stop"

# 1 GbE = 1e9 bits/s. Apos overhead de Ethernet/IP/TCP, ~941 Mbps uteis.
$UsableBytesPerSec = 117.6MB

function Test-Tool {
    param([string]$Name, [string]$InstallHint)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        Write-Warning "$Name nao encontrado. Instale com: $InstallHint"
        return $false
    }
    return $true
}

function Format-Rps { param([double]$v) return "{0:N0}" -f $v }

$results = [ordered]@{}

Write-Host "=== Fase 0: medicao de tetos ===" -ForegroundColor Cyan
Write-Host "Servidor alvo: $Server" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------------------
# 1. Largura de banda real (nao assumir 1 GbE: pode ser 2.5 GbE)
# ---------------------------------------------------------------------------
if (-not $SkipIperf) {
    if (Test-Tool -Name "iperf3" -InstallHint "winget install iperf3") {
        Write-Host "[1/4] Medindo largura de banda (iperf3, 8 streams, direcao reversa)..."
        Write-Host "      A direcao reversa e a que importa: mede o servidor ENVIANDO respostas."
        $iperf = & iperf3 -c $Server -P 8 -R -t 10 -J 2>&1 | Out-String
        try {
            $json = $iperf | ConvertFrom-Json
            $bps = $json.end.sum_received.bits_per_second
            $results["bandwidth_mbps"] = [math]::Round($bps / 1MB, 1)
            $results["bandwidth_bytes_per_sec"] = [math]::Round($bps / 8, 0)
            Write-Host ("      -> {0:N0} Mbps ({1:N1} MB/s)" -f ($bps / 1MB), ($bps / 8 / 1MB)) -ForegroundColor Green
        } catch {
            Write-Warning "iperf3 falhou. O servidor esta rodando 'iperf3 -s'?"
            $results["bandwidth_mbps"] = "FALHOU"
        }
    }
} else {
    Write-Host "[1/4] iperf3 pulado (-SkipIperf). Assumindo 1 GbE = 117.6 MB/s uteis."
    $results["bandwidth_bytes_per_sec"] = $UsableBytesPerSec
}

$wireBudget = if ($results["bandwidth_bytes_per_sec"] -is [double] -or
                  $results["bandwidth_bytes_per_sec"] -is [int]) {
    [double]$results["bandwidth_bytes_per_sec"]
} else { [double]$UsableBytesPerSec }

# ---------------------------------------------------------------------------
# 2. Teto de pacotes por segundo (define /health, /db/simple e /cache)
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "[2/4] Medindo teto de requisicoes/s com resposta minima (nginx)..."
Write-Host "      Este e o teto ABSOLUTO de qualquer framework nesta topologia."
if (Test-Tool -Name "bombardier" -InstallHint "scoop install bombardier") {
    $nginxUrl = "http://${Server}:${NginxNodePort}/"
    try {
        $out = & bombardier -c 200 -d 20s -l --print result $nginxUrl 2>&1 | Out-String
        if ($out -match "Reqs/sec\s+([\d.]+)") {
            $pps = [double]$Matches[1]
            $results["pps_ceiling_rps"] = [math]::Round($pps, 0)
            Write-Host ("      -> {0} req/s (teto de cliente/NIC)" -f (Format-Rps $pps)) -ForegroundColor Green
        } else {
            Write-Warning "Nao consegui parsear a saida do bombardier."
            Write-Host $out
        }
    } catch {
        Write-Warning "bombardier falhou. O pod ceiling-nginx esta exposto em :$NginxNodePort?"
    }
}

# ---------------------------------------------------------------------------
# 3. Tamanho real da resposta de cada cenario -> teto de rede por cenario
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "[3/4] Medindo tamanho de payload por cenario..."
Write-Host "      Informe a URL base de UMA implementacao ja deployada."

$scenarios = [ordered]@{
    "health"     = "/health"
    "json-10"    = "/json?n=10"
    "json-100"   = "/json?n=100"
    "json-1000"  = "/json"
    "db-simple"  = "/db/simple?id=1"
    "db-complex" = "/db/complex?days=30"
    "cache"      = "/cache?key=benchmark"
}

$baseUrl = Read-Host "URL base (ex.: http://${Server}:30081) ou ENTER para pular"
$payloads = [ordered]@{}

if ($baseUrl) {
    foreach ($name in $scenarios.Keys) {
        $url = "$baseUrl$($scenarios[$name])"
        try {
            $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10
            $bytes = $resp.RawContentLength
            if (-not $bytes) { $bytes = [Text.Encoding]::UTF8.GetByteCount($resp.Content) }
            # ~200 B de headers HTTP + framing TCP/IP por resposta
            $wire = $bytes + 200
            $netCeiling = $wireBudget / $wire
            $payloads[$name] = [pscustomobject]@{
                Scenario    = $name
                BodyBytes   = $bytes
                WireBytes   = $wire
                NetCeiling  = [math]::Round($netCeiling, 0)
            }
            Write-Host ("      {0,-12} {1,8:N0} B  -> teto de rede {2,10} req/s" -f `
                $name, $bytes, (Format-Rps $netCeiling))
        } catch {
            Write-Warning ("      {0,-12} FALHOU: {1}" -f $name, $_.Exception.Message)
        }
    }
}

# ---------------------------------------------------------------------------
# 4. Relatorio
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "[4/4] Gerando $OutFile ..."

$ppsCeiling = if ($results["pps_ceiling_rps"]) { $results["pps_ceiling_rps"] } else { "nao medido" }

$md = @"
# Baseline Ceilings

Gerado por ``scripts/measure-ceilings.ps1`` em $(Get-Date -Format "yyyy-MM-dd HH:mm").

Topologia: gerador de carga na workstation Windows -> NodePort do K3s em $Server.

## Tetos de infraestrutura

| Medida | Valor |
|---|---:|
| Largura de banda util (servidor -> cliente) | $($results["bandwidth_mbps"]) Mbps |
| Teto de req/s com resposta minima (PPS/NIC) | $ppsCeiling req/s |

## Teto de rede por cenario

| Cenario | Corpo | Wire (+200 B) | Teto de rede |
|---|---:|---:|---:|
"@

foreach ($p in $payloads.Values) {
    $md += "`n| ``$($p.Scenario)`` | $("{0:N0}" -f $p.BodyBytes) B | $("{0:N0}" -f $p.WireBytes) B | $("{0:N0}" -f $p.NetCeiling) req/s |"
}

$md += @"


## Como usar estes numeros

O teto efetivo de um cenario e o **menor** entre: teto de rede, teto de PPS,
e a capacidade do PostgreSQL/Redis (medir com ``pgbench``/``redis-benchmark``).

Todo resultado de framework deve ser reportado como percentual desse teto e
receber uma flag:

| Flag | Condicao |
|---|---|
| ``FRAMEWORK_BOUND`` | CPU do pod >= 90%, rede < 80% do teto, DB < 70% |
| ``NET_BOUND`` | bytes/s >= 80% da largura de banda medida |
| ``PPS_BOUND`` | req/s >= 80% do teto de PPS |
| ``CLIENT_BOUND`` | CPU da workstation >= 90% |
| ``DB_BOUND`` | PostgreSQL ou Redis >= 85% |

Apenas resultados ``FRAMEWORK_BOUND`` entram no ranking de throughput. Os
demais entram somente no ranking de eficiencia (custo de CPU por requisicao).
"@

$dir = Split-Path $OutFile -Parent
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
$md | Out-File -FilePath $OutFile -Encoding utf8

Write-Host "OK -> $OutFile" -ForegroundColor Green
