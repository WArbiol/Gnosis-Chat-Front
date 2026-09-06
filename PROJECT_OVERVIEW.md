# PROJECT_OVERVIEW_AND_STACK.md — gnosis-chat
> **Single Source of Truth (SSOT)** · Stack B — Best-of-Breed
> _Atualizado em Setembro de 2026_

---

## 1. Visão do Produto

### Objetivo
**Pergunte à Gnosis** é um app mobile e web de chat inteligente baseado em RAG (Retrieval-Augmented Generation) sobre um corpus fechado de **90 PDFs gnósticos**. O usuário faz perguntas em linguagem natural e recebe respostas fundamentadas, com citações de trechos dos documentos originais.

### Principais Features (MVP)
| Feature | Descrição |
|---------|-----------|
| **Chat RAG** | Respostas geradas a partir de chunks relevantes dos 90 PDFs com streaming em tempo real |
| **Citações & Leitor** | Referência à página e leitor interno de PDF on-demand (direto na página citada) |
| **Ticker Cósmico Deslizante** | Duas faixas horizontais de perguntas sugeridas que deslizam continuamente em sentidos opostos (`CosmicTicker`), com cards de vidro, brilho dourado e pausa ao toque/foco |
| **Feedback de Agente em Tempo Real** | Ticker dinâmico informando em tempo real qual nó está processando a pergunta (Orquestrador, Pesquisador, Crítico, Redator) |
| **Segunda Câmara** | 30 PDFs restritos visíveis apenas para `chamber_level = 2` |
| **Agentic RAG Resiliente** | LangGraph orquestra Extração de Filtros dinâmicos, Reescreve a Query e Avalia o contexto com cascata de múltiplos modelos Gemini (3.8, 3.7 e 2.5) |
| **Proteção contra Spikes & 429** | Timeout de 8s no 1º token de streaming e retry exponencial para rajadas de embeddings |
| **Layout Desktop & Popups Proporcionais** | Larguras máximas ergonômicas no Web Desktop (`440px` no Login, `420-460px` em Diálogos, `850px` no Chat) |
| **Filtros Opcionais (UI)** | Aba "Filtros" na interface para busca manual (Livros, Autores, 1ª/2ª Câmara — a 2ª Câmara fica **invisível** se chamber_level = 1) |
| **Tokens / Uso** | Rastreamento de consumo de mensagens por usuário |
| **Assinatura** | Planos gerenciados via Stripe (Web) e RevenueCat (iOS/Android): Free, Básico, Premium |

### Planos de Assinatura (Referência Inicial — sujeito a ajustes)

| Plano | Preço | Limite de Perguntas |
|-------|-------|--------------------|
| **Free** | R$ 0,00 | 3 perguntas / plano |
| **Básico** | R$ 9,90 / mês | 100 perguntas / mês |
| **Premium** | R$ 29,90 / mês | 1.000 perguntas / mês |

> ⚠️ **Valores iniciais** — Cobrança em BRL via RevenueCat (App Store / Play Store) e Stripe (Checkout web).

### Público-Alvo e Escopo do MVP
- **Usuários:** Estudiosos de hermetismo, gnosticismo e espiritualidade esotérica
- **Plataformas:** iOS, Android e Web Desktop/Mobile (Flutter)
- **Escala MVP:** até ~200 usuários ativos / mês

---

## 2. Arquitetura de Alto Nível

### Diagrama Textual

```
[Flutter App (iOS / Android / Web)]
      │
      │ HTTPS (SSE / JWT)
      ▼
[FastAPI — Backend Cloud Run]
      │
      ├───────────────────────────────────────┐
      │                                       │
      ▼                                       ▼
[Supabase]                             [Qdrant Cloud]
Auth + PostgreSQL + Storage             Vector DB
(users, sessions,                       └── gnosis_books
 chamber_level, pdfs,                       (90 PDFs, metadata: pdf_name,
 LangGraph checkpointer state)               page, access_level)
      │                                       │
      └──────────────┬────────────────────────┘
                     │
                     ▼
             [LangGraph — Agentic RAG]
     (Orchestrator hub central com múltiplos nós)
                     │
       ┌─────────────┼─────────────┐
       │             │             │
[3.5 Flash Lite] [Vertex AI]   [Gemini 3.8 Flash]
 (Orchestrator,   Ranking API   (Writer Principal)
  Critique, Judge, (Re-ranking   ↳ Fallback 3.7 & 2.5
  Recap, Direct)   top ~10 docs) (Citações rigorosas)
```

### Fluxo RAG Detalhado

```
INGESTÃO DE PDFs (offline, 1x por corpus update):
  PDF → pymupdf → Qdrant (gnosis_books) com metadados: (author, book_name, chamber)

QUERY (online, por mensagem do usuário):
  1. FastAPI recebe query + `ui_filters` + JWT.
  2. Middleware valida chamber_level e quota.
  3. LangGraph Node 1 (Orchestrator usando Gemini 3.5 Flash Lite):
         ↳ Se query simples, decide rota (ex: DIRECT_RESPONSE ou 1 sub-query ao Researcher).
         ↳ Se query complexa, decompõe em sub-queries e dispara N Researchers em paralelo.
  4. LangGraph Node 2 (Researcher):
         ↳ Executa Query Transformation.
         ↳ Gera embeddings com espaçamento anti-burst (gemini-embedding-2-preview).
         ↳ Busca ~30 chunks no Qdrant (gnosis_books).
         ↳ Re-rankeia para o top ~10 usando Vertex AI Ranking API.
  5. LangGraph Node 3 (Critique usando 3.5 Flash Lite): Avalia chunks vs Pergunta.
         ↳ Se suficiente: avança para o Writer.
         ↳ Se insuficiente: reporta ao Orchestrator com sugestões (loop máx. 2x).
  6. LangGraph Node 4 (Writer usando Gemini 3.8 Flash):
         ↳ Escreve a resposta final em streaming com citações estruturadas.
         ↳ Se houver spike de demanda (>8s sem 1º token ou 503), salta para o Gemini 3.7 Flash.
  7. LangGraph Node 5 (Judge usando Gemini 3.5 Flash Lite): Audita resposta contra alucinações.
         ↳ Se aprovado: avança para o Recap.
         ↳ Se rejeitado: retorna ao Orchestrator para reescrita (loop máx. 1x).
  8. LangGraph Node 6 (Recap usando Gemini 3.5 Flash Lite): Gera um resumo curto de 2-3 frases.
  9. Ask User (HIL): Se o Orchestrator identificar ambiguidade, pausa o grafo e solicita esclarecimentos ao usuário através do checkpointer Postgres.
  10. UX UI de Streaming (Flutter): O app lê o stream SSE recebendo eventos de status ("status"), tokens da resposta em tempo real ("token") e payload final consolidado ("final").
```

---

## 3. Stack Técnica Final

| Camada | Tecnologia | Custo MVP |
|--------|-----------|-----------|
| **Frontend Mobile & Web** | Flutter (Dart 3.x) + Riverpod + GoRouter | $0 |
| **Backend API** | FastAPI + Python 3.12 (Google Cloud Run) | incluso Cloud Host |
| **Orquestrador de IA** | LangGraph (Stateful Agentic RAG) | $0 |
| **Vector DB** | Qdrant Cloud (Free tier) | $0 |
| **Embeddings** | Google gemini-embedding-2-preview (768d) | $0 |
| **LLM (Nós Internos)** | Gemini 3.5 Flash Lite (Fallback: 2.5 Flash / 3.7 Flash) | ~$1 |
| **LLM (Redator / Writer)**| Gemini 3.8 Flash (Fallback: 3.7 Flash / 2.5 Flash) | ~$3–8 |
| **Re-Ranking** | Vertex AI Ranking API | Free tier / Baixo |
| **Auth & Banco Relacional** | Supabase (PostgreSQL 15 + RLS + Storage) | $0 |
| **Payments Mobile** | RevenueCat (App Store / Play Store) | 15%-30% tx |
| **Payments Web** | Stripe Billing (Checkout & Webhooks) | 2.9% + $0.30/tx |
| **Hospedagem Frontend** | Cloudflare Pages (`gnosischat.com`) | $0 |
| **Observabilidade** | LangSmith + Google Cloud Logging | $0 |
| **TOTAL ESTIMADO** | | **~$10–18/mês** |

---

## 4. Decisões Técnicas Críticas (ADRs)

### ADR-B1: Qdrant Cloud como Vector DB
- **Decisão:** Qdrant Cloud (free tier) sobre pgvector (Supabase).
- **Justificativa:** Payload filtering nativo — busca vetorial com filtro de `chamber_level` acontece *antes* do HNSW scan, sem post-processing SQL. Latência <50ms vs ~200ms do pgvector para 270k vetores.

### ADR-B2: Google gemini-embedding-2-preview com Blindagem Anti-Burst
- **Decisão:** gemini-embedding-2-preview (768d padrão) com micro-escalonamento de 80ms entre sub-queries e retry exponencial específico para `429 RESOURCE_EXHAUSTED` e `503`.
- **Justificativa:** Gera embeddings densos com janela de contexto estendida; previne que pesquisas simultâneas no LangGraph ativem o limitador de rajada da API do Google.

### ADR-B3: Supabase Auth & Multi-Provider
- **Decisão:** Supabase Auth sobre Firebase Auth. Suporte nativo para Google, Facebook e Apple (Web, iOS e Android).
- **Justificativa:** `chamber_level` e dados do perfil vinculados diretamente no PostgreSQL — controle de acesso por RLS sem necessidade de serviços externos intermediários.

### ADR-B4: LangGraph com Checkpointer PostgreSQL
- **Decisão:** LangGraph com persistência de estado ativa via `PostgresSaver`.
- **Justificativa:** Suporta o fluxo `Ask User` (Human-in-the-Loop) pausando e retomando a conversa entre turnos sem perder o histórico analítico.

### ADR-B5: Resiliência em Cascata Multi-Modelo e Timeout de 8s (Setembro 2026)
- **Decisão:** Cascata de 3 modelos para o Redator (`gemini-3.8-flash` → `gemini-3.7-flash` → `gemini-2.5-flash`) com timeout inteligente de 8 segundos no primeiro token emitido.
- **Justificativa:** Durante picos de demanda mundiais no lançamento de novos modelos, os servidores do Google podem reter requisições por até 40s em fila. O timeout de 8s garante que, se o 3.8 não responder de imediato, o 3.7 assume sem que o usuário perceba lentidão.

### ADR-F1: Ticker Cósmico Deslizante (`CosmicTicker`)
- **Decisão:** Dois trilhos contínuos horizontais independentes (`_MarqueeTrack`) na tela inicial vazia, com velocidade de 11.0 px/s (linha 1 para a esquerda) e 9.0 px/s (linha 2 para a direita).
- **Justificativa:** Conecta o usuário de forma instigante com 20 perguntas gnósticas curadas sem poluir a interface. Renderizado com `RepaintBoundary` isolado e fade gradiente nas pontas para performance de 60fps sem cintilação em navegadores e dispositivos móveis. Pausa automaticamente ao interagir ou focar a barra de digitação.

### ADR-F2: Ergonomia e Restrições de Largura Máxima Desktop
- **Decisão:** Restrição de largura máxima centralizada no layout Web/Desktop: `maxWidth: 440px` na tela de login, `420px - 460px` em modais e caixas de diálogo, e `850px` na coluna central do chat.
- **Justificativa:** Evita estiramento horizontal desproporcional de botões e cartões em telas ultrawide (1080p, 2K e 4K), mantendo a proporção áurea e a elegância de aplicações web de primeira linha (*ChatGPT, Linear, Claude*).

### ADR-B8: Pagamentos Híbridos (Stripe na Web / RevenueCat no Mobile)
- **Decisão:** Stripe Checkout para web e RevenueCat para compras integradas (IAP) no iOS e Android.
- **Justificativa:** 100% de conformidade com as diretrizes da App Store e Google Play Console, reduzindo taxas na web e centralizando o controle de cotas no Supabase.

---

## 5. Estrutura de Repositórios

O projeto é mantido em dois repositórios complementares (Polyrepo):

1. **`gnosis-chat-front`** (Flutter Client)
   - Contém o código multiplataforma (iOS, Android, Web).
   - Componentes chave: `CosmicTicker` (perguntas sugeridas deslizantes), `TypingIndicator` (status do agente em tempo real), `ChatScreen`, `PdfViewerScreen`.
   - Ponto de entrada: `lib/main.dart`

2. **`gnosis-chat-backend`** (FastAPI Backend & RAG)
   - Contém o servidor FastAPI, o grafo LangGraph e as integrações GCP/Qdrant.
   - Ponto de entrada: `app/main.py`
   - O gerenciador oficial de dependências é o `uv` / `.venv`.

---

## 6. Status e Roadmap

### ✅ Concluído e em Produção
- **Infraestrutura Cloud:** Google Cloud Run (`southamerica-east1`) ativo, Cloudflare Pages (`gnosischat.com`) ativo com SSL e proteção contra abusos.
- **Agentic RAG com Cascata:** Orquestrador, Pesquisador, Crítico, Redator e Juiz operando com fallback dinâmico entre Gemini 3.8, 3.7 e 2.5.
- **Blindagem Anti-Lentidão:** Timeout de 8s no 1º chunk do stream e retry exponencial com espaçamento de 80ms para embeddings contra erro 429.
- **Ticker Cósmico Deslizante:** Perguntas sugeridas animadas suavemente em GPU na Empty State com desacoplamento de fade e pausa inteligente.
- **Desktop Responsivo:** Trava de `maxWidth` no Login, Chat e todos os Diálogos/Popups do app.
- **Leitor de PDF On-Demand:** Abertura instantânea na página citada com URLs assinadas do Supabase Storage.
- **Autenticação:** Google, Facebook e Apple nativo/web integrados ao Supabase Auth.
- **Faturamento Web:** Stripe Checkout e Webhooks operacionais com liberação automática de cotas.

### 🟡 Fase Atual: Finalização de Lojas Mobile
- [x] Criação de produtos no Stripe (Básico e Premium).
- [x] Configuração de regras para Web vs Mobile (ocultar links incompatíveis).
- [ ] Conexão final do SDK `purchases_flutter` (RevenueCat) no app Mobile.
- [ ] Submissão final do build TestFlight (iOS) e faixa interna Google Play Console (Android).