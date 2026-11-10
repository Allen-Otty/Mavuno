-- Removes everything created by seed_demo.sql (only the @demo.mavuno.app accounts and their farms/products).
delete from public.products where farm_id in (select f.id from public.farms f join auth.users u on u.id=f.owner_id where u.email like '%@demo.mavuno.app');
delete from public.farm_locations where farm_id in (select f.id from public.farms f join auth.users u on u.id=f.owner_id where u.email like '%@demo.mavuno.app');
delete from public.farms where owner_id in (select id from auth.users where email like '%@demo.mavuno.app');
delete from public.profiles where id in (select id from auth.users where email like '%@demo.mavuno.app');
delete from auth.users where email like '%@demo.mavuno.app';
