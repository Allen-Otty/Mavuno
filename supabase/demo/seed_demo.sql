-- Demo data for Mavuno: 6 sample farms with produce. Safe to remove with remove_demo.sql.
-- Demo farmers are placeholder accounts (@demo.mavuno.app) with no password, so nobody can log in as them.
do $$
declare r record; uid uuid; fid uuid;
begin
  for r in select * from (values
    (1,'Mwangi Greens','Fresh vegetables grown without chemical sprays on the slopes of Mt Kenya.','Meru','Imenti',0.0470,37.6490,false,
      '[["Vegetables","Tomatoes",80,"kg",120],["Vegetables","Kale (sukuma wiki)",30,"bunch",200],["Vegetables","Cabbage",45,"piece",150],["Vegetables","Spinach",35,"bunch",100]]'),
    (2,'Limuru Dairy Farm','Family dairy farm. Milk collected fresh every morning.','Kiambu','Limuru',-1.1090,36.6420,true,
      '[["Dairy","Fresh milk",70,"litre",300],["Dairy","Yoghurt",120,"litre",60],["Dairy","Mala (fermented milk)",100,"litre",80]]'),
    (3,'Naivasha Fresh Fruits','Hass avocados, passion fruit and pawpaw picked to order.','Nakuru','Naivasha',-0.7172,36.4310,true,
      '[["Fruits","Hass avocados",25,"piece",600],["Fruits","Passion fruit",150,"kg",80],["Fruits","Pawpaw",80,"piece",60],["Fruits","Bananas",60,"bunch",90]]'),
    (4,'Mwea Rice Cooperative','Farmer group selling Pishori rice, maize and beans in bulk.','Kirinyaga','Mwea',-0.6590,37.3510,true,
      '[["Grains","Pishori rice",190,"kg",2000],["Grains","Maize",60,"kg",3000],["Grains","Beans",140,"kg",800]]'),
    (5,'Nyando Poultry & Fish','Kienyeji chicken, eggs and fresh tilapia from the lake.','Kisumu','Nyando',-0.1500,34.9500,false,
      '[["Eggs and poultry","Eggs",450,"tray",120],["Eggs and poultry","Kienyeji chicken",900,"piece",40],["Other","Fresh tilapia",500,"kg",70]]'),
    (6,'Tetu Highland Potatoes','Irish potatoes, carrots and garden peas from the Aberdares.','Nyeri','Tetu',-0.4200,36.9500,false,
      '[["Vegetables","Irish potatoes",55,"kg",1500],["Vegetables","Carrots",70,"kg",400],["Vegetables","Garden peas",180,"kg",150]]')
  ) as t(n,name,descr,county,ward,lat,lng,verified,prods)
  loop
    uid := gen_random_uuid();
    insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data)
    values (uid,'00000000-0000-0000-0000-000000000000','authenticated','authenticated','demo'||r.n||'@demo.mavuno.app',
            jsonb_build_object('full_name', r.name||' (demo)','county',r.county,'role','farmer'));
    insert into public.farms (owner_id,name,description,county,ward,public_lat,public_lng,verified,is_fpo)
    values (uid,r.name,r.descr,r.county,r.ward,r.lat,r.lng,r.verified, r.n=4) returning id into fid;
    insert into public.farm_locations (farm_id,lat,lng) values (fid,r.lat,r.lng);
    insert into public.products (farm_id,category,name,price,unit,quantity_available,active)
    select fid, p->>0, p->>1, (p->>2)::numeric, p->>3, (p->>4)::numeric, true from jsonb_array_elements(r.prods::jsonb) p;
  end loop;
end $$;
