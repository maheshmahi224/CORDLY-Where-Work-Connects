# CORDLY - Complete Installation, Setup & Deployment Guide

This guide will walk you through **everything** you need to do to install, run locally, and deploy CORDLY to production.

---

## 📋 **PREREQUISITES**

Before you start, make sure you have these installed on your computer:

### Required Software

1. **Node.js** (v18 or higher)
   - Download: https://nodejs.org/
   - Verify: `node --version`

2. **Flutter SDK** (3.2.0 or higher)
   - Download: https://flutter.dev/docs/get-started/install
   - Verify: `flutter --version`
   - If not in PATH, add it to your system PATH

3. **Git**
   - Download: https://git-scm.com/
   - Verify: `git --version`

4. **Code Editor**
   - VS Code (recommended) with Flutter + Dart extensions

### Accounts You'll Need

1. **Supabase Account** (Free tier is fine)
   - Sign up: https://supabase.com
   
2. **Google AI Studio Account** (For Gemini API)
   - Sign up: https://makersuite.google.com/app/apikey
   - Get a free API key

3. **Vercel Account** (Free tier)
   - Sign up: https://vercel.com (use GitHub login)

4. **Firebase Hosting** (Optional, for Flutter Web)
   - Or use Vercel/Netlify

---

## 🗂️ **PART 1: LOCAL SETUP**

### Step 1: Clone/Navigate to Project

```bash
cd "C:\Users\DELL\Desktop\CORDLY — Where Work Connects\CORDLY-Where-Work-Connects"
```

---

### Step 2: Setup Supabase (Database)

#### 2.1 Create Supabase Project

1. Go to https://supabase.com/dashboard
2. Click **"New Project"**
3. Fill in:
   - **Name**: `cordly-prod` (or any name)
   - **Database Password**: Create a strong password (save it!)
   - **Region**: Choose closest to you
4. Click **"Create new project"** (takes ~2 minutes)

#### 2.2 Run Database Migrations

1. Once project is ready, click **"SQL Editor"** in left sidebar
2. Click **"New Query"**
3. Copy entire contents of `database/schemas/001_core.sql`
4. Paste into SQL Editor
5. Click **"Run"** (bottom right)
6. You should see "Success. No rows returned"

7. Create a **new query** again
8. Copy entire contents of `database/policies/001_rls.sql`
9. Paste and click **"Run"**

#### 2.3 Get Supabase Credentials

1. Click **"Settings"** (gear icon) in left sidebar
2. Click **"API"**
3. Copy these values (you'll need them):
   - **Project URL** (looks like: `https://xxxxx.supabase.co`)
   - **anon public** key (under "Project API keys")
   - **service_role** key (click "Reveal" next to service_role)

---

### Step 3: Setup Backend

#### 3.1 Install Dependencies

```bash
cd backend
npm install
```

#### 3.2 Configure Environment Variables

1. Copy the example file:
```bash
copy .env.example .env
```

2. Open `.env` in your editor and fill in:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here
SUPABASE_ANON_KEY=your_anon_public_key_here
GEMINI_API_KEY=your_gemini_api_key_here
PORT=3000
NODE_ENV=development
CORS_ORIGIN=*
```

**To get Gemini API Key:**
1. Go to https://makersuite.google.com/app/apikey
2. Click "Create API Key"
3. Copy the key

#### 3.3 Test Backend Locally

```bash
npm run dev
```

You should see:
```
🚀 CORDLY Backend running on http://localhost:3000
   Environment: development
   Supabase: ✓ Connected
```

**Test it:**
- Open browser: http://localhost:3000/health
- You should see: `{"status":"ok",...}`

---

### Step 4: Setup Flutter Client

#### 4.1 Install Dependencies

```bash
cd ../apps/client
flutter pub get
```

#### 4.2 Generate Database Code

This generates the Drift database code:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Wait for it to complete (takes 30-60 seconds).

#### 4.3 Create Environment Config File

Create a file: `apps/client/lib/env.dart`

```dart
class Env {
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your_anon_key_here';
}
```

**OR** you can pass them as launch arguments (next step).

#### 4.4 Run Flutter App

**Option A: Using Command Line (Recommended)**

```bash
flutter run -d chrome --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

**Option B: Using VS Code**

1. Open VS Code
2. Open `apps/client/lib/main.dart`
3. Click "Run" → "Start Debugging" (F5)
4. In the "Select Device" dropdown, choose **Chrome (web-javascript)**

If you get errors about environment variables:
1. Open `.vscode/launch.json` (create if doesn't exist)
2. Add:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter (Chrome)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "args": [
        "--dart-define=SUPABASE_URL=https://your-project.supabase.co",
        "--dart-define=SUPABASE_ANON_KEY=your_anon_key_here"
      ]
    }
  ]
}
```

---

### Step 5: Test the App

1. **Sign Up:**
   - Click "Create Account"
   - Enter email: `test@example.com`
   - Enter password: `password123`
   - Click "Create Account"

2. **Sign In:**
   - Use the same credentials
   - You should see the Home Dashboard

3. **Create a Workspace:**
   - If prompted, create your first workspace
   - Name it "My Workspace"

4. **Add an Execution:**
   - Click "Execute" in sidebar
   - Click the + button
   - Add a task: "Test Task"
   - Click "Create"

---

## 🚀 **PART 2: DEPLOYMENT**

### Step 1: Deploy Backend to Vercel

#### 1.1 Prepare Backend for Deployment

Create `backend/vercel.json`:

```json
{
  "version": 2,
  "builds": [
    {
      "src": "src/index.ts",
      "use": "@vercel/node"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "src/index.ts"
    }
  ]
}
```

#### 1.2 Update package.json

Edit `backend/package.json` and make sure you have:

```json
{
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "vercel-build": "echo 'Build complete'"
  },
  "engines": {
    "node": "18.x"
  }
}
```

#### 1.3 Deploy to Vercel

1. **Install Vercel CLI:**
```bash
npm install -g vercel
```

2. **Navigate to backend:**
```bash
cd backend
```

3. **Login to Vercel:**
```bash
vercel login
```

4. **Deploy:**
```bash
vercel
```

Follow prompts:
- Set up and deploy? **Y**
- Which scope? (Choose your account)
- Link to existing project? **N**
- What's your project's name? **cordly-backend**
- In which directory is your code located? **. (current directory)**

5. **Set Environment Variables:**

```bash
vercel env add SUPABASE_URL
# Paste your Supabase URL, press Enter
# Choose: Production, Preview, Development (select all)

vercel env add SUPABASE_SERVICE_ROLE_KEY
# Paste your service role key

vercel env add SUPABASE_ANON_KEY
# Paste your anon key

vercel env add GEMINI_API_KEY
# Paste your Gemini key

vercel env add CORS_ORIGIN
# Enter: * (or your frontend domain later)

vercel env add NODE_ENV
# Enter: production
```

6. **Deploy to Production:**
```bash
vercel --prod
```

7. **Copy the URL** (looks like: `https://cordly-backend-xxx.vercel.app`)

8. **Test it:**
   - Visit: `https://your-backend-url.vercel.app/health`
   - Should see: `{"status":"ok",...}`

---

### Step 2: Deploy Flutter Web

#### 2.1 Build Flutter Web

```bash
cd apps/client
flutter build web --release
```

#### 2.2 Update Web App with Production Config

Before building, update `lib/main.dart` to use production Supabase URL:

Or build with:
```bash
flutter build web --release --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

#### 2.3 Deploy to Firebase Hosting (Option 1)

1. **Install Firebase CLI:**
```bash
npm install -g firebase-tools
```

2. **Login:**
```bash
firebase login
```

3. **Initialize:**
```bash
firebase init hosting
```

Answers:
- Use existing project? **Create new project** (or choose existing)
- What do you want to use as your public directory? **build/web**
- Configure as single-page app? **Yes**
- Set up automatic builds? **No**
- File build/web/index.html already exists. Overwrite? **No**

4. **Deploy:**
```bash
firebase deploy --only hosting
```

5. Copy the hosting URL (e.g., `https://cordly-xxx.web.app`)

#### 2.4 Deploy to Vercel (Option 2)

1. **Navigate to client build output:**
```bash
cd build/web
```

2. **Create vercel.json in build/web:**

Create `build/web/vercel.json`:
```json
{
  "routes": [
    { "handle": "filesystem" },
    { "src": "/.*", "dest": "/index.html" }
  ]
}
```

3. **Deploy:**
```bash
vercel --prod
```

---

### Step 3: Update CORS Settings

After deploying the Flutter web app:

1. Go to Vercel Dashboard → Your Backend Project
2. Go to **Settings** → **Environment Variables**
3. Edit `CORS_ORIGIN`
4. Change from `*` to: `https://your-flutter-app-url.vercel.app`
5. Redeploy backend:
```bash
vercel --prod
```

---

## 🔧 **TROUBLESHOOTING**

### Backend Issues

**Problem: "Cannot find module 'express'"**
- Solution: Run `npm install` in `/backend`

**Problem: "Supabase not configured"**
- Solution: Check `.env` file exists and has correct values

**Problem: Port 3000 already in use**
- Solution: Change PORT in `.env` to 3001 or kill the process using port 3000

### Flutter Issues

**Problem: "flutter: command not found"**
- Solution: Add Flutter to PATH or use full path to flutter executable

**Problem: "database.g.dart not found"**
- Solution: Run `dart run build_runner build --delete-conflicting-outputs`

**Problem: "SUPABASE_URL is empty"**
- Solution: Pass `--dart-define` arguments when running

**Problem: White screen on web**
- Check browser console (F12) for errors
- Ensure canvaskit/wasm files are loaded correctly

### Deployment Issues

**Problem: Vercel build fails**
- Check Node.js version matches (18.x)
- Ensure all dependencies are in `package.json`, not `devDependencies` if needed at runtime

**Problem: CORS errors in production**
- Update `CORS_ORIGIN` environment variable
- Redeploy backend after changing env vars

---

## 📊 **PRODUCTION CHECKLIST**

Before going live:

- [ ] Database migrations run successfully
- [ ] RLS policies enabled and tested
- [ ] Backend environment variables set in Vercel
- [ ] Backend deploys without errors
- [ ] Flutter web builds successfully
- [ ] Frontend can connect to backend API
- [ ] Authentication works (signup/login)
- [ ] CORS configured correctly
- [ ] Gemini API key has sufficient quota
- [ ] Supabase project is on correct billing plan
- [ ] Custom domain configured (optional)

---

## 🎯 **NEXT STEPS AFTER DEPLOYMENT**

1. **Custom Domain:**
   - Add your domain in Vercel Dashboard
   - Update DNS records
   - Update CORS_ORIGIN with new domain

2. **Monitoring:**
   - Check Vercel logs for errors
   - Monitor Supabase usage
   - Set up alerts for API errors

3. **Backups:**
   - Enable automatic backups in Supabase (paid feature)
   - Export SQL regularly for safety

4. **Performance:**
   - Enable caching in Vercel
   - Optimize images and assets
   - Monitor API response times

---

## 📞 **SUPPORT**

If you run into issues:

1. Check browser console (F12) for errors
2. Check Vercel logs: `vercel logs`
3. Check Supabase logs in dashboard
4. Verify all environment variables are set correctly

---

**You're all set! 🚀 Your CORDLY app is now live and ready to use.**
