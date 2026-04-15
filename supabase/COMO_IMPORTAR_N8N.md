# Como importar o workflow no n8n (3 minutos)

## Passo 1 — Criar a Credencial no n8n

Antes de importar o workflow, cria a credencial que vai guardar a `service_role` key:

1. n8n → **Credentials** → **New** → procura **"Header Auth"**
2. Preenche:
   - **Name:** `Supabase Service Role (All Resort)`
   - **Header Name:** `Authorization`
   - **Header Value:** `Bearer <COLE_A_SERVICE_ROLE_KEY_AQUI>`
3. **Save**

> Obs: o workflow também envia um header `apikey` com o mesmo valor. A credencial injeta só o `Authorization`. O `apikey` é setado inline no node — vou mostrar como consertar isso no Passo 4.

---

## Passo 2 — Importar o workflow

1. n8n → **Workflows** → **Add workflow** → menu **⋮** → **Import from File**
2. Seleciona `supabase/n8n_workflow_rd_to_supabase.json`
3. O workflow aparece com 4 nodes encadeados

---

## Passo 3 — Vincular a credencial

No node **"POST Supabase /inscricoes"**:
1. Clica nele → aba **Authentication**
2. Seleciona a credencial **"Supabase Service Role (All Resort)"** no dropdown
3. Save

---

## Passo 4 — Ajustar o header `apikey` (importante!)

O Supabase exige **dois** headers com a key: `apikey` e `Authorization: Bearer …`. A credencial só cuida do `Authorization`. Você precisa colocar a service_role também no header `apikey` manualmente:

1. No node **"POST Supabase /inscricoes"** → aba **Headers**
2. No header `apikey`, substitui o value `={{ $credentials.httpHeaderAuth.value }}` por:
   ```
   <COLE_A_SERVICE_ROLE_KEY_AQUI>
   ```
3. Save

**Alternativa mais limpa** (recomendado): em vez de editar o node, cria uma **variável de ambiente** no n8n:
- Settings → Environment Variables → `SUPABASE_SERVICE_ROLE` = `<service_role_key>`
- No header `apikey`, use: `={{ $env.SUPABASE_SERVICE_ROLE }}`
- Na credencial, use o mesmo: `Bearer {{ $env.SUPABASE_SERVICE_ROLE }}`

---

## Passo 5 — Ligar o trigger real

O workflow vem com **Manual Trigger** pra teste. Pra rodar de verdade, troca pelo trigger que você vai usar:

- **RD Station Webhook** (se o RD manda pra você) → substitui o Manual Trigger
- **RD Station (polling via API)** → usa o node **"RD Station"** com credencial OAuth
- **Schedule Trigger** (ex: a cada 15min, busca leads novos) → + node HTTP GET no RD

---

## Passo 6 — Testar

1. No node **"Normalizar payload RD"** → menu **⋮** → **Edit Output** → cola um JSON de teste:
   ```json
   {
     "name": "Teste Silva",
     "email": "teste@exemplo.com",
     "mobile_phone": "+5548999887766",
     "city": "Florianópolis",
     "modalidade": "Tênis",
     "turno": "10:00",
     "tipo_participacao": "jogador",
     "uuid": "rd-test-001"
   }
   ```
2. Clica em **Execute Workflow**
3. No output do node HTTP, você deve ver:
   ```json
   [{
     "id": "...",
     "nome": "Teste Silva",
     "status": "suplente",   // Tênis 10h está desabilitado
     "nivel": "intermediario",
     ...
   }]
   ```

---

## O que cada node faz

| Node | Função |
|---|---|
| **Manual Trigger** | Dispara teste manual (troque pelo webhook/polling real) |
| **Normalizar payload RD** | Converte "Tênis" → `tenis`, "10:00" → `10h`, extrai nome/email tolerando variações de nome de campo, falha se nome/email faltarem |
| **POST Supabase /inscricoes** | Insere no banco. O trigger SQL decide `status` (confirmado/suplente) e `nivel` automaticamente |
| **Status = confirmado?** | Bifurca o fluxo: saída TRUE → manda email de confirmação; FALSE → manda email de suplente (você conecta seus nodes de email/WhatsApp aqui) |

---

## Troubleshooting

- **401 Unauthorized:** headers `apikey` e `Authorization` estão com a key certa? Confere se é a `service_role` (não a `anon`)
- **400 Bad Request com mensagem sobre CHECK constraint:** `modalidade` ou `turno` veio com valor fora da lista. Checa o mapeamento no node Normalizar
- **409 Conflict:** `rd_uuid` duplicado — mas o `Prefer: resolution=ignore-duplicates` deveria evitar. Confere se o header está certo
- **Insert funciona mas `status` sempre `confirmado`:** o trigger não rodou. Confira em Supabase SQL Editor:
  ```sql
  select tgname from pg_trigger where tgrelid = 'public.inscricoes'::regclass;
  ```
  Deve listar `trg_set_inscricao_status`
