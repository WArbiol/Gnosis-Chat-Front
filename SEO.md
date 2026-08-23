# 🌐 Guia de Configuração de SEO — Pergunte à Gnosis

Este arquivo documenta todas as configurações de **SEO (Search Engine Optimization)**, metadados sociais e dados estruturados configurados na versão Web do aplicativo.

Se desejar alterar qualquer título, descrição, imagem ou palavra-chave, você pode editar diretamente este arquivo ou solicitar o ajuste e eu atualizarei os arquivos técnicos correspondentes (`web/index.html`, `web/robots.txt`, `web/sitemap.xml`).

---

## 📌 1. Metadados Principais (Google & Buscadores)

| Campo | Valor Configurado | Objetivo |
| :--- | :--- | :--- |
| **Título da Página (`<title>`)** | `Pergunte à Gnosis \| IA Gnóstica & Sabedoria Sagrada` | 50-60 caracteres. Palavras-chave no início para alto ranqueamento. |
| **Meta Description** | `Explore a Gnosis e a Sabedoria Sagrada com o Pergunte à Gnosis. IA especializada nas obras de Samael Aun Weor, Lakhsmi Daimon, Pistis Sophia, Alquimia, Psicologia, Tarot, Cabala, Autoconhecimento e muito mais.` | 150-160 caracteres com alta taxa de clique (CTR). |
| **Palavras-Chave (`keywords`)** | `Gnosis, Gnosticismo, Samael Aun Weor, Lakhsmi Daimon, Esoterismo, Pistis Sophia, Alquimia, Psicologia Revolucionária, Tarot, Cabala, Autoconhecimento, Despertar da Consciência, Meditação, Kundalini, Inteligência Artificial Gnóstica, Pergunte à Gnosis` | Termos mais buscados por estudantes e buscadores espirituais. |
| **URL Canônica** | `https://gnosischat.com/` | Evita conteúdo duplicado entre subdomínios ou parâmetros de URL. |
| **Idioma** | `pt-BR` | Define português brasileiro como idioma primário do conteúdo. |
| **Diretiva de Robôs** | `index, follow, max-image-preview:large` | Permite indexação total e exibição de snippets enriquecidos no Google. |

---

## 📱 2. Redes Sociais & Compartilhamento (Open Graph / WhatsApp / Telegram / Twitter)

Quando um link do site é compartilhado no WhatsApp, Telegram, Facebook, LinkedIn ou Twitter/X, o seguinte card é exibido automaticamente:

* **Título Social:** `Pergunte à Gnosis | IA Gnóstica & Sabedoria Sagrada`
* **Descrição Social:** `Explore a Gnosis e a Sabedoria Sagrada com o Pergunte à Gnosis. IA especializada nas obras de Samael Aun Weor, Lakhsmi Daimon, Pistis Sophia, Alquimia, Psicologia, Tarot, Cabala, Autoconhecimento e muito mais.`
* **Imagem de Pré-Visualização (`og:image`):** `https://gnosischat.com/icons/Icon-512.png` (512x512 px)
* **Formato Twitter Card:** `summary` (Card elegante com ícone e texto)

---

## 🏛️ 3. Dados Estruturados Schema.org (JSON-LD)

Implementado no `<head>` para permitir que o Google exiba **Rich Snippets** (resultados enriquecidos) e FAQ direto na página de resultados de busca:

1. **`WebApplication`:** Registra o sistema como aplicativo de software educativo e estilo de vida.
2. **`Organization`:** Define a marca "Pergunte à Gnosis" e seu logotipo oficial.
3. **`FAQPage`:** Perguntas frequentes estruturadas sobre o acervo, obras e citações bibliográficas.

---

## 🤖 4. Arquivos Técnicos de Indexação

### A. [`web/robots.txt`](file:///home/walter/Documents/AI%20projects/Mobile/gnosis-chat-front/web/robots.txt)
Informa aos rastreadores (Googlebot, Bingbot, etc.) quais páginas podem ser lidas e aponta o caminho do mapa do site:
```txt
User-agent: *
Allow: /
Allow: /terms.html
Allow: /privacy.html

Sitemap: https://gnosischat.com/sitemap.xml
```

### B. [`web/sitemap.xml`](file:///home/walter/Documents/AI%20projects/Mobile/gnosis-chat-front/web/sitemap.xml)
Lista todas as páginas públicas para acelerar a descoberta e reindexação pelos buscadores.

---

## 🔍 5. Camada Semântica para Crawlers (`<noscript>`)

Como o Flutter Web renderiza os elementos visuais em um canvas JavaScript, incluímos uma estrutura em HTML nativo (`<h1>`, `<h2>`, `<p>`, `<ul>`) com os pilares doutrinários dentro da tag `<noscript>`. 

Dessa forma, robôs de busca que leem o HTML puro antes da execução de scripts conseguem indexar todo o vocabulário gnóstico e os nomes dos mestres instantaneamente.
