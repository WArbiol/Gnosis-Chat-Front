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
- **Pagamentos:** Stripe Billing (Web, R$ 9,90/mês Básico e R$ 29,90/mês Premium) e RevenueCat (Mobile).

---

## 2. Aquisição de Domínio e Proteção (Cloudflare)

Ter um domínio próprio é essencial para a API, para a Web e para os links de políticas de privacidade nas lojas.

### 2.1. Comprando o Domínio

- [X] Domínio **gnosischat.com** adquirido através do Cloudflare Registrar.

### 2.2. Configurando o Cloudflare (DNS e Segurança)

- [X] Domínio registrado e DNS gerenciado nativamente pelo Cloudflare.
- [X] SSL/TLS automático em modo Full/Strict ativo.

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

- [X] Service Account `gnosis-chat-backend-sa@gnosis-chat-app.iam.gserviceaccount.com` configurada com permissões de leitura Vertex AI Ranking e Qdrant Cloud.

### 4.2. Deploy via gcloud CLI

- [X] Deploy executado com sucesso no Cloud Run (`gnosis-chat-api`) na região `southamerica-east1` (Projeto: `gnosis-chat-app`).
- [X] Endpoint `POST /payments/reactivate` implementado e ativo em produção.

### 4.3. Vinculando o Domínio ao Cloud Run

- [X] Domínio de redirect do Stripe e rotas de API apontando para `https://gnosischat.com` e URL do Cloud Run.

---

## 5. Deploy do Frontend Web (Cloudflare Pages)

O Flutter Web gera arquivos estáticos (`HTML`, `JS`, `WebAssembly`). O deploy no **Cloudflare Pages** garante alta performance global com SSL automático.

### 5.1. Compilando o Frontend

- [X] Compilação executada com sucesso via `flutter build web --release`.
- [X] `flutter analyze` 100% limpo com **0 erros e 0 avisos**.

### 5.2. Configuração de Roteamento SPA (Single Page App)

- [X] Arquivo `wrangler.jsonc` configurado com `"not_found_handling": "single-page-application"`.

### 5.3. Publicando no Cloudflare Pages / Workers

- [X] Deploy realizado com sucesso via `npx wrangler deploy`.
- [X] Domínio `https://gnosischat.com` ativo e sincronizado.

---

## 6. Faturamento: Stripe (Web) e RevenueCat (Mobile)

### 6.1. Configuração Web (Stripe Billing)

- [X] **Modelos de Preço & Cotas:**
  - **Plano Básico:** R$ 9,90/mês (100 perguntas/mês).
  - **Plano Premium:** R$ 29,90/mês (1.000 perguntas/mês).
- [X] **Integração Checkout & Redirecionamentos:** Stripe Checkout configurado com suporte a cartões nacionais e carteiras digitais (Apple Pay, Google Pay).
- [X] **Ciclo de Cancelamento & Reativação:**
  - **Cancelamento:** `cancel_at_period_end=True` no Stripe. O acesso permanece 100% liberado até o `current_period_end`.
  - **Status:** Atualizado no Supabase como `subscription_status = 'canceled'` mantendo a data de expiração.
  - **Reativação em 1 Clique:** Endpoint `POST /payments/reactivate` (`cancel_at_period_end=False`), permitindo reativar instantaneamente a renovação automática sem novo checkout.
- [X] **Webhooks Assíncronos:** Stripe Webhook configurado no backend em produção (`POST /payments/webhook`) para sincronização automática com o Supabase.

### 6.2. Configuração Mobile Unificada (RevenueCat)

O **RevenueCat** é o gateway unificador de In-App Purchases (IAP) para iOS e Android. Ele abstrai toda a complexidade do StoreKit 2 (Apple) e Google Play Billing, gerenciando o ciclo de vida das assinaturas, recibos e renovações.

#### 1. Arquitetura de Identificadores (Mapeamento Unificado)

| Entitlement RevenueCat | Produto Loja (Product ID) | Descrição | Preço Referência | Limite Mensal |
| :--- | :--- | :--- | :--- | :--- |
| `basic` | `gnosis_basic_monthly` | Acesso Básico Mensal | R$ 9,90 / mês | 100 perguntas |
| `premium` | `gnosis_premium_monthly` | Acesso Premium Mensal | R$ 29,90 / mês | 1.000 perguntas |

---

#### 2. Configuração da Apple App Store (iOS) - [Concluído]

1. **Assinaturas no App Store Connect:** Cadastradas no grupo `Planos de Acesso` (`gnosis_basic_monthly` a R$ 9,90 e `gnosis_premium_monthly` a R$ 29,90).
2. **Chave In-App Purchase (StoreKit 2):**
   - Gerada em *Usuários e Acesso > Integrações > Compras dentro do app*.
   - Chave `.p8` baixada, `Key ID` e `Issuer ID` vinculados no RevenueCat no app `Pergunte à Gnosis (App Store)` com Bundle ID `com.gnosischat.gnosisChat`.
3. **Chave SDK no Flutter:** `REVENUECAT_APPLE_KEY=appl_...` configurada no `.env`.

---

#### 3. Configuração do Google Play (Android) - [Passo a Passo Detalhado]

Para habilitar as compras no Android via Google Play Billing e RevenueCat:

1. **Cadastrar Assinaturas no Google Play Console:**
   - Acesse o [Google Play Console](https://play.google.com/console/) > Selecione o app `com.gnosischat.gnosis_chat`.
   - No menu lateral, vá em **Monetizar com o Google Play > Produtos > Assinaturas**.
   - **Criar 1ª Assinatura (Básico):**
     - ID do produto: `gnosis_basic_monthly`
     - Nome: `Plano Básico`
     - Faturamento: Mensal recorrente (R$ 9,90 / mês).
   - **Criar 2ª Assinatura (Premium):**
     - ID do produto: `gnosis_premium_monthly`
     - Nome: `Plano Premium`
     - Faturamento: Mensal recorrente (R$ 29,90 / mês).

2. **Criar a Service Account no Google Cloud Console:**
   - Acesse o [Google Cloud Console](https://console.cloud.google.com/) no projeto vinculado à sua Play Console.
   - Ative a **Google Play Android Developer API**.
   - Vá em **IAM e administração > Contas de serviço** > **Criar conta de serviço**:
     - Nome: `revenuecat-play-store`
     - Clique em **Criar e continuar** > **Concluir**.
   - Clique na conta criada > Aba **Chaves** > **Adicionar chave > Criar nova chave > JSON**.
   - Baixe o arquivo `.json` gerado para o seu computador.

3. **Conceder Permissões Financeiras no Google Play Console:**
   - No Google Play Console, vá em **Acesso da API** (ou *Usuários e permissões*).
   - Convide o e-mail da Service Account (`revenuecat-play-store@...`).
   - Em **Permissões do App**, adicione o app `Pergunte à Gnosis`.
   - Marque as permissões:
     - *Ver dados financeiros, pedidos e relatórios de cancelamento.*
     - *Gerenciar pedidos e assinaturas.*
   - Clique em **Salvar alterações**.

4. **Cadastrar o App Android no RevenueCat:**
   - No RevenueCat, vá em **Project Settings > Apps > Add App > Google Play Store**:
     - **App Name:** `Pergunte à Gnosis (Google Play)`
     - **Google Play Package Name:** `com.gnosischat.gnosis_chat`
     - **Service Account Credentials JSON:** Faça upload do arquivo `.json`.
     - Clique em **Save changes**.

5. **Anexar Produtos Google Play ao Catálogo no RevenueCat:**
   - Em **Product catalog > Products**: Clique em `+ New` > Selecione o app Google Play > Cadastre `gnosis_basic_monthly` (vincule ao entitlement `basic`) e `gnosis_premium_monthly` (vincule ao entitlement `premium`).
   - Em **Product catalog > Offerings > default**:
     - No pacote `$rc_monthly`: Anexe o produto Google Play `gnosis_basic_monthly`.
     - No pacote `premium`: Anexe o produto Google Play `gnosis_premium_monthly`.

6. **Chave SDK no Flutter:**
   - No RevenueCat > **API keys**, copie a chave pública `goog_...` e configure no `.env` do Flutter (`REVENUECAT_GOOGLE_KEY=goog_...`).

---

#### 4. Integração no Frontend Flutter (Pronta)

* **Serviço Centralizado:** `lib/services/iap/revenue_cat_service.dart`.
* **Inicialização Automática:** No `main.dart` ao iniciar no mobile nativo (`!kIsWeb`).
* **Sincronização de Usuário:** Ao autenticar no `auth_provider.dart`, chama `RevenueCatService.logIn(userId)`.
* **Checkout Reativo:** No `subscription_provider.dart`, compras no mobile disparam diretamente `RevenueCatService.purchasePlan(plan)` e na web utilizam o Stripe Checkout.

---

#### 5. Webhooks Assíncronos no Backend FastAPI (Pronto)

* **Endpoint Ativo:** `POST /api/v1/payments/revenuecat-webhook`.
* **Autenticação:** Header `Authorization: Bearer rc_whsec_gnosis_2026_secure`.
* **Eventos Processados Automaticamente:**
  - `INITIAL_PURCHASE` / `RENEWAL` / `UNCANCELLATION`: Atualiza `subscription_status = 'active'`, plano correspondente (`basic` ou `premium`), e reseta a cota de perguntas (`question_count = 0`).
  - `CANCELLATION`: Marca `subscription_status = 'canceled'` mantendo o acesso até `current_period_end`.
  - `EXPIRATION` / `REVOCATION`: Reverte o usuário para o plano gratuito (`plan = 'free'`).

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
  - **Mensagem de Impacto:** *"Esta ação é irreversível. Todas as suas conversas criptografadas, histórico de perguntas serão apagados dos nossos servidores."*
  - **Alerta Contextual de Assinatura (Context-Aware Banner):**
    - *Usuário Gratuito:* Nenhum aviso financeiro adicional.
    - *Assinante Stripe (Web):* *"Sua assinatura ativa do Plano Ilimitado será cancelada automaticamente e nenhuma nova cobrança será realizada."*
    - *Assinante Apple / Google:* Card âmbar/amarelo de aviso:
      > ⚠️ *Você possui uma assinatura ativa via App Store / Google Play. Para evitar cobranças futuras, lembre-se de cancelar a renovação nos Ajustes do seu celular.*
      > [Botão Secundário: **Gerenciar na App Store** ↗]
      >
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
2. App ID (`com.gnosischat.gnosisChat`) com In-App Purchase e Sign in with Apple.

### 7.2. Configurando Assinaturas

1. Assinaturas Auto-Renováveis no App Store Connect associadas ao RevenueCat.

### 7.3. Build e Submissão (via GitHub Actions)

1. Action `.github/workflows/ios_deploy.yml` configurada para compilação remota macOS e upload `.ipa` para o TestFlight/App Store.

---

## 8. Deploy Mobile: Android (Google Play)

### 8.1. Burocracias Iniciais no Google Play Console

1. **Conta de Desenvolvedor:** Taxa única de US$ 25 no [Google Play Console](https://play.google.com/console/).
2. **Criar o App:**
   - **Nome:** `Pergunte à Gnosis`
   - **Idioma Padrão:** `Português (Brasil)`
   - **Tipo:** `App` / `Gratuito` (com compras no app)
   - **Package Name:** `com.gnosischat.gnosis_chat`

### 8.2. Configuração de Assinaturas no Google Play Console

1. Acesse o app no Play Console > Menu lateral **Monetizar com o Google Play** > **Produtos** > **Assinaturas**.
2. **Criar 1ª Assinatura (Plano Básico):**
   - **ID do produto:** `gnosis_basic_monthly`
   - **Nome:** `Plano Básico`
   - **Plano básico de faturamento:** Renovação automática mensal (1 mês).
   - **Preço:** R$ 9,90 / mês.
3. **Criar 2ª Assinatura (Plano Premium):**
   - **ID do produto:** `gnosis_premium_monthly`
   - **Nome:** `Plano Premium`
   - **Plano básico de faturamento:** Renovação automática mensal (1 mês).
   - **Preço:** R$ 29,90 / mês.

### 8.3. Conectar o Google Play ao RevenueCat (Service Account JSON)

Para que o RevenueCat valide as compras do Google Play automaticamente:

1. **Ativar a API no Google Cloud Console:**
   - Acesse o [Google Cloud Console](https://console.cloud.google.com/) no mesmo projeto vinculado à sua conta Play Console.
   - Ative a **Google Play Android Developer API**.
2. **Criar a Service Account (Conta de Serviço):**
   - Vá em **IAM e administração > Contas de serviço** > Clique em **Criar conta de serviço**.
   - Nome: `revenuecat-play-store`.
   - Clique em **Concluir**.
3. **Gerar a Chave Privada JSON:**
   - Clique na conta de serviço criada > Aba **Chaves** > **Adicionar chave** > **Criar nova chave** > Tipo **JSON**.
   - Baixe o arquivo `.json` gerado para o seu computador.
4. **Conceder Permissões no Google Play Console:**
   - No Google Play Console > Menu lateral **Acesso da API** (ou *Usuários e permissões*).
   - Convide o e-mail da conta de serviço recém-criada (`revenuecat-play-store@...`).
   - Em **Permissões do App**, selecione o app `Pergunte à Gnosis`.
   - Marque as permissões financeiras:
     - *Ver dados financeiros, pedidos e relatórios de cancelamento.*
     - *Gerenciar pedidos e assinaturas.*
   - Clique em **Salvar alterações**.
5. **Configurar no Dashboard do RevenueCat:**
   - No RevenueCat > **Project Settings > Apps > Add App > Google Play Store**:
     - **App Name:** `Pergunte à Gnosis (Google Play)`
     - **Google Play Package Name:** `com.gnosischat.gnosis_chat`
     - **Service Account Credentials JSON:** Faça o upload do arquivo `.json` baixado.
     - Clique em **Save changes**.
6. **Vincular Produtos à Offering Existente no RevenueCat:**
   - Em **Product catalog > Products**: Cadastre `gnosis_basic_monthly` e `gnosis_premium_monthly` para o app Google Play e vincule aos entitlements `basic` e `premium`.
   - Em **Product catalog > Offerings > default**: Anexe os produtos Google Play aos pacotes existentes (`$rc_monthly` e `premium`).
7. **Obter a Public Google API Key:**
   - No RevenueCat > **API keys**, copie a chave pública `goog_...` e configure no `.env` do Flutter (`REVENUECAT_GOOGLE_KEY=goog_...`).

### 8.4. Build e Submissão do Pacote Android (AAB)

1. **Configurar Chave de Assinatura (Keystore):**
   - Gerar `key.jks` e configurar em `android/key.properties`.
2. **Compilar Pacote Release:**
   ```bash
   flutter build appbundle --release
   ```
3. **Upload no Play Console:**
   - No Play Console > **Produção** ou **Teste Fechado (Closed Testing)**.
   - Criar nova versão e fazer upload do arquivo `build/app/outputs/bundle/release/app-release.aab`.
   - Preencher a classificação de conteúdo, política de privacidade e enviar para revisão.

---

## Resumo das Proteções Finais de Segurança:

- O **Frontend Web** nunca expõe Service Roles ou segredos; variáveis públicas tratadas isoladamente.
- As chaves de serviço de LLM e Banco de Dados só existem como variáveis seguras no **Cloud Run**.
- O **Cloudflare WAF** bloqueia ataques de negação de serviço e requisições maliciosas.
- Validação criptográfica de Webhooks (Stripe & RevenueCat).

O sistema está 100% implantado e ativo em produção na Web!
