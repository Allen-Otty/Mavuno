# Mavuno: product definition

Everything decided so far, in one place. Items marked **(example)** are illustrations, not commitments.

## 1. Vision

Cut out the middlemen between farm and plate. Households, food vendors, supermarkets and distributors buy directly from farmers and FPOs, so more of the price stays with the farmer. County officers, CBFs and partner organizations join the same platform so farmers get advice, verification and support where they are.

## 2. Principles

- Open-source map (OpenStreetMap), nothing from Google, no per-use map cost.
- Geo-focused: country, then county, then ward, then the exact farm.
- Start simple (pay on delivery), add M-Pesa later without rebuilding.
- Trust comes from declared practices, in-person verification, reviews and clear complaint rules.
- Build with a tiny team: rules over manual case handling.

## 3. Accounts and pages

Every account type has its own sign-up form and its own pages. The app link opens on a sign-up / sign-in page first.

### Farmer (built in demo)
- **Sign-up:** name, phone (WhatsApp), farm name, ward/village, county, directions to the farm (landmarks, road, nearest centre).
- **Profile page:** GPS pin (set on the farm by the farmer or by the team during a visit), directions, farm photo, practices (pesticides, fertilizers, pest control method, farming method), verification status.
- **Products page:** product, category, price, unit, quantity available, photo. **(example)** Mboga (ALVs), KES 10 per bunch, 300 kg.
- **Orders page:** messages from buyers, incoming orders.
- **Help page:** ask a CBF, the county officer or a partner organization; see notices and complaints about the farm.

### FPO (built in demo)
- **Members:** farmers who supply the FPO.
- **Stock:** listed produce with photos, price and quantity.
- **Bulk:** requests from supermarkets and distributors, with a Send quote action.
- **Payouts:** the FPO sells members' produce, keeps the commission it sets, and pays the rest to each farmer directly or through the farmer's savings group.

### CBF: community-based facilitator (built in demo)
- Trains farmers and gives extension services alongside county agricultural officers.
- **Visits:** verification visits using the directions the farmer posted; submits a report.
- **Training:** schedules training sessions.
- **Requests:** help requests from farmers. CBFs are **not assigned** to farmers by anyone; farmers reach out when they need help.
- Accounts are approved by the county agricultural office and Mavuno admins.

### County agricultural officer (basic page in demo)
- Confirms verification reports from CBFs and awards the verified badge.
- Resolves complaints: refund buyer, partial refund, dismiss.
- Answers help requests and oversees CBFs.

### Partner organization / NGO (basic page in demo)
- Programme overview, notices to farmers, answers help requests, offers services farmers can ask for.
- **(example)** names used in the demo: CIDCO, CGA, Vibrant Village. They are examples only, not confirmed partners.

### Local buyer: household or food vendor (basic page in demo)
- Finds farms on the map, chats, orders, reports problems, leaves reviews.

### Bulk buyer: supermarket, distributor, restaurant, school (basic page in demo)
- Posts bulk requests (product, quantity, frequency) and receives quotes from FPOs.

### Rider (basic page in demo)
- Boda boda and delivery riders can be listed. Not a focus at launch.

## 4. Core flows

### 4.1 Discovery
Home screen is a map with category chips (All, Beef, Chicken, Eggs, Vegetables, Milk). Tapping a chip filters the farm pins and lists farms with prices. Opening a farm shows photos, verified badge, declared practices, products, prices and quantity.

### 4.2 Location privacy
- The map shows only a general area (about 100 m) for each farm.
- The exact location is revealed to a buyer only after an order or negotiation starts.
- The farmer sets the pin with phone GPS, or the Mavuno team sets it during a visit.

### 4.3 Chat and ordering
- Anyone can message a farm. Buyer and farmer agree the amount (**(example)** "I want mboga for KES 300"), packing, pickup versus delivery, who pays transport, and payment terms.
- Delivery is flexible: buyer collects, farmer delivers, or a rider delivers. Transport cost is negotiated between buyer and farmer.
- Buyers can also place a standard order from the farm page.

### 4.4 Payments
- **Launch:** pay on delivery.
- **Later:** M-Pesa through the app. Money is held until delivery is confirmed, then paid to the farmer minus Mavuno's commission. If the buyer rejects the goods and the farmer confirms they came back as sent, the money is reversed.
- Build a placeholder for M-Pesa now so it can be added without redesign.
- Holding customer money has legal and regulatory requirements in Kenya. Get proper advice before launching escrow.

### 4.5 Disputes and complaints
- Either side can file a complaint: non-payment, no-show, poor quality, other.
- Rules settle most cases: report within a time window (24 hours in the demo), photo evidence required, partial refund option for perishables.
- A county officer resolves what the rules cannot.

### 4.6 Verification
- Farmers do **not** request verification. After sign-up, the Mavuno team (CBFs and county officers) visits using the directions and the practices the farmer posted.
- Flow: farmer signs up, CBF visits and submits a report, county officer confirms, verified badge appears.
- The badge means a person visited. Declared practices are still labelled farmer-declared.
- Reviews from buyers fill the gap where visits are delayed.

### 4.7 Help for farmers
A farmer can ask a CBF, the county officer or a partner organization for help at any time. Replies are tracked as answered.

### 4.8 Bulk trade
Bulk buyers post requests. FPOs see them and send quotes. Order handling after a quote is accepted is still to be designed.

### 4.9 Notifications
WhatsApp and in-app. No SMS for now because of budget.

## 5. Money

Open decision: how Mavuno earns. Options discussed: commission on payments made through the app (preferred once M-Pesa is in), farmer subscription or featured listing, ads from agro-dealers and similar, a fee for verification visits. Rate and plan are not decided.

## 6. Decisions log

| Decision | Detail |
|---|---|
| Name | Mavuno ("harvest"). Check Play Store and domain availability before committing |
| Launch | Kenya, starting around Luanda, Vihiga County |
| Farm data | Founder recruits first farmers in person |
| Payments | Pay on delivery first, M-Pesa later |
| Notifications | WhatsApp and in-app |
| Map | OpenStreetMap, MapLibre. No Google |
| Delivery | Negotiated between buyer and farmer, riders optional |
| Disputes | Rule-based, officers as last resort |
| Verification | Initiated by the team after sign-up, not requested by farmers |
| Build | PWA first, then a mobile app. Timeline can stretch; scope is not cut |
| UI | Claymorphism style on a white background |

## 7. Open questions

- Commission rate and who pays it.
- Legal route for holding M-Pesa funds.
- How a bulk order proceeds after a quote.
- Which countries after Kenya.
- App name availability (Play Store, domain).
