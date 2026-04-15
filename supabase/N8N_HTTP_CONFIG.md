# Config do nó HTTP Request (n8n) — RD Station → Supabase

## 1. Rodar a migration primeiro

1. Abra o Supabase: https://supabase.com/dashboard/project/plbzwswqkeozvyirzqma/sql
2. Cole o conteúdo de `supabase/migrations/001_inscricoes_schema.sql`
3. Execute (botão **Run**)
4. Confira em **Table Editor** que `inscricoes` e `limites_vagas` apareceram

---

## 2. Nó HTTP Request (n8n) — INSERT na tabela `inscricoes`

### Endpoint

```
POST https://plbzwswqkeozvyirzqma.supabase.co/rest/v1/inscricoes?on_conflict=rd_uuid
```

O `?on_conflict=rd_uuid` permite UPSERT: se o RD mandar o mesmo lead duas vezes (mesmo `rd_uuid`), não duplica.

### Headers

| Key | Value |
|---|---|
| `apikey` | `<SERVICE_ROLE_KEY>` |
| `Authorization` | `Bearer <SERVICE_ROLE_KEY>` |
| `Content-Type` | `application/json` |
| `Prefer` | `resolution=ignore-duplicates,return=representation` |

> **Importante:** use a `service_role` key (não a `anon`). Ela bypassa RLS e permite inserir.
> Guarde como **Credential** no n8n (tipo "Header Auth") — não deixe hardcoded no workflow.

### Body (JSON)

Ajuste o mapeamento de campos conforme o payload que o RD Station te envia. Modelo base:

```json
{
  "nome": "={{ $json.name }}",
  "email": "={{ $json.email }}",
  "telefone": "={{ $json.mobile_phone || $json.personal_phone }}",
  "cidade": "={{ $json.city }}",
  "area_profissional": "={{ $json.job_title }}",
  "tipo_participacao": "={{ $json.tipo_participacao || 'jogador' }}",
  "modalidade": "={{ $json.modalidade }}",
  "turno": "={{ $json.turno }}",
  "rd_uuid": "={{ $json.uuid || $json.id }}",
  "rd_conversion_identifier": "={{ $json.conversion_identifier }}",
  "origem": "rd_station",
  "raw_payload": "={{ $json }}"
}
```

**Campos obrigatórios:** `nome`, `email`.
**Campos que o trigger preenche sozinho:**
- `status` — será `confirmado` ou `suplente` conforme as vagas
- `nivel` — derivado de `turno` (9h→iniciante, 10h→intermediário, 11h→avançado)

---

## 3. Mapeamento de valores esperados

Os campos `modalidade` e `turno` precisam vir nos valores exatos abaixo (o banco rejeita outros via CHECK constraint):

| Campo | Valores válidos |
|---|---|
| `modalidade` | `tenis`, `padel`, `beachtennis` |
| `turno` | `9h`, `10h`, `11h` |
| `tipo_participacao` | `jogador`, `acompanhante` |

**Se o RD manda com outro formato** (ex: "Beach Tennis", "09:00"), use um nó **Set/Function** antes do HTTP Request para normalizar:

```js
// Exemplo em Function node
const map_modalidade = {
  'Tênis': 'tenis', 'Tenis': 'tenis',
  'Pádel': 'padel', 'Padel': 'padel',
  'Beach Tennis': 'beachtennis', 'Beach Tenis': 'beachtennis'
};
const map_turno = { '09:00': '9h', '10:00': '10h', '11:00': '11h' };

return items.map(item => {
  item.json.modalidade = map_modalidade[item.json.modalidade_raw] || item.json.modalidade_raw;
  item.json.turno = map_turno[item.json.turno_raw] || item.json.turno_raw;
  return item;
});
```

---

## 4. Resposta esperada

Com `Prefer: return=representation`, o Supabase retorna o registro criado incluindo o `status` atribuído:

```json
[{
  "id": "a1b2c3...",
  "created_at": "2026-04-15T12:30:00Z",
  "nome": "João Silva",
  "email": "joao@exemplo.com",
  "modalidade": "tenis",
  "turno": "10h",
  "nivel": "intermediario",
  "status": "suplente",   // ← preenchido pelo trigger
  ...
}]
```

Use `$json.status` no fluxo seguinte do n8n pra decidir: se `suplente`, manda email avisando; se `confirmado`, manda email de confirmação.

---

## 5. Consultar vagas disponíveis (opcional)

Endpoint público (usa `anon` key, seguro pra frontend/dashboard):

```
GET https://plbzwswqkeozvyirzqma.supabase.co/rest/v1/vagas_disponiveis

Headers:
  apikey: <ANON_KEY>
  Authorization: Bearer <ANON_KEY>
```

Retorna:
```json
[
  {
    "modalidade": "tenis", "turno": "10h",
    "ativo": false, "limite": 4, "confirmados": 4,
    "suplentes": 2, "vagas_restantes": 0, "estado": "desabilitado"
  },
  ...
]
```

O campo `estado` já vem calculado: `aberto` | `suplentes` | `desabilitado`.

---

## 6. Teste rápido via curl

```bash
curl -X POST 'https://plbzwswqkeozvyirzqma.supabase.co/rest/v1/inscricoes' \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '{
    "nome": "Teste",
    "email": "teste@exemplo.com",
    "tipo_participacao": "jogador",
    "modalidade": "tenis",
    "turno": "10h"
  }'
```

Esperado: retorna o registro com `"status": "suplente"` (porque Tênis 10h está `ativo=false`).
