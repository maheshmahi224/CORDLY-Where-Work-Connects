# CORDLY — Where Work Connects

**CORDLY** is a private, personal operating system designed to connect actions, people, schedules, habits, and memory into one continuous system. It is built for high-agency achievers, ensuring context is never lost.

## 🔒 Private & Personal
This system is built exclusively for a single primary user. It prioritizes data ownership, reliability, and speed over public features.
- No SEO.
- No public links.
- No marketing fluff.

## 🏗 Tech Stack (Strict)

### Monorepo Structure
- **/apps/client**: Unified **Flutter** codebase for Mobile (iOS/Android) and Web (Desktop-class UI).
- **/backend**: **Node.js + TypeScript** API, orchestration, and business logic.
- **/database**: **Supabase (PostgreSQL)** for data, Auth, Realtime, and Vector Store.
- **/shared**: shared TypeScript types and constants.

### Core Architecture
- **Offline-First**: Client uses `drift` (SQLite) for zero-latency local operations, syncing to Supabase.
- **Single Source of Truth**: Backend guarantees data integrity via RLS and strict validation.
- **AI as Analyst**: Gemini API integrated for deep context retrieval and brutal honesty.

## 🚀 Mission
Connect actions, people, schedules, habits, and memory into one continuous system so progress never breaks.
