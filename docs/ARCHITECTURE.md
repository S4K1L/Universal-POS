# Architecture — as built

This describes what is in the repository today. [`PLAN.md`](PLAN.md) is the original plan; where the two differ
(capabilities marked *planned*, listed in the README) this document wins.

```
 Flutter till (web / desktop / mobile)                        FastAPI + PostgreSQL
┌──────────────────────────────────────────┐              ┌───────────────────────────────┐
│ UI (Riverpod, go_router)                 │              │ /auth /tenants /products …    │
│   ↓ reads                    ↑ writes    │   online     │ /billing  /admin/*  /reports  │
│ Drift SQLite: catalogue · stock · sales  │─────────────▶│ /sync/push   (idempotent)     │
│              customers · OUTBOX          │◀─────────────│ /sync/pull?cursor (change log)│
│ SyncController (15 s tick + on-demand)   │              │ sync_changes log (per tenant) │
└──────────────────────────────────────────┘              └───────────────────────────────┘
```

## 1. Business types

`business_types` rows hold a JSON template: `capabilities[]`, `attributes[]` (extra product fields with Bangla labels),
`variant_axes[]`, `stock` defaults (costing, FEFO, negative stock), `units[]`, `tax` defaults, `payment_methods[]`,
`terminology` (what a "customer" is called), `theme`, and a starter catalogue. Creating a business **copies** the
template into the tenant's settings and records `template_version`; editing a type publishes a new version and the
admin can push it to a business (`apply-template`). Capability resolution:

```
effective = ((type ∪ enabled-for-this-business) − disabled) ∩ plan-allowed, closed over `requires`
```

The app builds its navigation from `context.modules` (each module is `available`, or locked with a reason —
`capability`, `plan`, `permission`), so a local shop never sees *Orders* or *Shifts*. `GET /tenants/me/context` is the single
source: user, permissions, capabilities, terminology, features, limits, payment methods, tax, subscription state.
It is cached on the device so a till can start offline.

## 2. Offline-first selling

**Local database** (Drift): products + variants + barcodes, stock balances (per branch), customers, categories, tax
classes, units, local sales and lines, and the outbox. The POS screen reads only from this database.

**Ids and numbers.** Every row a till creates gets a client UUIDv7. Invoice numbers are per till:
`INV-{deviceCode}-{seq}` (e.g. `INV-D01-000042`), so two offline tills can never collide. A till is registered once
(`POST /devices/register`) and receives its code.

**Outbox event types**: `sale.create`, `sale.return`, `sale.void`, `payment.receive`, `customer.upsert`,
`stock.adjust`, `expense.create`, `shift.open`, `shift.close`.

**Push** — `POST /sync/push {device_id, events[≤100]}`. Each event: `{id, type, occurred_at, actor_id, payload}`.
The server applies each in its own SAVEPOINT and answers per event:

| status | meaning | client does |
|---|---|---|
| `applied` | stored; result may carry `flags` | mark synced, store server invoice/ids |
| `duplicate` | this id was seen before (retry) | mark synced — the original result is returned |
| `rejected` | structurally unusable (`code`, `message`) | keep in outbox, show in Sync center for a human to retry or discard |

A till's **completed sale is a fact**: the server never refuses it for business reasons. Price changed at the till,
discount beyond the cashier's permission, stock shortfall, credit limit exceeded, wrong branch, total mismatch — the sale
is recorded and **flagged** (`Reports → Flagged sales`), because the customer has already walked out with the goods.
Network errors and 5xx keep events pending; 401 triggers one token refresh.

**Pull** — `GET /sync/pull?device_id&cursor&limit`. A SQLAlchemy flush hook writes one `sync_changes` row
(`seq`, `entity`, `id`, `op`, `data`) whenever a synced entity changes. The client applies changes in order and stores
the new cursor. Cursor `0` returns everything and the log is compacted to the latest row per entity. Stock rows are
scoped to the device's branch; `cost` is stripped unless the user has `view_cost`; the first sync of a new till is
marked `bootstrapped` so the UI can say "Loading your catalogue…".

**What the cashier sees.** Displayed stock = server snapshot − pending outbox deltas, so selling the last item offline
shows 0 immediately. The top-bar **beacon** shows online / syncing / offline / needs attention. A probe
(`GET /health`) decides reachability, so captive portals and dead Wi-Fi are caught; `connectivity_plus` triggers an
immediate sync when the link returns, and a 15 s tick covers everything else. *Settings → This device → Work offline*
forces offline mode for demos.

**Subscription while offline.** The context carries `valid_until` (end of period + grace). The till keeps selling
offline until that moment, then locks with "Connect once to unlock"; sales already made always sync.

## 3. Pricing — one algorithm, two implementations

Gross lines → per-line discount → net → bill discount pro-rated across lines → tax (inclusive or exclusive, per-item
rate) → cash rounding to the nearest taka (half-up) → total. Python (`app/services/pricing.py`, `Decimal`) and Dart
(`lib/core/money/pricing.dart`, integer paisa / milli-units) both replay `docs/pricing_vectors.json` — 252 cases,
generated by `backend/scripts/gen_pricing_vectors.py` — so an offline total always equals the server's total.
Money is integer paisa on the client and decimal strings on the wire.

## 4. Inventory

Append-only **stock ledger** (`stock_movements`: sale, purchase, return, adjust, void, opening) + `stock_balances`
(per branch × variant) + **lots** (`stock_lots`: lot no., expiry, remaining). With FEFO allocation a sale consumes the soonest-expiring
lot first and records the allocation per sale line, so a return puts stock back into the same lot. Expiry alerts use the
type's `expiry_alert_days`. Purchases update stock, weighted-average cost and the supplier balance together; supplier
payments are recorded against the purchase.

## 5. Customers and credit

`customer_ledger` rows (sale on credit, payment, return credit, adjustment, opening balance) give the running balance;
collections are applied to the oldest unpaid invoices first. Invariant enforced on every sale: **paid = Σ payments**,
the remainder is on account (needs a customer and the `customer_credit` capability).

## 6. Orders (furniture and other order-based types)

`quotation → confirmed (deposit ≥ type minimum %) → ready → delivered (invoice created from the order) / cancelled`.
Deposits are payments against the order; delivery takes the balance and creates a normal sale whose lines carry the
order's spec notes. Cancelling refunds deposits as recorded refunds.

## 7. Subscriptions

Tables: `plans` (price monthly/yearly, trial days, `features[]`, `limits{}`, capability allow-list, `active`,
`popular`), `payment_channels` (bKash/Nagad/Rocket/Upay/bank/Bangla QR: account, instructions), `payment_requests`,
`subscription_invoices`, `platform_settings` (`grace_days`, `maintenance`, `support`). Everything is edited in the admin console.

**Maintenance mode.** While `maintenance.enabled` is on, every business route answers `503 {"code": "maintenance", "detail": <admin message>}`;
auth, the console and `/public/*` stay open. The app learns of it two ways — `GET /public/status` (checked on launch, right
after sign-in, and polled every 60 s, or every 10 s while it is on) and any call that returns that 503 — and sends business
users to a full-screen maintenance page that lets go on its own. The super admin is never held there. An
*unreachable* server is never read as maintenance, so an offline till keeps selling; anything unsynced stays in the outbox.

States: `trialing → active → grace → expired`, plus `suspended` / `cancelled`.

| State | Reads | Writes (online) | Sync push | Till offline |
|---|---|---|---|---|
| trialing / active | ✓ | ✓ | ✓ | ✓ |
| grace | ✓ | ✓ (banner) | ✓ | ✓ |
| expired (lapsed) | ✓ | **402** except billing | ✓ | until `valid_until`, then locked |
| suspended | billing/context only | ✗ | ✓ | locked |

Renewal flow: business picks a plan and cycle → server **prices and freezes** the request → business pays into a listed
account and submits the transaction ID, sender number and note → admin sees it in *Payments*, compares with the statement,
**approves** (period extended, invoice issued, state recomputed) or **rejects with a reason** (business can resubmit).
The business's own claim is never trusted: the amount comes from the frozen price. Limits (branches, tills, staff,
products) and features are enforced server-side by the same plan record the admin edits.

## 8. Security notes

bcrypt password hashes; JWT access (60 min) + refresh tokens that rotate on use and can be revoked (tracked by `jti`); login rate limiting per phone;
tokens held in `flutter_secure_storage`; every state-changing admin action writes an `audit_log` row; `extra="forbid"`
request schemas; row access is always `tenant_id`-scoped through `tenant_ctx` (one dependency, one place);
cost prices are never sent to users without `view_cost`; production refuses to boot with the dev JWT secret or `*` CORS.

## 9. Where things are

```
backend/app/core/        config, money, ids (UUIDv7), security, capabilities, permissions
backend/app/models/      40 tables (platform, tenant, identity, catalogue, inventory, customers, sales, orders, sync)
backend/app/services/    pricing, sales, inventory, purchases, orders, sync, billing, subscription, reports, provisioning
backend/app/api/v1/      routers; admin/ holds the platform console API
backend/app/seeds/       business types, platform defaults, sample catalogues
app/lib/core/            theme tokens, money/pricing, i18n (bn.dart), UI kit
app/lib/data/            Drift database, repos, session, sync engine
app/lib/features/        auth, shell, dashboard, pos, sales, products, stock, purchases, customers, orders,
                         expenses, shifts, reports, settings, billing, sync, admin
```

## 10. Testing

| Suite | What it proves |
|---|---|
| `backend/tests` (302) | gates (plan × capability × role), pricing vectors, inventory/FEFO, sync idempotency and flags, billing flow, orders, provisioning |
| `app/test/pricing_test.dart` | Dart pricing reproduces all 252 vectors |
| `app/test/offline_flow_test.dart` | against the live API: sell offline → outbox → reconnect → server has it, once |
| `app/test/pos_flow_test.dart` | a cashier rings up, pays and receipts a sale with the connection down (phone and desktop) |
| `app/test/*_smoke_test.dart` | every screen at phone/tablet/desktop width against payloads captured from the real API — no overflow, no bad cast |
| `app/test/bangla_ui_test.dart`, `i18n_test.dart` | Bangla renders and fits; no untranslated string can ship |
