# PROJECT_OVERVIEW_AND_STACK.md — gnosis-chat
> **Single Source of Truth (SSOT)** · Stack B — Best-of-Breed
> _Atualizado em Julho de 2026_

---

## 1. Visão do Produto

### Objetivo
**Pergunte à Gnosis** é um app mobile de chat inteligente baseado em RAG (Retrieval-Augmented Generation) sobre um corpus fechado de **90 PDFs gnósticos**. O usuário faz perguntas em linguagem natural e recebe respostas fundamentadas, com citações de trechos dos documentos originais.

### Principais Features (MVP)
| Feature | Descrição |
|---------|-----------|
| **Chat RAG** | Respostas geradas a partir de chunks relevantes dos 90 PDFs |
| **Citações & Leitor** | Referência à página e leitor interno de PDF on-demand (direto na página citada) |
| **Segunda Câmara** | 30 PDFs restritos visíveis apenas para `chamber_level = 2` |
| **Agentic RAG** | LangGraph orquestra Extração de Filtros dinâmicos, Reescreve a Query e Avalia o contexto em looping antes de gerar a resposta final |
| **Filtros Opcionais (UI)** | Aba "Filtros" na interface para busca manual (Livros, Autores, 1ª/2ª Câmara — a 2ª Câmara fica **invisível** se chamber_level = 1) |
| **Tokens / Uso** | Rastreamento de consumo de mensagens por usuário |
| **Assinatura** | Planos gerenciados via Stripe (Web) e RevenueCat (iOS/Android): Free, Básico, Premium |

### Planos de Assinatura (Referência Inicial — sujeito a ajustes)

| Plano | Preço | Limite de Perguntas |
|-------|-------|--------------------|
| **Free** | R$ 0,00 | 3 perguntas / plano |
| **Básico** | R$ 9,90 / mês | 100 perguntas / mês |
| **Premium** | R$ 29,90 / mês | 1.000 perguntas / mês |

> ⚠️ **Valores iniciais** — podem ser revisados antes do lançamento. Cobrança em BRL via RevenueCat (App Store / Play Store) e Stripe (Checkout web).

### Público-Alvo e Escopo do MVP
- **Usuários:** Estudiosos de hermetismo, gnosticismo e espiritualidade esotérica
- **Plataformas:** iOS e Android (Flutter)
- **Escala MVP:** até ~200 usuários ativos / mês

---

## 2. Arquitetura de Alto Nível

### Diagrama Textual

```
[Flutter App]
      │
      │ HTTPS (SSE / JWT)
      ▼
[FastAPI — Backend]
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
[3.1 Flash Lite] [Vertex AI]   [Gemini 3.5 Flash]
 (Orchestrator,   Ranking API   (Síntese / Writer)
  Critique, Judge, (Re-ranking   (Citações rigorosas)
  Recap, Direct)   top ~10 docs)
```

### Fluxo RAG Detalhado

```
INGESTÃO DE PDFs (offline, 1x por corpus update):
  PDF → pymupdf → Qdrant (gnosis_books) com metadados: (author, book_name, chamber)

QUERY (online, por mensagem do usuário):
  1. FastAPI recebe query + `ui_filters` + JWT.
  2. Middleware valida chamber_level e quota.
  3. LangGraph Node 1 (Orchestrator usando Gemini 3.1 Flash Lite):
         ↳ Se query simples, decide rota (ex: DIRECT_RESPONSE ou 1 sub-query ao Researcher).
         ↳ Se query complexa, decompõe em sub-queries e dispara N Researchers em paralelo.
  4. LangGraph Node 2 (Researcher):
         ↳ Executa Query Transformation.
         ↳ Busca ~30 chunks no Qdrant (gnosis_books).
         ↳ Re-rankeia para o top ~10 usando Vertex AI Ranking API.
  5. LangGraph Node 3 (Critique usando 3.1 Flash Lite): Avalia chunks vs Pergunta.
         ↳ Se suficiente: avança para o Writer.
         ↳ Se insuficiente: reporta ao Orchestrator com sugestões (loop máx. 2x).
  6. LangGraph Node 4 (Writer usando Gemini 3.5 Flash): Escreve a resposta final com citações estruturadas.
  7. LangGraph Node 5 (Judge usando Gemini 3.1 Flash Lite): Audita resposta contra alucinações.
         ↳ Se aprovado: avança para o Recap.
         ↳ Se rejeitado: retorna ao Orchestrator para reescrita (loop máx. 1x).
  8. LangGraph Node 6 (Recap usando Gemini 3.1 Flash Lite): Gera um resumo curto de 2-3 frases.
  9. Ask User (HIL): Se o Orchestrator identificar ambiguidade, pausa o grafo e solicita esclarecimentos ao usuário através do checkpointer Postgres.
  10. UX UI de Streaming (Flutter): O app lê o stream SSE (Server-Sent Events) recebendo eventos de status ("status"), tokens da resposta em tempo real ("token") e o payload final consolidado ("final").
```

---

## 3. Stack Técnica Final

| Camada | Tecnologia | Custo MVP |
|--------|-----------|-----------|
| **Mobile** | Flutter (Dart 3.x) | $0 |
| **Backend** | FastAPI + Python 3.12 | incluso Cloud Host |
| **Orquestrador** | LangGraph | $0 |
| **Vector DB** | Qdrant Cloud (Free tier) | $0 |
| **Embeddings** | Google gemini-embedding-2-preview | $0 |
| **LLM (Internal)** | Gemini 3.1 Flash Lite | ~$1 |
| **LLM (Output)**| Gemini 3.5 Flash | ~$3–8 |
| **Auth** | Supabase Auth | $0 |
| **DB Relacional** | Supabase PostgreSQL | $0 |
| **Payments Mobile**| RevenueCat (App Store / Play Store) | 15%-30% tx |
| **Payments Web** | Stripe | 2.9% + $0.30/tx |
| **Observabilidade**| LangSmith | $0 |
| **TOTAL ESTIMADO** | | **~$10–18/mês** |

---

## 4. Decisões Técnicas Críticas

### ADR-B1: Qdrant Cloud como Vector DB
- **Decisão:** Qdrant Cloud (free tier) sobre pgvector (Supabase)
- **Justificativa:** Payload filtering nativo — busca vetorial com filtro de `chamber_level` acontece *antes* do HNSW scan, sem post-processing SQL. Latência <50ms vs ~200ms do pgvector para 270k vetores.

### ADR-B2: Google gemini-embedding-2-preview (gratuito)
- **Decisão:** gemini-embedding-2-preview (768d padrão)
- **Justificativa:** Gera vetores de 768 dimensões por padrão, suporta context window estendido de 8.192 tokens e é altamente otimizado para tarefas de RAG.

### ADR-B3: Supabase Auth
- **Decisão:** Supabase Auth sobre Firebase Auth
- **Justificativa:** `chamber_level` como coluna simples na tabela `users` do PostgreSQL — controle de acesso sem gerenciamento complexo.

### ADR-B4: LangGraph como Orquestrador (Com Checkpointer PostgreSQL)
- **Decisão:** LangGraph com persistência de estado ativa via `PostgresSaver`.
- **Justificativa:** Necessidade de suportar a feature `Ask User` (Human-in-the-Loop) no MVP, exigindo retenção do estado da máquina entre turnos.

### ADR-B5: Agentic RAG com Orquestrador Central e Limites de Sessão
- **Decisão:** Orquestrador centralizado operando com múltiplos nós e loops reflexivos controlados por limites estritos na sessão.
- **Modelos Usados:** `Gemini 3.1 Flash Lite` atua como cérebro de orquestração (rápido e barato), enquanto `Gemini 3.5 Flash` é usado pelo *Writer* para redação erudita.
- **Re-Ranking:** Utilizamos a **Vertex AI Ranking API** para refinar de 30 para 10 chunks relevantes.

### ADR-B6: Persistência de Conversas — Optimistic Write
- **Decisão:** 3 tabelas normalizadas (`conversations` → `messages` → `citations`) no Supabase PostgreSQL com RLS cascadeado.
- **Justificativa:** Cada mensagem do user é salva imediatamente (nunca perde a pergunta). O backend processa o streaming, e atualiza de forma assíncrona o título da conversa via LLM na primeira mensagem.

### ADR-B7: Leitor de PDF On-Demand e Supabase Storage
- **Decisão:** Manter 90 PDFs no Supabase Storage. O Flutter abre o arquivo sob demanda via URL Assinada e vai direto para a página citada (`jumpToPage`).
- **Justificativa:** Protege propriedade intelectual (Segunda Câmara) ao mesmo tempo que mantém o app leve (sem ~500MB de PDFs embuteados).

### ADR-B8: Solução Multiplataforma para Pagamentos (Julho 2026)
- **Decisão:** Uso híbrido de RevenueCat (Mobile) e Stripe (Web).
- **Justificativa:** Conformidade com as regras da App Store e Google Play (uso de IAP obrigatório), delegando a gestão do mobile para o RevenueCat, enquanto o Web utiliza link de checkout do Stripe diretamente.

---

## 5. Estrutura de Repositórios

O projeto foi estruturado em dois repositórios independentes (Polyrepo):

1. **`gnosis-chat-front`** (Repositório Público · Flutter Client)
   - Contém o código do app Flutter para iOS, Android e Web.
   - Ponto de entrada: `lib/main.dart`

2. **`gnosis-chat-backend`** (Repositório Privado · FastAPI Backend & RAG)
   - Contém o servidor FastAPI, a pipeline RAG do LangGraph e scripts de ingestão.
   - Ponto de entrada: `app/main.py`
   - O `uv` é usado como gerenciador de pacotes e ambientes virtuais.

---

## 6. Status e Roadmap — Atualizado 

### ✅ O que já foi concluído (Pronto para Produção)
- **Infraestrutura e Setup:** Repositórios separados, configuração Qdrant, Supabase, Google AI Studio e Stripe.
- **Frontend Core & UX:** Navegação via GoRouter, State management (Riverpod), UI Premium com glassmorphism, suporte nativo para multi-plataformas.
- **Auth (Supabase):** Sign In com Google, Apple (Web e iOS), e Facebook. RLS configurado no backend.
- **Database e Persistência:** Cache offline no Hive (Mobile) sincronizando com Supabase.
- **Backend RAG (LangGraph):** Orquestrador, Query Transformer, Vertex Reranking, Streaming de Tokens (SSE).
- **Geração Inteligente:** Títulos gerados com `Gemini 3.1 Flash Lite` em modo assíncrono.
- **Init Otimizado:** Modelos de IA e bancos vetoriais carregados via `lifespan` do FastAPI na subida do servidor para latência zero no cold-start de RAG.

### 🟡 Fase Atual: Faturamento e Compliance (Quase finalizado)
- [x] Criação de produtos no Stripe (Webhook finalizado no backend `payment_service.py`).
- [x] Inserção da lógica de Apple Sign-In no código.
- [x] Ocultar cancelamento de assinaturas via interface web quando a compra foi feita pela Apple/Google.
- [ ] **Integração do pacote `purchases_flutter` (RevenueCat) no app Mobile para In-App Purchases.**
- [ ] Criação e configuração do app no RevenueCat Dashboard e Apple/Google Consoles.

### 🚀 Próximos Passos Finais (Deploy & Lojas)
- [ ] TestFlight (beta testing iOS) e testes na Play Console (Android).
- [ ] Ajuste final das chaves de produção (Supabase Prod, Qdrant Cloud Prod).
- [ ] Revisão do UI/UX em dispositivos reais (iPhone e Android).
- [ ] Lançamento oficial na App Store e Google Play Store.