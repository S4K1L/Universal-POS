# Universal POS

One point-of-sale for every kind of shop in Bangladesh — supershop, local grocery, cosmetics, furniture showroom, pharmacy.
It works with **no internet** and syncs on its own when the connection returns. The platform owner sets the
**subscription prices and limits from an admin dashboard**.

| | |
|---|---|
| [Universal-POS-Backend](https://github.com/S4K1L/Universal-POS-Backend) | FastAPI · SQLAlchemy 2 (async) · PostgreSQL · Alembic — 116 endpoints, 302 tests (separate repository) |
| this repository | Flutter (web, macOS, Windows, Android, iOS) — Riverpod · go_router · Drift (SQLite) — 350+ tests |
| `docs/PLAN.md` | The product & architecture plan this was built from |
| `docs/ARCHITECTURE.md` | How it is actually built: sync protocol, pricing, subscriptions, business types |
| `docs/pricing_vectors.json` | 252 golden cases that the Python and Dart pricing code must both reproduce |

## The idea: a business type is data, not code

When a super admin adds a business they pick its **business type**. A type is a versioned template — capabilities,
extra product fields, stock/tax defaults, payment methods, terminology, theme — and the app reads it. Nothing in the code
branches on "pharmacy" or "furniture"; it branches on capabilities (`expiry_tracking`, `document_flow`, `fractional_qty` …).

| Type | What it switches on |
|---|---|
| Local shop | sell by weight, loose units, **baki** (customer due ledger), fast keypad |
| Supershop | barcode + scale labels, batches & expiry (FEFO), VAT per item, loyalty points, shifts |
| Cosmetics | variants (shade/size), batches & expiry, loyalty |
| Furniture | quotation → deposit → delivery → invoice, made-to-order notes, warranty, salesperson |
| Pharmacy | batches & expiry, generic name / strength / dosage form, prescription-only flag |

Access is the product of three gates: **Plan** (what the business bought) × **Capability** (what its type does) × **Role**
(owner, manager, cashier, salesperson, stock keeper, accountant — with per-user overrides).

## Run it

**Backend** lives in its own repository, [Universal-POS-Backend](https://github.com/S4K1L/Universal-POS-Backend) (Python 3.12+, PostgreSQL). Clone it, follow its README to migrate and seed the demo data, and start it on port 8000.

**App** (Flutter 3.47):

```bash
flutter pub get
flutter run -d chrome --dart-define=DEMO=true      # DEMO=true adds one-tap demo logins to the sign-in page
flutter build web --release --dart-define=DEMO=true
flutter test                                       # no server needed
```

The sign-in page has a server address (default `http://localhost:8000/api/v1`) — change it for a real deployment.

### Demo accounts (development only)

Password `demo12345` for all shops; the platform admin is `01700000000` / `admin12345`.

| Phone | Business | Type | Role |
|---|---|---|---|
| 01711000001 | Rahim General Store | local shop | owner |
| 01722000001 | Fresh Bazar Superstore | supershop | owner (`…02` manager, `…03`/`…04` cashiers) |
| 01733000001 | Glow & Co Beauty | cosmetics | owner |
| 01744000001 | Nakshi Furniture Showroom | furniture | owner (`…02` salesperson) |
| 01755000001 | Shefa Pharmacy | pharmacy | owner |
| 01700000000 | Platform console | — | super admin |

## Offline selling, in one paragraph

Every till keeps a local copy of the catalogue, customers and stock (SQLite, via Drift; WebAssembly on the web). Selling never
waits for the network: a sale is priced on the device, given a till-local invoice number (`INV-K7Q2-000042`), stored, and put
in an **outbox**. A background sync pushes the outbox to `POST /sync/push` — every event has a client-generated UUIDv7 so a
retry can never double-post — and pulls changes from `GET /sync/pull?cursor=…`. The beacon in the top bar says
*online / syncing / offline / needs attention*. Details in [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Subscriptions, set from the admin dashboard

*Platform console → Plans* edits, live: monthly and yearly price, free-trial days, limits (branches, tills, staff, products)
and which features each plan includes. Businesses pay by **bKash / Nagad / Rocket / Upay / bank transfer / Bangla QR** into
accounts the admin lists under *Payments*, then submit the transaction ID. The request is priced on the server and frozen;
**only an admin's approval moves a subscription**. A grace period (platform setting) follows expiry; after it the till is
read-only for writes but sells offline until its cached subscription lapses, and everything already sold still syncs.

## Bangla

Full Bangla UI (language toggle in the top bar and Settings), Bangla digits, ৳ with lakh/crore grouping (12,34,567.50),
bundled Bangla fonts, per-business-type Bangla field labels. `test/i18n_test.dart` fails if any UI string lacks a translation.

## What is not built yet

Be aware before relying on it — these were in the plan and are **not** implemented:

- Promotions, bundles/kits, serial-number tracking, multiple stock locations, instalment plans (shown as "coming soon" capabilities)
- ESC/POS thermal-printer raw printing (receipts print through the system print dialog / PDF), camera barcode scanning (USB/Bluetooth scanners work as keyboard input)
- Offline PIN login (a till needs one online sign-in after it is registered; after that it keeps selling offline)
- Custom role editor (roles are fixed, per-user permission overrides are supported)
- Admin "log in as" support sessions exist in the API but have no UI
- Payment-gateway automation: bKash/Nagad payments are verified by a person comparing the transaction ID with the statement
- macOS/Windows/Android/iOS release builds are not configured or tested here (web is); macOS needs the network-client entitlement

Plan prices and the payment-account numbers in the seed are **placeholders** — set real ones in the admin console.

## Production checklist

- `ENV=production`, a random `JWT_SECRET_KEY` (≥ 32 chars) and explicit `CORS_ORIGINS` — the app refuses to boot otherwise
- `SEED_ADMIN_PASSWORD` set before the first `seed_platform` run; change it after first login
- PostgreSQL with the `pg_trgm` extension available (the migration creates it)
- Terminate TLS in front of the API; the Flutter web build is static files
