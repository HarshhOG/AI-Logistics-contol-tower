# Deployment Guide: Vercel & Supabase

This guide walks you through deploying the **AI Logistics Control Tower** to **Vercel** (frontend & serverless APIs) and **Supabase** (managed PostgreSQL database).

---

## Architecture Overview

```
                                      ┌────────────────────────────────────────────────┐
                                      │              VERCEL (Edge & Serverless)        │
                                      │                                                │
[ Browser / Transport Dispatcher ] ───┼─► Static CDN ────────► React 19 + Three.js UI  │
                                      │                         (frontend/dist)        │
                                      │                                                │
                                      │─► /api/* ─────────────► Python FastAPI ASGI    │
                                      │                         (api/index.py)         │
                                      └───────────────────────┬────────────────────────┘
                                                              │
                                                              ▼ (SSL Encrypted Connection)
                                      ┌────────────────────────────────────────────────┐
                                      │              SUPABASE (Cloud PostgreSQL)       │
                                      │                                                │
                                      │  • PostgreSQL 15+ Schema (9 Relational Tables)  │
                                      │  • Connection Pooler (PgBouncer, Port 6543)     │
                                      │  • Real-time Subscriptions (Optional)          │
                                      │  • Row-Level Security (RLS) Enabled            │
                                      └────────────────────────────────────────────────┘
```

---

## Step 1: Set Up Supabase Database

1. Sign in or create a project at **[supabase.com](https://supabase.com)**.
2. Select your preferred AWS / GCP region (e.g. `ap-south-1` for India / Mumbai if serving Indian logistics).
3. Once the database is ready:
   - Navigate to **SQL Editor** in the left sidebar.
   - Click **New query**.
   - Open and copy the contents of [`supabase/schema.sql`](file:///e:/Sugar%20Spot/Planning%20tool/supabase/schema.sql).
   - Paste the SQL into the editor and click **Run**.
   - This creates all 9 tables (`users`, `trips`, `location_updates`, `sla_evaluations`, `delivery_forecasts`, `exceptions`, `import_jobs`, `api_sync_logs`, `audit_events`), indexes, and RLS policies.
4. Retrieve your database credentials:
   - Go to **Project Settings** (gear icon) ➔ **Database**.
   - Under **Connection String**, select the **URI** tab.
   - Choose **Connection Pooling** (recommended for Vercel serverless, port `6543`, Transaction mode) or **Direct** (port `5432`).
   - Copy the string and replace `[YOUR-PASSWORD]` with your database password:
     ```
     postgresql://postgres.[YOUR-PROJECT-REF]:[YOUR-PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres?sslmode=require
     ```
   - Go to **Project Settings** ➔ **API** and copy:
     - `Project URL` (e.g. `https://xyzcompany.supabase.co`)
     - `anon public key` (`eyJhbGciOi...`)

---

## Step 2: Deploy to Vercel

### Option A: Via GitHub (Recommended)

1. Push your repository to GitHub, GitLab, or Bitbucket.
2. In the **[Vercel Dashboard](https://vercel.com/dashboard)**, click **Add New...** ➔ **Project**.
3. Import your repository.
4. Vercel automatically detects the project settings from `vercel.json`:
   - **Framework Preset**: `Vite`
   - **Build Command**: `cd frontend && pnpm run build` (or `npm run build`)
   - **Output Directory**: `frontend/dist`
5. Under **Environment Variables**, add the following:

| Variable Name | Recommended Value | Description |
| :--- | :--- | :--- |
| **`DATABASE_URL`** | `postgresql://postgres.[ref]:[pass]@aws-0-[region].pooler.supabase.com:6543/postgres?sslmode=require` | Supabase PostgreSQL Connection String |
| **`SUPABASE_URL`** | `https://[YOUR-PROJECT-REF].supabase.co` | Supabase API URL |
| **`SUPABASE_ANON_KEY`** | `eyJhbGciOi...` | Supabase Public Anon Key |
| **`VITE_SUPABASE_URL`** | `https://[YOUR-PROJECT-REF].supabase.co` | Exposed to Vite React client |
| **`VITE_SUPABASE_ANON_KEY`** | `eyJhbGciOi...` | Exposed to Vite React client |
| **`VITE_API_URL`** | `/api` | Relative API path (avoids CORS) |

6. Click **Deploy**. Vercel will bundle the frontend into high-speed Edge CDN assets and compile the Python serverless function in `api/index.py`.

---

### Option B: Via Vercel CLI

```bash
# 1. Install Vercel CLI if not already installed
npm install -g vercel

# 2. Login to Vercel
vercel login

# 3. Deploy preview
vercel

# 4. Set Environment Variables
vercel env add DATABASE_URL
vercel env add VITE_SUPABASE_URL
vercel env add VITE_SUPABASE_ANON_KEY

# 5. Deploy production
vercel --prod
```

---

## Step 3: Verification & Diagnostics

Once deployed, verify that the services are communicating properly:

1. **System Health Check**:
   Open:
   ```
   https://[YOUR-VERCEL-DOMAIN].vercel.app/health
   ```
   Or:
   ```
   https://[YOUR-VERCEL-DOMAIN].vercel.app/api/health
   ```
   Expected response:
   ```json
   {
     "status": "healthy",
     "app": "AI Logistics Control Tower",
     "version": "1.0.0",
     "environment": "production-ready"
   }
   ```

2. **API Endpoint Verification**:
   Open:
   ```
   https://[YOUR-VERCEL-DOMAIN].vercel.app/api/trips
   ```
   Should return the active fleet consignments. If starting with an empty Supabase database, the application automatically seeds the 8 initial Indian freight corridor benchmark trips.

3. **Frontend Application**:
   Open:
   ```
   https://[YOUR-VERCEL-DOMAIN].vercel.app
   ```
   - Explore the **3D Cinematic Digital Twin** with orbital controls and highway particle energy flows.
   - Test **Manual Location Updates** via OpenStreetMap geocoding search and interactive pin drop.
   - Run **Grounded AI Queries** in the Operations Assistant.

---

## Troubleshooting: "No FastAPI entrypoint found"

If Vercel logs the error:
`No FastAPI entrypoint found. Set "tool.vercel.entrypoint" in pyproject.toml or define an entrypoint in one of: app.py, index.py, server.py, main.py...`

This repository includes the complete resolution:
1. **`pyproject.toml`** at repo root explicitly registers:
   ```toml
   [tool.vercel]
   entrypoint = "index.py"
   ```
2. **`index.py` & `main.py`** at repo root expose the FastAPI application:
   ```python
   from fastapi import FastAPI
   from backend.app.main import app
   application = app
   ```
3. **`api/index.py`** provides the ASGI handler for serverless routing:
   ```python
   from fastapi import FastAPI
   from backend.app.main import app
   application = app
   ```
4. **`backend/app/main.py`** automatically adds the backend directory to `sys.path` so module imports (`from app...`) work under Vercel's runtime regardless of working directory.

If importing into Vercel manually:
- Set **Framework Preset** to **Other** (or **Vite**).
- Ensure Root Directory is `./` (repository root).
- Ensure your environment variables (`DATABASE_URL`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `VITE_API_URL`) are populated.

---

## Local Development vs. Production (Dual Engine Mode)

The codebase has built-in database auto-detection:

- **When `DATABASE_URL` is set** (Production on Vercel or local `.env`):
  `backend/app/core/database.py` connects to **Supabase PostgreSQL** via `psycopg2-binary` with SSL pooling and dictionary cursor mapping.
- **When `DATABASE_URL` is omitted** (Local Offline Dev / Automated Tests):
  The app gracefully falls back to local SQLite (`backend/logistics_control_tower.db`). The complete test suite (`pytest backend/tests`) runs out-of-the-box without requiring live cloud credentials.
