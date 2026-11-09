-- 1) Create profile automatically on sign-up; self-service roles limited to buyer/farmer
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare r public.user_role;
begin
  r := case when new.raw_user_meta_data->>'role' = 'farmer' then 'farmer'::public.user_role else 'buyer'::public.user_role end;
  insert into public.profiles (id, role, full_name, phone, county, ward)
  values (new.id, r, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'phone',
          new.raw_user_meta_data->>'county', new.raw_user_meta_data->>'ward')
  on conflict (id) do nothing;
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

-- 2) Close privilege escalation: clients may no longer insert profiles or change their own role
drop policy if exists "own profile insert" on public.profiles;
create or replace function public.lock_role() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is not null then new.role := old.role; end if;
  return new;
end $$;
drop trigger if exists lock_profile_role on public.profiles;
create trigger lock_profile_role before update on public.profiles for each row execute function public.lock_role();

-- 3) Exact farm pin visible to a buyer only once they have an active order with that farm
drop policy if exists "location buyer with order" on public.farm_locations;
create policy "location buyer with order" on public.farm_locations for select to authenticated
using (exists (select 1 from public.orders o where o.farm_id = farm_locations.farm_id
  and o.buyer_id = (select auth.uid()) and o.status not in ('rejected','cancelled')));

-- 4) Photo storage: public read, users write only inside their own folder
insert into storage.buckets (id, name, public) values ('photos','photos', true) on conflict (id) do nothing;
drop policy if exists "photos upload own folder" on storage.objects;
create policy "photos upload own folder" on storage.objects for insert to authenticated
with check (bucket_id = 'photos' and (storage.foldername(name))[1] = (select auth.uid())::text);
