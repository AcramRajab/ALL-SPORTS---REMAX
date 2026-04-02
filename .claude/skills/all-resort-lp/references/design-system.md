# ALL Resort — Design System para Landing Pages

## Paleta de Cores

```javascript
tailwind.config = {
  theme: {
    extend: {
      colors: {
        primary: '#1F2F2A',              // Verde escuro — headers, footers, seções de destaque
        'primary-foreground': '#F7F6F2', // Texto sobre primary
        secondary: '#2C3E46',            // Azul escuro — variação para seções
        'secondary-foreground': '#F3F1EC',
        background: '#F3F1EC',           // Bege/creme — fundo de seções claras
        foreground: '#2A2A2A',           // Texto principal
        'text-on-light': '#2A2A2A',      // Texto sobre fundo claro
        'accent-green': '#5A6F63',       // Verde médio — CTAs, destaques, links
        destructive: '#E53E3E',          // Vermelho — alertas, regras importantes
      },
      fontFamily: {
        heading: ['Inter', 'sans-serif'],
        paragraph: ['Inter', 'sans-serif'],
      },
    },
  },
}
```

## Tipografia

- **Fonte:** Inter (Google Fonts, weight 100-900)
- **Headings:** `font-heading`, bold (700), tracking-wide
  - H1: `text-4xl md:text-5xl lg:text-6xl`
  - H2: `text-3xl md:text-4xl` ou `text-4xl md:text-5xl`
  - H3: `text-lg md:text-xl` ou `text-xl md:text-2xl`
- **Parágrafo:** `font-paragraph`, normal (400)
  - Body: `text-base md:text-lg`
  - Descrição: `text-lg md:text-xl`
  - Nota: `text-sm`

## Componentes

### Botão Primário (CTA)
```html
<a href="#formulario" class="px-8 py-4 bg-accent-green text-primary-foreground font-heading font-semibold rounded-lg hover:bg-accent-green/90 transition-colors text-lg">
  Texto do CTA
</a>
```

### Botão Secundário (outline)
```html
<a href="#regras" class="px-8 py-4 border-2 border-primary-foreground text-primary-foreground font-heading font-semibold rounded-lg hover:bg-white/10 transition-colors text-lg">
  Texto do Botão
</a>
```

### Card de Benefício
```html
<div class="fade-up p-6 md:p-8 bg-background rounded-lg border border-accent-green/20 hover:border-accent-green/50 transition-colors">
  <h3 class="font-heading text-lg md:text-xl font-semibold text-text-on-light mb-3">Título</h3>
  <p class="font-paragraph text-text-on-light/70">Descrição</p>
</div>
```

### Card de Diferencial (com imagem)
```html
<div class="group flex flex-col h-full overflow-hidden fade-up">
  <div class="relative w-full overflow-hidden rounded-lg mb-6 bg-accent-green/10">
    <div class="aspect-video">
      <img src="URL" alt="Alt" class="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105" />
    </div>
    <div class="absolute inset-0 bg-gradient-to-t from-primary/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
  </div>
  <div class="flex-1 flex flex-col">
    <h3 class="font-heading text-xl font-semibold text-primary-foreground mb-3">Título</h3>
    <p class="text-base md:text-lg text-primary-foreground/85">Descrição</p>
  </div>
  <div class="mt-6 h-1 w-12 bg-accent-green rounded-full group-hover:w-full transition-all duration-300"></div>
</div>
```

### Card de Regra (borda verde)
```html
<div class="fade-up bg-white border-2 border-accent-green/40 rounded-lg p-8 md:p-10 hover:border-accent-green/70 transition-colors">
  <div class="flex items-center gap-4 mb-6">
    <div class="w-12 h-12 rounded-lg bg-accent-green/15 flex items-center justify-center">
      <span class="text-xl font-bold text-accent-green">1</span>
    </div>
    <h3 class="font-heading text-xl md:text-2xl font-semibold text-text-on-light">Título</h3>
  </div>
  <!-- conteúdo: lista com checks ou texto -->
</div>
```

### Card de Regra (borda vermelha / destructive)
```html
<div class="fade-up bg-white border-2 border-destructive/30 rounded-lg p-8 md:p-10 hover:border-destructive/60 transition-colors">
  <div class="flex items-center gap-4 mb-6">
    <div class="w-12 h-12 rounded-lg bg-destructive/10 flex items-center justify-center">
      <span class="text-xl font-bold text-destructive">4</span>
    </div>
    <h3 class="font-heading text-xl md:text-2xl font-semibold text-text-on-light">Atenção</h3>
  </div>
  <!-- conteúdo de alerta -->
</div>
```

### Card de Stat (número grande)
```html
<div class="fade-up group relative bg-gradient-to-br from-accent-green/25 to-accent-green/10 rounded-xl p-8 md:p-10 border border-accent-green/30 hover:border-accent-green/60 transition-all duration-300 cursor-default">
  <div class="absolute inset-0 rounded-xl bg-accent-green/5 opacity-0 group-hover:opacity-100 transition-opacity duration-300 blur-xl"></div>
  <div class="relative z-10">
    <div class="font-heading text-7xl md:text-8xl font-bold text-accent-green mb-4 leading-none">3</div>
    <div class="font-paragraph text-lg md:text-xl text-primary-foreground/90 font-medium">Descrição do número</div>
  </div>
</div>
```

### Campo de Formulário
```html
<div>
  <label class="block font-heading font-semibold text-text-on-light mb-2">Label *</label>
  <input type="text" required placeholder="Placeholder"
    class="w-full px-4 py-3 border border-accent-green/30 rounded-lg font-paragraph text-text-on-light bg-white focus:outline-none focus:ring-2 focus:border-accent-green focus:ring-accent-green/20 transition-colors" />
</div>
```

### Select de Formulário
```html
<div>
  <label class="block font-heading font-semibold text-text-on-light mb-2">Label *</label>
  <select required
    class="w-full px-4 py-3 border border-accent-green/30 rounded-lg font-paragraph text-text-on-light bg-white focus:outline-none focus:ring-2 focus:border-accent-green focus:ring-accent-green/20 transition-colors">
    <option value="">Selecione uma opção</option>
    <option value="valor">Opção</option>
  </select>
</div>
```

## Animações

### Fade-up (scroll reveal)
```css
.fade-up {
  opacity: 0;
  transform: translateY(20px);
  transition: opacity 0.3s ease-in-out, transform 0.5s cubic-bezier(0.4, 0, 0.2, 1);
}
.fade-up.visible {
  opacity: 1;
  transform: none;
}
```

### IntersectionObserver
```javascript
const observer = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (entry.isIntersecting) {
      const existingDelay = entry.target.style.transitionDelay;
      if (!existingDelay) {
        entry.target.style.transitionDelay = '0ms';
      }
      entry.target.classList.add('visible');
      observer.unobserve(entry.target);
    }
  });
}, { threshold: 0.1, rootMargin: '0px 0px -50px 0px' });

document.querySelectorAll('.fade-up').forEach(el => observer.observe(el));
```

### Delays escalonados
Para cards em grid, adicionar `style="transition-delay: Nms;"` onde N = 0, 100, 200, 300...

## Hero Parallax
```css
.hero-bg {
  background-attachment: fixed;
  background-size: cover;
  background-position: center;
}
@media (max-width: 768px) {
  .hero-bg { background-attachment: scroll; }
}
```

## Padrões de Seção

| Seção | Background | Texto |
|-------|------------|-------|
| Hero | Imagem + overlay `bg-black/40` | `text-primary-foreground` |
| Benefícios | `bg-white` | `text-text-on-light` |
| Diferenciais | `bg-primary` | `text-primary-foreground` |
| Regras | `bg-background` | `text-text-on-light` |
| Stats | `bg-primary` | `text-primary-foreground` / `text-accent-green` |
| Formulário | `bg-white` | `text-text-on-light` |
| Footer | `bg-primary` | `text-primary-foreground/60` |

## Espaçamento Padrão
- Seções: `py-24 px-8` (ou `py-32` para stats)
- Container: `max-w-6xl mx-auto` (ou `max-w-7xl` para diferenciais, `max-w-5xl` para stats, `max-w-2xl` para form)
- Grid gaps: `gap-6 md:gap-8`
- Margin bottom de headings: `mb-4` a `mb-12`

## Imagens Placeholder (Unsplash)

Usar URLs do Unsplash com parâmetros de qualidade:
```
https://images.unsplash.com/photo-ID?w=WIDTH&q=80
```

Sugestões por contexto:
- Quadra de tênis/padel: `photo-1622279457486-62dcc4a431d6`, `photo-1554068865-24cecd4e34b8`
- Resort/golf: `photo-1535131749006-b7f58c99034b`
- Networking: `photo-1511578314322-379afb476865`
- Food/brunch: buscar "brunch table" ou "coffee reception"
- Fitness: buscar "outdoor fitness" ou "functional training"

## Tom de Voz

- Premium sem ser esnobe
- Exclusividade real, não artificial
- Urgência sutil baseada em fatos (vagas limitadas por estrutura)
- Foco em experiência, não em venda
- Linguagem direta, sem jargão imobiliário
- Frases curtas e impactantes nos headings
