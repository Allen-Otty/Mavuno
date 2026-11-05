# Roadmap

## Done
- Product definition (`docs/PRODUCT.md`).
- Database schema v1 (`supabase/migrations/001_initial_schema.sql`), applied to a Supabase project.
- Interactive demo (`index.html`): sign-up and sign-in, map with category filters, farm pages, chat, orders, photo upload, role dashboards, claymorphism UI. All data is sample data held in the browser.

## Phase 1: real accounts and listings
- Apply `002_roles_help_bulk_photos.sql`.
- Supabase Auth (phone or email) and profile creation per role.
- Farmer profile, products and photo upload (Supabase Storage).
- Map with MapLibre and OpenStreetMap, farm pins with fuzzed location.
- Farm pages, listings and prices from the database.

## Phase 2: trading
- Chat between buyer and farmer, stored in the database.
- Orders, pay on delivery, order status.
- WhatsApp and in-app notifications.
- Reviews.

## Phase 3: trust and support
- Verification flow: CBF report, officer confirmation.
- Complaints with photos, rules, officer resolution.
- Help requests, trainings and partner notices.

## Phase 4: FPOs and bulk
- FPO members, stock and payouts.
- Bulk requests and quotes.

## Phase 5: money
- M-Pesa (Safaricom Daraja) with funds held until delivery, commission and reversals. Legal advice first.
- Riders and delivery jobs.

## Phase 6: scale
- Android app wrapper, more counties, more countries.
