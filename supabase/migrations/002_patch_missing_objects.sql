-- =============================================================================
-- PATCH: completa o schema que não foi aplicado na migration 001
-- Roda depois que a tabela public.inscricoes já existe (criada via UI).
-- Idempotente — pode rodar várias vezes sem quebrar.
-- =============================================================================

-- 0. Limpar o registro de teste sujo (com prefixo =)
delete from public.inscricoes where nome like '=%' or email like '=%';

-- 1. Adicionar colunas que faltam em inscricoes
alter table public.inscricoes
  add column if not exists nivel  text,
  add column if not exists status text not null default 'confirmado';

-- 2. Adicionar CHECK constraints (rejeita valores errados como '=tenis')
do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'inscricoes_tipo_participacao_check') then
    alter table public.inscricoes add constraint inscricoes_tipo_participacao_check
      check (tipo_participacao in ('jogador','acompanhante'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'inscricoes_modalidade_check') then
    alter table public.inscricoes add constraint inscricoes_modalidade_check
      check (modalidade is null or modalidade in ('tenis','padel','beachtennis'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'inscricoes_turno_check') then
    alter table public.inscricoes add constraint inscricoes_turno_check
      check (turno is null or turno in ('9h','10h','11h'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'inscricoes_nivel_check') then
    alter table public.inscricoes add constraint inscricoes_nivel_check
      check (nivel is null or nivel in ('iniciante','intermediario','avancado'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'inscricoes_status_check') then
    alter table public.inscricoes add constraint inscricoes_status_check
      check (status in ('confirmado','suplente','cancelado'));
  end if;
end $$;

-- 3. Garantir unique em rd_uuid (pra idempotência)
do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'inscricoes_rd_uuid_key') then
    alter table public.inscricoes add constraint inscricoes_rd_uuid_key unique (rd_uuid);
  end if;
end $$;

-- 4. Índices
create index if not exists idx_inscricoes_modalidade_turno
  on public.inscricoes (modalidade, turno) where status <> 'cancelado';
create index if not exists idx_inscricoes_created_at
  on public.inscricoes (created_at desc);

-- 5. Tabela limites_vagas
create table if not exists public.limites_vagas (
  modalidade       text not null,
  turno            text not null,
  limite           int  not null default 0,
  limite_suplentes int  not null default 0,
  ativo            boolean not null default true,
  primary key (modalidade, turno),
  check (modalidade in ('tenis','padel','beachtennis')),
  check (turno in ('9h','10h','11h'))
);

insert into public.limites_vagas (modalidade, turno, limite, limite_suplentes, ativo) values
  ('padel','9h',4,2,true),
  ('padel','10h',4,2,true),
  ('padel','11h',4,2,true),
  ('tenis','9h',8,4,true),
  ('tenis','10h',4,2,false),     -- desabilitado
  ('tenis','11h',4,2,true),
  ('beachtennis','9h',4,2,true),
  ('beachtennis','10h',4,2,true),
  ('beachtennis','11h',4,2,true)
on conflict (modalidade,turno) do nothing;

-- 6. Função + trigger de atribuição de status
create or replace function public.fn_set_inscricao_status()
returns trigger language plpgsql security definer as $$
declare
  v_limite int; v_ativo boolean; v_confirmados int;
begin
  if new.tipo_participacao = 'acompanhante' or new.modalidade is null or new.turno is null then
    if new.status is null then new.status := 'confirmado'; end if;
    return new;
  end if;

  if new.nivel is null then
    new.nivel := case new.turno
      when '9h' then 'iniciante'
      when '10h' then 'intermediario'
      when '11h' then 'avancado'
    end;
  end if;

  if new.status is not null and new.status <> 'confirmado' then return new; end if;

  select limite, ativo into v_limite, v_ativo
    from public.limites_vagas
   where modalidade = new.modalidade and turno = new.turno;

  if v_limite is null or v_ativo = false then
    new.status := 'suplente'; return new;
  end if;

  select count(*) into v_confirmados
    from public.inscricoes
   where modalidade = new.modalidade and turno = new.turno and status = 'confirmado';

  new.status := case when v_confirmados < v_limite then 'confirmado' else 'suplente' end;
  return new;
end $$;

drop trigger if exists trg_set_inscricao_status on public.inscricoes;
create trigger trg_set_inscricao_status
  before insert on public.inscricoes
  for each row execute function public.fn_set_inscricao_status();

-- 7. View agregada pública
create or replace view public.vagas_disponiveis as
select
  l.modalidade, l.turno, l.ativo, l.limite, l.limite_suplentes,
  coalesce(count(i.*) filter (where i.status='confirmado'),0)::int as confirmados,
  coalesce(count(i.*) filter (where i.status='suplente'),  0)::int as suplentes,
  greatest(l.limite - coalesce(count(i.*) filter (where i.status='confirmado'),0)::int, 0)::int as vagas_restantes,
  case
    when l.ativo=false then 'desabilitado'
    when coalesce(count(i.*) filter (where i.status='confirmado'),0) >= l.limite then 'suplentes'
    else 'aberto'
  end as estado
from public.limites_vagas l
left join public.inscricoes i
  on i.modalidade=l.modalidade and i.turno=l.turno and i.status<>'cancelado'
group by l.modalidade, l.turno, l.ativo, l.limite, l.limite_suplentes;

-- 8. RLS
alter table public.inscricoes    enable row level security;
alter table public.limites_vagas enable row level security;

drop policy if exists "anon_read_limites" on public.limites_vagas;
create policy "anon_read_limites" on public.limites_vagas for select to anon using (true);

grant select on public.vagas_disponiveis to anon;
grant select on public.limites_vagas     to anon;
