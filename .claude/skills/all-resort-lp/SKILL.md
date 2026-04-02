---
name: all-resort-lp
description: Criar e manter landing pages HTML para o ALL Resort Club Residence. Usar sempre que precisar criar uma nova LP, editar uma LP existente, adaptar conteúdo de briefing/PDF para landing page, clonar estrutura visual de uma página de referência, ou atualizar dados de evento nas páginas. Também acionar quando o usuário mencionar "landing page", "LP", "página de captura", "lista prioritária", "formulário de inscrição", ou qualquer página web relacionada ao ALL Resort ou eventos REMAX.
---

# ALL Resort Landing Page Builder

Skill para criar landing pages single-file HTML de alta conversão para o ALL Resort Club Residence e eventos associados (ALL Sports REMAX, Ecolibra Padel Series, etc.).

## Contexto do Projeto

O ALL Resort Club Residence é um empreendimento em Porto Belo — SC, com foco em lifestyle esportivo premium (tênis, padel, beach tennis, pickleball, golf). As landing pages são usadas para captação de leads, listas prioritárias e inscrições em eventos exclusivos.

## Design System

As LPs seguem um design system consistente baseado na identidade visual do ALL Resort. Antes de criar ou editar qualquer LP, consulte o arquivo de referência:

→ **[references/design-system.md](references/design-system.md)** — Cores, fontes, componentes, padrões visuais

### Tokens Rápidos
- Primária: `#1F2F2A` (verde escuro)
- Background: `#F3F1EC` (bege/creme)
- Accent: `#5A6F63` (verde médio)
- Texto: `#2A2A2A`
- Destructive: `#E53E3E` (vermelho para alertas)
- Fonte: Inter (Google Fonts)

## Stack Técnica

- HTML5 single-file (todo CSS/JS inline)
- Tailwind CSS via CDN (`https://cdn.tailwindcss.com`)
- Google Fonts (Inter): `https://fonts.googleapis.com/css2?family=Inter:wght@100..900`
- JavaScript vanilla (sem frameworks)
- Animações: fade-up com IntersectionObserver
- Responsivo mobile-first

## Estrutura Padrão de uma LP

Toda LP segue esta sequência de seções (pode variar conforme o objetivo):

### 1. HERO (bg escuro com parallax)
- Imagem de fundo full-screen com overlay escuro
- Logo/marca no topo
- Título principal (h1)
- Subtítulo com nome do evento e data
- Imagem ou vídeo destaque
- Texto de chamada
- 2 CTAs (primário: scroll para form, secundário: scroll para regras/programação)

### 2. BENEFÍCIOS (bg-white)
- Heading com gancho emocional
- Subtítulo explicativo
- 4 cards em grid 2x2 com título + descrição
- Card CTA final com urgência

### 3. DIFERENCIAIS (bg-primary verde escuro)
- Heading + subtítulo
- 4 cards com imagem (aspect-video), título, descrição
- Barra animada de underline em cada card (hover)

### 4. REGRAS (bg-background bege)
- Heading + subtítulo
- 4 cards: 3 com borda verde (checkmarks) + 1 com borda vermelha (destructive/alertas)
- Cada card com ícone numérico, título, lista, e citação ou nota

### 5. STATS (bg-primary verde escuro)
- Heading grande sobre limitação
- Subtítulo em accent-green
- 3 cards de números grandes com descrição
- Linha de fechamento com urgência

### 6. FORMULÁRIO (bg-white)
- Heading
- Disclaimer em card suave
- Campos do form (sempre incluir: nome, WhatsApp, cidade, área profissional)
- Botão submit
- Nota de privacidade
- Mensagem de sucesso (hidden por padrão)

### 7. FOOTER (bg-primary)
- Copyright

## Workflow de Criação

1. **Ler o briefing** — Se existe PDF ou documento de briefing, extrair todos os dados: evento, data, local, público, programação, instrutores, ativações, logística
2. **Consultar referência visual** — Se existe uma página de referência clonada, estudar sua estrutura de seções e padrões visuais
3. **Mapear conteúdo** — Criar um mapeamento de cada seção da referência → conteúdo do briefing
4. **Criar a LP** — Escrever o HTML completo seguindo o design system e a estrutura padrão
5. **Verificar** — Comparar a LP final com o briefing para garantir que todos os dados estão presentes

## Regras Importantes

- Imagens: usar Unsplash como placeholder até termos assets reais. Escolher imagens que remetam ao contexto (quadras, resort, gastronomia, fitness)
- Formulários: sempre simular o envio com setTimeout (substituir por webhook real depois)
- Textos: tom premium, exclusividade sutil, urgência sem apelação
- Nunca inventar dados que não estão no briefing
- Manter consistência visual absoluta entre todas as LPs do projeto
- Arquivo final deve ser um único HTML autocontido e funcional
