# ClientBook AI

Personal CRM for retail sales executives — NestJS + Prisma + PostgreSQL backend,
Flutter mobile app. This drop covers Milestones 1–3 (Auth, Customer Module,
Follow-up Module). See `ARCHITECTURE.md` for the full design rationale.

## Repo layout

```
backend/   NestJS API (Auth, Users, Customers, Follow-ups) + Prisma schema
mobile/    Flutter app source (lib/) — role-based shells, My Customers, Tasks
```

## 1. Backend — run with Docker (fastest path)

```bash
docker compose up --build
```

This starts Postgres, Redis, and the API, runs `prisma migrate deploy` and the
demo seed automatically, and serves the API at `http://localhost:3000`.

Demo accounts created by the seed (all share one password):

| Role          | Email                   | Password       |
|---------------|-------------------------|----------------|
| Sales Exec    | sales@clientbook.ai     | Password123!   |
| Store Manager | manager@clientbook.ai   | Password123!   |
| Admin         | admin@clientbook.ai     | Password123!   |

## 2. Backend — run locally without Docker

Requires Node 20+, a local PostgreSQL instance, and a local Redis instance.

```bash
cd backend
npm install
cp .env.example .env        # edit DATABASE_URL/REDIS_URL if not using the defaults
npx prisma migrate dev      # creates the schema
npm run prisma:seed         # creates demo Store/Users/Customer/FollowUp rows
npm run start:dev           # http://localhost:3000
```

A ready-to-use `.env` (matching `docker-compose.yml`'s Postgres/Redis credentials)
is already included for local dev — replace `JWT_SECRET` before deploying
anywhere real. It defines `DATABASE_URL`, `JWT_SECRET`, `PORT`, and
`REDIS_URL`. A duplicate copy also lives at `backend/prisma/.env` so
`prisma` CLI commands find it regardless of which directory they're invoked
from. **`backend/.env` is intentionally tracked (not gitignored)** — this is
a dev/demo project meant to run immediately after clone with zero manual
setup; swap in real secrets before using this as a template for production.

### Verifying it's healthy

```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"sales@clientbook.ai","password":"Password123!"}'
```

You should get back `accessToken`, `refreshToken`, and a `user` object. Use the
`accessToken` as a `Bearer` token against `/api/v1/customers` and
`/api/v1/followups`.

## 3. Mobile app

The Flutter **source** (`lib/`, `pubspec.yaml`) is complete for Milestones 1–3,
but this drop does not include the generated native `android/`/`ios/` project
folders (Flutter regenerates these from a template — they aren't meant to be
hand-maintained or committed by feature work). Before the app can be built or
run, generate them once:

```bash
cd mobile
flutter create . --project-name clientbook_ai --org com.clientbook   # adds android/ ios/ etc. only; does not touch lib/ or pubspec.yaml
flutter pub get
flutter run
```

By default `main.dart` points at `https://api.clientbook.ai`. For local
development against the backend above, change the `baseUrl` passed to
`ApiClient(...)` in `mobile/lib/main.dart` to:
- `http://10.0.2.2:3000` — Android emulator
- `http://localhost:3000` — iOS simulator

## 4. What's implemented so far

- **Milestone 1** — JWT auth (access + rotating refresh tokens), role guards
  (`SALES_EXEC` / `STORE_MANAGER` / `ADMIN`), portal-based login + role-based
  mobile shells.
- **Milestone 2** — Customer Module: "My Customers" list with filter chips
  (status, recency, birthday/anniversary, wishlist, search), customer detail +
  timeline, notes.
- **Milestone 3** — Follow-up Module: create/edit/complete/delete, due-date
  and priority filters, dashboard summary cards, list/calendar toggle, local
  reminder notifications.

Every Customer/Follow-up endpoint is scoped to the requesting sales executive
at the query layer (`common/repositories/ownership.util.ts`) — a rep can never
read or write another rep's rows, and Managers/Admins have no route into this
data at all (see `ARCHITECTURE.md` §1, §4).

## 5. Production notes

- `bcryptjs` (pure JS) is used instead of native `bcrypt` so the backend
  installs and builds without a C++ toolchain — this matters for CI images
  and any environment without native build tooling.
- `ThrottlerGuard` is registered globally (`app.module.ts`) so the `@Throttle`
  decorator on `POST /auth/login` actually enforces its limit.
- `docker-compose.yml` builds the backend from `backend/Dockerfile`
  (multi-stage: Prisma-generate + `nest build` in the builder stage, a slim
  runtime image in the final stage).
