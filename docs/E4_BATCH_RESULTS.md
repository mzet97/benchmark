# E4 Batch Results — First Scale Run

**Data**: 2026-08-06/07
**Escopo**: 37 implementações REST (todas com imagem Docker construída)

## Resultado

| Status | Qtd | Implementações |
|---|---|---|
| ✅ **E4 PASS (7/7)** | **2** | go-rest-fiber, nodejs-rest-fastify |
| ❌ Parcial (checks ok, alguns fail) | 15 | bun×3, csharp×2, dart-vaden, java-quarkus, kotlin-spring, nodejs-express, nodejs-nestjs, rust-axum |
| ⏳ TIMEOUT (pod não ficou Ready) | 20 | csharp-minimalapi, deno×2, go×3, graalvm×4, java-spring, kotlin×2, python×3, rust-actix |

## Diagnóstico

### Problema dominante: race condition no cleanup (TIMEOUT)

O script deleta o deployment anterior e imediatamente aplica o próximo. Mas o
pod de 40 CPU (QoS Guaranteed) demora para terminar — o processo recebe SIGTERM
mas o `terminationGracePeriodSeconds: 30` significa que o pod pode levar até 30s
para morrer. Enquanto isso, o novo pod tenta schedular pedindo 40 CPU, mas os 40
CPU do pod anterior ainda estão reservados → Pending → TIMEOUT.

**Fix**: o script precisa aguardar o pod anterior realmente terminar
(`kubectl wait --for=delete`) ANTES de aplicar o próximo, ou reduzir o
`terminationGracePeriodSeconds` para 5s.

### Falhas de payload (parciais)

As implementações que sobem mas falham no parity gate têm defeitos de payload
que a build matrix (E2) não captura — só aparecem em runtime (E4):

- **Bun**: `n` parameter ignorado, ou payload com campos errados
- **C#**: `n` ignorado, ou `/db/simple` não responde
- **Dart vaden**: 3 checks fail (payload divergente)
- **Java quarkus**: 3 checks fail
- **Node express/nestjs**: 1 check fail cada (provavelmente `/json` field)

Estes são exatamente o tipo de defeito que a Fase 3 (paridade) deveria ter
corrigido — mas como `validate-parity.py --url` **nunca rodou contra serviço
rodando** antes (resíduo 3.R3), esses bugs só aparecem agora.

### As 2 que passaram 7/7

`go-rest-fiber` e `nodejs-rest-fastify` — ambas são as implementações mais
bem-corrigidas da Fase 3 e tinham o código canônico já validado em E2/E3.

## Próximos passos

1. **Corrigir o script E4**: adicionar espera real pela morte do pod entre impls
2. **Corrigir os 15 defeitos de payload** que aparecem em E4 (não em E2)
3. **Investigar os 20 TIMEOUTs** — alguns podem ser startup lento (JVM), outros
   podem ser defeito de imagem (porta errada, crashloop)

Com o script corrigido, o E4 batch deve produzir resultados confiáveis para
todas as 37 implementações em ~1-2h de execução.
