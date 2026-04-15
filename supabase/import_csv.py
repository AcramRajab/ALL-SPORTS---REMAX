#!/usr/bin/env python3
"""
Importa leads do CSV exportado do RD Station para o Supabase.
- Ordena cronologicamente (Data da primeira conversão ASC)
- Insere 1 a 1 pra o trigger atribuir status corretamente
- Idempotente via rd_uuid (pode rodar de novo sem duplicar)
"""
import csv, json, os, sys, re, urllib.request, urllib.error
from datetime import datetime

CSV_PATH = '/Users/rodrigosouza/Downloads/rd-www-remaxsantacatarina-com-br-leads-site-open-all-resort.csv'
SUPABASE_URL = 'https://plbzwswqkeozvyirzqma.supabase.co'
SERVICE_ROLE = os.environ.get('SUPABASE_SERVICE_ROLE') or sys.argv[1] if len(sys.argv) > 1 else None
if not SERVICE_ROLE:
    sys.exit('Falta SERVICE_ROLE: passe como arg ou setenv SUPABASE_SERVICE_ROLE')

MAP_MODALIDADE = {
    'tenis': 'tenis', 'tênis': 'tenis',
    'padel': 'padel', 'pádel': 'padel',
    'beach tennis': 'beachtennis', 'beach tenis': 'beachtennis',
    'beachtennis': 'beachtennis',
}
MAP_TURNO = {
    '9h': '9h', '09h': '9h', '09:00': '9h',
    '10h': '10h', '10:00': '10h',
    '11h': '11h', '11:00': '11h',
}

def norm(s):
    return (s or '').strip().lower()

def extract_uuid(url):
    m = re.search(r'/leads/public/([0-9a-f-]{36})', url or '')
    return m.group(1) if m else None

def parse_date(s):
    # RD formato: "2026-04-15 10:34:50 -0300"
    try:
        return datetime.strptime(s.strip(), '%Y-%m-%d %H:%M:%S %z')
    except Exception:
        return datetime.min.replace(tzinfo=None)

def req(method, path, body=None, headers=None):
    url = f'{SUPABASE_URL}{path}'
    h = {
        'apikey': SERVICE_ROLE,
        'Authorization': f'Bearer {SERVICE_ROLE}',
        'Content-Type': 'application/json',
    }
    if headers:
        h.update(headers)
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(url, data=data, method=method, headers=h)
    try:
        with urllib.request.urlopen(r) as resp:
            return resp.status, resp.read().decode()
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()

# 1. Ler CSV e montar lista
rows = []
with open(CSV_PATH, encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for r in reader:
        uuid = extract_uuid(r.get('URL pública', ''))
        modalidade_raw = norm(r.get('[Open All Resort] Clínica escolhida', ''))
        turno_raw = norm(r.get('[Open All Resort] Horário', ''))
        tipo_raw = norm(r.get('[Open All Resort] Tipo de Participação', 'jogador'))
        nome = (r.get('Nome') or '').strip()
        email = (r.get('Email') or '').strip()
        if not nome or not email:
            continue
        rows.append({
            'nome': nome,
            'email': email,
            'telefone': (r.get('Celular') or r.get('Telefone') or '').strip() or None,
            'cidade': (r.get('Cidade') or '').strip() or None,
            'area_profissional': (r.get('Cargo') or r.get('Biografia') or '').strip() or None,
            'tipo_participacao': 'acompanhante' if 'acompanh' in tipo_raw else 'jogador',
            'modalidade': MAP_MODALIDADE.get(modalidade_raw) or None,
            'turno': MAP_TURNO.get(turno_raw) or None,
            'rd_uuid': uuid,
            'rd_conversion_identifier': r.get('Origem da primeira conversão') or 'All resort página evento',
            'origem': 'rd_csv_import',
            '_sort': parse_date(r.get('Data da primeira conversão', '')),
        })

# 2. Ordenar cronologicamente (ASC)
rows.sort(key=lambda x: x['_sort'])
print(f'Total de leads válidos: {len(rows)}')

# 3. Limpar testes antigos (nomes conhecidos, preserva rd_uuids sincronizados)
print('\nLimpando testes antigos...')
for email in ['debug@test.com']:
    code, body = req('DELETE', f'/rest/v1/inscricoes?email=eq.{email}')
    print(f'  delete {email}: {code}')

# 4. Inserir em ordem
print('\nInserindo...')
ok = dup = err = 0
for i, row in enumerate(rows, 1):
    body = {k: v for k, v in row.items() if not k.startswith('_')}
    code, resp = req(
        'POST',
        '/rest/v1/inscricoes?on_conflict=rd_uuid',
        body=body,
        headers={'Prefer': 'resolution=ignore-duplicates,return=representation'}
    )
    if code in (200, 201):
        try:
            data = json.loads(resp)
            status = data[0]['status'] if data else '(sem retorno — duplicado ignorado)'
            nivel = data[0].get('nivel', '-') if data else '-'
            print(f'  {i:>2}. {row["nome"][:30]:<30} {row["modalidade"] or "-":<12} {row["turno"] or "-":<4} -> {status} ({nivel})')
            if data:
                ok += 1
            else:
                dup += 1
        except Exception as e:
            print(f'  {i:>2}. {row["nome"][:30]:<30} OK mas parse falhou: {e}')
            ok += 1
    else:
        print(f'  {i:>2}. ERRO {code}: {resp[:200]}')
        err += 1

print(f'\nResumo: {ok} inseridos, {dup} duplicados (ignorados), {err} erros')
