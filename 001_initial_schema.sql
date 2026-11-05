-- MAVUNO: initial schema (Supabase / Postgres)
-- Run in Supabase SQL Editor.

create extension if not exists "pgcrypto";

-- ENUMS
create type user_role as enum ('buyer','farmer','fpo','advisor','rider','admin');
create type order_status as enum ('pending','accepted','delivered','completed','rejected','disputed','refunded','cancelled');
create type payment_mode as enum ('cash_on_delivery','mpesa_escrow');
create type complaint_status as enum ('open','resolved','dismissed');

-- PROFILES (one per login)
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role user_role not null default 'buyer',
  full_name text,
  phone text,                  -- used for WhatsApp notifications
  country text not null default 'KE',
  county text,
  ward text,
  created_at timestamptz default now()
);

-- FARMS (also used for FPOs: is_fpo = true)
create table farms (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references profiles(id) on delete cascade,
  name text not null,
  description text,
  country text not null default 'KE',
  county text,
  ward text,
  is_fpo boolean default false,
  -- public location is fuzzed (~100 m); exact one lives in farm_locations
  public_lat double precision,
  public_lng double precision,
  -- declared farm practices (self-reported)
  practices jsonb default '{}'::jsonb,   -- {pesticides:[], fertilizers:[], management:""}
  verified boolean default false,        -- true only after Mavuno team visit
  verified_by uuid references profiles(id),
  verified_at timestamptz,
  created_at timestamptz default now()
);

-- EXACT LOCATION (private, revealed only after an order/negotiation starts)
create table farm_locations (
  farm_id uuid primary key references farms(id) on delete cascade,
  lat double precision not null,
  lng double precision not null
);

-- FPO MEMBERS (which farmers supply which FPO)
create table fpo_members (
  fpo_id uuid references farms(id) on delete cascade,
  farmer_id uuid references profiles(id) on delete cascade,
  primary key (fpo_id, farmer_id)
);

-- PRODUCTS
create table products (
  id uuid primary key default gen_random_uuid(),
  farm_id uuid not null references farms(id) on delete cascade,
  category text not null,               -- beef, chicken, eggs, vegetables, ...
  name text not null,
  price numeric(12,2) not null,         -- KES
  unit text not null default 'kg',
  quantity_available numeric(12,2),
  photo_url text,
  active boolean default true,
  created_at timestamptz default now()
);

-- ORDERS
create table orders (
  id uuid primary key default gen_random_uuid(),
  buyer_id uuid not null references profiles(id),
  farm_id uuid not null references farms(id),
  status order_status not null default 'pending',
  payment_mode payment_mode not null default 'cash_on_delivery',
  fulfilment text default 'to_negotiate',  -- pickup | farmer_delivery | rider
  transport_cost numeric(12,2) default 0,
  rider_id uuid references profiles(id),
  total numeric(12,2) default 0,
  commission_rate numeric(5,4) default 0,  -- used when escrow is enabled
  delivered_at timestamptz,
  created_at timestamptz default now()
);

create table order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders(id) on delete cascade,
  product_id uuid not null references products(id),
  quantity numeric(12,2) not null,
  unit_price numeric(12,2) not null
);

-- CHAT between buyer and farmer (negotiation)
create table messages (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders(id) on delete cascade,
  sender_id uuid not null references profiles(id),
  body text not null,
  created_at timestamptz default now()
);

-- PAYMENTS (placeholder for M-Pesa escrow later)
create table payments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders(id) on delete cascade,
  provider text default 'mpesa',
  provider_ref text,
  amount numeric(12,2),
  held boolean default false,
  released boolean default false,
  refunded boolean default false,
  created_at timestamptz default now()
);

-- REVIEWS
create table reviews (
  id uuid primary key default gen_random_uuid(),
  order_id uuid unique not null references orders(id),
  farm_id uuid not null references farms(id),
  buyer_id uuid not null references profiles(id),
  rating int check (rating between 1 and 5),
  comment text,
  created_at timestamptz default now()
);

-- COMPLAINTS / DISPUTES (rule-based: photos + report window)
create table complaints (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders(id),
  raised_by uuid not null references profiles(id),
  reason text not null,           -- non_payment | no_show | poor_quality | other
  details text,
  photo_urls text[] default '{}',
  status complaint_status default 'open',
  created_at timestamptz default now()
);

-- ADVISOR POSTS (extension officers, NGOs: advice, alerts, trainings)
create table advisories (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references profiles(id),
  county text,
  ward text,
  title text not null,
  body text,
  created_at timestamptz default now()
);

-- NOTIFICATIONS (in-app; WhatsApp sending is added later)
create table notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  title text,
  body text,
  read boolean default false,
  created_at timestamptz default now()
);

-- ---------- LOCATION PRIVACY ----------
-- Exact pin is returned only to the farm owner or to a buyer with an order on that farm.
create or replace function get_exact_location(p_farm_id uuid)
returns table (lat double precision, lng double precision)
language sql security definer set search_path = public as $$
  select l.lat, l.lng
  from farm_locations l
  join farms f on f.id = l.farm_id
  where l.farm_id = p_farm_id
    and (
      f.owner_id = auth.uid()
      or exists (select 1 from orders o
                 where o.farm_id = p_farm_id and o.buyer_id = auth.uid()
                   and o.status not in ('rejected','cancelled'))
    );
$$;

-- Fuzz the public pin by up to ~100 m whenever a farm is saved with an exact location.
create or replace function fuzz_public_location() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  update farms
  set public_lat = new.lat + (random() - 0.5) * 0.0018,
      public_lng = new.lng + (random() - 0.5) * 0.0018
  where id = new.farm_id;
  return new;
end $$;

create trigger trg_fuzz after insert or update of lat, lng on farm_locations
for each row execute function fuzz_public_location();

-- ---------- ROW LEVEL SECURITY ----------
alter table profiles        enable row level security;
alter table farms           enable row level security;
alter table farm_locations  enable row level security;
alter table fpo_members     enable row level security;
alter table products        enable row level security;
alter table orders          enable row level security;
alter table order_items     enable row level security;
alter table messages        enable row level security;
alter table payments        enable row level security;
alter table reviews         enable row level security;
alter table complaints      enable row level security;
alter table advisories      enable row level security;
alter table notifications   enable row level security;

-- Profiles: read/update own
create policy "own profile read"   on profiles for select using (id = auth.uid());
create policy "own profile write"  on profiles for update using (id = auth.uid());
create policy "own profile insert" on profiles for insert with check (id = auth.uid());

-- Farms & products: public read, owner write
create policy "farms public read"  on farms for select using (true);
create policy "farms owner write"  on farms for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "products public read" on products for select using (true);
create policy "products owner write" on products for all
  using (exists (select 1 from farms f where f.id = farm_id and f.owner_id = auth.uid()))
  with check (exists (select 1 from farms f where f.id = farm_id and f.owner_id = auth.uid()));

-- Exact locations: owner only (buyers go through get_exact_location())
create policy "location owner only" on farm_locations for all
  using (exists (select 1 from farms f where f.id = farm_id and f.owner_id = auth.uid()))
  with check (exists (select 1 from farms f where f.id = farm_id and f.owner_id = auth.uid()));

-- Orders: buyer or farm owner can see
create policy "orders parties read" on orders for select using (
  buyer_id = auth.uid()
  or exists (select 1 from farms f where f.id = farm_id and f.owner_id = auth.uid()));
create policy "orders buyer create" on orders for insert with check (buyer_id = auth.uid());
create policy "orders parties update" on orders for update using (
  buyer_id = auth.uid()
  or exists (select 1 from farms f where f.id = farm_id and f.owner_id = auth.uid()));

create policy "items parties read" on order_items for select using (
  exists (select 1 from orders o where o.id = order_id and
    (o.buyer_id = auth.uid() or exists (select 1 from farms f where f.id = o.farm_id and f.owner_id = auth.uid()))));
create policy "items buyer create" on order_items for insert with check (
  exists (select 1 from orders o where o.id = order_id and o.buyer_id = auth.uid()));

-- Messages: only the two parties on the order
create policy "messages parties" on messages for all using (
  exists (select 1 from orders o where o.id = order_id and
    (o.buyer_id = auth.uid() or exists (select 1 from farms f where f.id = o.farm_id and f.owner_id = auth.uid()))))
  with check (sender_id = auth.uid());

-- Reviews: public read, buyer writes own
create policy "reviews public read" on reviews for select using (true);
create policy "reviews buyer write" on reviews for insert with check (buyer_id = auth.uid());

-- Complaints: parties only
create policy "complaints parties" on complaints for all using (
  raised_by = auth.uid() or exists (select 1 from orders o where o.id = order_id and
    (o.buyer_id = auth.uid() or exists (select 1 from farms f where f.id = o.farm_id and f.owner_id = auth.uid()))))
  with check (raised_by = auth.uid());

-- Advisories: public read, advisors write
create policy "advisories public read" on advisories for select using (true);
create policy "advisories advisor write" on advisories for insert with check (
  author_id = auth.uid() and exists (select 1 from profiles p where p.id = auth.uid() and p.role in ('advisor','admin')));

-- Notifications: own only
create policy "notifications own" on notifications for all using (user_id = auth.uid());

-- FPO members: public read, FPO owner manages
create policy "fpo members read" on fpo_members for select using (true);
create policy "fpo members owner" on fpo_members for all
  using (exists (select 1 from farms f where f.id = fpo_id and f.owner_id = auth.uid()))
  with check (exists (select 1 from farms f where f.id = fpo_id and f.owner_id = auth.uid()));

-- Payments: parties can read; writes happen later via a secure server function (M-Pesa)
create policy "payments parties read" on payments for select using (
  exists (select 1 from orders o where o.id = order_id and
    (o.buyer_id = auth.uid() or exists (select 1 from farms f where f.id = o.farm_id and f.owner_id = auth.uid()))));
