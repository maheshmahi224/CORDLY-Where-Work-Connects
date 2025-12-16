# Developer Setup Guide

## Prerequisites
- **Node.js** (v18+)
- **Flutter SDK** (Latest Stable)
- **Docker** (Optional, for local DB testing)
- **Supabase CLI**

## Implementation Logic

### 1. Project Initialization
The project uses a simplified monorepo structure.
- `apps/client`: Flutter App
- `backend`: Node.js API
- `shared`: Shared definitions

### 2. Environment Variables
Create `.env` files in `backend` and `apps/client` directories.
*Never commit `.env` files.*

#### Backend `.env`
```env
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
GEMINI_API_KEY=your_gemini_key
PORT=3000
```

#### Client `.env` (via `--dart-define` or `.env` package)
```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
```

### 3. Running Locally

#### Backend
```bash
cd backend
npm install
npm run dev
```

#### Flutter Client
```bash
cd apps/client
flutter run -d chrome # or flutter run -d windows
```

## Directory Layout
- **/database/schemas**: SQL definitions for tables.
- **/database/policies**: RLS policy definitions (Row Level Security).
- **/shared**: Source of truth for Types.

## Critical Rules
1. **No Logic Duplication**: Business logic lives in the Backend.
2. **Offline First**: Client must work without internet. Use `drift` for local storage.
3. **Type Safety**: Run `npm run generate-types` to sync Database Types -> TypeScript -> Dart.
