# PROJECT_OVERVIEW_AND_STACK.md — gnosis-chat
> **Single Source of Truth (SSOT)** · Stack B — Best-of-Breed · 2026-03-01
> _Gerado por @orchestrator · Fontes: STACK_COMPARISON.md + TECH_DECISIONS_stack_b.md_
> _Atualizado em 2026-03-07 · Fase 2.5 (Persistência de Conversas) concluída_
> _Roadmap reordenado em 2026-02-27 · Prioridade: Mobile → Auth → Backend RAG (LLM por último)_

---

## 1. Visão do Produto

### Objetivo
Gnosis-chat é um app mobile de chat inteligente baseado em RAG (Retrieval-Augmented Generation) sobre um corpus fechado de **90 PDFs gnósticos**. O usuário faz perguntas em linguagem natural e recebe respostas fundamentadas, com citações de trechos dos documentos originais.

### Principais Features (MVP)
| Feature | Descrição |
|---------|-----------|
| **Chat RAG** | Respostas geradas a partir de chunks relevantes dos 90 PDFs |
| **Citações & Leitor** | Referência à página e leitor interno de PDF on-demand (direto na página citada) |
| **Segunda Câmara** | 30 PDFs restritos visíveis apenas para `chamber_level = 2` |
| **Agentic RAG** | LangGraph orquestra Extração de Filtros dinâmicos, Reescreve a Query e Avalia o contexto em looping antes de gerar a resposta final |
| **Filtros Opcionais (UI)** | Aba "Filtros" na interface para busca manual (Livros, Autores, 1ª/2ª Câmara — a 2ª Câmara fica **invisível** se chamber_level = 1) |
| **Personalização RAG** | Interesses do usuário inferidos automaticamente do histórico e armazenados em `user_interests` (Qdrant) |
| **Tokens / Uso** | Rastreamento de consumo de mensagens por usuário |
| **Assinatura** | 3 planos via Stripe: Free, Básico, Premium (ver tabela abaixo) |

### Planos de Assinatura (Referência Inicial — sujeito a ajustes)

| Plano | Preço | Limite de Perguntas | Perfil de Interesses (RAG_USER) |
|-------|-------|--------------------|---------------------------------|
| **Free** | R$ 0,00 | 3 perguntas / semana | Nenhum (sem personalização) |
| **Básico** | R$ 9,99 / mês | 100 perguntas / mês | 20 vetores de interesse inferidos (sliding window) |
| **Premium** | R$ 29,90 / mês | 1.000 perguntas / mês | 200 vetores de interesse inferidos (sliding window) |

> ⚠️ **Valores iniciais** — podem ser revisados antes do lançamento. Cobrança em BRL via Stripe.
> 💡 **Interesses são inferidos automaticamente** do histórico de perguntas — o usuário nunca precisa configurar manualmente.

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
[FastAPI — Railway]
      │
      ├───────────────────────────────────────┐
      │                                       │
      ▼                                       ▼
[Supabase]                             [Qdrant Cloud]
Auth + PostgreSQL + Storage             Vector DB (2 collections)
(users, sessions,                       ├── gnosis_books
 chamber_level, pdfs,                   │   (90 PDFs, metadata: pdf_name,
 LangGraph checkpointer state)          │    page, access_level)
                                        └── user_interests
                                            (interesses inferidos por user_id;
                                             quota: Basic=20 | Premium=200)
      │                                       │
      └──────────────┬────────────────────────┘
                     │
                     ▼
             [LangGraph — Agentic RAG]
     (Orchestrator hub central com 8 nós)
                     │
       ┌─────────────┼─────────────┐
       │             │             │
[3.0 Flash Lite] [Vertex AI]   [Gemini 3.0 Flash]
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
  3. LangGraph Node 1 (Orchestrator usando Gemini 3.0 Flash Lite):
         ↳ Se query simples, decide rota (ex: DIRECT_RESPONSE ou 1 sub-query ao Researcher).
         ↳ Se query complexa, decompõe em sub-queries e dispara N Researchers em paralelo.
  4. LangGraph Node 2 (Researcher):
         ↳ Executa Query Transformation.
         ↳ Busca ~30 chunks no Qdrant (gnosis_books + user_interests).
         ↳ Re-rankeia para o top ~10 usando Vertex AI Ranking API.
  5. LangGraph Node 3 (Critique usando 3.0 Flash Lite): Avalia chunks vs Pergunta.
         ↳ Se suficiente: avança para o Writer.
         ↳ Se insuficiente: reporta ao Orchestrator com sugestões (loop máx. 2x).
  6. LangGraph Node 4 (Writer usando Gemini 3.0 Flash): Escreve a resposta final com citações estruturadas.
  7. LangGraph Node 5 (Judge usando Gemini 3.0 Flash Lite): Audita resposta contra alucinações.
         ↳ Se aprovado: avança para o Recap.
         ↳ Se rejeitado: retorna ao Orchestrator para reescrita (loop máx. 1x).
  8. LangGraph Node 6 (Recap usando Gemini 3.0 Flash Lite): Gera um resumo curto de 2-3 frases.
  9. Ask User (HIL): Se o Orchestrator identificar ambiguidade, pausa o grafo e solicita esclarecimentos ao usuário através do checkpointer Postgres.
  10. UX UI de Streaming (Flutter): O app lê o stream SSE (Server-Sent Events) recebendo eventos de status ("status"), tokens da resposta em tempo real ("token") e o payload final consolidado ("final").
---

## 3. Stack Técnica Final (DECIDIDA)

| Camada | Tecnologia | Versão / Tier | Custo MVP |
|--------|-----------|---------------|-----------|
| **Mobile** | Flutter | stable (Dart 3.x) | $0 |
| **Backend** | FastAPI + Python | Python 3.12 | incluso Railway |
| **Orquestrador** | LangGraph | latest stable | $0 |
| **RAG Engine** | LlamaIndex | latest stable | $0 |
| **Vector DB** | Qdrant Cloud | Free tier (1GB) | $0 |
| **Embeddings** | Google gemini-embedding-001 | Free tier AI Studio | $0 |
| **LLM (Internal)** | Gemini 3.0 Flash Lite | Pay-per-use (ultra baixo) | ~$1 |
| **LLM (Output)**| Gemini 3.0 Flash | Pay-per-use | ~$3–8 |
| **Auth** | Supabase Auth | Free tier | $0 |
| **DB Relacional** | Supabase PostgreSQL | Free tier | $0 |
| **Payments** | Stripe | 2.9% + $0.30/tx | variável |
| **Deploy** | Railway | Hobby ($5/mês) | ~$5–10 |
| **Observabilidade** | LangSmith | Free tier | $0 |
| **OCR Fallback** | pytesseract + pymupdf | latest | $0 |
| **TOTAL ESTIMADO** | | | **~$10–18/mês** |

---

## 4. Decisões Técnicas Críticas

### ADR-B1: Qdrant Cloud como Vector DB
- **Decisão:** Qdrant Cloud (free tier) sobre pgvector (Supabase)
- **Justificativa:** Payload filtering nativo — busca vetorial com filtro de `chamber_level` acontece *antes* do HNSW scan, sem post-processing SQL. Latência <50ms vs ~200ms do pgvector para 270k vetores.
- **Alternativa rejeitada:** pgvector/Supabase — funcional, mas query híbrida SQL+vetor é mais lenta e o filtro de acesso é implementado em SQL WHERE, não no índice vetorial.

### ADR-B2: Google gemini-embedding-001 (gratuito) — Revisado 2026-03-01
- **Decisão:** gemini-embedding-001 (3072d nativo, reduzido para 768d via MRL) sobre text-embedding-004 (deprecated) e OpenAI text-embedding-3-small (1536d)
- **Justificativa:** Substitui `text-embedding-004` que será desligado em **14/01/2026**. Suporta 100+ idiomas, Matryoshka Representation Learning (MRL) permite reduzir de 3072d para 768d sem re-ingestion. $0 no free tier AI Studio ($0.15/M tokens depois). Mesmo billing e dashboard do Gemini.
- **Trade-off aceito:** 768d (via MRL) é suficiente para corpus fechado gnóstico — qualidade superior ao text-embedding-004 de mesmo tamanho.

### ADR-B3: Supabase Auth (não Firebase)
- **Decisão:** Supabase Auth sobre Firebase Auth
- **Justificativa:** `chamber_level` como coluna simples na tabela `users` do PostgreSQL — controle de acesso sem gerenciamento de Custom Claims JWT do Firebase. JWT + RLS + SDK Flutter maduro.
- **Stack C rejeitada:** Firebase Auth exigiria Custom Claims para chamber_level, adicionando complexidade de sincronização.

### ADR-B8: Login Social-Only + Premium UX (2026-03-01)
- **Decisão:** OAuth social-only (Google + Facebook + Apple) — sem login email/senha
- **Provedores:** Google (Android + iOS + Linux debug), Facebook (Android + iOS), Apple (iOS + Linux debug, por compliance App Store)
- **Justificativa:** Reduz fricção de signup (~1 tap vs formulário), elimina gestão de senhas fracas, e o público-alvo brasileiro usa amplamente Google e Facebook. Supabase `signInWithOAuth` suporta todos nativamente.
- **UX Login:** Tema dark premium com efeito liquid glass (frosted glassmorphism), logo 3D com glow animado (gold + blue), paleta de cores brand: Royal Blue (#3A7BD5) + Gold (#E8B730) + Flame Red (#C94040)
- **Google icon:** `CustomPainter` desenhando o "G" 4-cores sem dependências externas
- **Textos:** Português (BR) — público exclusivamente brasileiro

### ADR-B4: Railway como Deploy
- **Decisão:** Railway sobre Fly.io e Modal.com
- **Justificativa:** Deploy via Git push, $5/mês elimina cold starts (sem hibernação), preview environments por PR, DX superior para times pequenos com Python.
- **Modal.com rejeitado:** Cold starts graves incompatíveis com UX premium de app meditativo/esotérico.

### ADR-B5: LangGraph como Orquestrador (Com Checkpointer PostgreSQL)
- **Decisão:** LangGraph com persistência de estado ativa via `PostgresSaver`.
- **Justificativa:** Diferente da versão inicial stateless, a necessidade de suportar a feature `Ask User` (Human-in-the-Loop) no MVP exige a retenção do estado exato da máquina de estados do grafo entre turnos de conversação. Usaremos a infraestrutura PostgreSQL do Supabase já configurada para salvar os checkpoints.
- **Resiliência:** Essa abordagem permite suspender a execução do grafo, coletar o input do usuário na UI do Flutter horas depois, e restabelecer a execução do grafo a partir do nó correto, mesmo em caso de reinicialização da API no Railway.

### ADR-B6: Qdrant `user_interests` — Interesses Inferidos por Plano
- **Decisão:** Collection `user_interests` separada de `gnosis_books` no mesmo Qdrant Cloud. Quota enforçada no backend antes de cada upsert.
- **Limites:** Free = 0 | Básico = 20 vetores | Premium = 200 vetores. Eviction por sliding window (remove mais antigos).
- **Inferência:** O `interest_tracker.py` analisa cada query após o retrieval e gera embeddings de interesse para upsert automático — sem ação explícita do usuário.
- **Justificativa:** Zero novo serviço; payload filter nativo por `user_id`; personalização sem armazenar histórico literal.
- **Alternativa rejeitada:** pgvector/Supabase — funcional, mas mistura concerns relacionais + vetoriais e não aproveita o HNSW do Qdrant.

### ADR-B7: Agentic RAG com Orquestrador Central e Limites de Sessão
- **Decisão:** Orquestrador centralizado do LangGraph operando com 8 nós especializados e loops reflexivos controlados por limites estritos na sessão.
- **Limites por Sessão:** Máximo de 7 chamadas ao Researcher (pesquisa + retries do Critique), máximo de 2 loops Critique → Orchestrator, máximo de 1 loop Judge → Orchestrator e no máximo 2 chamadas Ask User para evitar loops infinitos ou custos excessivos de API.
- **Re-Ranking:** Para melhorar o recall sem sobrecarregar o prompt do Writer, recuperamos ~30 chunks e filtramos os top ~10 mais relevantes usando a **Vertex AI Ranking API** (Google Cloud), que tem faturamento unificado no GCP e metade do custo do Cohere Rerank.
- **Reflexão (Critique/Judge):** O Critique avalia a relevância das fontes antes da redação. O Judge (Gemini 3.0 Flash Lite) faz uma auditoria rigorosa da resposta redigida pelo Writer (Gemini 3.0 Flash) para evitar alucinações e certificar as citações.
- **Feedback Loop:** Em caso de ambiguidade, o orquestrador redireciona ao nó `Ask User` para coletar dados do usuário e retoma o grafo.

### ADR-B9: Persistência de Conversas — Schema Normalizado + Optimistic Write (2026-03-05)
- **Decisão:** 3 tabelas normalizadas (`conversations` → `messages` → `citations`) no Supabase PostgreSQL com RLS cascadeado. Optimistic write path (ChatGPT-style).
- **Justificativa:** Cada mensagem do user é salva imediatamente (nunca perde a pergunta). Mensagem do assistant + citações são salvas pelo backend após o RAG. Título gerado via LLM em background (~$0.001/título). Hive como read cache no Flutter (Supabase = source of truth).
- **Schema:** `conversations` (id, user_id, title, created_at, updated_at) → `messages` (id, conversation_id, role, content, route, token_count, created_at) → `citations` (id, message_id, pdf_name, page, snippet, chunk_id, sort_order)
- **Lazy creation:** Conversa só é criada na 1ª mensagem (zero conversas fantasma, como ChatGPT)
- **Título híbrido:** Trunca na hora → Gemini Flash gera título de 5-8 palavras em background → atualiza via PATCH
- **API:** RESTful com cursor pagination (`GET /conversations?limit=20&after=cursor`), mobile-optimized (message_count + last_message_preview no list)
- **Alternativas rejeitadas:** JSONB para citações (harder to query/index), full offline com CRDT (overengineering para MVP single-user-per-device), transactional save (perde msg do user se app fechar durante RAG)

### ADR-B10: Leitor de PDF On-Demand e Supabase Storage (2026-03-11)
- **Decisão:** Manter 90 PDFs no Supabase Storage (Bucket `gnosis-pdfs`) com enforcements de Role-Level Security (RLS) baseados em `chamber_level`. O Flutter abre um pop-up/modal carregando o respectivo arquivo via URL Assinada sob demanda e indo direto para a página citada (`jumpToPage`).
- **Justificativa:** Protege propriedade intelectual (Segunda Câmara) ao mesmo tempo que mantém o app leve (sem ~500MB de PDFs locais embuteados).
- **Trade-off:** Exige conexão de rede pra ler a citação na íntegra (ausente em modo offline puro) e adiciona consumo módico à cota de egress (Banda de saída) do Supabase.

### Tradeoffs Aceitos
| Tradeoff | Decisão |
|----------|---------|
| 2 painéis (Supabase + Qdrant) | Aceito — complexidade operacional moderada justificada pela performance |
| Qdrant upgrade $25/mês ao escalar | Aceito — trigger claro: >70% do free tier (1GB) |
| gemini-embedding-001 3072d → 768d via MRL | Aceito — MRL permite escalar dimensão sem re-ingestão; 768d suficiente para corpus fechado |
| LangGraph sem checkpointer → RAG_USER | Aceito — interesses inferidos são mais eficientes que histórico literal para personalização |
| LLM Classifier +~300ms de latência | Aceito — melhora precisão do retrieval justifica o custo |
| LLM para título de conversa +~$0.10/mês | Aceito — títulos inteligentes justificam custo negligível |

---

## 5. Requisitos Não-Funcionais

| Requisito | Target MVP |
|-----------|-----------|
| **Latência de resposta** | <3s para query RAG end-to-end (p95) |
| **Latência Qdrant** | <50ms para retrieval (HNSW, 270k vetores) |
| **Disponibilidade** | 99.5% (Railway Hobby SLA) |
| **Escalabilidade** | Até 200 usuários ativos / mês sem mudança de infra |
| **Custo MVP** | <$20/mês total |
| **Custo scale** | ~$120–130/mês para 1.000 usuários |
| **Segurança** | JWT obrigatório em todos endpoints; chamber_level validado server-side no middleware |
| **Privacidade** | PDFs restritos nunca expostos a chamber_level = 1 em nenhuma camada |
| **OCR** | Fallback automático para PDFs escaneados sem texto extraível |

---

## 6. Restrições Fixas

### Tecnologias NÃO alteráveis pelo Scaffold Generator

```
FIXED:
  mobile:        Flutter (Dart 3.x)
  backend:       FastAPI (Python 3.12)
  vector_db:     Qdrant Cloud
    collections:   gnosis_books (90 PDFs) + user_interests (interesses inferidos)
  embeddings:    Google gemini-embedding-001 (3072d → 768d via MRL)
  re_ranking:    Vertex AI Ranking API (Google Cloud)
  llm_inference: Gemini 3.0 Flash Lite (Orchestrator, Critique, Judge, Recap, Direct Response)
  llm_synthesis: Gemini 3.0 Flash (Writer / Resposta Final)
  agentic_rag:   LangGraph com orquestração centralizada de 8 nós e loops reflexivos
  auth:          Supabase Auth
  db:            Supabase PostgreSQL
  payments:      Stripe
  deploy:        Railway
  rag_engine:    LlamaIndex
  orchestrator:  LangGraph (com checkpointer PostgreSQL / PostgresSaver para HIL)
  logging:       LangSmith
```

### Limites de Arquitetura

- ❌ **Sem serverless pesado** (Modal.com, AWS Lambda) — cold starts inaceitáveis para UX
- ❌ **Sem Firebase** — complexidade de Custom Claims desnecessária
- ❌ **Sem pgvector** — payload filtering do Qdrant é requisito para Segunda Câmara
- ❌ **Sem monolito** — Flutter e FastAPI são serviços independentes
- ❌ **Sem overengineering** — MVP sem Kubernetes, service mesh, ou múltiplos micro-serviços
- ✅ **Docker Compose** apenas para desenvolvimento local (não em produção)
- ✅ **Supabase gerencia** toda a camada relacional; Qdrant gerencia toda a camada vetorial

---

## 7. Diretrizes para o Scaffold Generator

### Estrutura de Repositórios

O projeto foi estruturado em dois repositórios independentes (Polyrepo) para modularidade e segurança de dados:

1. **`gnosis-chat-front`** (Repositório Público · Flutter Client)
   - Contém o código do app Flutter para iOS, Android e Web.
   - Organizado no formato padrão do Flutter (com `/lib`, `/android`, `/ios`, `/web`, `/assets`).
   - Ponto de entrada: `lib/main.dart`

2. **`gnosis-chat-backend`** (Repositório Privado · FastAPI Backend & RAG)
   - Contém o servidor FastAPI, a pipeline RAG do LangGraph e scripts de ingestão de PDFs.
   - Ponto de entrada: `app/main.py`
   - Contém também o `docker-compose.yml` para desenvolvimento local de serviços auxiliares (Qdrant + PostgreSQL locais).


### Convenções de Projeto

| Item | Convenção |
|------|-----------|
| **Repo** | Polyrepo composto por `gnosis-chat-front` (público) e `gnosis-chat-backend` (privado) |
| **Python** | 3.12, tipagem estrita com `mypy`, formatação com `ruff` |
| **Dart/Flutter** | Dart 3.x, análise com `flutter analyze`, state management com Riverpod |
| **Env vars** | `.env` independente em cada repositório (nunca comitados) |
| **Docker** | `docker-compose.yml` no repositório de backend para dev local (Qdrant + PostgreSQL locais) |
| **CI/CD** | Railway auto-deploy no backend; PRs no frontend validam compilações e builds |
| **Versionamento** | Semver para backend; Flutter `version` no pubspec |

### Linguagens e Versões Fixas

```yaml
python: "3.12"
dart: ">=3.0.0"
flutter: ">=3.19.0"
fastapi: ">=0.111.0"
llama-index: "latest stable"
langgraph: "latest stable"
qdrant-client: ">=1.9.0"
```

### Regras para o Scaffold Generator

1. **NÃO alterar a stack decidida** — nenhuma substituição de componente sem aprovação explícita
2. **NÃO adicionar serviços extras** não listados (ex: Redis, Celery) sem justificativa de gargalo mensurável
3. **IMPLEMENTAR** apenas o que está definido neste documento
4. **chamber_level** deve ser validado no middleware FastAPI antes de qualquer operação RAG — nunca no cliente Flutter
5. **Quota de interesses** (`MAX_INTERESTS`) deve ser enforçada no `interest_tracker.py` antes de cada upsert — nunca assumir espaço disponível
6. **Query Router** é o primeiro nó do grafo LangGraph — nenhum retrieval acontece sem passar pelo classificador
7. **Docker Compose** é exclusivo para desenvolvimento local — Railway gerencia produção
8. **Scripts de ingestão** (`scripts/ingest.py`) são separados da API e rodam offline (apenas para `gnosis_books`)
9. **LangSmith** deve ser configurado desde o início para observabilidade do grafo LangGraph e das decisões do Query Router

---

## 8. Status do Scaffold (Atualizado 2026-06-30)

> ✅ **Divisão em 2 repositórios concluída** — código e histórico organizados.

### Backend — `gnosis-chat-backend/`

| Camada | Arquivos-chave | Status |
|--------|---------------|--------|
| **Infra** | `pyproject.toml` (uv), `Dockerfile` (multi-stage uv), `railway.json` | ✅ Pronto |
| **Core** | `app/main.py`, `app/core/config.py`, `app/core/middleware.py`, `app/core/security.py` | ✅ Boilerplate funcional |
| **Schemas** | `app/schemas/chat.py`, `app/schemas/user.py`, `app/schemas/conversation.py` | ✅ Pydantic v2 |
| **Services** | `app/services/chat_service.py`, `app/services/auth_service.py`, `app/services/conversation_service.py` | ✅ Lógica de Chat/Títulos pronta |
| **API v1** | `app/api/v1/router.py`, `app/api/v1/chat.py`, `app/api/v1/auth.py` | ⚠️ Thin routers (delegam aos services) |
| **RAG** | `app/rag/state.py`, `app/rag/pipeline.py`, `app/rag/router.py`, `app/rag/retriever.py`, `app/rag/synthesizer.py` | ⚠️ Skeletons com TODOs |
| **Scripts** | `scripts/ingest.py` | ⚠️ Skeleton com TODOs |
| **Tests** | `tests/conftest.py`, `tests/test_health.py` | ✅ Pronto |

### Frontend — `gnosis-chat-front/`

| Camada | Arquivos-chave | Status |
|--------|---------------|--------|
| **Core** | `lib/main.dart`, `lib/app.dart`, `lib/core/theme/app_theme.dart` | ✅ Funcional |
| **Auth** | `lib/features/auth/domain/user_entity.dart`, `lib/features/auth/presentation/login_screen.dart` | ✅ UI premium — Supabase por integrar |
| **Chat** | `lib/features/chat/domain/message_entity.dart`, `lib/features/chat/presentation/chat_screen.dart` | ✅ UI premium — API real por integrar |
| **Chat Navigation** | `lib/features/chat/domain/conversation_entity.dart`, `lib/features/chat/presentation/chat_shell.dart` | ✅ Sidebar, perfil, JIT e Persistência |
| **Subscription** | `lib/features/subscription/domain/plan_entity.dart`, `lib/features/subscription/presentation/subscription_screen.dart` | ✅ UI premium — Stripe por integrar |
| **Segunda Câmara** | `lib/features/auth/presentation/second_chamber_dialog.dart` | ✅ Unlock/lock flow completo |
| **Shared** | `lib/core/widgets/animated_background.dart`, `lib/core/widgets/google_logo.dart` | ✅ Pronto |
| **Services** | `lib/core/api/api_client.dart` (Dio), `lib/core/api/secure_storage.dart` | ✅ Pronto |

### Legenda

- ✅ **Pronto** — funcional, sem TODOs pendentes
- ⚠️ **Stub/Skeleton** — estrutura existe, lógica de negócio marcada com `TODO`

### Como iniciar o desenvolvimento

```bash
# 1. Para executar o Backend:
cd gnosis-chat-backend
uv sync                          # cria .venv + instala deps
cp .env.example .env             # preencher chaves reais
uv run uvicorn app.main:app --reload

# 2. Para executar o Frontend (iOS / Android / Web):
cd gnosis-chat-front
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```


---

## 9. Roadmap — Próximos Passos

> 💡 **Estratégia de custo:** Mobile e Auth primeiro (sem custo de LLM). Backend RAG com Gemini 2.5 Flash apenas quando o front estiver pronto.

### Fase 0: Setup de Ambiente ✅ CONCLUÍDA
- [X] Instalar Flutter SDK na máquina de dev
- [X] Scaffold v2 gerado (`gnosis-chat/` com backend e mobile)
- [X] Criar projeto Supabase → obter `URL`, `anon_key`, `service_role_key`
- [X] Criar conta Qdrant Cloud → obter `URL` e `API_KEY`
- [X] Criar conta Google AI Studio → obter `GOOGLE_API_KEY`
- [X] Criar conta Stripe → obter `secret_key` e `webhook_secret`
- [X] Preencher `.env` com todas as chaves
- [X] Rodar `docker compose up -d` (Qdrant + PostgreSQL locais)
- [X] Rodar `flutter pub run build_runner build` (gerar código Freezed)
- [X] Subir no github

### Fase 1: Mobile — UI & Navegação Polish 📱 ← EM PROGRESSO
> _Sem custo de API. Foco total no Flutter._

#### ✅ Concluído
- [x] Redesign `login_screen.dart` — UI premium com liquid glass, social-only OAuth
- [x] Login social-only: Google + Facebook + Apple (iOS/Linux) — mock auth funcional
- [x] Paleta de cores: Royal Blue (#3A7BD5) + Gold (#E8B730) + Flame Red (#C94040)
- [x] Logo 3D com glow animado (gold + blue pulsante)
- [x] `GoogleLogo` CustomPainter (4-color G, sem dependências externas)
- [x] Textos traduzidos para Português (BR)
- [x] Redesign `chat_screen.dart` — UI premium (AppBar custom, empty state com logo glow, input bar glassmorphism)
- [x] `animated_background.dart` compartilhado entre login e chat
- [x] `message_bubble.dart` — glass bubbles (user gradient + AI glassmorphism + citation chips premium)
- [x] Mock streaming word-by-word no `chat_provider.dart` (efeito de digitação)
- [x] Input bar: borda dourada animada no foco, botão send com scale animation

#### ✅ Concluído — Navegação & Fluxos
- [x] **Sidebar / Drawer de Conversas** — `ChatShell` (sliding panel com push animation), `ConversationsPanel` (busca, swipe-to-delete, gradient accents)
- [x] **Nova Conversa** — ao clicar "Nova conversa" limpa o chat e volta ao empty state com logo
- [x] **Gerenciamento de Conversas em Memória** — `ConversationProvider` (Riverpod) com CRUD + ativa conversation tracking (sem persistência até Fase 5)
- [x] **Tela de Perfil** — `ProfileBottomSheet` (glassmorphism): nome, plano, badge de câmara (⚜️ 1ª/2ª), botão "Gerenciar Plano", botão da Segunda Câmara, logout com confirmação

#### ✅ Concluído — UX & Interações
- [x] **Loading state do chat** — `TypingIndicator` (3 dots gold animados) com delay mockado de 2 segundos
- [x] **Animação de entrada de mensagens** — fade + slide up (300ms) via `_AnimatedMessage`
- [x] **Haptic feedback** — `lightImpact` ao enviar, `mediumImpact` ao receber resposta
- [x] **Long press em mensagem** — bottom sheet contextual: Copiar (Clipboard) + Compartilhar (`share_plus`)
- [x] **Teclado dismiss** — `GestureDetector` wrapper no body do Scaffold

#### ✅ Concluído — Subscription & System
- [x] Polir `subscription_screen.dart` — glassmorphism cards com tint por plano (neutro/azul/gold), preços em BRL (R$9,99 / R$29,90)
- [x] **CTA inline no chat** — banner "⚠️ Limite atingido · [✨ Fazer Upgrade]" (depende de quotas reais — Fase 5)
- [x] Splash screen animada (logo com glow fade-in → auto-redirect)
- [x] Ícone customizado do app (logo Gnosis adaptado para launcher icon)
- [x] Deep linking setup (GoRouter `redirect` + URI scheme `gnosis://`)
- [x] Testar navegação completa: login → chat → sidebar → perfil → gerenciar plano → subscription → logout

#### ✅ Concluído — Segunda Câmara (Acesso no Perfil)
- [x] `AuthNotifier.unlockSecondChamber()` — atualiza `chamberLevel: 2` no estado
- [x] `AuthNotifier.revertToFirstChamber()` — reverte para `chamberLevel: 1` com confirmação
- [x] `SecondChamberDialog` — modal glassmorphism com campo obscured, validação de senha, haptic feedback
- [x] `ProfileBottomSheet` — badge visual (⚜️ 1ª/2ª Câmara) + botão toggle (acessar / restringir)
- [x] Premium não dá acesso direto à 2ª Câmara — acesso apenas pelo flow do perfil

### Fase 2: Auth Mobile — Supabase Real 🔐
> _Custo: $0 (Supabase free tier)._
- [ ] Criar tabela `users` no Supabase com `chamber_level INT DEFAULT 1` e `plan TEXT DEFAULT 'free'`
- [ ] Wiring do `auth_remote_source.dart` → Supabase Flutter SDK (signInWithOAuth: Google, Facebook, Apple)
- [ ] Implementar GoRouter redirect guard (auth state → redireciona para `/login`) — depende de sessão real
- [ ] Salvar JWT via `secure_storage.dart` (já implementado)
- [ ] Remover o delay artificial (1.5s) da `splash_screen.dart` após o setup do Supabase.
- [ ] Implementar `security.py` (backend) com validação JWT real (JWKS Supabase)
- [ ] Wiring do `auth_service.py` (signup, login via Supabase SDK)
- [ ] Implementar counter de uso (quotas por plano) no `middleware.py`
- [ ] Testar auth end-to-end Flutter ↔ Supabase ↔ FastAPI

### Fase 2.5: Persistência de Conversas 💬 ✅ CONCLUÍDA
> _Custo: $0 (Supabase free tier). Inspirado no ChatGPT — cada mensagem salva imediatamente._

#### 2.5.1 — Schema SQL + RLS (Supabase)
- [x] Criar tabela `conversations` (id UUID, user_id UUID FK, title TEXT, created_at, updated_at)
- [x] Criar tabela `messages` (id UUID, conversation_id UUID FK CASCADE, role TEXT, content TEXT, route TEXT, token_count INT, created_at)
- [x] Criar tabela `citations` (id UUID, message_id UUID FK CASCADE, pdf_name TEXT, page INT, snippet TEXT, chunk_id TEXT, sort_order SMALLINT)
- [x] Criar índices: `conversations(user_id, updated_at)`, `messages(conversation_id, created_at)`, `citations(message_id)`
- [x] Configurar RLS: cada user vê apenas suas conversas (cascaded via FKs)

#### 2.5.2 — Backend Endpoints (FastAPI)
- [x] Schemas Pydantic: `ConversationCreate`, `ConversationResponse`, `ConversationList`, `MessageResponse`, `MessageCreate`
- [x] `conversation_service.py` — CRUD + title generation (Gemini Flash background)
- [x] Router `conversations.py` — `GET /conversations`, `POST /conversations`, `GET /conversations/{id}`, `DELETE /conversations/{id}`, `PATCH /conversations/{id}`
- [x] Router `conversations.py` — `GET /conversations/{id}/messages`, `POST /conversations/{id}/messages`
- [x] Refatorar `POST /chat/ask` — salva msg user → executa RAG → salva msg assistant → retorna
- [x] Lazy creation: se `conversation_id` é novo, cria conversa automaticamente
- [x] Geração de título: trunca na 1ª msg → Gemini Flash gera título em background → PATCH

#### 2.5.3 — Mobile — Wiring ConversationProvider → API
- [x] `conversation_remote_source.dart` — Dio client para endpoints CRUD
- [x] `ConversationProvider` usa API real (substituindo CRUD em memória)
- [x] `ChatProvider` persiste via `POST /chat/ask`
- [x] Lazy creation no Flutter: ao enviar 1ª msg, cria conversa via API
- [x] Atualizar `ConversationEntity` com campos do servidor (message_count, last_message_preview)
- [x] **Opção A (Fresh Start):** App sempre abre em um chat novo/vazio por padrão.

#### 2.5.4 — Mobile — Cache Local (Hive)
- [x] Setup Hive boxes: `conversationsBox` e `messagesBox`
- [x] Read cache: app abre → Hive (instantâneo) → background fetch do servidor
- [x] Write-through: nova msg → salva no Hive + server

#### 2.5.5 — Verificação
- [x] Testar CRUD end-to-end: criar conversa → enviar msgs → listar → deletar
- [x] Testar lazy creation + título LLM gerado em background
- [x] Testar RLS: user A não vê conversas de user B
- [x] Testar cache Hive: abrir app offline → conversas aparecem do cache

### Fase 3: Pagamentos (Stripe) 💳
> _Custo: 2.9% + $0.30/tx (apenas em produção)._
- [ ] Criar Products + Prices no Stripe (Básico R$9,90 / Premium R$29,90 em BRL)
- [ ] Implementar `payment_service.py` (checkout session + webhook handler)
- [ ] Webhook atualiza coluna `plan` na tabela `users` do Supabase
- [ ] Wiring do `subscription_screen.dart` → abrir Stripe Checkout via `url_launcher`
- [ ] Testar ciclo completo: free → checkout → upgrade → webhook → plan atualizado

### Fase 4: Backend RAG Funcional 🧠
> _⚠️ Custo começa aqui: Gemini 3.0 Flash pay-per-use (~$3–8/mês no MVP)._
- [ ] Criar collections no Qdrant: `gnosis_books` e `user_interests` (com schema de metadata)
- [ ] Implementar `scripts/ingest.py` completo (pymupdf + OCR + embeddings → `gnosis_books`)
- [ ] Ingerir os 90 PDFs (60 public + 30 chamber_2) com metadata tags
- [ ] Configurar Supabase Storage (Bucket `gnosis-pdfs`) com políticas RLS (`chamber_level`)
- [ ] Endpoint FastAPI para gerar Signed URLs e proteger acesso (`GET /api/v1/pdfs/{name}`)
- [ ] Configurar `PostgresSaver` conectando o checkpointer do LangGraph no Supabase PostgreSQL
- [ ] Implementar os 8 nós do grafo de agentes (`app/agents/`) centrados no `Orchestrator`
- [ ] Integrar a **Vertex AI Ranking API** para a etapa de Re-ranking no `Researcher`
- [ ] Implementar `interest_tracker.py` (inferência de interesses + upsert + sliding window)
- [ ] Configurar LangSmith (observabilidade do grafo + transições de nós)
- [ ] Testar RAG end-to-end via `POST /api/v1/conversations/{id}/ask` com shell client

### Fase 5: Mobile — Integração Chat + Streaming 📡
> _Conecta o Flutter ao backend RAG real via SSE._
- [ ] Wiring do `chat_remote_source.dart` → `POST /api/v1/conversations/{id}/ask`
- [ ] Adicionar consumo de streaming de resposta via **Server-Sent Events (SSE)**
- [ ] Tratar os eventos `status` (pílulas de status dos agentes), `token` (palavras geradas) e `final` (citações e recap)
- [ ] Exibir citações de PDF na UI do chat como cards ou chips interativos
- [ ] Implementar Modal/Pop-up com Leitor de PDF interno (`syncfusion_flutter_pdfviewer` ou `pdfrx`). O modal carrega PDF on-demand via Signed URL e faz `jumpToPage` direto para a citação.
- [ ] **Pull-to-refresh** — `RefreshIndicator` no chat para re-fetch de mensagens
- [ ] Remover o mock de 3 mensagens "⚠️ Limite atingido · [✨ Fazer Upgrade]" (para que dependa de quotas reais)
- [ ] Testar chat end-to-end Flutter ↔ FastAPI ↔ RAG via SSE e HIL (Human-in-the-Loop)

### Fase 6: Segunda Câmara + Personalização RAG 🔒
- [ ] Validar filtro de `chamber_level` no RAG end-to-end
- [ ] Validar quota de vetores por plano (Free=0, Básico=20, Premium=200)
- [ ] Validar sliding window de eviction em `interest_tracker.py`
- [ ] Testar Query Router nos 4 cenários: `RAG_BOOKS`, `RAG_USER`, `RAG_BOTH`, `DIRECT`
- [ ] Testar personalização: após N perguntas, respostas refletem interesses inferidos

### Fase 7: Deploy + Polish + Publicação 🚀
> _Inclui burocracia de lojas, termos, e submission._

#### 7.1 — Infraestrutura de Produção
- [ ] Deploy backend no Railway (Git push → auto-deploy)
- [ ] Migrar Qdrant de local para Qdrant Cloud (produção)
- [ ] Configurar Supabase em produção (RLS policies, Auth providers)
- [ ] Stripe webhook URL em produção
- [ ] Variáveis de ambiente de produção configuradas (Railway + Supabase Vault)

#### 7.2 — Build Android
- [ ] Build release (AAB) assinado com keystore
- [ ] Testar em device real (performance, auth, pagamento)
- [ ] Capturar screenshots para Google Play (phone + tablet se aplicável)
- [ ] Testes de performance (latência RAG < 3s p95)

#### 7.3 — Build iOS
- [ ] Configurar certificados Apple Developer + provisioning profiles
- [ ] Configurar Sign in with Apple (requer Apple Developer Program)
- [ ] Build release (IPA) via Xcode
- [ ] Deploy para TestFlight (beta testing)
- [ ] Capturar screenshots para App Store (iPhone 6.7" + 5.5")

#### 7.4 — Burocracia & Conteúdo das Lojas
- [ ] Redigir Termos de Uso
- [ ] Redigir Política de Privacidade (LGPD)
- [ ] Ficha Google Play: título, descrição curta/longa, categoria, classificação etária
- [ ] Ficha App Store: título, subtitle, descrição, keywords, categoria
- [ ] Ícone final do app (launcher icon adaptado para ambas as lojas)
- [ ] Feature graphic (Google Play — 1024×500)

#### 7.5 — Submit & Review
- [ ] Submit Google Play Console → review (~3–7 dias)
- [ ] Submit App Store Connect → review (~1–3 dias)
- [ ] Fixes de review (se solicitado pelas lojas)
- [ ] 🎉 Publicação

---

*Fontes: `STACK_COMPARISON.md` · `TECH_DECISIONS_stack_b.md`*
*Agentes: `@project-planner` · `@backend-specialist` · `@documentation-writer` · `@orchestrator`*
*Skills: `@[skills/architecture]` · `@[skills/api-patterns]` · `@[skills/database-design]` · `@[skills/mobile-design]`*
*Última atualização: 2026-03-07 · Fase 2.5 Persistência de Conversas concluída · Opção A (Fresh Start) implementada.*


Rodar backend local: uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000