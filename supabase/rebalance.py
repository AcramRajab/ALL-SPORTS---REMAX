#!/usr/bin/env python3
"""
Rebalanceia limites e status conforme decisões do CEO (2026-04-15):
- Padel: 8 por turno (2 quadras x 4)
- Tênis: 8 por turno (reativa 10h)
- Beach: 4 por turno (spec original)
- Re-ranqueia status por created_at ASC dentro de cada (modalidade, turno)
"""
import json, os, sys, urllib.request, urllib.error

SUPABASE_URL = 'https://plbzwswqkeozvyirzqma.supabase.co'
SERVICE_ROLE = sys.argv[1] if len(sys.argv) > 1 else os.environ.get('SUPABASE_SERVICE_ROLE')
if not SERVICE_ROLE:
    sys.exit('Falta SERVICE_ROLE')

def req(method, path, body=None, headers=None):
    h = {'apikey': SERVICE_ROLE, 'Authorization': f'Bearer {SERVICE_ROLE}', 'Content-Type': 'application/json'}
    if headers: h.update(headers)
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(f'{SUPABASE_URL}{path}', data=data, method=method, headers=h)
    try:
        with urllib.request.urlopen(r) as resp:
            return resp.status, resp.read().decode()
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()

# 1. Update limites
print('=== Atualizando limites ===')
novos_limites = [
    ('padel','9h',8,True), ('padel','10h',8,True), ('padel','11h',8,True),
    ('tenis','9h',8,True), ('tenis','10h',8,True), ('tenis','11h',8,True),
    ('beachtennis','9h',4,True), ('beachtennis','10h',4,True), ('beachtennis','11h',4,True),
]
for mod, turno, limite, ativo in novos_limites:
    code, _ = req('PATCH',
        f'/rest/v1/limites_vagas?modalidade=eq.{mod}&turno=eq.{turno}',
        body={'limite': limite, 'ativo': ativo},
        headers={'Prefer': 'return=minimal'})
    print(f'  {mod} {turno}: limite={limite} ativo={ativo} -> {code}')

# 2. Rebalancear status por chegada cronológica
print('\n=== Puxando jogadores ordenados ===')
code, resp = req('GET',
    '/rest/v1/inscricoes?select=id,modalidade,turno,status,created_at'
    '&tipo_participacao=eq.jogador&modalidade=not.is.null&turno=not.is.null'
    '&status=neq.cancelado&order=modalidade,turno,created_at.asc')
leads = json.loads(resp)
print(f'  total: {len(leads)}')

# Agrupa por (modalidade, turno) e calcula rank
from collections import defaultdict
grouped = defaultdict(list)
for lead in leads:
    grouped[(lead['modalidade'], lead['turno'])].append(lead)

# Puxa limites atualizados
code, resp = req('GET', '/rest/v1/limites_vagas?select=modalidade,turno,limite,ativo')
limites = {(l['modalidade'], l['turno']): l for l in json.loads(resp)}

# 3. Atualiza status de cada lead
print('\n=== Rebalanceando status ===')
promovidos = rebaixados = inalterados = 0
for (mod, turno), leads_group in sorted(grouped.items()):
    cfg = limites.get((mod, turno), {})
    limite = cfg.get('limite', 0) if cfg.get('ativo') else 0
    print(f'\n  {mod} {turno}: limite={limite}, total inscritos={len(leads_group)}')
    for idx, lead in enumerate(leads_group):
        novo = 'confirmado' if idx < limite else 'suplente'
        if novo == lead['status']:
            inalterados += 1
            continue
        code, _ = req('PATCH',
            f'/rest/v1/inscricoes?id=eq.{lead["id"]}',
            body={'status': novo},
            headers={'Prefer': 'return=minimal'})
        if lead['status'] == 'suplente' and novo == 'confirmado':
            promovidos += 1
            marker = '↑'
        else:
            rebaixados += 1
            marker = '↓'
        print(f'    {marker} {lead["id"][:8]}: {lead["status"]} -> {novo} ({code})')

print(f'\n=== Resumo ===')
print(f'  Promovidos (suplente -> confirmado): {promovidos}')
print(f'  Rebaixados (confirmado -> suplente): {rebaixados}')
print(f'  Inalterados: {inalterados}')
