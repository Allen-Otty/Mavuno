# Mavuno 🌾

**Farm to plate, no middlemen.**

Mavuno ("harvest" in Swahili) is a map-based marketplace that connects farmers, farmer produce organizations (FPOs), households, food vendors and bulk buyers directly. County agricultural officers, community-based facilitators (CBFs) and partner organizations support farmers on the same platform.

- **Pilot area:** Luanda, Vihiga County, Kenya. Kenya first, then other African countries.
- **Inspired by** the US app Localize, rebuilt for African markets: pay on delivery, WhatsApp notifications, M-Pesa later.
- **Live demo (sample data only):** https://allen-otty.github.io/Mavuno/

## What it does

1. Open the map, pick a category (beef, chicken, eggs, vegetables, milk) and see nearby farms with prices.
2. Farmers post listings with photos, price per unit, quantity and their farm practices.
3. Anyone can message a farmer, agree amount, packing, delivery and payment terms, and order.
4. Pay on delivery at launch. M-Pesa payments held until delivery come later.
5. Farms are verified in person by CBFs and county officers. Complaints are settled by rules and officers.
6. FPOs and bulk buyers (supermarkets, distributors) trade in bulk on the same platform.

## Accounts

| Account | What they do |
|---|---|
| Farmer | Lists produce with photos, declares practices, chats with buyers, fulfils orders, asks for help |
| FPO | Sells members' produce in bulk, lists stock, quotes bulk requests, pays members |
| Local buyer (household or food vendor) | Finds farms on the map, chats, orders, reports problems |
| Bulk buyer (supermarket, distributor, restaurant, school) | Posts bulk requests, receives quotes from FPOs |
| CBF (community-based facilitator) | Trains and monitors farmers, does verification visits, answers help requests |
| County agricultural officer | Confirms verification, resolves complaints, oversees CBFs |
| Partner organization / NGO | Offers support and trainings, sends notices to farmers |
| Rider (boda boda / delivery) | Delivers orders (listed at launch, not the focus) |

## Repo layout

```
index.html                     Installable demo app (PWA, single file, sample data), served by GitHub Pages
manifest.webmanifest           PWA manifest (name, icons, colours)
sw.js                          Service worker (offline support). Change the version in it when index.html changes
icons/                         App icons
docs/PRODUCT.md                Vision, accounts and pages, flows, decisions
docs/ROADMAP.md                Phases and what is built vs planned
docs/TECH.md                   Stack, database, security, setup
supabase/migrations/           SQL for the database (run in order)
.env.example                   Environment variables (placeholders only)
```

## Status

Demo built and shared. The real app is not built yet: next step is connecting the front end to Supabase (accounts, listings, photos, chat). See `docs/ROADMAP.md`.

## Updating the demo link

Upload a new `index.html` to the repo root (Add file → Upload files → Commit). GitHub Pages refreshes in about a minute.

## Real app vs demo
- `index.html` is the real app: email + password accounts, farms on a map, produce listings with photos, order requests and chat, all stored in Supabase.
- `demo.html` is the earlier clickable demo with sample data.
- Maps: set `GMAPS_KEY` near the top of `index.html` to use Google Maps (restrict the key to your site address in Google Cloud). While it is empty the app uses free OpenStreetMap.
- Database changes live in `supabase/migrations/`. Migrations 003 and 004 are already applied to the Supabase project.
