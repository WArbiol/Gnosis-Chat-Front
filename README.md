# Gnosis Chat (Frontend)

> Intelligent chat interface based on RAG over 150 gnostic PDFs — iOS, Android & Web.

This repository contains the frontend client code built with Flutter.

> [!NOTE]  
> The Python/FastAPI backend that handles the RAG pipeline, agentic workflows, database migrations, and integrations is hosted in a **private repository**.

---

## 🛠️ Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter (Dart 3.x) |
| **State Management** | Riverpod |
| **Routing** | GoRouter |
| **Database & Auth Client** | Supabase Auth + PostgreSQL |
| **Payments Integration** | Stripe |

---

## 🚀 Quick Start

### Prerequisites
Make sure you have Flutter installed on your system. You can check the installation using `flutter doctor`.

### Installation

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Configure environment variables. Create a `.env` file in the root directory:
   ```properties
   # Supabase configuration
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=sb_publishable_...

   # Backend API Url
   BACKEND_URL=http://localhost:8000
   ```
   *(Make sure never to commit your `.env` file to version control)*

3. Run the application:
   ```bash
   flutter run
   ```

---

## 📂 Project Structure

```
gnosis-chat-front/
├── android/          # Native Android configuration
├── ios/              # Native iOS configuration
├── lib/              # Flutter Dart source files
│   ├── main.dart     # Application entrypoint
│   └── ...           # Features, routing, state providers, and UI pages
├── assets/           # Static images, assets, and icons
├── web/              # Web platform support
└── pubspec.yaml      # Dart package definitions
```

---

## 🔗 Architecture Overview

The frontend communicates with the private backend API and Supabase direct services:

```
Flutter Client (App/Web) ──> Supabase Auth / Database (User session)
                      └──> FastAPI Backend (Private Repo) ──> LangGraph RAG Agent
```
