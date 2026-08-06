# E4 Pilot — Trilha C Progress

**Data**: 2026-08-06
**Implementação piloto**: `go-rest-fiber`

## O que foi validado

### Pipeline completo (C1 → C2)

1. **Build da imagem Docker** no `.51` (46.7 MB, multi-stage)
2. **Importação no containerd** via `docker run --privileged --pid=host` (k8s1 tem docker mas não sudo)
3. **Deploy via overlay** kustomize — pod subiu com **QoS Guaranteed**, 40 CPU / 40 GiB
4. **`validate-parity.py --url`** contra o serviço rodando no NodePort 30080

### Resultado do E4 (primeiro do repositório)

```
=== http://localhost:30080 ===
    [ok]   /json?n=10 payload matches canonical
    [ok]   /json?n=100 payload matches canonical
    [ok]   /json?n=1000 payload matches canonical
    [FAIL] /health key set matches contract
           missing: ['version']
    [FAIL] /db/simple?id=1 key set matches contract
           request failed: HTTP Error 404: Not Found
    [ok]   /db/complex?days=30 key set matches contract
    [ok]   /cache?key=benchmark key set matches contract
```

**5/7 checks passam.** O `/json` — o cenário que invalidou todos os resultados
anteriores — está **canônico em n=10/100/1000**.

### As 2 falhas (pontuais, não de pipeline)

1. **`/health` falta `version`**: o handler retorna `{status, database, cache, timestamp}`
   mas o contrato exige `version` também. Fix: adicionar `version` ao handler.

2. **`/db/simple?id=1` retorna 404**: os IDs na tabela `users` do `benchmark_api`
   começam em **3**, não em 1. Ou o seed tem um offset, ou `validate-parity.py`
   precisa testar `id=3` (ou um ID que existe). Verificar `sql/02_seed.sql`.

## Estado do cluster após Trilha B

- Allocatable: 44 CPU / 60 GiB (4 reservados para K3s/SO/vizinhos)
- cpu-manager-policy: **static** (cores exclusivos para pods Guaranteed)
- `nr_throttled`: **0** (validado)
- traefik/servicelb/metrics-server: **desabilitados**
- Redis: in-cluster (confounder declarado para `/cache`)

## Próximos passos

1. Fix `/health` version (todas as impls precisam adicionar o campo)
2. Verificar offset de ID no seed (`sql/02_seed.sql`) ou ajustar `validate-parity.py`
3. C1: build das 74 imagens restantes (paralelizável)
4. C2: E4 para cada uma (deploy + parity gate)
5. C4: executar a matriz (~45 h de máquina)
