# ALL Resort Xperience — Projeto de Marketing Digital

## Contexto
Projeto de marketing e vendas para o empreendimento **ALL Resort Club Residence**, localizado em Porto Belo — Santa Catarina. O projeto é operado pela imobiliária RE/MAX e gerenciado pela agência de marketing do Rodrigo.

## Empreendimento
- **Nome:** ALL Resort Club Residence
- **Localização:** Porto Belo — Santa Catarina
- **Conceito:** Resort Club Residence com infraestrutura esportiva premium (tênis, padel, beach tennis, pickleball, golf), showroom, restaurante (Bruder), sport center
- **Tagline:** "It's ALL."
- **Público-alvo:** Investidores, empresários, executivos e profissionais liberais ligados ao universo do esporte, lifestyle e investimento imobiliário

## Identidade Visual
- **Cor primária:** #1F2F2A (verde escuro)
- **Cor de fundo:** #F3F1EC (bege/creme)
- **Cor de texto:** #2A2A2A
- **Cor accent:** #5A6F63 (verde médio)
- **Cor secundária:** #2C3E46
- **Fonte:** Inter (Google Fonts)
- **Tom:** Premium, exclusivo, sofisticado mas acessível

## Eventos
### ALL Sports — REMAX (18 de Abril)
- Evento presencial no Showroom ALL Resort e Sport Center
- 54 convidados + acompanhantes por turno (até 100 pessoas total)
- 3 turnos: 9h, 10h, 11h
- Clínicas: Tênis (Walter Gringo), Padel (Julio Julianoti, JP Moraes), Beach Tennis (Vini Chaparro)
- Ativações: Treino Funcional, Pickleball
- Coffee receptivo, ilha de hidratação, Restaurante Bruder

## Estrutura de Arquivos
```
All-resort-xperience/
├── CLAUDE.md                     # Este arquivo — contexto do projeto
├── README.md                     # Visão geral do projeto
├── PLANNING.md                   # Roadmap e planejamento
├── lp-remax-open.html            # LP Lista Prioritária — ALL Sports REMAX
├── 1804 - REMAX ALL RESORT (3).pdf  # Briefing do evento
├── ecolibrapadelseries.com.br_lista_prioritaria/  # Referência visual clonada
│   ├── index.html
│   └── assets/
└── .claude/
    └── skills/
        └── all-resort-lp/        # Skill para criação de LPs
            ├── SKILL.md
            └── references/
                └── design-system.md  # Design tokens, componentes, padrões
```

## Stack Técnica
- HTML/CSS/JS standalone (single-file)
- Tailwind CSS via CDN
- Google Fonts (Inter)
- Deploy: Vercel (quando pronto)
- Automação: n8n
- Gestão: ClickUp (via MCP)

## Skills do Projeto
- **all-resort-lp** — Acionar sempre ao criar/editar landing pages. Contém design system, componentes, padrões visuais e workflow de criação. Referência completa em `.claude/skills/all-resort-lp/references/design-system.md`

## Regras de Trabalho
1. Sempre consultar o PDF de briefing antes de criar conteúdo para o evento
2. Sempre acionar a skill `all-resort-lp` ao criar/editar landing pages
3. Consultar `design-system.md` para manter consistência visual
4. Manter consistência visual com a identidade da marca ALL Resort
5. Landing pages devem ser single-file HTML (Tailwind + JS inline)
6. Usar imagens placeholder do Unsplash até termos assets reais
7. Formulários devem capturar: nome, WhatsApp, cidade, área profissional, turno, modalidade
8. Tom de comunicação: exclusividade real, urgência sutil, posicionamento premium
9. Referência visual principal: página clonada da Ecolibra Padel Series
