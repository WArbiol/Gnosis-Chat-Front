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

### 6.2. Configuração Mobile (RevenueCat)

O **RevenueCat** é o gateway unificador de In-App Purchases (IAP) para iOS e Android. Ele abstrai toda a complexidade do StoreKit 2 (Apple) e Google Play Billing, gerenciando o ciclo de vida das assinaturas, recibos e renovações.

#### 1. Arquitetura de Identificadores (Mapeamento)

| Entitlement RevenueCat | Produto Loja (Product ID)  | Descrição           | Preço Referência | Limite Mensal   |
| ---------------------- | -------------------------- | --------------------- | ------------------ | --------------- |
| `basic`              | `gnosis_basic_monthly`   | Acesso Básico Mensal | R$ 9,90 / mês     | 100 perguntas   |
| `premium`            | `gnosis_premium_monthly` | Acesso Premium Mensal | R$ 29,90 / mês    | 1.000 perguntas |

---

#### 2. Passo a Passo no Dashboard do RevenueCat

1. **Criar o Projeto:**

   - Nome do projeto: `Pergunte à Gnosis`.
   - Confirmar o e-mail de verificação da conta (clicar no link de confirmação).
2. **Cadastrar os Aplicativos (Apps):**

   - **iOS (Apple App Store):**
     - **App Name:** `Pergunte à Gnosis (App Store)`
     - **Bundle ID:** `com.gnosischat.gnosisChat`
     - **Custom URL Scheme:** `gnosis`
     - **In-App Purchase Key (StoreKit 2):**
       1. Acesse o [App Store Connect](https://appstoreconnect.apple.com) > **Usuários e Acesso** > **Integrações/Chaves** > **In-App Purchase**.
       2. Clique em `+`, crie uma chave com o nome `RevenueCat Key` e baixe o arquivo `.p8` (guarde-o com segurança, download único).
       3. Copie o **Key ID** (código de 10 caracteres) e o **Issuer ID** (UUID no topo da página).
       4. No RevenueCat, faça upload do arquivo `.p8`, cole o `Key ID` e o `Issuer ID` e salve.
   - **Android (Google Play):**
     - **App Name:** `Pergunte à Gnosis (Google Play)`
     - **Package Name:** `com.gnosischat.gnosis_chat`
     - **Google Play Service Account Credentials JSON:**
       1. No Google Cloud Console (projeto vinculado à Play Console), crie uma Service Account com permissão para gerenciar compras e assinaturas do Google Play.
       2. Gere a chave privada em formato JSON.
       3. No RevenueCat, faça o upload desse arquivo JSON e salve.
3. **Configurar o Catálogo de Produtos:**

   - **Entitlements (`Product catalog > Entitlements`):**
     - Criar `basic` com descrição `Acesso Básico (100 perguntas/mês)`.
     - Criar `premium` com descrição `Acesso Premium (1.000 perguntas/mês)`.
   - **Products (`Product catalog > Products`):**
     - Cadastrar `gnosis_basic_monthly` e vincular ao entitlement `basic`.
     - Cadastrar `gnosis_premium_monthly` e vincular ao entitlement `premium`.
   - **Offerings (`Product catalog > Offerings`):**
     - Criar a Offering marcada como **Default** (Identifier: `default`).
     - Adicionar os Packages:
       - Package `$rc_monthly` (ou `basic`) → Produto `gnosis_basic_monthly`
       - Package Custom (ex: `premium`) → Produto `gnosis_premium_monthly`
4. **Obter Chaves de API (`API keys`):**

   - Copiar a **Public Apple API Key** (`appl_...`).
   - Copiar a **Public Google API Key** (`goog_...`).
   - Configurar no `.env` do Flutter (`gnosis-chat-front/.env`):
     ```env
     REVENUECAT_APPLE_KEY=appl_xxxxxxxxxxxxxxxxxxxx
     REVENUECAT_GOOGLE_KEY=goog_xxxxxxxxxxxxxxxxxxxx
     ```
5. **Integração no Frontend Flutter:**

   - Pacote oficial: `purchases_flutter`.
   - Inicialização em `main.dart`:
     ```dart
     if (!kIsWeb) {
       final apiKey = Platform.isIOS
           ? dotenv.env['REVENUECAT_APPLE_KEY']!
           : dotenv.env['REVENUECAT_GOOGLE_KEY']!;
       await Purchases.configure(
         PurchasesConfiguration(apiKey)..appUserID = supabaseUser.id,
       );
     }
     ```
   - No `subscription_provider.dart`: Ao comprar em dispositivos móveis, chamar `Purchases.purchasePackage(package)`. Na Web (`kIsWeb`), redirecionar para o Stripe Checkout.
6. **Webhooks Assíncronos no Backend (FastAPI):**

   - No RevenueCat, vá em **Integrations > Webhooks** e cadastre o endpoint:
     `POST https://gnosischat.com/payments/revenuecat-webhook`
   - Configurar a chave de autorização no cabeçalho (Webhook Authorization Header).
   - O backend processa eventos (`INITIAL_PURCHASE`, `RENEWAL`, `CANCELLATION`, `EXPIRATION`) e sincroniza com a tabela `users` no Supabase:
     ```json
     {
       "plan": "basic" | "premium",
       "subscription_provider": "revenuecat",
       "subscription_status": "active" | "canceled"
     }
     ```

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
