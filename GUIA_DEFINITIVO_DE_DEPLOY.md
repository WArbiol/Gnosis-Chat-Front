# Guia Definitivo de Deploy - Gnosis Chat (iOS, Android, Web e Backend)

Este é o guia completo, definitivo e detalhado, passo a passo, para levar o Gnosis Chat do ambiente de desenvolvimento local para produção nas lojas de aplicativos (iOS e Android) e na Web, cobrindo infraestrutura, segurança, faturamento e domínio.

---

## Índice
1. [Visão Geral da Arquitetura](#1-visão-geral-da-arquitetura)
2. [Aquisição de Domínio e Proteção (Cloudflare)](#2-aquisição-de-domínio-e-proteção-cloudflare)
3. [Segurança contra Flooding e Abusos](#3-segurança-contra-flooding-e-abusos)
4. [Deploy do Backend (Google Cloud Run)](#4-deploy-do-backend-google-cloud-run)
5. [Deploy do Frontend Web (Flutter Web)](#5-deploy-do-frontend-web-flutter-web)
6. [Faturamento: Stripe (Web) e RevenueCat (Mobile)](#6-faturamento-stripe-web-e-revenuecat-mobile)
7. [Deploy Mobile: iOS (App Store)](#7-deploy-mobile-ios-app-store)
8. [Deploy Mobile: Android (Google Play)](#8-deploy-mobile-android-google-play)

---

## 1. Visão Geral da Arquitetura

Para que o aplicativo funcione em escala, a arquitetura de produção será distribuída da seguinte forma:
- **Backend:** Google Cloud Run (Serverless, auto-escalável).
- **Banco de Dados/Auth:** Supabase.
- **Banco Vetorial:** Qdrant Cloud.
- **Frontend Web:** Firebase Hosting (ou Vercel), protegido pela Cloudflare.
- **Mobile:** Publicado nativamente via App Store Connect e Google Play Console.
- **Pagamentos:** Stripe (para a Web) e RevenueCat interligando Apple IAP e Google Play Billing (para Mobile).

---

## 2. Aquisição de Domínio e Proteção (Cloudflare)

Ter um domínio próprio (ex: `gnosis-chat.com`) é essencial para a API, para a Web e para os links de políticas de privacidade nas lojas.

### 2.1. Comprando o Domínio
- [x] Domínio **gnosischat.com** adquirido com sucesso através do Cloudflare (https://dash.cloudflare.com/).

### 2.2. Configurando o Cloudflare (DNS e Segurança)
O Cloudflare atuará como um "escudo" na frente do seu Frontend Web e, opcionalmente, do Backend.
Como o domínio foi comprado diretamente pelo próprio Cloudflare (Cloudflare Registrar), a configuração de Nameservers já foi feita automaticamente de forma nativa!
- [x] Domínio registrado e DNS gerenciado pelo Cloudflare.

---

## 3. Segurança contra Flooding e Abusos

Como seu Frontend Web fará requisições abertas para o Backend, é vital proteger contra ataques de DDoS, Bots e Flooding (quando um usuário malicioso tenta esgotar sua cota de IA).

### 3.1. Proteção no Cloudflare (Frontend Web)
1. No painel do Cloudflare, vá em **Security > WAF**.
2. **Rate Limiting:** Crie uma regra bloqueando IPs que façam mais de X requisições por minuto (o plano gratuito tem limitações nisso, mas as proteções padrão de DDoS do Cloudflare já ajudam muito).
3. **Turnstile (CAPTCHA Invisível):** Para a tela de login/cadastro web, você pode integrar o [Cloudflare Turnstile](https://developers.cloudflare.com/turnstile/) para garantir que quem acessa é humano e não um bot.
4. **Bot Fight Mode:** Habilite na aba Security > Bots.

### 3.2. Proteção no Backend (GCP / FastAPI)
1. **Rate Limiter no FastAPI:** Mantenha (ou adicione) a biblioteca `slowapi` no seu backend Python. Limite, por exemplo, rotas de geração de IA para 10 requisições por minuto por IP ou por ID de usuário (JWT).
   - *Atenção:* Como o tráfego passará pelo Cloud Run (e possivelmente Cloudflare), seu backend deve ler o IP do cliente através do cabeçalho `X-Forwarded-For`, caso contrário ele bloqueará a si mesmo.
2. **Token JWT:** NENHUMA rota de IA deve ser pública. O aplicativo (Web ou Mobile) deve sempre enviar o JWT de autenticação do Supabase no cabeçalho `Authorization: Bearer <TOKEN>`.

### 3.3. Firebase App Check (Proteção Avançada para Mobile e Web)
Se o abuso persistir, implemente o **Firebase App Check** no seu app Flutter. Ele atesta (usando DeviceCheck da Apple, Play Integrity do Google e reCAPTCHA na Web) que a requisição vem genuinamente do seu aplicativo original e não de um script, anexando um token especial que o backend pode validar.

---

## 4. Deploy do Backend (Google Cloud Run)

O Cloud Run rodará o container Docker do seu FastAPI (arquitetura Agentic RAG).

### 4.1. Preparar a Conta de Serviço (IAM)
- [x] Service Account `gnosis-chat-backend-sa@gnosis-chat-app.iam.gserviceaccount.com` criada no GCP com as permissões necessárias (`Discovery Engine Viewer`).

### 4.2. Deploy via gcloud CLI
- [x] Deploy executado com sucesso no Cloud Run (`gnosis-chat-api`) na região `us-central1` com variáveis de ambiente de produção injetadas.

### 4.3. Vinculando o Domínio ao Cloud Run
- [x] Registro `CNAME` (`api` -> `gnosis-chat-api-971574732695.us-central1.run.app`) adicionado no Cloudflare com proxy ativo (nuvem laranja).

---

## 5. Deploy do Frontend Web (Cloudflare Pages)

O Flutter Web gera arquivos estáticos (HTML, JS, WebAssembly). Como seu domínio `gnosischat.com` foi comprado diretamente no Cloudflare, a hospedagem no **Cloudflare Pages** foi concluída com sucesso: 100% gratuita, sem limites de tráfego/banda e com SSL automático.

### 5.1. Compilando o Frontend
- [x] Compilado com sucesso via `flutter build web --release --dart-define=API_URL=https://gnosis-chat-api-971574732695.us-central1.run.app/api/v1/`.

### 5.2. Configuração de Roteamento SPA (Single Page App)
- [x] Configurado no `wrangler.jsonc` com `"not_found_handling": "single-page-application"` para garantir o funcionamento de todas as rotas no Cloudflare.

### 5.3. Publicando no Cloudflare Pages / Workers
- [x] Deploy realizado com sucesso via `npx wrangler deploy`.
- [x] Domínios `gnosischat.com` e `www.gnosischat.com` vinculados ao Worker/Pages no painel do Cloudflare com HTTPS ativo.

---

## 6. Faturamento: Stripe (Web) e RevenueCat (Mobile)

Não podemos misturar pagamentos. A Web usa Stripe e o Mobile usa Apple/Google (gerenciados pelo RevenueCat).

### 6.1. Configuração Web (Stripe)
1. O backend já possui integração Stripe Webhook (`STRIPE_WEBHOOK_SECRET` em prod).
2. Acesse o **Stripe Dashboard > Webhooks**.
3. Adicione o endpoint `https://api.gnosis-chat.com/api/v1/payments/webhook`.
4. O frontend Web, ao detectar `kIsWeb == true`, chamará o Stripe Checkout para efetuar o pagamento, e o Stripe atualizará o status no Supabase.

### 6.2. Configuração Mobile (RevenueCat)
1. Crie uma conta no [RevenueCat](https://www.revenuecat.com/).
2. Crie um novo App/Projeto para **App Store** e outro para **Play Store**.
3. Crie os **Products** (ex: `premium_monthly`) e **Entitlements** (ex: `premium_access`).
4. **Webhook:** Em *Project Settings > Webhooks*, aponte para uma nova rota do seu backend: `https://api.gnosis-chat.com/api/v1/payments/revenuecat-webhook`.
5. O backend precisa traduzir os eventos do RevenueCat (`INITIAL_PURCHASE`, `RENEWAL`, `EXPIRATION`) para atualizar as colunas `subscription_expires_at` e `subscription_provider` na tabela de usuários do Supabase.

---

## 7. Deploy Mobile: iOS (App Store)

A Apple é rigorosa. Todo o passo a passo precisa ser feito com atenção.

### 7.1. Burocracias Iniciais
1. Pague os US$ 99/ano no [Apple Developer Program](https://developer.apple.com/programs/).
2. No App Store Connect, vá em **Agreements, Tax, and Banking** e preencha os formulários fiscais. Sem isso, você não pode vender assinaturas.
3. No [Apple Developer Portal](https://developer.apple.com/account/), vá em **Identifiers** e crie um **App ID** (ex: `com.gnosischat.app`) com *In-App Purchase* e *Sign in with Apple* ativados.
4. Se você suporta Sign in with Apple, configure a Private Key (`.p8`) e o Service ID no painel do Supabase, conforme detalhado no plano de billing.

### 7.2. Configurando Assinaturas (App Store Connect)
1. Acesse o **App Store Connect** e crie o App.
2. Na aba lateral, vá em **In-App Purchases**.
3. Crie assinaturas Auto-Renováveis (ex: `premium_monthly`). Defina preço, tradução e o grupo de assinaturas.
4. Vá em **Users and Access > Integrations** e gere uma *In-App Purchase Key*. Coloque essa chave no painel do **RevenueCat**.

### 7.3. Build e Submissão (via GitHub Actions)
Como você não possui um Mac atualizado, utilizaremos o **GitHub Actions** (usando runners em nuvem com macOS) para fazer o build e o upload para a App Store automaticamente.

1. **Gere os Certificados e Perfis de Provisionamento:**
   Mesmo sem Mac, você precisará gerar um certificado de distribuição (`.p12`) e um Provisioning Profile através do portal Apple Developer. Ferramentas como OpenSSL (no Linux) podem gerar a chave CSR necessária.
2. **Crie os Secrets no GitHub:**
   No repositório do seu frontend no GitHub, vá em **Settings > Secrets and variables > Actions** e adicione:
   - `APP_STORE_CONNECT_API_KEY`: Chave da API do App Store Connect (para upload).
   - `CERTIFICATES_P12`: Seu certificado de distribuição em formato base64.
   - `CERTIFICATES_P12_PASSWORD`: Senha do seu certificado `.p12`.
   - `PROVISIONING_PROFILE`: Seu arquivo mobileprovision em formato base64.
3. **Crie o Arquivo de Workflow:**
   No seu projeto, crie o diretório `.github/workflows/` e o arquivo `ios_deploy.yml`:
   ```yaml
   name: iOS Build and Deploy
   on:
     workflow_dispatch: # Permite rodar manualmente pelo painel do GitHub

   jobs:
     build-ios:
       runs-on: macos-latest
       steps:
         - uses: actions/checkout@v3
         - uses: subosito/flutter-action@v2
           with:
             flutter-version: '3.x'
             
         - name: Install Apple Certificate and Provisioning Profile
           env:
             BUILD_CERTIFICATE_BASE64: ${{ secrets.CERTIFICATES_P12 }}
             P12_PASSWORD: ${{ secrets.CERTIFICATES_P12_PASSWORD }}
             BUILD_PROVISION_PROFILE_BASE64: ${{ secrets.PROVISIONING_PROFILE }}
             KEYCHAIN_PASSWORD: ${{ secrets.KEYCHAIN_PASSWORD }}
           run: |
             # O script padronizado do GitHub Actions importa o certificado para o keychain do runner
             
         - name: Install Dependencies
           run: flutter pub get
           
         - name: Build IPA
           run: flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
           
         - name: Upload to App Store Connect
           env:
             API_KEY: ${{ secrets.APP_STORE_CONNECT_API_KEY }}
           run: |
             xcrun altool --upload-app -t ios -f build/ios/ipa/*.ipa --apiKey $API_KEY
   ```
4. **Envio e Revisão:**
   - Ao executar a action pelo GitHub, o servidor do GitHub usará um Mac na nuvem, compilará o Flutter e enviará o `.ipa` direto para a Apple.
   - Vá ao [App Store Connect](https://appstoreconnect.apple.com/), selecione a aba **TestFlight** ou **App Store** e a build estará lá processando.
   - Preencha os metadados (screenshots, política de privacidade), adicione uma conta de teste no backend para o revisor logar, e clique em **Add for Review**.

---

## 8. Deploy Mobile: Android (Google Play)

O processo no Google é ligeiramente diferente e exige testes prévios antes do lançamento público.

### 8.1. Burocracias Iniciais
1. Pague a taxa única de US$ 25 no [Google Play Console](https://play.google.com/console/).
2. Preencha o "Perfil para Pagamentos" para habilitar a monetização.
3. No Google Cloud Console, crie uma **Service Account** para o Play Console, baixe a chave `.json` e faça o upload dela no painel do **RevenueCat** para integrar a comunicação.

### 8.2. Configurando Assinaturas (Play Console)
1. No Play Console, vá em **Produtos > Assinaturas**.
2. Crie a assinatura `premium_monthly`.
3. Adicione um **Plano Base** (Base Plan) de renovação automática e defina o preço. Ative o plano.

### 8.3. Assinatura do App (Keystore)
Diferente da Apple onde o Xcode faz muita coisa, no Android você precisa gerar a sua própria chave de assinatura para o release.
1. No terminal:
   ```bash
   keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   *Guarde a senha dessa chave muito bem. Se você perdê-la, não poderá atualizar o aplicativo.*
2. No arquivo `android/app/build.gradle`, adicione a configuração de *signingConfigs* apontando para essa keystore.
   *(A documentação oficial do Flutter "Build and release an Android app" possui os passos exatos para adicionar as variáveis da keystore no arquivo `key.properties`).*

### 8.4. Build e Submissão
1. No terminal do Flutter:
   ```bash
   flutter build appbundle
   ```
   *(Isso gera um arquivo `.aab` na pasta `build/app/outputs/bundle/release/`).*
2. No Google Play Console, antes de ir para a "Produção", você deve criar uma **Faixa de Teste Fechado (Closed Testing)**.
3. Suba o arquivo `.aab`.
4. Preencha toda a presença na loja (Ícone, Banners, Screenshots, Textos).
5. Responda as declarações (Classificação indicativa, Segurança dos Dados, Privacidade).
6. Nas **Instruções para acesso do app**, forneça as credenciais de teste para a equipe do Google.
7. Mande para revisão no Teste Fechado.
8. Somente após aprovado (ou dependendo das novas regras do Google, após 20 testers ativos por 14 dias se for conta nova), você pode promover essa release para **Produção (Production)**.

---

## Resumo das Proteções Finais de Segurança:
- O **Frontend Web** nunca revela IPs de banco de dados; todas as chaves no Firebase Hosting/Vercel são públicas (anon keys).
- As chaves de serviço (Service Role, API Keys da OpenAI/Gemini/Qdrant) só existem como variáveis de ambiente dentro do **Cloud Run**.
- O **Cloudflare** barra picos anormais de tráfego na URL pública da API.
- Os pagamentos (Web e Mobile) utilizam **Webhooks** validados criptograficamente (Stripe Webhook Secret / Validação RevenueCat) para impedir que hackers mandem requests falsas dando a si mesmos "Premium".

Você está pronto para o lançamento! Siga as etapas e faça testes na Web (Stripe Test Mode) e Mobile (TestFlight no iOS / Internal Testing no Android) antes de abrir ao público geral.
