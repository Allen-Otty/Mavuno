alter table public.messages add column if not exists read_at timestamptz;

create or replace function public.shares_order(other uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.orders o join public.farms f on f.id = o.farm_id
    where (o.buyer_id = other and f.owner_id = auth.uid()) or (f.owner_id = other and o.buyer_id = auth.uid()))
$$;
revoke execute on function public.shares_order(uuid) from public, anon;
grant execute on function public.shares_order(uuid) to authenticated;

drop policy if exists "profile counterparty read" on public.profiles;
create policy "profile counterparty read" on public.profiles for select to authenticated
using (public.shares_order(id));

create or replace function public.mark_read(p_order uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  if exists (select 1 from public.orders o where o.id = p_order and (o.buyer_id = auth.uid()
      or exists (select 1 from public.farms f where f.id = o.farm_id and f.owner_id = auth.uid()))) then
    update public.messages set read_at = now() where order_id = p_order and sender_id <> auth.uid() and read_at is null;
  end if;
end $$;
revoke execute on function public.mark_read(uuid) from public, anon;
grant execute on function public.mark_read(uuid) to authenticated;
