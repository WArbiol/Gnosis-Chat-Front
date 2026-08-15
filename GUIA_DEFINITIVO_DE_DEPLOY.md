# Guia Definitivo de Deploy - Gnosis Chat (iOS, Android, Web e Backend)

Este é o guia completo, definitivo e detalhado, passo a passo, para levar o Gnosis Chat do ambiente de desenvolvimento local para produção nas lojas de aplicativos (iOS e Android) e na Web, cobrindo infraestrutura, segurança, faturamento e domínio.

---

## Índice
1. [Visão Geral da Arquitetura](#1-visão-geral-da-arquitetura)
2. [Aquisição de Domínio e Proteção (Cloudflare)](#2-aquisição-de-domínio-e-proteção-cloudflare)
3. [Segurança contra Flooding e Abusos](#3-segurança-contra-flooding-e-abusos)
4. [Deploy do Backend (Google Cloud Run)](#4-deploy-do-backend-google-cloud-run)
5. [Deploy do Frontend Web (Cloudflare Pages)](#5-deploy-do-frontend-web-cloudflare-pages)
6. [Faturamento: Stripe (Web) e RevenueCat (Mobile)](#6-faturamento-stripe-web-e-revenuecat-mobile)
7. [Deploy Mobile: iOS (App Store)](#7-deploy-mobile-ios-app-store)
8. [Deploy Mobile: Android (Google Play)](#8-deploy-mobile-android-google-play)

---

## 1. Visão Geral da Arquitetura

Para que o aplicativo funcione em escala, a arquitetura de produção é distribuída da seguinte forma:
- **Backend:** Google Cloud Run (`gnosis-chat-api` no GCP `gnosis-chat-app`, região `southamerica-east1`).
- **Banco de Dados/Auth:** Supabase.
- **Banco Vetorial:** Qdrant Cloud (90 Obras Gnósticas).
- **Frontend Web:** Cloudflare Pages (`gnosischat.com`), 100% gratuito e protegido pela rede global da Cloudflare.
- **Mobile:** Publicado nativamente via App Store Connect e Google Play Console.
- **Pagamentos:** Stripe Billing (Web, R$ 9,99/mês Básico e R$ 29,99/mês Premium) e RevenueCat (Mobile).

---

## 2. Aquisição de Domínio e Proteção (Cloudflare)

Ter um domínio próprio é essencial para a API, para a Web e para os links de políticas de privacidade nas lojas.

### 2.1. Comprando o Domínio
- [x] Domínio **gnosischat.com** adquirido através do Cloudflare Registrar.

### 2.2. Configurando o Cloudflare (DNS e Segurança)
- [x] Domínio registrado e DNS gerenciado nativamente pelo Cloudflare.
- [x] SSL/TLS automático em modo Full/Strict ativo.

---

## 3. Segurança contra Flooding e Abusos

### 3.1. Proteção no Cloudflare (Frontend Web)
1. **WAF & Rate Limiting:** Proteções padrão de DDoS do Cloudflare ativas.
2. **Bot Fight Mode:** Ativado na aba Security > Bots.

### 3.2. Proteção no Backend (GCP / FastAPI)
1. **Rate Limiter no FastAPI:** Configurado com `slowapi` limitando requisições por IP e JWT.
2. **Token JWT:** Autenticação obrigatória Supabase JWT no cabeçalho `Authorization: Bearer <TOKEN>`.

---

## 4. Deploy do Backend (Google Cloud Run)

O Cloud Run executa o container Docker do FastAPI (arquitetura Agentic RAG otimizada).

### 4.1. Preparar a Conta de Serviço (IAM)
- [x] Service Account `gnosis-chat-backend-sa@gnosis-chat-app.iam.gserviceaccount.com` configurada com permissões de leitura Vertex AI Ranking e Qdrant Cloud.

### 4.2. Deploy via gcloud CLI
- [x] Deploy executado com sucesso no Cloud Run (`gnosis-chat-api`) na região `southamerica-east1` (Projeto: `gnosis-chat-app`).
- [x] Endpoint `POST /payments/reactivate` implementado e ativo em produção.

### 4.3. Vinculando o Domínio ao Cloud Run
- [x] Domínio de redirect do Stripe e rotas de API apontando para `https://gnosischat.com` e URL do Cloud Run.

---

## 5. Deploy do Frontend Web (Cloudflare Pages)

O Flutter Web gera arquivos estáticos (`HTML`, `JS`, `WebAssembly`). O deploy no **Cloudflare Pages** garante alta performance global com SSL automático.

### 5.1. Compilando o Frontend
- [x] Compilação executada com sucesso via `flutter build web --release`.
- [x] `flutter analyze` 100% limpo com **0 erros e 0 avisos**.

### 5.2. Configuração de Roteamento SPA (Single Page App)
- [x] Arquivo `wrangler.jsonc` configurado com `"not_found_handling": "single-page-application"`.

### 5.3. Publicando no Cloudflare Pages / Workers
- [x] Deploy realizado com sucesso via `npx wrangler deploy`.
- [x] Domínio `https://gnosischat.com` ativo e sincronizado.

---

## 6. Faturamento: Stripe (Web) e RevenueCat (Mobile)

### 6.1. Configuração Web (Stripe Billing)
- [x] **Modelos de Preço & Cotas:**
  - **Plano Básico:** R$ 9,99/mês (100 perguntas/mês).
  - **Plano Premium:** R$ 29,99/mês (1.000 perguntas/mês).
- [x] **Integração Checkout & Redirecionamentos:** Stripe Checkout configurado com suporte a cartões nacionais e carteiras digitais (Apple Pay, Google Pay).
- [x] **Ciclo de Cancelamento & Reativação:**
  - **Cancelamento:** `cancel_at_period_end=True` no Stripe. O acesso permanece 100% liberado até o `current_period_end`.
  - **Status:** Atualizado no Supabase como `subscription_status = 'canceled'` mantendo a data de expiração.
  - **Reativação em 1 Clique:** Endpoint `POST /payments/reactivate` (`cancel_at_period_end=False`), permitindo reativar instantaneamente a renovação automática sem novo checkout.
- [x] **Webhooks Assíncronos:** Stripe Webhook configurado no backend em produção (`POST /payments/webhook`) para sincronização automática com o Supabase.

### 6.2. Configuração Mobile (RevenueCat)
1. Integração via `RevenueCat` com produtos e entitlements `premium_access`.
2. Webhooks de sincro no backend: `POST /payments/revenuecat-webhook`.

### 6.3. Ciclo de Vida da Conta & Exclusão de Perfil (Account Deletion & UI/UX)

> ⚠️ **Requisito Obrigatório das Lojas (App Store & Google Play):**  
> De acordo com a **Apple App Store Guideline 5.1.1 (v)** e as diretrizes da Google Play Store (além da LGPD/GDPR), qualquer aplicativo com suporte a login **deve obrigatoriamente fornecer uma opção de exclusão de conta dentro do próprio app**. A ausência dessa funcionalidade no mobile resulta em **rejeição sumária na revisão da Apple**.

#### 1. Arquitetura do Cancelamento de Assinaturas na Exclusão
- **Stripe (Web):**
  - O backend cancela imediatamente a assinatura ativa no Stripe via API (`stripe.Subscription.delete`). O usuário não precisa realizar nenhuma ação manual externa.
- **Apple App Store (iOS) & Google Play Store (Android):**
  - **Regra de Segurança da Apple/Google:** Aplicativos de terceiros **não têm permissão para cancelar cobranças de In-App Purchases diretamente no cartão do usuário via API**.
  - **Diretriz de Conformidade UX da Apple:** O modal de exclusão de conta deve **detectar se o usuário possui assinatura ativa via loja** e alertá-lo explicitamente com link/botão para gerenciar e cancelar a assinatura na central do dispositivo (`apps.apple.com/account/subscriptions` ou `play.google.com/store/account/subscriptions`) antes de finalizar a exclusão.

#### 2. Especificação de UI/UX (Padrão Figma / Linear / Notion)

- **Ponto de Entrada (`ProfileBottomSheet`):**
  - Posicionado no rodapé da folha de perfil, logo abaixo do botão "Sair", de forma discreta para evitar toques acidentais, porém perfeitamente visível.
  - Estilo: Texto e ícone sutis (`Icons.delete_outline_rounded`) em tom de alerta suave (`AppColors.error.withValues(alpha: 0.7)`).

- **Modal de Confirmação Destrutivo (`Destructive Confirmation Dialog`):**
  - **Card de Impacto Visual:** Fundo obsidiana com borda em vermelho carmesim translúcido e ícone de lixeira em destaque.
  - **Título Claro:** *"Excluir conta permanentemente?"*
  - **Mensagem de Impacto:** *"Esta ação é irreversível. Todas as suas conversas criptografadas, histórico de perguntas e preferências serão apagados dos nossos servidores."*
  - **Alerta Contextual de Assinatura (Context-Aware Banner):**
    - *Usuário Gratuito:* Nenhum aviso financeiro adicional.
    - *Assinante Stripe (Web):* *"Sua assinatura ativa do Plano Ilimitado será cancelada automaticamente e nenhuma nova cobrança será realizada."*
    - *Assinante Apple / Google:* Card âmbar/amarelo de aviso:  
      > ⚠️ *Você possui uma assinatura ativa via App Store / Google Play. Para evitar cobranças futuras, lembre-se de cancelar a renovação nos Ajustes do seu celular.*  
      > [Botão Secundário: **Gerenciar na App Store** ↗]
  - **Ações de Decisão:**
    - Botão Primário (Segurança): **"Manter Minha Conta"** (Estilo sólido padrão — previne erros de toque).
    - Botão Destrutivo: **"Sim, Excluir Definitivamente"** (Estilo outline vermelho suave).

#### 3. Orquestração no Backend (`POST /api/v1/auth/delete-account`):
1. **Verificação de Identidade:** Valida o JWT do usuário autenticado no header.
2. **Cancelamento do Provedor de Pagamento:** Se `user.subscription_provider == 'stripe'`, dispara `stripe.Subscription.delete()`. Se `revenuecat`, marca entitlement como revogado.
3. **Expurgo de Dados Criptografados:**
   - Remove mensagens vinculadas (`DELETE FROM messages WHERE user_id = ...`).
   - Remove conversas vinculadas (`DELETE FROM conversations WHERE user_id = ...`).
   - Remove perfil (`DELETE FROM user_profiles WHERE id = ...`).
4. **Exclusão no Supabase Auth:** Executa `supabase.auth.admin.delete_user(user_id)` utilizando a Service Role Key, eliminando credenciais e acessos.
5. **Encerramento no Frontend:** Limpa o cache local do Hive, executa logout no Supabase e redireciona para a tela de Login com feedback suave.

---

## 7. Deploy Mobile: iOS (App Store)

### 7.1. Burocracias Iniciais
1. Conta no [Apple Developer Program](https://developer.apple.com/programs/).
2. App ID (`com.gnosischat.app`) com In-App Purchase e Sign in with Apple.

### 7.2. Configurando Assinaturas
1. Assinaturas Auto-Renováveis no App Store Connect associadas ao RevenueCat.

### 7.3. Build e Submissão (via GitHub Actions)
1. Action `.github/workflows/ios_deploy.yml` configurada para compilação remota macOS e upload `.ipa` para o TestFlight/App Store.

---

## 8. Deploy Mobile: Android (Google Play)

### 8.1. Burocracias Iniciais
1. Taxa única no [Google Play Console](https://play.google.com/console/).
2. Service Account para validação de assinaturas RevenueCat.

### 8.2. Build e Submissão
1. Compilação do pacote AAB: `flutter build appbundle`.
2. Upload na esteira de Teste Fechado / Produção no Play Console.

---

## Resumo das Proteções Finais de Segurança:
- O **Frontend Web** nunca expõe Service Roles ou segredos; variáveis públicas tratadas isoladamente.
- As chaves de serviço de LLM e Banco de Dados só existem como variáveis seguras no **Cloud Run**.
- O **Cloudflare WAF** bloqueia ataques de negação de serviço e requisições maliciosas.
- Validação criptográfica de Webhooks (Stripe & RevenueCat).

O sistema está 100% implantado e ativo em produção na Web!
