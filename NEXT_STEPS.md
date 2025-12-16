# CORDLY - Launch Instructions

Your project codebase is effectively complete. Follow these steps to launch the application.

## 1. Backend Setup

The backend handles API requests, AI integration, and Supabase connection.

1.  **Navigate to backend:**
    ```bash
    cd backend
    ```

2.  **Install Dependencies:**
    ```bash
    npm install
    ```
    *This will fix all the "Cannot find module" errors you might see in the editor.*

3.  **Configure Environment:**
    - Copy `.env.example` to `.env` if you haven't already.
    - Fill in your `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, and `GEMINI_API_KEY`.

4.  **Start Server:**
    ```bash
    npm run dev
    ```
    *Server will start on http://localhost:3000*

## 2. Flutter Client Setup

The client is the main application (Mobile + Web).

1.  **Navigate to client:**
    ```bash
    cd apps/client
    ```

2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Generate Database Code:**
    This is critical for Drift (local DB) to work.
    ```bash
    dart run build_runner build
    ```

4.  **Run the App:**
    ```bash
    flutter run -d chrome
    # OR
    flutter run -d windows
    ```

## 3. Supabase Setup

1.  **Create Project:** Go to [supabase.com](https://supabase.com) and create a new project.
2.  **Run SQL:** Open the **SQL Editor** in Supabase and run the scripts in your `database/` folder:
    - First: `database/schemas/001_core.sql`
    - Second: `database/policies/001_rls.sql`

## 4. Verification

- **Login:** Open the Flutter app. You should see the login screen.
- **Sign Up:** Use the "Create Account" button to creating a user in Supabase.
- **Home:** Once logged in, you should see the Home Dashboard.
- **Create Data:** Go to "Execute" tab and add a task. This will save to the local Drift database.

---
**Note:** You currently have a complete "Offline-First" architecture. Data saves locally immediately. The background sync logic is wired to a queue but requires a separate background service to be fully active. For now, enjoy instant local performance!
