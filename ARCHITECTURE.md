# ClientBook AI — Milestone 1: Architecture, Database, Auth, UI Shell

## 1. Core Design Rule (drives everything below)

**Data ownership is per sales executive, not per store.**
A customer record is not "a store's customer" — it is "Prince's customer for the store he works at."
Every table that holds customer-linked data carries `sales_executive_id`, and every backend query
filters by `sales_executive_id = current_user.id` for SALES_EXEC-role tokens. Managers and Admins
get a **separate, read-only reporting path** that aggregates but never opens a customer's private
notes/timeline (per your "managers can view reports but cannot modify personal notes" rule — we go
further and make it structurally impossible for a manager token to hit the personal-notes endpoints
at all, not just hidden in the UI).

## 2. Tech Stack (as specified)

| Layer | Choice |
|---|---|
| Mobile | Flutter (Android + iOS), offline-first via local SQLite cache + sync queue |
| Backend | Node.js + NestJS (modular monolith to start; module boundaries are drawn so any module can later split into a microservice) |
| DB | PostgreSQL (Prisma ORM for schema/migrations/type-safety) |
| Cache/Queue | Redis (session blacklist, rate limiting, WhatsApp/reminder job queues via BullMQ) |
| Auth | JWT (access + refresh), role guards, per-sales-executive row-level scoping |
| API | REST, versioned `/api/v1/...` |

## 3. High-Level Module Map

```
                        ┌───────────────────────────┐
                        │        Mobile App          │
                        │  (Flutter, role-aware)     │
                        │  ┌─────────────┐┌─────────┐│
                        │  │ Sales Exec  ││ Manager ││
                        │  │   Shell     ││  Shell  ││
                        │  └─────────────┘└─────────┘│
                        └──────────────┬─────────────┘
                                       │ REST + JWT
                        ┌──────────────▼─────────────┐
                        │        NestJS API           │
                        │ ┌─────────┐ ┌─────────────┐ │
Milestone 1 →           │ │  Auth   │ │   Users     │ │
                        │ └─────────┘ └─────────────┘ │
Milestone 2 →           │ ┌─────────┐ ┌─────────────┐ │
                        │ │Customers│ │  Timeline   │ │
                        │ └─────────┘ └─────────────┘ │
Milestone 3 →           │ ┌─────────┐ ┌─────────────┐ │
                        │ │Follow-up│ │  Wishlist   │ │
                        │ └─────────┘ └─────────────┘ │
Milestone 4 →           │ ┌─────────┐                │
                        │ │WhatsApp │                │
                        │ └─────────┘                │
Milestone 5 →           │ ┌─────────┐                │
                        │ │ Calling │                │
                        │ └─────────┘                │
Milestone 6 →           │ ┌─────────┐                │
                        │ │   POS   │                │
                        │ │  Sync   │                │
                        │ └─────────┘                │
                        └──────────────┬─────────────┘
                                       │
                      ┌────────────────┼────────────────┐
                      ▼                ▼                ▼
                 PostgreSQL          Redis          POS Systems
                 (source of      (cache, queue,    (import only,
                  truth)          rate limit)       never write-back)
```

## 4. Role Model

- `SALES_EXEC` — owns customers assigned to them by POS import (by `created_by_sales_exec` on the invoice). Full CRUD on their own notes/timeline/follow-ups/wishlist. Zero visibility into other reps' customers, enforced at the repository/query layer.
- `STORE_MANAGER` — read-only aggregate reports for their store (sales, conversion, retention). Cannot open, edit, or export any individual customer's private notes/timeline/voice notes.
- `ADMIN` — system configuration, user provisioning, POS integration settings, org-wide reports. Same restriction: no access to individual private notes.

This is enforced two ways, not one:
1. **API layer** — `RolesGuard` + `OwnershipGuard` reject any request where the JWT's role/id doesn't match the resource's owner.
2. **Query layer** — every Prisma query for customer-linked tables is wrapped in a scoping helper that injects `WHERE sales_executive_id = :currentUserId`, so a bug in a controller can't accidentally leak another rep's data.

## 5. Milestone 1 Deliverables (this drop)

- `backend/prisma/schema.prisma` — full data model for Users, Stores, Customers, and the scaffolding Milestones 2–6 will build on (tables are defined now so migrations don't churn later, but only Auth/Users endpoints are implemented this milestone).
- `backend/src/auth/*` — JWT auth (login, refresh, guards, role decorator) for all three login types.
- `backend/src/users/*` — user profile module (self + admin-managed).
- `mobile/lib/core/*` — Flutter app shell, theme (light/dark), API client with token refresh interceptor.
- `mobile/lib/features/auth/*` — the three login screens (Sales Executive / Store Manager / Admin) wired to the auth API.

Everything else in the spec (Customer Module, Follow-up, WhatsApp, Calling, POS) is deliberately **not** touched yet — their tables exist in the schema so foreign keys are stable, but no endpoints/screens for them ship until their milestone.

## 6. Milestone 2 Deliverables (delivered)

- `backend/src/common/repositories/ownership.util.ts` — Layer 2 of the ownership
  rule: every Customer-linked query is forced through `ownedBy()`/`assertOwnsRecord()`,
  so no controller bug can leak another rep's rows even with a correct role.
- `backend/src/customers/*` — `GET /customers` (filterable: status, recency
  window, birthday/anniversary this month, wishlist, free-text search),
  `GET /customers/:id`, `GET /customers/:id/timeline`, `POST /customers/:id/notes`,
  `GET /customers/today-highlights`. All `SALES_EXEC`-only.
- `mobile/lib/features/customers/*` — My Customers list (search bar + filter
  chips for VIP/Regular/Inactive/Lost, 30/60/90 days, birthday, anniversary,
  wishlist), Customer Detail screen (profile stats grid + full timeline feed),
  add-note bottom sheet. Wired into the Sales Exec shell's first tab.

**Known follow-up item flagged in code:** the birthday/anniversary month
filters currently compare against this calendar year's date rather than
day-of-month across years — noted inline in `customers.service.ts` for a
`$queryRaw` fix during hardening; the API contract (query params, response
shape) won't change when that lands.

## 7. Milestone 3 Deliverables (delivered)

- `backend/prisma/schema.prisma` — `FollowUp` is now a live table.
  `FollowUpStatus` (PENDING/COMPLETED/RESCHEDULED/CANCELLED),
  `FollowUpType` (CALL/WHATSAPP/VISIT), and `FollowUpPriority`
  (LOW/MEDIUM/HIGH) replace the earlier placeholder status enum. "Missed"
  is deliberately **not** a stored status — it's derived as
  `status = PENDING AND reminderAt < now` so overdue follow-ups don't
  depend on a background job to flip a column.
- `backend/src/followups/*` — `POST /followups`, `GET /followups`
  (filterable: due bucket [today/tomorrow/thisWeek/overdue], status,
  priority, type, missed, customerId), `GET /followups/:id`,
  `PATCH /followups/:id` (edit/reschedule/cancel), `POST /followups/:id/complete`,
  `DELETE /followups/:id`, `GET /followups/dashboard-summary`. All
  `SALES_EXEC`-only, all routed through `ownedBy()`/`assertOwnsRecord()` —
  same Layer 2 ownership pattern as Customers.
- **Timeline integration**: creating a follow-up writes a `REMINDER`
  Interaction; completing one writes a second Interaction whose type
  mirrors the follow-up's type (CALL/WHATSAPP/VISIT) — enforced inside
  `FollowUpsService.complete()` in a single `$transaction` so the follow-up
  row and its Timeline entry can never drift apart.
- `mobile/lib/features/followups/*` — Follow-up list (due/status/priority
  filter chips), Create/Edit Follow-up screen, Calendar view, Timeline
  already renders Reminder/Call/WhatsApp/Visit entries (Milestone 2 UI,
  unchanged). Local reminder notifications via `flutter_local_notifications`
  (`mobile/lib/core/notifications/*`) — push delivery is stubbed for the
  Milestone 4/5 WhatsApp/Calling backends to fill in.
- Sales Exec shell's "Tasks" tab (previously a placeholder) now renders the
  Follow-up dashboard + list.
- Customer Detail screen gained an "Add Follow-up" action and an upcoming
  follow-ups section, scoped to that customer via the existing
  `assertOwnsRecord` check.

**Migration note:** this drop ships `schema.prisma` changes only; no
`prisma/migrations/*` folder existed in the repo before this milestone
(Milestone 1/2 shipped schema-only, migration-free). Run
`npx prisma migrate dev --name milestone3_followups` against your dev
database to generate and apply the first migration.

## 8. Next Milestones (unchanged from your list)

4. WhatsApp (Business API integration, personalized bulk send, history)
5. Calling (virtual number provisioning, call logging, recording attach)
6. POS Integration (customer/invoice/product/visit auto-import, no manual entry)
7. Testing & Deployment
