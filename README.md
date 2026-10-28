# AI Logistics Control Tower

Enterprise-grade operations command centre built for transport managers, dispatchers, logistics analysts, and operations executives. Provides continuous visibility, deterministic SLA tracking, manual and GPS location synchronization, road-network arrival forecasting, 3D cinematic digital twin corridors, and evidence-grounded customer replanning.

**Ready for deployment to Vercel (Edge UI + Python Serverless API) and Supabase (Cloud PostgreSQL).**

---

## 1. System Architecture

```
                                  [ Web Browser / Command Centre UI ]
                                                    │
                        ┌───────────────────────────┴───────────────────────────┐
                        ▼                                                       ▼
            [ React 19 + TypeScript ]                               [ 3D Cinematic & 2D Tactical ]
            - 70% Neutral Light Surfaces                            - Three.js 3D Corridor Digital Twin
            - 20% Navy Brand Anchors                                - Highway Splines & Energy Flows
            - High-Density Trip Ledger                              - Leaflet GPS vs. Manual Markers
            - Replanning Authorization Modal                        - Visual Freshness Degradation
                        │                                                       │
                        └───────────────────────────┬───────────────────────────┘
                                                    │  REST API (/api)
                                                    ▼
                                          [ FastAPI Application ]
                                        (Vercel Python Serverless)
                        ┌───────────────────────────┼───────────────────────────┐
                        ▼                           ▼                           ▼
             [ SLA Calculation Engine ]   [ Forecasting Engine ]      [ Geocoding & Routing ]
             - Loading SLA (<14:00 vs)    - 38 km/h Highway Model     - NH48 / NH44 Corridors
             - Transit (400km / 24h)      - Statutory Driver Rest     - Nominatim Fallback
             - Unloading SLA (<16:00)     - Replanning Decisions      - Waypoint Interpolator
                        │                           │                           │
                        └───────────────────────────┼───────────────────────────┘
                                                    ▼
                                   [ Dual-Engine Database Layer ]
                         • Supabase PostgreSQL 15+ (Production / Cloud)
                         • SQLite with WAL mode (Local Fallback & Testing)
```

---

## 2. Deploying to Vercel & Supabase

Full step-by-step instructions are documented in [`DEPLOYMENT.md`](file:///e:/Sugar%20Spot/Planning%20tool/DEPLOYMENT.md).

### Quick Setup:

1. **Supabase Setup**:
   - Create a project on [supabase.com](https://supabase.com).
   - In **SQL Editor**, run [`supabase/schema.sql`](file:///e:/Sugar%20Spot/Planning%20tool/supabase/schema.sql) to provision all 9 relational tables, indexes, and RLS policies.
   - Copy your PostgreSQL connection string from **Project Settings -> Database -> Connection String**.
2. **Vercel Deployment**:
   - Push this repo to GitHub and import it into [Vercel](https://vercel.com).
   - Set environment variables in Vercel:
     - `DATABASE_URL`: Your Supabase PostgreSQL Connection String (port 6543 pooler or port 5432)
     - `SUPABASE_URL`: `https://[YOUR-PROJECT-REF].supabase.co`
     - `SUPABASE_ANON_KEY`: `eyJhbGciOi...`
     - `VITE_SUPABASE_URL`: `https://[YOUR-PROJECT-REF].supabase.co`
     - `VITE_SUPABASE_ANON_KEY`: `eyJhbGciOi...`
     - `VITE_API_URL`: `/api`
   - Click **Deploy**!

---

## 3. Key Operational Capabilities

### Deterministic SLA Engine
- **Loading SLA**: If trip starts `< 14:00`, dispatch required same calendar day (`23:59:59`). If start `>= 14:00`, dispatch required within `24 hours`. Exactly `14:00:00` boundary tested.
- **Transit SLA**: `CEILING(elapsed transit hours / 24) * 400 km`. Evaluates distance covered and calculates shortfall.
- **Unloading SLA**: If vehicle reaches destination `< 16:00`, same day completion (`23:59:59`). If `>= 16:00`, next day completion.
- **Unit Test Coverage**: 100% verified boundary test suite in `backend/tests/test_sla.py`.

### Manual Location Workflow (Critical Feature)
For vehicles without continuous GPS:
1. Search real checkpoints (e.g. *Hubballi Toll Plaza, Karnataka*, *NH48 near Tumakuru*, *Bhiwandi Logistics Park*).
2. Autocomplete suggestions with place name, address, and coordinates.
3. Interactive map preview with click-to-pin and draggable verification.
4. Collects reported time, odometer reading, verification reason, and remarks.
5. Saves an immutable audit record in `location_updates` (does not erase historical positions).
6. Instantly recalculates road distance, remaining km, transit progress, SLA, and arrival forecast.

### Delivery Forecasting & Replanning Hub
- Computes realistic commercial transit time:
  $$\text{Transit Hours} = \frac{\text{Remaining Road KM}}{38\text{ km/h}} + \text{Statutory Rest (8h per 10h drive)} + \text{Buffers (2h)}$$
- Detects projected delays against scheduled delivery commitment.
- Recommends realistic revised delivery window.
- Demands authorization approval before updating customer commitment.
- Reduces confidence score on stale locations ($> 12\text{ hours}$).

### Guided Ingestion Wizard
- Supports `.xlsx`, `.xls`, and `.csv`.
- Previews first 5 rows and automatically maps source headers to standard domain fields.
- Validates duplicate IDs, negative distances, and missing coordinates.
- Displays comprehensive import summary.

### Grounded AI Operations Assistant
- Natural language query responder grounded in live database metrics.
- Returns structured responses:
  1. Conclusion
  2. Supporting Evidence
  3. Calculation or Rule Applied
  4. Missing Information / Uncertainty
  5. Confidence Level
  6. Recommended Next Action & Owner

---

## 4. Design System & Palette

- **`surface-50` (`#F8FAFC`)**: 70% Neutral light canvas for maximum readability during long dispatch shifts.
- **`surface-0` (`#FFFFFF`)**: Pure white cards, dense operational tables, slideout drawers.
- **`brand-900` (`#101828`)**: 20% Navy persistent navigation and brand structure.
- **`brand-700` (`#344054`)**: Secondary structural chrome and active indicators.
- **`accent-500` (`#14B8A6`)**: Primary operational accent (corridor glows, active tracking).
- **`action-600` (`#2563EB`)**: Action buttons (Import, Confirm, Reschedule).
- **Semantic Status**:
  - `success-600` (`#16A34A`): SLA Met, on track
  - `warning-600` (`#D97706`): Ageing telemetry (4–12h), replanning proposal
  - `danger-600` (`#DC2626`): Breached SLA, stale telemetry (>12h)
- **Wallboard Mode**: Dedicated dark monitoring toggle for wallboard control-room displays.

---

## 5. Running Locally & Testing

### Run Development Server
```bash
# Start backend (auto-falls back to SQLite when DATABASE_URL is not set)
python -m uvicorn app.main:app --app-dir backend --host 127.0.0.1 --port 8000 --reload

# Start frontend
cd frontend
pnpm run dev
```

### Run Backend Test Suite
```bash
pytest backend/tests -v
```
All 19 tests in `backend/tests/` verify deterministic business logic, arrival forecasting, CSV ingestion, and SLA calculations.
