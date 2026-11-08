# Technical notes

## Stack

| Part | Choice |
|---|---|
| Front end | Phase 1: PWA (installable website that works on weak connections). Demo is one HTML file. Real app: React with Vite |
| Mobile app | Later, by wrapping the PWA (or React Native with Expo) |
| Backend | Supabase: Postgres, Auth, Storage, Row Level Security, Edge Functions |
| Map | MapLibre GL with OpenStreetMap data. Public OSM tile servers have usage limits, so move to a low-cost tile provider or self-host when traffic grows |
| Notifications | WhatsApp Business Cloud API, called from an Edge Function, plus in-app |
| Payments (later) | Safaricom Daraja (M-Pesa), called only from Edge Functions |
| Demo hosting | GitHub Pages |
| App hosting | Netlify or Vercel (free tiers) |

## Database

Run the files in `supabase/migrations/` in order in the Supabase SQL Editor.

- `001_initial_schema.sql`: profiles, farms, exact locations (private), products, orders, chat per order, payments placeholder, reviews, complaints, advisories, notifications, row-level security, location fuzzing.
- `002_roles_help_bulk_photos.sql`: roles for CBF, partner organization and bulk buyer; farm directions and photo; verification visits; chat before an order; help requests; bulk requests and quotes; trainings; officer access to complaints; protection against self-granting roles or the verified badge.

002 has **not been run yet**. Run it on a test project or branch first and fix any error before using it on real data. If you see "unsafe use of new value" on the first lines, run the three `alter type` lines on their own first, then the rest.

## Security rules

- Row Level Security is on for every table. Never turn it off.
- Only the publishable (anon) key goes in the front end.
- Never commit the `service_role` or secret key, the database password, or `.env`.
- Farm verification and officer, CBF and partner roles must not be self-granted. 002 enforces this with triggers.
- The exact farm location is only readable through `get_exact_location()`, for the owner or a buyer with an active order.
- M-Pesa and WhatsApp credentials live in Edge Function secrets, never in the browser.

## Setup

1. Create a Supabase project.
2. Run the migrations in order.
3. Copy `.env.example` to `.env` and fill in the project URL and publishable key.
4. Create two public storage buckets: `farm-photos` and `product-photos`, with policies so only the owner can upload.
5. Deploy the front end.

## Photos

The demo shrinks images in the browser and keeps them in memory. The real app should upload to Supabase Storage and store the URL in `farms.photo_url` and `products.photo_url`.

## Demo versus real app

The demo (`index.html`) shows the structure, screens and flows. It has no backend: sign-in accepts any phone and PIN, and refreshing the page resets everything.

## PWA (installable app)

The demo is a Progressive Web App: `index.html`, `manifest.webmanifest`, `sw.js` and `icons/` at the repo root.

- **Install:** open the GitHub Pages link in Chrome on Android and tap **Install app** (or the browser menu, then Install). On iPhone, use Share, then Add to Home Screen.
- **Offline:** the service worker caches the app so it opens without a connection. Live data will still need a connection once the Supabase back end is connected.
- **Updating:** when you change `index.html`, edit `const V = "mavuno-v1"` in `sw.js` to a new number (v2, v3...) so phones fetch the new version.
- **Requires HTTPS.** GitHub Pages provides it.
- **Not included yet:** push notifications and background sync. WhatsApp notifications will come from a server function, not from the PWA.
