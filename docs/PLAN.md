# Universal POS — Product & Technical Plan

**Version** 0.1 (draft for review) · **Date** 2026-10-06
**Basis** Line-by-line audit of `S4K1L/PharmaCare` (Flutter) and `S4K1L/PharmaCare-Backend` (FastAPI)
**Working title** "Universal POS" (see open question on branding, §16)

---

## 0. Executive summary

PharmaCare is a **good platform wrapped around a pharmacy-shaped core**. About half of what it
contains (multi-tenancy, auth, plan/role gating, SaaS billing, branches, audit, super-admin
console) is business-agnostic and worth carrying over almost verbatim. The other half
(products with `generic_name`/`rx_only`, mandatory batch expiry, FEFO-only stock, `Patient`,
medicine master, pack/box hierarchy, integer quantities, a hard-coded nav and feature list) is
pharmacy logic baked into the schema and UI, and cannot simply be renamed.

**Recommendation**

1. **Build Universal POS as a new codebase**, porting the platform layer and rebuilding the
   catalogue / inventory / sales core. Don't refactor PharmaCare in place: 66 of 101 Flutter
   files (480 lines) and 256 backend lines mention pharmacy vocabulary (pharma / medicine /
   patient / prescription / generic / Rx / expiry — a rough grep, so an upper bound), and the
   changes needed (variants, stock ledger, Decimal money, fractional quantities) cut across
   most of them.
2. **Make "business type" data, not code.** A *Business Type* is a versioned template that
   bundles: **capabilities** (what the engine may do), **attribute definitions** (what extra
   fields a product has), stock rules, units, tax defaults, terminology, dashboard widgets,
   report packs and receipt layout. When a super admin adds a business, they pick a type and
   the platform provisions the tenant from that template. Inventory, add-product, POS and
   reports then adapt automatically.
3. **Evolve PharmaCare's best idea.** Its invariant is "two independent gates — plan and role —
   must both pass". Universal POS has **three**: *Plan* (what they paid for) × *Capability*
   (what their business type enables) × *Role* (what this user may do).
4. **Two sales flows cover all four target businesses**: *Counter retail* (Local shop,
   Supershop, Cosmetic — scan, pay, done) and *Order-based / high-ticket* (Furniture —
   quote → order with deposit → delivery → invoice). Pharmacy is just a counter-retail profile
   and doubles as the best regression test of the abstraction.
5. **Design for offline and scale from day one** (client-generated UUIDs, idempotency keys,
   delta-sync cursors, server-side search), even though offline mode ships in Phase 2. The
   current POS loads the whole catalogue into memory and needs the network for every sale.

Planning estimate: **MVP (3 business types, pilot-ready) ≈ 13 weeks; full scope ≈ 8–9 months**
for a team of 3–4 engineers (see §13; double the calendar time for a solo developer).

---

## 1. What PharmaCare gives us — audit findings

### 1.1 Snapshot

| | Backend | Frontend |
|---|---|---|
| Stack | FastAPI 0.115, SQLAlchemy 2 async + asyncpg, Alembic, PostgreSQL, JWT (python-jose), passlib/bcrypt | Flutter (Dart ^3.11), GetX, Dio, fl_chart, mobile_scanner, pdf/printing, qr_flutter |
| Size | ~6.6k LOC app, 2.3k LOC tests (12 test files), 11 migrations | ~31k LOC `lib/` (101 files), 12.7k LOC tests (49 test files) |
| Targets | No Dockerfile/compose; run with uvicorn; local-disk uploads | Android, Web, Windows |
| Docs | `docs/BACKEND_ARCHITECTURE.md` (1,065 lines, accurate and detailed) | README only |

The app has already rebranded to "Nexora POS" on the Flutter side (commit `cc190e8`), while the
backend still says PharmaCare.

### 1.2 KEEP — business-agnostic assets (port nearly verbatim)

| Asset | Where | Why it's worth keeping |
|---|---|---|
| Row-level multi-tenancy | `db/mixins.py` `TenantScopedMixin`; every query filtered by token's `tenant_id` | Simple, proven, matches scale target |
| Two-gate auth | `core/permissions.py`, `api/deps.py` (`require_permission`, `require_feature`) | Server-side enforcement; client checks are UX only |
| Per-user permission overrides | `User.permissions` JSONB; `null` = inherit, `[]` = revoked | The null-vs-empty distinction is load-bearing and well tested |
| Branch-restricted staff | `services/branch_access.py`, 404-not-403 for other branches' sales | Good security posture, already enforced server-side |
| Atomic per-tenant numbering | `services/numbering.py` (UPSERT…RETURNING) | Collision-free under concurrency |
| Stock locking | `stock.consume_fefo` uses `SELECT … FOR UPDATE` | Correct under concurrent checkout |
| Payments ledger invariant | `sales.paid == SUM(sale_payments)`; over-payment rejected, row locked | Exactly the right model; extend it |
| Returns capped at sold qty | `services/sales.create_return` | Server-side anti-over-refund |
| Server-side pricing | `checkout` recomputes totals from DB prices | Never trusts the cart |
| Deletion policy | `ON DELETE RESTRICT` + `active` flag | Financial records stay intact |
| Branches + branch stock + transfers | `models/transfer.py`, `services/transfers.py` | Multi-outlet is a selling point for every business type |
| SaaS billing | Manual payment channels (the latest migration `8afd66a047db` collapses wallet/bank kinds into **Bangla QR**), payment requests, approve/reject, `uq_payment_requests_live_txn` | Fits the target market; no gateway dependency |
| Super-admin console | Tenants, onboarding, impersonation (`impersonated_by` claim), announcements, audit log, **maintenance kill-switch** | Production-grade ops tooling already exists |
| Error contract | `{detail, code}` via `DomainError` handlers | Easy to map to UI messages |
| Flutter shell patterns | Responsive shell, mobile nav, locked-not-hidden nav items, shimmer, 80 mm receipt, PDF reports, QR labels, scanner (camera + keyboard-wedge) | Large amount of polished UI to reuse |
| Test culture | 49 Flutter + 12 backend test files incl. layout-overflow sweeps | Keep the habit; fix the tooling (§12) |

### 1.3 GENERALISE — pharmacy logic embedded in the core

| Today | Problem for a universal system | Becomes |
|---|---|---|
| `Tenant.pharmacy_name` | Naming | `tenants.name` + `business_type_id` |
| `Product.generic_name, manufacturer, rx_only, storage_condition` | Fixed pharmacy columns | Attribute definitions in the business-type template |
| `Batch.expiry` **NOT NULL**, FEFO-only | Furniture has no expiry; electronics need serials; shops may want average-cost | Optional lots; `tracking` ∈ {none, lot, serial}; allocation strategy is a stock rule |
| `pack_unit/pack_size/box_unit/box_size` | Hard-wired 3-level ladder | General UoM conversion table (strip/box becomes configuration) |
| `int` quantities everywhere | Can't sell 1.5 kg, 2.5 m of fabric | `Numeric(14,3)` quantities |
| `Patient` + `sale.patient_id` | Pharmacy-only | `Customer` + optional profile attributes per type |
| `MedicineMaster` (DGDA import) | Pharmacy-only shared catalogue | Business-type-scoped **Master Catalogue** (FMCG barcodes, cosmetic brands, medicines…) |
| `UserRole.pharmacist` | Pharmacy label | `manager` + tenant-defined custom roles |
| `Feature` enum includes `patients`; nav is a `const` list in `home_controller.dart` | Features/screens fixed at compile time | Module registry driven by capabilities |
| AI insights: expiry, Rx share | Irrelevant to furniture | Insight providers that activate per capability |
| Plan catalogue static in `core/permissions.py` | Pricing change needs a deploy | DB-driven plans (the doc already planned this "later") |

### 1.4 GAPS — missing for a universal POS (found in code, not assumed)

| # | Gap | Evidence |
|---|---|---|
| G1 | **No variants** (size/colour/shade) | `Product` is the sellable unit; no SKU level |
| G2 | **No fractional quantities** (weighed goods, metres, litres) | `qty: int` in models, DTOs and Dart |
| G3 | **No tax engine** | `tax=0` hard-coded in `services/sales.checkout`; `PosController.vatRate = 0.0` |
| G4 | **No stock-movement ledger** | Stock is a mutable `Batch.quantity`; stock-count `reason` "accepted but not stored" (architecture doc §9) — no history, no reconciliation |
| G5 | **No sale → lot/serial traceability** | `SaleItem` has no batch reference; FEFO consumption isn't recorded per line (blocks recalls, warranty, returns to the right lot) |
| G6 | **No offline mode** | No local DB dependency in `pubspec.yaml`; every sale is one network call |
| G7 | **Whole catalogue loaded client-side** | `PosController._all` filtered in memory — breaks at supershop SKU counts |
| G8 | **No register / shift / cash drawer** | No till session, float, cash-in/out, Z-report |
| G9 | **No customer entity beyond patients** | `customer_name` free text; credit sales need a name but there is no ledger per customer |
| G10 | **No promotions / price lists / loyalty** | Only a flat line discount + bill discount |
| G11 | **No document flow** | No quotation → order → delivery; no deposits/instalments/delivery (furniture needs all) |
| G12 | **Money is `float` in Python and `double` in Dart** | `Numeric(12,2)` columns but `float(...)` arithmetic in `services/sales.py`; `_cents()` rounding in `PosController` |
| G13 | **Reports read every sale into memory** | `services/reports.summary` and `ai_analysis.run_analysis` `select(Sale)` unfiltered |
| G14 | **Client-side invoice number left in POS code** | `PosController.checkout` builds `INV-${millis}`; `ApiService.createSale` never sends it (the server numbers via `numbering.next_number`), so it's dead code — but a trap for anyone reading it |
| G15 | **Tenant-level actions aren't audited** | `log_audit` is called only from `/admin/*` and billing; voids, price edits, stock adjustments, discounts leave no trail |
| G16 | **Tokens in `SharedPreferences`** (plain) | `data/token_store.dart` |
| G17 | **Insecure defaults** | `.env.example`: `CORS_ORIGINS=*`, `JWT_SECRET_KEY=change-me…`; no startup guard |
| G18 | **A user belongs to one tenant** | `users.phone` globally unique + single `tenant_id` — an accountant can't serve two businesses |
| G19 | **Hand-written API client + 1,860-line fake** | `api_service.dart` (930 lines) and `test/fakes/fake_api_service.dart` must be edited in lock-step; README admits the fake was an open follow-up |
| G20 | **Local-disk uploads** | `services/uploads.py`; fine for one instance only |

---

## 2. Product vision & principles

**Vision.** One platform where any shop owner can be live in under 15 minutes with a POS that
*feels built for their trade* — a furniture showroom sees quotations and deliveries, a
supershop sees scales and barcodes, a corner shop sees "baki" (due) ledgers and big buttons.

**Principles**

1. **Capabilities, not business names, drive behaviour.** Code never says
   `if business_type == "furniture"`. It says `if tenant.has(Capability.serial_tracking)`.
   (Enforced by a CI grep rule.)
2. **Attributes describe; capabilities decide.** Dynamic product fields are for display,
   search, filtering, labels and receipts — never for business logic.
3. **Server is the source of truth for money and stock.** Client previews; server computes.
4. **Append-only ledgers for anything that is money or stock.** Balances are derived or
   transactionally maintained and property-tested against the ledger.
5. **Simple by default.** A local shop never sees lots, variants or documents unless enabled.
6. **Three gates, all server-enforced:** Plan × Capability × Role.
7. **Offline-tolerant by design.** Idempotent writes, client UUIDs, deterministic sync.
8. **Port, don't rewrite, what already works** (§1.2).

---

## 3. The core idea: Business Type → Capabilities → Behaviour

### 3.1 Layers

```
 ┌───────────────────────────────────────────────────────────────────────────┐
 │  SUPER ADMIN adds business ──► picks BUSINESS TYPE (e.g. "Supershop")     │
 └───────────────┬───────────────────────────────────────────────────────────┘
                 │ provisioning (one transaction, §3.6)
                 ▼
 ┌───────────────────────────────────────────────────────────────────────────┐
 │ BUSINESS TYPE TEMPLATE (versioned, data)                                  │
 │  capabilities · attribute defs · variant axes · stock rules · units ·     │
 │  tax defaults · terminology · roles · categories · POS layout ·           │
 │  dashboard widgets · report pack · receipt/invoice templates              │
 └───────────────┬───────────────────────────────────────────────────────────┘
                 │ resolved per tenant:  template ± tenant overrides, ∩ plan
                 ▼
 ┌───────────────────────────────────────────────────────────────────────────┐
 │ TENANT CONTEXT  (GET /tenants/me/context, ETag-cached on the client)      │
 │  { capabilities[], features[], limits, terminology, attribute_defs,       │
 │    stock_rules, tax, nav_modules[], dashboard[], plan, status }           │
 └──────┬───────────────────────┬──────────────────────┬─────────────────────┘
        ▼                       ▼                      ▼
   Flutter shell           Engines (server)        Documents & reports
   • nav = registry        • catalogue validates   • receipt/invoice template
     ∩ capabilities          attributes            • report pack
   • DynamicForm renders   • inventory picks       • dashboard widgets
     product form            allocation strategy
   • POS layout variant    • sales runs doc flow
```

### 3.2 What lives in a Business Type template

| Section | Examples |
|---|---|
| `capabilities` | `variants`, `expiry_tracking`, `fractional_qty`, `document_flow` … (§3.3) |
| `product_attributes` | typed field definitions (§3.4) |
| `variant_axes` | `[shade, size_ml]` for cosmetics; `[material, colour, dimension]` for furniture |
| `stock` | costing (`weighted_average`/`fifo`), allocation (`fefo`/`fifo`/`none`), `allow_negative`, expiry alert days, reorder defaults |
| `units` | kg/g/pc/dozen/carton… with default conversions |
| `tax` | inclusive vs exclusive, default class, cash rounding |
| `terminology` | `{item: "Product", customer: "Patient", …}` — lets the same screen say the right word |
| `roles` | default role set and permissions (e.g. `salesperson` for furniture) |
| `default_categories`, `master_catalogue_ref` | starter tree; optional shared catalogue to search when adding products |
| `pos` | layout (`grid_scan`, `quick_keys`, `quote_builder`), require-customer rules, hold/resume |
| `dashboard`, `reports` | widget and report-pack ids |
| `documents` | receipt template (80 mm thermal / A4 invoice / challan / quotation) |

Templates are **versioned**. A tenant stores `business_type_id` + `template_version`; a new
template version never mutates live tenants silently — the console offers a diff and an
"apply update" action (audited).

### 3.3 Capability catalogue (closed, curated set — target ≤ 20)

Each capability declares `requires`, `conflicts`, minimum plan tier, and has its own test suite.

| Capability | What it turns on | Needs |
|---|---|---|
| `barcode_scanning` | Scan-to-cart, multiple barcodes/variant, label printing | — |
| `fractional_qty` | Decimal quantities, weight/length/volume units | — |
| `multi_uom` | Alternate units with conversion (strip/box, dozen/carton) | — |
| `scale_barcode` | Embedded weight/price barcodes, scale integration | `fractional_qty` |
| `variants` | Option axes → SKU per combination; matrix entry | — |
| `lot_tracking` | Lot/batch numbers on receipts and stock | — |
| `expiry_tracking` | Expiry on lots, FEFO, expiry alerts & loss report | `lot_tracking` |
| `serial_tracking` | Unique serial/IMEI per unit, sale-to-serial link | — |
| `warranty` | Warranty period on sale, claim log | `serial_tracking` (recommended) |
| `bundles` | Kits / gift sets with component stock | — |
| `item_tax` | Per-item tax class, tax lines on invoice | — |
| `promotions` | Rule engine (BOGO, % by category, happy hour) | — |
| `loyalty` | Points, tiers, birthday offers | `customers` |
| `customer_credit` | Per-customer due ledger ("khata"), credit limits | — |
| `installments` | Payment plans with schedule and reminders | `customer_credit` |
| `document_flow` | Quotation → order (deposit) → delivery → invoice | — |
| `delivery` | Delivery scheduling, charges, assignment, proof | `document_flow` |
| `custom_orders` | Made-to-order lines with specs and production status | `document_flow` |
| `multi_location` | Locations within a branch (showroom/godown/shelf) | — |
| `regulated_items` | Rx-style flag, customer profile required (pharmacy) | `lot_tracking` |
| `shifts` | Register shifts, float, Z-report | — |
| `salesperson_commission` | Attribute sales to staff, commission rules | — |
| `offline_pos` | Local DB + outbox sync on terminals | plan ≥ Pro |

**Resolution rule.** `effective = (template ∪ tenant_enabled) − tenant_disabled`, then
filtered by the plan's allowed capabilities. *Enable freely; disable only while unused*
(e.g. `expiry_tracking` can't be switched off while lots with expiry hold stock).

### 3.4 Dynamic product attributes

`attribute_definitions` rows (copied from the template into the tenant at provisioning so
tenants can add their own):

```jsonc
{
  "key": "skin_type",
  "label": "Skin type",
  "type": "multiselect",            // text|textarea|int|decimal|money|bool|date|select|multiselect|
                                    // select_or_create|color|dimension|image
  "options": ["Oily","Dry","Combination","Sensitive","All"],
  "required": false,
  "unit": null,
  "flags": { "searchable": false, "filterable": true, "show_in_pos": false,
             "show_on_label": false, "show_on_receipt": false, "variant_axis": false },
  "sort": 40, "group": "Details"
}
```

* Stored on the product as `attributes JSONB`, **validated server-side** against the
  definitions; GIN index (`jsonb_path_ops`) for filterable keys, `pg_trgm` for searchable ones.
* Core reporting uses core columns only — attributes never gate reports or stock logic.
* Flutter renders the add/edit-product form from the definitions (`DynamicForm`), so a new
  business type needs **no client release**.
* Removing a definition soft-hides it; existing values are retained.

### 3.5 What changes per business type — the matrix

| Area | Local shop | Supershop | Cosmetic | Furniture | Pharmacy (legacy) |
|---|---|---|---|---|---|
| **Family / sales flow** | Counter | Counter | Counter | Order-based | Counter |
| **Add-product form** | Name, price, unit, qty (quick-add) | + barcode(s), dept, tax, MRP, weighed?, supplier | + brand, shade/size variants, skin type, PAO, expiry, origin | + material, dimensions, colour/finish variants, images, warranty, CBM, lead time | + generic, strength, form, Rx, pack ladder, storage |
| **Variants** | – | optional | ✔ | ✔ | – |
| **Fractional qty / scale** | by-unit (kg/dozen) | ✔ + scale barcodes | – | – | – |
| **Lots & expiry** | – | ✔ perishables | ✔ | – | ✔ mandatory |
| **Serials & warranty** | – | – | – | ✔ high-value | – |
| **Stock allocation** | none/average | FEFO (perishables) else avg | FEFO | none / serial pick | FEFO |
| **Inventory screen** | simple list + low stock | dept tree, reorder, wastage, price labels | variant matrix, expiry board | locations (showroom/godown), incoming POs | batches/expiry |
| **POS layout** | big buttons, open-price item, due sales | scan-first, hold/resume, quick keys, split pay, weigh | scan-first, customer lookup, loyalty | **quote builder** → order → deposit → delivery | scan-first + Rx check |
| **Payments** | cash, bKash/Nagad, due | cash, card, MFS, split | cash, card, MFS, store credit | deposit + balance, instalments, cheque | cash, card, MFS |
| **Customer** | name + phone, due ledger | optional + loyalty | profile (skin type), loyalty | required: address(es), ledger | patient profile |
| **Documents** | 58/80 mm receipt | 80 mm receipt, tax invoice | 80 mm receipt | A4 quotation / invoice / challan | 80 mm receipt |
| **Dashboard** | today, dues, low stock, cash | today, hourly, top depts, shrinkage, shifts | today, top brands, expiring, loyalty | open quotes, deposits, deliveries due, receivables | today, expiring, Rx |
| **Reports pack** | daily book, due ageing | dept/margin, shrinkage, tax, shift Z | brand/variant, expiry loss | pipeline, receivables, delivery SLA | expiry, Rx log |
| **Typical capabilities** | `customer_credit`, `multi_uom` | `fractional_qty`, `scale_barcode`, `lot_tracking`, `expiry_tracking`, `promotions`, `loyalty`, `shifts`, `item_tax` | `variants`, `lot_tracking`, `expiry_tracking`, `bundles`, `promotions`, `loyalty` | `variants`, `serial_tracking`, `warranty`, `document_flow`, `delivery`, `custom_orders`, `installments`, `multi_location`, `salesperson_commission` | `lot_tracking`, `expiry_tracking`, `multi_uom`, `regulated_items` |

### 3.6 Provisioning — what happens when the super admin adds a business

1. **Wizard** in the console: business details → **business type** (cards that preview what's
   included) → country / currency / timezone / language → plan & trial → owner → branch count
   → optional *sample data*.
2. **One transaction** (`POST /admin/tenants/`): create tenant (`business_type_id`,
   `template_version`, locale/currency/tz, settings) → owner user & membership → main branch +
   default location + default register → roles from template → categories, units, tax
   classes → attribute definitions → numbering series → document templates → (sample catalogue)
   → audit entry. All-or-nothing, like today's `create_tenant`, but richer.
3. **Capability resolution** → cached tenant context with a version stamp; invalidated on any
   change (plan change, override, template apply).
4. **First login** → onboarding checklist (add first product, set tax, connect printer, invite
   staff, print a test receipt).
5. **Changing business type later** is a super-admin-only action: capabilities may be added;
   removal is blocked while dependent data exists; always audited.

### 3.7 Guardrails against configuration explosion

* Capabilities are a **closed set owned by engineering**, not free-form flags; ≤ 20 target.
* Each capability: dependency declaration, plan tier, test suite, docs page, owner.
* Business types are *data*, but every shipped type must pass the **shared scenario suite**
  (provision → add product → purchase → sell → return → close day) with expectations varying
  only by capability.
* CI grep forbids business-type names in application code.
* A new business type that needs a new capability goes through design review — the capability
  is added once and benefits every type.

---

## 4. Business-type playbooks

### 4.1 Local shop (general store / "mudi dokan")
*Design goal: fastest to learn, works on a cheap phone, tolerates bad connectivity.*
* **Quick-add product**: name + price + unit; stock optional ("don't track" mode); open-price
  items for loose goods.
* **Units** with conversion (sell by piece/dozen/kg, buy by carton/sack).
* **Customer due ledger (baki khata)**: part-pay, collect later, reminders by SMS/WhatsApp
  share; supplier due ledger; daily **cash book** (sales, expenses, collections).
* Bangla-first UI, large touch targets, optional thermal printer, mobile-wallet payments.
* Offline sale capture is a headline feature for this segment (Phase 2).

### 4.2 Supershop
*Design goal: throughput and shrinkage control.*
* Barcode-first; multiple barcodes per item; **weighed items** (scale-embedded barcodes) with
  decimal quantity; departments/categories tree; per-item tax class with inclusive pricing.
* **Hold/resume carts**, quick keys, split tender, cash rounding, customer-facing display.
* **Promotions**: BOGO, % off category, bundle price, time-boxed; **loyalty** points.
* **Shifts**: opening float, cash in/out, blind close, variance, Z-report.
* Lots/expiry for perishables; wastage & shrinkage capture; reorder suggestions; shelf-label
  printing; stocktake (cycle counts).
* Supplier purchasing with cost updates (weighted-average) and purchase returns.

### 4.3 Cosmetic shop
*Design goal: rich catalogue + customer relationship.*
* **Variants** (shade × size) with a matrix entry screen and per-variant barcode.
* Lots with **expiry and PAO** (period-after-opening) on labels; expiry board; FEFO.
* Brand, skin-type, origin/authenticity attributes (all filterable); **bundles / gift sets**;
  testers tracked as non-sale stock.
* Loyalty tiers, birthday offers, store credit; return policy by condition (opened/unopened).
* Promotions by brand/category; beauty-advisor attribution (`salesperson_commission` optional).

### 4.4 Furniture (order-based family)
*Design goal: manage a long, high-value sale, not a fast one.*
* **Variants** by material/colour/dimension; image galleries; assembly/knock-down flag; CBM.
* **Document flow**: *Quotation* (validity, terms, PDF/WhatsApp share) → *Sales order* with
  **deposit** → *Delivery* (schedule, vehicle, installer, proof of delivery, delivery &
  assembly charges as service lines) → *Invoice* (A4) → *Instalments* if enabled.
* **Serial/warranty** on high-value pieces; claim log.
* **Custom orders**: spec capture, supplier/workshop production status, lead time.
* **Multi-location**: showroom vs godown; incoming purchase orders visible to sales as
  "expected stock"; reservation against orders.
* Salesperson attribution & commission; heavy customer ledger; cheque handling.

### 4.5 Pharmacy (existing product — shipped as a built-in profile)
Same engine with `lot_tracking`, `expiry_tracking`, `multi_uom`, `regulated_items`; attributes
`generic_name`, `strength`, `dosage_form`, `manufacturer`, `rx_only`, `storage_condition`;
master catalogue = existing DGDA import; terminology `customer → patient`. **Acceptance gate:**
every PharmaCare backend test scenario must pass on Universal with this profile.

---

## 5. Functional scope by module

| Module | Core features | Capability-dependent |
|---|---|---|
| **Platform console** | Tenants, onboarding wizard, plans & limits, **business types & capability matrix**, billing review, impersonation, announcements, audit, maintenance switch, usage metrics | Template diff/apply, tenant capability overrides |
| **Identity & access** | Login (phone/email/PIN), roles, per-user overrides, branch restriction, sessions | Custom roles, manager-PIN overrides |
| **Catalogue** | Products (stockable/service/non-stock/bundle), categories tree, brands, UoM, barcodes, images, price lists, tax classes, import/export (CSV/XLSX), label printing | Variants, attributes, master catalogue, scale barcodes |
| **Inventory** | Stock ledger, balances, adjustments with reason, stocktake, reorder levels, transfers (instant or with in-transit), valuation, negative-stock policy | Lots/expiry, serials, multi-location, wastage, reservations |
| **Purchasing** | Suppliers, purchase orders, goods receipt (partial), supplier invoices/payments, purchase returns, landed cost | Lot/expiry/serial capture at receipt |
| **Sales (POS)** | Cart, search/scan, discounts with limits, tax, split payments, hold/resume, returns/exchanges, void with approval, receipts | Promotions, loyalty, weigh, shifts, quote builder |
| **Documents** | Receipt, tax invoice, A4 invoice, challan, quotation | Order/delivery docs (`document_flow`) |
| **Customers** | Directory, groups, credit limit, ledger, statements | Loyalty, profiles, instalments |
| **Finance-lite** | Registers, cash movements, expenses, day book, payment-method reconciliation | Shifts/Z-report |
| **Reporting** | Sales, margin, stock valuation, ageing (customers/suppliers), tax, cash, staff | Report packs by type |
| **Insights** | Explainable rules (carried over from `ai_analysis`) as pluggable providers | Provider list varies by capability |
| **Integrations** | Printer/scanner/scale/cash drawer, SMS/WhatsApp share, accounting export, webhooks/API | e-commerce sync (later) |

---

## 6. Architecture

### 6.1 Stack decisions

| Concern | Decision | Rationale |
|---|---|---|
| Backend | **FastAPI + async SQLAlchemy 2 + Alembic + PostgreSQL** (keep) | Works, well structured, team knows it |
| Style | **Modular monolith** (package per domain), one deployable | Microservices add cost with no benefit at this scale; keep boundaries enforceable |
| Client | **Flutter** (keep GetX), single codebase for Android tablets/phones, Windows POS, and Web back-office | Biggest asset to preserve is the UI investment; re-platforming the UI framework is the highest-cost/lowest-value change on the table |
| API contract | **OpenAPI → generated Dart client** | Kills the 930-line hand-written `ApiService` and its 1,860-line fake (G19) |
| Money | Python `Decimal` / `Numeric(14,2)`; **decimal strings on the wire**; Dart `Decimal` | Fixes G12 |
| Quantity | `Numeric(14,3)` | Fixes G2 |
| IDs | UUIDv7 generated **client-side** for offline-created rows | Idempotent sync, time-sortable index locality |
| Cache / queue | Redis (cache, rate limit) + a simple job runner (ARQ/Celery) for reports, SMS, exports | Needed for rollups & notifications; add when first needed |
| Files | S3-compatible object storage (MinIO in dev) | Fixes G20 |
| Search | Postgres `pg_trgm` + FTS first; revisit only past ~500k SKUs/tenant | Keep infra small |
| Local DB (client) | **Drift (SQLite)** with FTS5 for offline catalogue | Phase 2 |
| Hosting | Containerised (Docker), managed Postgres with PITR backups | Basic DR |

### 6.2 Backend module layout

```
app/
  platform/      tenants, business_types, capabilities, plans, subscriptions, billing, admin, audit, announcements, maintenance
  identity/      users, memberships, roles, permissions, sessions
  catalogue/     products, variants, categories, uoms, barcodes, attributes, price_lists, tax, master_catalogue
  inventory/     ledger, balances, lots, serials, locations, transfers, stocktake, valuation
  purchasing/    suppliers, purchase_orders, receipts, supplier_ledger
  sales/         cart_pricing, promotions, checkout, payments, returns, documents(quote/order/delivery), installments
  customers/     customers, groups, ledger, loyalty
  finance/       registers, shifts, cash_movements, expenses
  reporting/     rollups, report_packs, insights
  integrations/  printers, sms, webhooks, exports
  core/          config, security, db, errors, pagination, idempotency, tenant_context
```
Rules: modules talk through service interfaces (no cross-module table access); `import-linter`
enforces the dependency graph in CI. Route handlers stay thin (as today).

### 6.3 Multi-tenancy & security

* Keep `tenant_id` on every tenant table + composite indexes `(tenant_id, …)`.
* **Add Postgres Row-Level Security** as defence-in-depth: each transaction runs
  `SET LOCAL app.tenant_id = …`; policies deny cross-tenant reads even if a query forgets the filter.
* **Users ↔ tenants via `memberships`** (G18): one person, many businesses; role per membership.
  Login by phone **or** email; PIN login for cashier terminals.
* Access token 15–30 min; refresh rotation (keep); **secure storage** on device (Keychain /
  Keystore) (G16); web uses in-memory access token + refresh via storage.
* **Startup guard**: refuse to boot in production with default JWT secret or `CORS_ORIGINS=*` (G17).
* **Tenant-level audit log** (G15): price changes, discounts above threshold, voids, refunds,
  stock adjustments, role changes, cash-drawer opens, template changes — append-only,
  with `actor`, `impersonated_by`, before/after.
* Rate-limit login and sensitive endpoints; MFA for super-admins and owners.
* PII minimisation, export & delete tooling for customer data.

### 6.4 Core data model (summary)

```
PLATFORM   business_types(+versions) · plans · plan_modules · plan_limits · subscriptions
           subscription_invoices · payment_channels · payment_requests · audit_log
TENANT     tenants(name, business_type_id, template_version, currency, locale, tz, settings)
           tenant_capability_overrides · branches · locations · registers
IDENTITY   users · memberships · roles · role_permissions · membership_permission_overrides
CATALOGUE  categories(tree) · products · product_variants · product_barcodes · uoms · uom_conversions
           attribute_definitions · price_lists(+items) · tax_classes/rates · master_catalogue_items
INVENTORY  stock_lots · stock_serials · stock_movements (append-only) · stock_balances
           stock_counts(+lines) · stock_transfers(+lines, status)
PURCHASING suppliers · supplier_ledger · purchase_orders(+lines) · goods_receipts(+lines) · purchase_returns
SALES      sales · sale_lines · sale_line_allocations(lot/serial) · sale_payments · sale_returns(+lines)
           documents(quotation/order/delivery) · deliveries · installment_plans(+schedule) · promotions
CUSTOMERS  customers · customer_groups · customer_ledger (append-only) · loyalty_accounts
FINANCE    shifts · cash_movements · expenses
OPS        idempotency_keys · outbox_events · sync_cursors · files · notifications
```

Key shapes:

```
products(id, tenant_id, name, type[stockable|service|non_stock|bundle], category_id,
         base_uom_id, tracking[none|lot|serial], track_expiry, tax_class_id,
         attributes jsonb, active, image_id)
product_variants(id, product_id, sku, option_values jsonb, cost, price, active)   -- 1 per product if no variants
product_barcodes(variant_id, barcode, uom_id, qty_per_scan, is_scale)             -- unique per tenant
stock_movements(id, tenant_id, variant_id, lot_id?, serial_id?, location_id,
                qty_delta numeric(14,3), unit_cost numeric(14,4),
                reason[purchase|sale|return|adjust|transfer_in|transfer_out|count|wastage|opening],
                ref_type, ref_id, actor_id, occurred_at)
stock_balances(tenant_id, variant_id, lot_id?, location_id, on_hand, reserved)    -- updated in same txn
sale_lines(id, sale_id, variant_id, qty numeric(14,3), uom_id, unit_price, discount, tax,
           unit_cost_snapshot, salesperson_id?)
sale_line_allocations(sale_line_id, lot_id?, serial_id?, qty)                     -- traceability (G5)
```

**Invariants (property-tested, §12):**
`stock_balances.on_hand = Σ stock_movements.qty_delta` ·
`sales.paid = Σ sale_payments.amount` ·
`customers.balance = Σ customer_ledger.amount` ·
`returned_qty ≤ sold_qty` · `reserved ≤ on_hand` unless negative stock allowed.

### 6.5 Inventory engine

* Every stock change is a **ledger row**; balances updated in the same transaction with row
  locks (carry over the `FOR UPDATE` discipline of `consume_fefo`).
* **Allocation strategy** pluggable per product/tenant: `fefo` (earliest expiry), `fifo`,
  `average` (no lot pick), `serial` (explicit unit). Chosen from stock rules, not branches of
  business-type `if`s.
* **Costing**: weighted-average default, FIFO optional; each sale line snapshots unit cost for
  margin reports.
* **Units**: all quantities stored in the base UoM; conversions applied at the edge (generalises
  today's pack/box logic).
* **Negative stock** policy (block / warn / allow) — essential for offline sales.
* **Transfers**: instant (today) or *request → dispatch → receive* with an in-transit state.
* **Stocktake**: sessions with blind counts, variance posting to ledger.
* **Reservations** for orders (`document_flow`); available = on_hand − reserved.

### 6.6 Pricing, tax & payment engine

Order of evaluation (single server function, also exposed as `POST /pricing/quote` so the
client previews exactly what the server will charge):

`price list (customer group / branch) → promotions → manual discount (limit by role; manager PIN
above it) → tax (inclusive/exclusive, per item) → cash rounding → total`

* Payments: multi-tender, change, deposits, credit (due), store credit, loyalty redemption;
  **ledger invariant retained**; payment methods are **data** (cash, card, bKash, Nagad, Rocket,
  Upay, bank, cheque, store credit…) not an enum.
* Idempotent checkout: `Idempotency-Key` header; replays return the original sale.
* Invoice numbers: per tenant × branch × register series from an atomic counter; **offline
  terminals lease number blocks** so numbers never collide.
* Returns/exchanges honour a tenant return policy (window, condition, restock-or-scrap).
* Void/refund/discount-override each require explicit permissions and write an audit row.

### 6.7 API conventions

* `/api/v1`, snake_case JSON (keep), `{detail, code}` errors (keep).
* **Cursor pagination** and server-side search on every list; `updated_since` cursors for sync.
* `GET /tenants/me/context` — the single bootstrap call (capabilities, features, limits,
  terminology, attribute definitions, nav modules, plan/status); ETag + version stamp.
* OpenAPI generated clients; contract tests run in CI against the same spec.

### 6.8 Flutter architecture

* **Feature modules register themselves** in a `ModuleRegistry`:
  `ModuleDefinition{ id, routes, navItem, requiredCapabilities, requiredFeature, permission,
  dashboardWidgets, settingsPanels }`. Replaces the `const _all` list in `home_controller.dart`.
  Nav = registry ∩ tenant context; **keep PharmaCare's "locked, not hidden" pattern** for plan
  and permission locks, but *hide* modules whose capability is absent (a local shop shouldn't
  see "Serials").
* **`TenantContext` service** replaces `SubscriptionService` + parts of `AuthService`:
  `has(Capability)`, `has(Feature)`, `can(Permission)`, `term('customer')`, `limits`.
* **`DynamicForm`** renders product (and customer) forms from attribute definitions with
  server-validated errors surfaced inline.
* **POS layout variants** over one pure-Dart `CartEngine`: `CounterPos` (scan/grid) and
  `QuoteBuilder` (order-based). Pricing preview calls `/pricing/quote`; no client-side tax or
  discount logic that could disagree with the server.
* Server-side product search with debounce (replaces in-memory `_all`, G7); a small local cache
  of hot items for instant scan.
* Responsive layouts reuse the existing shell/mobile-nav approach; keep the overflow sweep tests.

### 6.9 Offline-first (designed now, shipped Phase 2)

* Local SQLite catalogue snapshot (delta-synced by cursor) + **outbox** of sales with
  client UUIDs and idempotency keys; background sync with exponential backoff.
* **Conflict policy:** sales/payments/movements are append-only events → no merge conflicts;
  catalogue/price changes are server-wins; stock may go negative offline → reconcile and
  alert on sync.
* Offline numbering via leased blocks (§6.6); clear UI state: *Online / Syncing / Offline (n queued)*.
* Receipts print offline; reports/search of history require connectivity.

### 6.10 Hardware & documents

| Device | Approach |
|---|---|
| Barcode scanner | Camera (`mobile_scanner`, exists) + HID keyboard-wedge (exists) |
| Receipt printer | Keep PDF/`roll80` path; **add ESC/POS raw** (Bluetooth/USB/LAN) for speed and cash-drawer kick; Bangla glyph support via embedded Unicode font (the receipt code already flags this limitation) |
| Weighing scale | Phase 2: scale-barcode labels first (no integration needed), then serial/USB/BT scale |
| Cash drawer | Via printer kick pulse |
| Label printer | PDF label sheets first; ZPL/TSPL later |
| Customer display | Second window on Windows; later |

---

## 7. Super-admin console (extends the existing one)

* **Business Types**: list, create/edit (capabilities matrix with dependency validation,
  attribute definitions, units, tax, terminology, categories, dashboard & report packs,
  document templates), **version history, diff, publish**, "tenants on this version".
* **Tenant onboarding wizard** (§3.6) with live preview of the chosen type.
* **Tenant detail**: plan, status, limits & usage, **capability overrides** (with reasons),
  template version & "apply update", impersonate (audited), data export.
* **Plans & pricing** editor (DB-driven): modules, limits, add-ons, per-business-type pricing.
* Keep: payment review queue, channels, announcements, audit, maintenance switch, MRR.
* **Ops views**: error rates, slowest endpoints, sync backlog, tenants nearing limits.

---

## 8. Roles & permissions

* Roles become **rows** (`roles`, `role_permissions`) — system roles seeded from the template
  (`owner`, `manager`, `cashier`, `stock_keeper`, `accountant`, `salesperson`) and
  **custom roles** per tenant. `pharmacist` maps to `manager`.
* Keep **per-user override semantics** (`null` inherit / `[]` none) and **branch restriction**.
* Extend the catalogue: `override_price`, `max_discount_percent` (value, not boolean),
  `approve_void`, `approve_refund_over`, `open_cash_drawer`, `close_shift`, `manage_shifts`,
  `view_cost_price` (keep), `manage_promotions`, `manage_customers`, `manage_documents`,
  `view_margin`, `export_data`, `manage_roles`.
* Permissions can require a capability (a `manage_serials` permission is meaningless without
  `serial_tracking`) — hidden in the role editor when the capability is absent.
* **Manager override** by PIN for gated actions at the till; every override audited.

---

## 9. Plans, billing & limits

* Plan = set of **modules/features** + **limits** (products, staff, branches,
  monthly sales, storage) + **allowed capabilities** (e.g. `offline_pos`, `installments` on Pro).
* Move `PLAN_CATALOG` from code to tables (the existing doc deferred this "later" — Universal
  needs it now so per-business-type pricing works without a deploy).
* Keep manual payment verification (Bangla QR today) as v1; add an **automated gateway**
  adapter interface so one can be plugged in later without touching business logic.
* Keep period-stacking rules for renewals (paying early never costs days).
* Usage metering for limits + soft warnings at 80/100 %.
* Add-ons: extra branch, extra register, SMS pack.

---

## 10. Reporting & insights

* **Rollup tables** (`daily_sales_by_branch/product/category/payment`) updated by the checkout
  transaction or a job — **replaces unfiltered `select(Sale)`** (G13). All reports are
  date-bounded, paginated and index-backed.
* Common packs: sales summary, margin, stock valuation, ageing (customers & suppliers), tax,
  cash/day book, staff performance. Type packs from the template (§3.5).
* Exports: CSV/XLSX/PDF (keep the PDF pipeline), scheduled email/WhatsApp-share summaries.
* **Insights** become providers: `LowStock`, `DeadStock`, `DueExposure`, `SalesTrend` (all
  types); `ExpiryRisk` (needs `expiry_tracking`); `RxMix` (needs `regulated_items`);
  `OrderPipelineStall`, `UndeliveredDeposits` (needs `document_flow`). Keep the "every insight
  traces to a concrete number" rule from `ai_analysis.py`.

---

## 11. Non-functional requirements

| Area | Target |
|---|---|
| Scale (initial) | 5,000 tenants · ≤ 100k SKUs/tenant · ≤ 20 registers/tenant · 5M sale lines/tenant/yr |
| Latency (p95) | Checkout API < 400 ms · product search < 150 ms · scan-to-cart < 100 ms (local) |
| Availability | 99.9 % API; POS keeps selling offline (Phase 2) |
| Data safety | PITR backups, tested restores quarterly, RPO ≤ 5 min, RTO ≤ 1 h |
| Security | OWASP ASVS L2 target; RLS; secrets in a vault; dependency scanning; annual pen test |
| Observability | Structured logs with `tenant_id`/`request_id`, metrics, tracing, Sentry-style error tracking, per-tenant dashboards |
| Compliance | Verify local tax-invoice requirements (e.g. NBR VAT invoice format for registered businesses) with an accountant before Phase 1 exit; PII export/delete |
| Accessibility & i18n | Bangla + English; ARB-based localisation; Unicode receipt fonts; large-touch mode |
| Devices | Low-end Android (2 GB RAM) supported for Local-shop profile |

---

## 12. Quality strategy & DevOps

* **Testing pyramid**
  * Unit: pricing/tax/rounding, allocation strategies, UoM conversion (golden tables).
  * **Property tests** for ledger invariants (§6.4) with Hypothesis, run against real Postgres
    (Testcontainers), including concurrent checkout of the last unit.
  * **Shared scenario suite** run per business type (§3.7) — the guard on "universal".
  * Contract tests from the OpenAPI spec; Flutter widget tests keep the layout-overflow sweeps.
  * Replace the hand-maintained `FakeApiService` with the generated client against a
    docker-compose backend in CI, plus a small in-memory fake only for pure-UI tests (G19).
* **CI/CD**: GitHub Actions — lint, type-check (mypy/pyright, `flutter analyze`), tests,
  Alembic "single head + upgrade/downgrade" check, import-linter, grep rule for business-type
  names, build artefacts (APK, Windows installer, web bundle); staging auto-deploy; prod gated.
* **Migrations**: one logical change per migration (keep the discipline in the existing doc);
  expand/contract for zero-downtime.
* **Feature flags** for risky modules; staged rollout by tenant cohort.
* **Docs**: ADRs for each decision here, capability catalogue page, runbooks.

---

## 13. Roadmap

*Estimates assume ~3–4 engineers (2 backend, 1–2 Flutter) plus part-time design/QA. They are
planning figures with ±25 % uncertainty, to be re-baselined after Phase 0.*

| Phase | Weeks | Scope | Exit criteria |
|---|---|---|---|
| **0 — Foundations** | 3 | New repo, CI, OpenAPI→Dart client, ADRs, UX flows for the 4 types, design system, template JSON for each type, tenant-context contract, schema v1 | Walking skeleton: login → tenant context → empty nav built from capabilities |
| **1 — Platform + Engine MVP** | 10 | Ported platform layer (auth, memberships, RBAC, plans, billing, audit, console); **Business Types admin + provisioning wizard**; catalogue (products, variants, UoM, dynamic attributes, barcodes); inventory ledger/balances, purchases, transfers; Counter POS (scan/search, hold, split pay, discounts w/ limits, returns, receipts); customers + due ledger; core reports. **Live types: Local shop, Supershop (lite), Cosmetic** | Pilot with 3 real shops (one per type); shared scenario suite green for all three |
| **2 — Retail depth + offline + pharmacy parity** | 8 | Shifts & Z-report, promotions, loyalty, weighed items & scale barcodes, ESC/POS + cash drawer, label printing, expiry board, stocktake, rollup reports, **offline POS**, **Pharmacy profile** | Offline soak test (24 h disconnected, no number collisions); PharmaCare scenarios pass on Universal |
| **3 — Order-based flow (Furniture)** | 8 | Document flow (quote → order → delivery → invoice), deposits, instalments, delivery module, serial & warranty, locations, A4 documents, salesperson commission, custom orders | Pilot with 2 furniture showrooms; receivables & delivery reports accepted |
| **4 — Hardening & scale** | 6 | RLS, load/chaos tests, observability, backup/restore drills, security review & pen test, full Bangla localisation, performance tuning | Targets in §11 met; restore drill passed |
| **5 — Ecosystem** | ongoing | **Business Type Studio** (self-service templates), public API & webhooks, e-commerce / accounting integrations, automated payment gateway, marketplace of templates | — |

**Why this order.** Local shop validates that the engine can be *simple*; Supershop and
Cosmetic exercise the counter path under load and with variants/lots; Pharmacy proves backward
compatibility; Furniture is the largest new flow, so it ships after the engine is stable.

---

## 14. Migration path from PharmaCare

A one-time **ETL with dry-run and reconciliation** (totals must match: stock valuation,
receivables, payables, sales count/amount per month).

| PharmaCare | Universal |
|---|---|
| `tenants.pharmacy_name` | `tenants.name`; `business_type = pharmacy`, template v1 |
| `products.generic_name / manufacturer / rx_only / storage_condition` | `attributes` JSONB (+ definitions from the pharmacy template) |
| `pack_unit/pack_size/box_unit/box_size`, `loose_sale_allowed` | `uoms` + `uom_conversions` |
| `batches` | `stock_lots` + an **opening-balance** `stock_movements` row each |
| `patients` | `customers` + profile attributes (conditions, allergies, age, gender) |
| `sales`, `sale_items` | `sales`, `sale_lines` (no lot allocation for legacy rows — flagged `legacy=true`) |
| `sale_payments`, `sale_returns*` | same names; payment methods → data rows |
| `suppliers`, `purchases*` | `suppliers`, `purchase_orders` + receipts; supplier due → `supplier_ledger` opening entry |
| `users.role` (`pharmacist`) | `memberships.role = manager`; permission overrides mapped 1:1, new permissions default off |
| `medicine_master` | Pharmacy **master catalogue** |
| `subscription_*`, `payment_*`, `audit_log`, `announcements` | Carried over unchanged |

PharmaCare keeps running during Phases 1–2; customers move tenant-by-tenant after Phase 2.

---

## 15. Risks & mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| **Over-generalisation** — config sprawl, every shop "special" | Complexity, slow delivery | Closed capability set (§3.7), shared scenario suite, design review gate |
| **Dynamic forms hurt UX** | Slow, generic-feeling screens | Attribute groups, sensible defaults per type, hand-tuned layouts for the top 3 screens |
| **Offline sync bugs** (duplicates, negative stock) | Money/stock errors | Append-only events, idempotency keys, leased invoice blocks, soak tests, negative-stock reconciliation |
| **Rewrite risk** | Lost time, feature regression | Port the platform layer; PharmaCare parity gate; keep PharmaCare live |
| **Float → Decimal migration errors** | Rounding bugs | Golden-table tests; property tests; Decimal end-to-end |
| **Tax/regulatory differences** | Compliance exposure | Tax engine is data-driven; confirm local invoice rules early; per-country packs later |
| **Hardware variability** (printers, scales) | Support burden | Certified-device list; scale-barcode path needs no integration |
| **Scope creep per vertical** | Schedule slip | Phase gates; each new vertical must reuse capabilities or justify a new one |
| **Single-instance infra** (disk uploads, one process) | Outage / data loss | Object storage, managed DB with PITR, stateless API |
| **Small team bus-factor** | Delivery risk | ADRs, runbooks, generated client, strong CI |

---

## 16. Open questions (answers change the plan)

1. **Market scope** — Bangladesh only at launch, or multi-country (currency, tax, language packs)?
2. **Team & timeline** — the roadmap assumes 3–4 engineers; what's the real capacity and any
   hard launch date?
3. **Brand** — the Flutter app already rebranded to "Nexora POS". Is Universal POS the next
   generation of that product line (shared brand and customers) or a separate product?
4. **Pharmacy** — do existing PharmaCare/Nexora customers need to migrate? That decides whether
   Phase 2's parity gate is a requirement or a nice-to-have.
5. **Offline** — is offline selling a launch requirement (move into Phase 1) or acceptable at
   v1.1 for Local shop / Supershop?
6. **Pricing model** — per-tenant, per-branch, per-register, or per-business-type? (affects the
   plan schema and add-ons)
7. **Hardware** — which printers/scanners/scales must be supported on day one?
8. **E-commerce / online channel** — in scope for the first year?
9. **Accounting** — is a full ledger/chart-of-accounts needed, or "finance-lite" plus export?
10. **Hosting & data residency** — cloud provider constraints?

---

## Appendix A — Example business-type template (Cosmetic Shop, v1)

```jsonc
{
  "key": "cosmetic",
  "version": 1,
  "label": "Cosmetic Shop",
  "family": "counter_retail",
  "capabilities": ["barcode_scanning", "variants", "lot_tracking", "expiry_tracking",
                   "bundles", "promotions", "loyalty", "customer_credit", "shifts"],
  "terminology": { "item": "Product", "customer": "Customer" },
  "product_attributes": [
    { "key": "brand",       "label": "Brand",        "type": "select_or_create", "required": true,
      "flags": { "searchable": true, "filterable": true } },
    { "key": "skin_type",   "label": "Skin type",    "type": "multiselect",
      "options": ["Oily", "Dry", "Combination", "Sensitive", "All"], "flags": { "filterable": true } },
    { "key": "pao_months",  "label": "Period after opening (months)", "type": "int",
      "flags": { "show_on_label": true } },
    { "key": "origin",      "label": "Country of origin", "type": "text" },
    { "key": "ingredients", "label": "Key ingredients",   "type": "textarea" }
  ],
  "variant_axes": ["shade", "size_ml"],
  "stock": { "costing": "weighted_average", "allocation": "fefo",
             "allow_negative": false, "expiry_alert_days": [90, 30] },
  "units": ["pc", "ml", "g", "set"],
  "tax": { "mode": "inclusive", "cash_rounding": "nearest_1" },
  "default_categories": ["Skincare", "Makeup", "Hair", "Fragrance", "Bath & Body"],
  "pos": { "layout": "counter", "quick_keys": true, "hold_resume": true, "require_customer": false },
  "dashboard": ["today_sales", "low_stock", "expiring_soon", "top_brands"],
  "reports": ["sales_summary", "brand_performance", "expiry_loss", "stock_valuation"],
  "documents": { "receipt": "thermal_80_basic", "invoice": "a4_simple" }
}
```

## Appendix B — Suggested first 10 engineering tickets

1. Repo skeleton, CI (lint, types, tests, migration-head check, import-linter, grep rule).
2. `core`: config with production startup guard, error contract, idempotency, cursor pagination.
3. Port `identity` + `platform` (tenants, plans in DB, billing, audit, maintenance) with memberships.
4. `capabilities` registry (enum + dependency graph + resolver) and `business_types` tables with versioning.
5. `GET /tenants/me/context` + Flutter `TenantContext` + `ModuleRegistry` + capability-built nav.
6. Catalogue: products/variants/UoM/barcodes + attribute definitions + server validation.
7. Flutter `DynamicForm` + product add/edit for three templates (local, supershop, cosmetic).
8. Inventory ledger/balances + allocation strategies + property tests for invariants.
9. Pricing/tax/payment engine + `/pricing/quote` + idempotent checkout + receipt.
10. Provisioning wizard (console) + shared scenario suite running for all three launch types.
