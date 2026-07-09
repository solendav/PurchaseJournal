# Purchase Journal

Personal purchase journal app — record what you buy from each supplier, how much you paid, and attach receipt photos. Scan receipts with on-device OCR to pre-fill line items.

**Not a B2B marketplace** — no orders, buyers, or sellers. Just your purchase history grouped by supplier.

## Stack

- **Mobile:** Flutter, BLoC-ready structure, GetIt, Dio, go_router, Google ML Kit (receipt OCR)
- **Backend:** Node.js 20, Express 5, JWT auth, PostgreSQL
- **Database:** PostgreSQL 15 (`purchase_journal`)

## Features

- Register / sign in
- Manage **suppliers** (vendors you buy from)
- Record **purchases** with line items and amount paid
- **Scan receipt** — camera/gallery → OCR → suggested items
- **Dashboard** — total spent and breakdown **per supplier**
- Receipt images stored on the backend (`/uploads/receipts/`)

## Quick start

### 1. Database

```bash
docker compose up -d db
```

PostgreSQL runs on **localhost:5435** (database: `purchase_journal`).

### 2. Backend

```bash
cd backend
cp .env.example .env
npm install
npm run db:setup
npm run db:seed
npm run dev
```

API: `http://localhost:5003/api`

### 3. Flutter app

```bash
cd mobile
cp dart_defines.dev.json.example dart_defines.dev.json
flutter pub get
flutter run --dart-define-from-file=dart_defines.dev.json
```

**Android emulator:** defaults to `http://10.0.2.2:5003` when `API_BASE_URL` is empty.

**Physical device:** set your PC's LAN IP in `dart_defines.dev.json`.

## Demo account (after seed)

| Email | Password |
|-------|----------|
| `demo@purchasejournal.local` | `password123` |

## API overview

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/auth/register` | Create account |
| POST | `/api/auth/login` | Sign in |
| GET | `/api/suppliers` | List suppliers |
| POST | `/api/suppliers` | Add supplier |
| GET | `/api/purchases` | List purchases (`?supplierId=`) |
| POST | `/api/purchases` | Create purchase with items |
| POST | `/api/uploads/receipt` | Upload receipt image |
| GET | `/api/dashboard/summary` | Totals overall + by supplier |

## Project structure

```
PurchaseJournal/
├── backend/          # Express API
├── mobile/           # Flutter app
├── docker-compose.yml
└── package.json
```
