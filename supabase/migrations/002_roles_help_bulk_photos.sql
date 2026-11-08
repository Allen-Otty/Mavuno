-- MAVUNO migration 002 (NOT YET RUN: test on a dev project first)
-- Adds roles, directions, photos, verification visits, pre-order chat,
-- help requests, bulk requests and quotes, trainings, and privilege protection.
-- If you get "unsafe use of new value", run the three ALTER TYPE lines alone first.

alter type user_role add value if not exists 'cbf';
alter type user_role add value if not exists 'ngo';
alter type user_role add value if not exists 'bulk';

-- ---------- columns ----------
alter table profiles add column if not exists organization text;
alter table profiles add column if not exists service_wards text;
alter table profiles add column if not exists approved boolean not null default false;

alter table farms add column if not exists directions text;
alter table farms add column if not exists photo_url text;
alter table farms add column if not exists verification_status text not null default 'awaiting_visit'
  check (verification_status in ('awaiting_visit','report_submitted','verified'));

alter table products add column if not exists quantity_label text;      -- e.g. '300 kg'
alter table products add column if not exists supplier_farmer_id uuid references profiles(id); -- FPO stock supplier

alter table complaints add column if not exists resolution text;        -- refunded | partial_refund | dismissed
alter table complaints add column if not exists resolved_by uuid references profiles(id);
alter table complaints add column if not exists resolved_at timestamptz;

-- ---------- role helper (only approved accounts count) ----------
create or replace function public.my_role() returns user_role
language sql stable security definer set search_path = public as $$
  select role from profiles where id = auth.uid() and approved
$$;

-- ---------- approval: self-serve roles auto-approved; others need an admin ----------
create or replace function public.profile_guard() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then return new; end if;               -- dashboard / service role
  if new.role::text = 'admin' then raise exception 'Cannot self-assign admin'; end if;
  new.approved := new.role::text in ('buyer','farmer','fpo','bulk','rider');
  return new;
end $$;
drop trigger if exists trg_profile_guard on profiles;
create trigger trg_profile_guard before insert or update of role on profiles
  for each row execute function profile_guard();

-- ---------- protect verification fields on farms ----------
create or replace function public.protect_verification() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null or current_setting('mavuno.skip_protect', true) = '1' then return new; end if;
  if coalesce(public.my_role()::text,'') in ('officer','admin') then return new; end if;
  if tg_op = 'INSERT' then
    new.verified := false; new.verified_by := null; new.verified_at := null;
    new.verification_status := 'awaiting_visit';
  elsif new.verified is distinct from old.verified
     or new.verified_by is distinct from old.verified_by
     or new.verified_at is distinct from old.verified_at
     or new.verification_status is distinct from old.verification_status then
    raise exception 'Only county officers can change verification';
  end if;
  return new;
end $$;
drop trigger if exists trg_protect_verification on farms;
create trigger trg_protect_verification before insert or update on farms
  for each row execute function protect_verification();

-- ---------- verification visits (CBF report -> officer decision) ----------
create table if not exists verification_visits (
  id uuid primary key default gen_random_uuid(),
  farm_id uuid not null references farms(id) on delete cascade,
  cbf_id uuid references profiles(id),
  officer_id uuid references profiles(id),
  gps_matches boolean, practices_confirmed boolean, produce_seen boolean,
  notes text,
  status text not null default 'report_submitted' check (status in ('report_submitted','approved','rejected')),
  created_at timestamptz default now(), decided_at timestamptz
);

create or replace function public.visits_sync() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  perform set_config('mavuno.skip_protect','1',true);
  if tg_op = 'INSERT' then
    update farms set verification_status = 'report_submitted' where id = new.farm_id;
  elsif new.status = 'approved' then
    update farms set verified = true, verification_status = 'verified',
      verified_by = new.officer_id, verified_at = now() where id = new.farm_id;
  elsif new.status = 'rejected' then
    update farms set verified = false, verification_status = 'awaiting_visit' where id = new.farm_id;
  end if;
  perform set_config('mavuno.skip_protect','',true);
  return new;
end $$;
drop trigger if exists trg_visits_sync on verification_visits;
create trigger trg_visits_sync after insert or update of status on verification_visits
  for each row execute function visits_sync();

-- ---------- chat before any order ----------
create table if not exists conversations (
  id uuid primary key default gen_random_uuid(),
  farm_id uuid not null references farms(id) on delete cascade,
  buyer_id uuid not null references profiles(id) on delete cascade,
  created_at timestamptz default now(),
  unique (farm_id, buyer_id)
);
create table if not exists chat_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references conversations(id) on delete cascade,
  sender_id uuid not null references profiles(id),
  body text not null,
  created_at timestamptz default now()
);

-- ---------- help requests from farmers ----------
create table if not exists help_requests (
  id uuid primary key default gen_random_uuid(),
  farmer_id uuid not null references profiles(id) on delete cascade,
  to_role text not null check (to_role in ('cbf','officer','ngo')),
  to_user_id uuid references profiles(id),
  topic text not null,
  reply text,
  status text not null default 'new' check (status in ('new','answered')),
  created_at timestamptz default now()
);

-- ---------- bulk requests and quotes ----------
create table if not exists bulk_requests (
  id uuid primary key default gen_random_uuid(),
  buyer_id uuid not null references profiles(id) on delete cascade,
  product text not null,
  quantity_label text not null,           -- e.g. '300 kg weekly'
  deliver_to text,
  status text not null default 'open' check (status in ('open','closed')),
  created_at timestamptz default now()
);
create table if not exists bulk_quotes (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references bulk_requests(id) on delete cascade,
  fpo_farm_id uuid not null references farms(id) on delete cascade,
  price numeric(12,2),
  note text,
  status text not null default 'sent' check (status in ('sent','accepted','declined')),
  created_at timestamptz default now()
);

-- ---------- trainings ----------
create table if not exists trainings (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null references profiles(id) on delete cascade,
  title text not null,
  ward text,
  starts_at timestamptz,
  notes text,
  created_at timestamptz default now()
);

-- ---------- row level security for new tables ----------
alter table verification_visits enable row level security;
alter table conversations       enable row level security;
alter table chat_messages       enable row level security;
alter table help_requests       enable row level security;
alter table bulk_requests       enable row level security;
alter table bulk_quotes         enable row level security;
alter table trainings           enable row level security;

create policy "visits read" on verification_visits for select using (
  cbf_id = auth.uid()
  or exists (select 1 from farms f where f.id = farm_id and f.owner_id = auth.uid())
  or my_role()::text in ('officer','admin'));
create policy "visits insert" on verification_visits for insert with check (
  cbf_id = auth.uid() and my_role()::text in ('cbf','officer','admin'));
create policy "visits decide" on verification_visits for update
  using (my_role()::text in ('officer','admin')) with check (my_role()::text in ('officer','admin'));

create policy "conv parties" on conversations for all using (
  buyer_id = auth.uid() or exists (select 1 from farms f where f.id = farm_id and f.owner_id = auth.uid()))
  with check (buyer_id = auth.uid());
create policy "chat parties read" on chat_messages for select using (
  exists (select 1 from conversations c where c.id = conversation_id and
    (c.buyer_id = auth.uid() or exists (select 1 from farms f where f.id = c.farm_id and f.owner_id = auth.uid()))));
create policy "chat parties send" on chat_messages for insert with check (
  sender_id = auth.uid() and exists (select 1 from conversations c where c.id = conversation_id and
    (c.buyer_id = auth.uid() or exists (select 1 from farms f where f.id = c.farm_id and f.owner_id = auth.uid()))));

create policy "help read" on help_requests for select using (
  farmer_id = auth.uid() or to_user_id = auth.uid() or my_role()::text = to_role or my_role()::text = 'admin');
create policy "help create" on help_requests for insert with check (farmer_id = auth.uid());
create policy "help answer" on help_requests for update using (
  to_user_id = auth.uid() or my_role()::text = to_role or my_role()::text = 'admin');

create policy "bulk req read" on bulk_requests for select using (
  buyer_id = auth.uid() or my_role()::text in ('fpo','farmer','admin'));
create policy "bulk req create" on bulk_requests for insert with check (
  buyer_id = auth.uid() and my_role()::text = 'bulk');
create policy "bulk req own update" on bulk_requests for update using (buyer_id = auth.uid());

create policy "bulk quote read" on bulk_quotes for select using (
  exists (select 1 from bulk_requests r where r.id = request_id and r.buyer_id = auth.uid())
  or exists (select 1 from farms f where f.id = fpo_farm_id and f.owner_id = auth.uid()));
create policy "bulk quote create" on bulk_quotes for insert with check (
  exists (select 1 from farms f where f.id = fpo_farm_id and f.owner_id = auth.uid() and f.is_fpo));
create policy "bulk quote respond" on bulk_quotes for update using (
  exists (select 1 from bulk_requests r where r.id = request_id and r.buyer_id = auth.uid()));

create policy "training read" on trainings for select using (true);
create policy "training write" on trainings for insert with check (
  host_id = auth.uid() and my_role()::text in ('cbf','ngo','officer','admin'));

-- officers resolve complaints and can see the related order
create policy "complaints officers read" on complaints for select using (my_role()::text in ('officer','admin'));
create policy "complaints officers resolve" on complaints for update using (my_role()::text in ('officer','admin'));
create policy "orders officers read" on orders for select using (my_role()::text in ('officer','admin'));
