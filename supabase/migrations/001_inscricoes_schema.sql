-- =============================================================================
-- ALL Resort Xperience — Schema de inscrições do evento ALL Sports REMAX
-- Projeto Supabase: plbzwswqkeozvyirzqma
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Tabela de limites de vagas (config editável)
-- -----------------------------------------------------------------------------
create table if not exists public.limites_vagas (
  modalidade       text not null,
  turno            text not null,
  limite           int  not null default 0,
  limite_suplentes int  not null default 0,
  ativo            boolean not null default true,
  primary key (modalidade, turno),
  check (modalidade in ('tenis', 'padel', 'beachtennis')),
  check (turno in ('9h', '10h', '11h'))
);

insert into public.limites_vagas (modalidade, turno, limite, limite_suplentes, ativo) values
  ('padel',       '9h',  4, 2, true),
  ('padel',       '10h', 4, 2, true),
  ('padel',       '11h', 4, 2, true),
  ('tenis',       '9h',  8, 4, true),
  ('tenis',       '10h', 4, 2, false),  -- DESABILITADO (client pediu em 08:34)
  ('tenis',       '11h', 4, 2, true),
  ('beachtennis', '9h',  4, 2, true),
  ('beachtennis', '10h', 4, 2, true),
  ('beachtennis', '11h', 4, 2, true)
on conflict (modalidade, turno) do nothing;

-- -----------------------------------------------------------------------------
-- 2. Tabela principal de inscrições
-- -----------------------------------------------------------------------------
create table if not exists public.inscricoes (
  id                       uuid primary key default gen_random_uuid(),
  created_at               timestamptz not null default now(),

  -- dados do lead
  nome                     text not null,
  email                    text not null,
  telefone                 text,
  cidade                   text,
  area_profissional        text,

  -- dados do evento
  tipo_participacao        text check (tipo_participacao in ('jogador', 'acompanhante')),
  modalidade               text check (modalidade in ('tenis', 'padel', 'beachtennis')),
  turno                    text check (turno in ('9h', '10h', '11h')),
  nivel                    text check (nivel in ('iniciante', 'intermediario', 'avancado')),

  -- controle
  status                   text not null default 'confirmado'
                           check (status in ('confirmado', 'suplente', 'cancelado')),
  origem                   text not null default 'rd_station',

  -- idempotência + debug
  rd_uuid                  text unique,
  rd_conversion_identifier text,
  raw_payload              jsonb
);

create index if not exists idx_inscricoes_modalidade_turno
  on public.inscricoes (modalidade, turno)
  where status <> 'cancelado';

create index if not exists idx_inscricoes_email
  on public.inscricoes (lower(email));

create index if not exists idx_inscricoes_created_at
  on public.inscricoes (created_at desc);

-- -----------------------------------------------------------------------------
-- 3. Trigger: atribui status (confirmado/suplente) automaticamente no INSERT
-- -----------------------------------------------------------------------------
create or replace function public.fn_set_inscricao_status()
returns trigger
language plpgsql
security definer
as $$
declare
  v_limite        int;
  v_ativo         boolean;
  v_confirmados   int;
  v_suplentes     int;
  v_limite_supl   int;
begin
  -- Acompanhantes não consomem vagas das clínicas
  if new.tipo_participacao = 'acompanhante' or new.modalidade is null or new.turno is null then
    if new.status is null then new.status := 'confirmado'; end if;
    return new;
  end if;

  -- Deriva nível a partir do turno, se não vier preenchido
  if new.nivel is null then
    new.nivel := case new.turno
      when '9h'  then 'iniciante'
      when '10h' then 'intermediario'
      when '11h' then 'avancado'
    end;
  end if;

  -- Se o chamador forçou status (ex: 'cancelado'), respeita
  if new.status is not null and new.status <> 'confirmado' then
    return new;
  end if;

  select limite, ativo, limite_suplentes
    into v_limite, v_ativo, v_limite_supl
  from public.limites_vagas
  where modalidade = new.modalidade and turno = new.turno;

  -- Turno não existe ou está desativado: vai pra suplente
  if v_limite is null or v_ativo = false then
    new.status := 'suplente';
    return new;
  end if;

  select
    count(*) filter (where status = 'confirmado'),
    count(*) filter (where status = 'suplente')
  into v_confirmados, v_suplentes
  from public.inscricoes
  where modalidade = new.modalidade and turno = new.turno;

  if v_confirmados < v_limite then
    new.status := 'confirmado';
  else
    new.status := 'suplente';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_set_inscricao_status on public.inscricoes;
create trigger trg_set_inscricao_status
  before insert on public.inscricoes
  for each row
  execute function public.fn_set_inscricao_status();

-- -----------------------------------------------------------------------------
-- 4. View pública: contagem de vagas por modalidade/turno (sem expor leads)
-- -----------------------------------------------------------------------------
create or replace view public.vagas_disponiveis as
select
  l.modalidade,
  l.turno,
  l.ativo,
  l.limite,
  l.limite_suplentes,
  coalesce(count(i.*) filter (where i.status = 'confirmado'), 0)::int as confirmados,
  coalesce(count(i.*) filter (where i.status = 'suplente'),   0)::int as suplentes,
  greatest(l.limite - coalesce(count(i.*) filter (where i.status = 'confirmado'), 0)::int, 0)::int as vagas_restantes,
  case
    when l.ativo = false then 'desabilitado'
    when coalesce(count(i.*) filter (where i.status = 'confirmado'), 0) >= l.limite then 'suplentes'
    else 'aberto'
  end as estado
from public.limites_vagas l
left join public.inscricoes i
  on i.modalidade = l.modalidade
 and i.turno      = l.turno
 and i.status    <> 'cancelado'
group by l.modalidade, l.turno, l.ativo, l.limite, l.limite_suplentes;

-- -----------------------------------------------------------------------------
-- 5. Row Level Security
-- -----------------------------------------------------------------------------
alter table public.inscricoes     enable row level security;
alter table public.limites_vagas  enable row level security;

-- Anon NÃO pode ler leads (só via view agregada)
-- Anon PODE ler limites e a view de vagas
drop policy if exists "anon_read_limites" on public.limites_vagas;
create policy "anon_read_limites"
  on public.limites_vagas for select
  to anon
  using (true);

-- A view vagas_disponiveis herda as permissões das tabelas; precisamos
-- conceder SELECT explícito pra anon.
grant select on public.vagas_disponiveis to anon;
grant select on public.limites_vagas     to anon;

-- service_role bypassa RLS (default), então n8n/backend continuam funcionando.
