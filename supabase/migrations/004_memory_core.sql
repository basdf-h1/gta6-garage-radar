-- Memory Core v0.13. Requires 001 + 002. Includes idempotent 003.
BEGIN;
-- Garage Radar v0.9 — Discovery AI inbox + tasks
-- Execute in Supabase SQL Editor as project owner, after 001_init.sql and 002_api_grants.sql.
-- This migration does not modify or delete current garage/farming data.
create table if not exists public.discovery_sources (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  source_url text not null check (length(source_url) between 12 and 2048),
  creator text not null default '',
  platform text not null default 'other' check (platform in ('instagram','youtube','tiktok','other')),
  title text not null default '',
  notes text not null default '',
  status text not null default 'pending' check(status in ('pending','reviewed','discarded')),
  created_at timestamptz not null default now(),
  unique(user_id,source_url)
);
create table if not exists public.discovery_findings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  source_id uuid not null references public.discovery_sources(id) on delete cascade,
  item_label text not null check (length(item_label) between 1 and 200),
  external_number integer,
  category text not null default 'vehicle' check(category in ('vehicle','location','activity','secret','other')),
  description text not null default '',
  status text not null default 'unverified' check(status in ('unverified','review','approved','discarded')),
  evidence_note text not null default '',
  created_at timestamptz not null default now(),
  unique(source_id,item_label)
);
create table if not exists public.user_tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  finding_id uuid references public.discovery_findings(id) on delete set null,
  title text not null check (length(title) between 1 and 200),
  description text not null default '',
  zone text not null default '',
  priority text not null default 'medium' check(priority in ('low','medium','high')),
  status text not null default 'todo' check(status in ('todo','doing','done','discarded')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_discovery_source_user on public.discovery_sources(user_id,created_at desc);
create index if not exists idx_discovery_findings_user on public.discovery_findings(user_id,source_id);
create index if not exists idx_discovery_tasks_user on public.user_tasks(user_id,status,created_at desc);
alter table public.discovery_sources enable row level security;
alter table public.discovery_findings enable row level security;
alter table public.user_tasks enable row level security;
grant usage on schema public to authenticated;
revoke all on public.discovery_sources,public.discovery_findings,public.user_tasks from anon;
grant select,insert,update,delete on public.discovery_sources,public.discovery_findings,public.user_tasks to authenticated;
drop policy if exists "disc source owner select" on public.discovery_sources;
create policy "disc source owner select" on public.discovery_sources for select to authenticated using ((select auth.uid())=user_id);
drop policy if exists "disc source owner insert" on public.discovery_sources;
create policy "disc source owner insert" on public.discovery_sources for insert to authenticated with check ((select auth.uid())=user_id);
drop policy if exists "disc source owner update" on public.discovery_sources;
create policy "disc source owner update" on public.discovery_sources for update to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
drop policy if exists "disc source owner delete" on public.discovery_sources;
create policy "disc source owner delete" on public.discovery_sources for delete to authenticated using ((select auth.uid())=user_id);
drop policy if exists "disc finding owner select" on public.discovery_findings;
create policy "disc finding owner select" on public.discovery_findings for select to authenticated using ((select auth.uid())=user_id);
drop policy if exists "disc finding owner insert" on public.discovery_findings;
create policy "disc finding owner insert" on public.discovery_findings for insert to authenticated with check ((select auth.uid())=user_id and exists (select 1 from public.discovery_sources s where s.id=source_id and s.user_id=(select auth.uid())));
drop policy if exists "disc finding owner update" on public.discovery_findings;
create policy "disc finding owner update" on public.discovery_findings for update to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id and exists (select 1 from public.discovery_sources s where s.id=source_id and s.user_id=(select auth.uid())));
drop policy if exists "disc finding owner delete" on public.discovery_findings;
create policy "disc finding owner delete" on public.discovery_findings for delete to authenticated using ((select auth.uid())=user_id);
drop policy if exists "disc task owner select" on public.user_tasks;
create policy "disc task owner select" on public.user_tasks for select to authenticated using ((select auth.uid())=user_id);
drop policy if exists "disc task owner insert" on public.user_tasks;
create policy "disc task owner insert" on public.user_tasks for insert to authenticated with check ((select auth.uid())=user_id and (finding_id is null or exists (select 1 from public.discovery_findings f where f.id=finding_id and f.user_id=(select auth.uid()))));
drop policy if exists "disc task owner update" on public.user_tasks;
create policy "disc task owner update" on public.user_tasks for update to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id and (finding_id is null or exists (select 1 from public.discovery_findings f where f.id=finding_id and f.user_id=(select auth.uid()))));
drop policy if exists "disc task owner delete" on public.user_tasks;
create policy "disc task owner delete" on public.user_tasks for delete to authenticated using ((select auth.uid())=user_id);
-- A second user's source/finding cannot be read through private owner policies.
-- Data API verification:
select c.relname as table_name,c.relrowsecurity as rls_enabled,
has_table_privilege('authenticated', c.oid,'SELECT') as can_read,
has_table_privilege('authenticated', c.oid,'INSERT') as can_insert,
has_table_privilege('anon', c.oid,'SELECT') as anon_can_read
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relname in ('discovery_sources','discovery_findings','user_tasks')
order by c.relname;

create table if not exists public.radar_findings (id text primary key, vehicle_id text not null references public.vehicles(id), reference text not null, title text not null, zone text, source_label text not null, description text, status text not null default 'reported' check(status in ('reported','corroborated','verified','disputed')));
create table if not exists public.radar_map_assets (id text primary key, label text not null, width integer not null, height integer not null, revision text not null);
create table if not exists public.radar_locations (id text primary key, finding_id text not null references public.radar_findings(id), map_id text not null references public.radar_map_assets(id), x double precision not null check(x between 0 and 1), y double precision not null check(y between 0 and 1), precision_level text not null check(precision_level in ('regional','point')), note text not null);
create table if not exists public.cheat_catalog (id integer primary key, category text not null, title text not null, sequence text not null, source_label text not null, status text not null default 'reported' check(status in ('reported','corroborated','verified','disputed')));
create table if not exists public.cheat_trials (user_id uuid not null references auth.users(id) on delete cascade, cheat_id integer not null references public.cheat_catalog(id), result text not null check(result in ('pending','works','failed')), updated_at timestamptz not null default now(), primary key(user_id,cheat_id));
create table if not exists public.radar_private_backups (user_id uuid not null references auth.users(id) on delete cascade, snapshot_id uuid not null default gen_random_uuid(), payload jsonb not null check(jsonb_typeof(payload)='object' and octet_length(payload::text)<=2000000), created_at timestamptz not null default now(), primary key(user_id,snapshot_id));
alter table public.radar_findings enable row level security;
revoke all on public.radar_findings from anon,authenticated;
grant select on public.radar_findings to anon,authenticated;
drop policy if exists catalog_read on public.radar_findings;
create policy catalog_read on public.radar_findings for select to anon,authenticated using(true);
alter table public.radar_map_assets enable row level security;
revoke all on public.radar_map_assets from anon,authenticated;
grant select on public.radar_map_assets to anon,authenticated;
drop policy if exists catalog_read on public.radar_map_assets;
create policy catalog_read on public.radar_map_assets for select to anon,authenticated using(true);
alter table public.radar_locations enable row level security;
revoke all on public.radar_locations from anon,authenticated;
grant select on public.radar_locations to anon,authenticated;
drop policy if exists catalog_read on public.radar_locations;
create policy catalog_read on public.radar_locations for select to anon,authenticated using(true);
alter table public.cheat_catalog enable row level security;
revoke all on public.cheat_catalog from anon,authenticated;
grant select on public.cheat_catalog to anon,authenticated;
drop policy if exists catalog_read on public.cheat_catalog;
create policy catalog_read on public.cheat_catalog for select to anon,authenticated using(true);
alter table public.cheat_trials enable row level security;
revoke all on public.cheat_trials from anon,authenticated;
grant select,insert,update,delete on public.cheat_trials to authenticated;
drop policy if exists owner_only on public.cheat_trials;
create policy owner_only on public.cheat_trials for all to authenticated using((select auth.uid())=user_id) with check((select auth.uid())=user_id);
alter table public.radar_private_backups enable row level security;
revoke all on public.radar_private_backups from anon,authenticated;
grant select,insert on public.radar_private_backups to authenticated;
drop policy if exists owner_only on public.radar_private_backups;
create policy owner_only on public.radar_private_backups for all to authenticated using((select auth.uid())=user_id) with check((select auth.uid())=user_id);
insert into public.vehicles(id,name,category,description,status) values
('toros','Pegassi Charred Toros','Lujo','La Perle: reportado; sin coordenada validada','reported'),
('firebug','Vapid Firebug Dominator','Especial','La Cascara Motel: reportado; sin coordenada validada','reported'),
('montagne','Vapid Montagne XL','4x4','Pendiente de comprobación','reported'),
('crawler','Canis Crawler','4x4','Pendiente de comprobación','reported'),
('penumbra','Maibatsu Penumbra FF','Lujo','Pendiente de comprobación','reported'),
('caracara','Vapid Truth & Justice Caracara','Especial','June Warehouse: reportado; sin coordenada validada','reported'),
('smuggler','Vapid Smuggler Caracara','4x4','Brooks Boatworks: reportado; sin coordenada validada','reported'),
('thrax','Truffade Thrax','Lujo','Pendiente de comprobación','reported'),
('dom_charger','Charger estilo Dom · Driveshaft Gauntlet','Especial','Grayson junto a San Malo Bay · cobertizo, según captura de @wiildeyy','reported'),
('yosemite1500','Yosemite 1500','4x4','AfrozPlays: sin ubicación calibrada','reported'),
('hellion','Hellion','4x4','AfrozPlays: sin ubicación calibrada','reported'),
('infernus','Infernus','Lujo','AfrozPlays: sin ubicación calibrada','reported'),
('tempesta','Tempesta','Lujo','AfrozPlays: sin ubicación calibrada','reported'),
('hellfire','Gauntlet Hellfire','Especial','AfrozPlays: sin ubicación calibrada','reported'),
('riata70','Riata ’70','4x4','AfrozPlays: sin ubicación calibrada','reported'),
('mamba_gt','Mamba GT','Lujo','AfrozPlays: sin ubicación calibrada','reported'),
('paragon','Paragon','Lujo','AfrozPlays: sin ubicación calibrada','reported'),
('growler','Growler','Lujo','AfrozPlays: sin ubicación calibrada','reported'),
('zorrusso','Zorrusso','Lujo','AfrozPlays: sin ubicación calibrada','reported'),
('sf90_report','Ferrari SF90 Stradale (reportado)','Lujo','Extremo norte de Vespucci Island','reported'),
('turbo_ruiner','Imponte Turbo Ruiner NOS','Especial','Costa oriental de Key Lento','reported'),
('purple_supercar','Supercar morado (modelo pendiente)','Lujo','Sector occidental de Waxman Island','reported'),
('leonard_bike','Motocicleta rápida (modelo pendiente)','Especial','Leonard County · al este de carretera norte-sur','reported'),
('skyline_report','Nissan Skyline estilo Paul Walker','Especial','Zona urbana junto a autopista elevada y canal; región pendiente','reported'),
('capri_supercar','Superdeportivo de Capri (modelo pendiente)','Lujo','Capri · sector noroeste de la localidad, junto a Capri Sound','reported'),
('futo','Futo','Especial','AfrozPlays: referencia sin calibrar','reported'),
('sultan','Sultan (recompensa)','Especial','AfrozPlays: referencia sin calibrar','reported'),
('wild_hog_planes','Wild Hog Planes','Especial','AfrozPlays: referencia sin calibrar','reported'),
('wyman_wreck','Wyman Wreck','Especial','AfrozPlays: referencia sin calibrar','reported'),
('reynolds_kit','Reynolds Kit Car','Especial','AfrozPlays: referencia sin calibrar','reported'),
('dominator_buggy','Dominator Buggy','4x4','AfrozPlays: referencia sin calibrar','reported'),
('lazer_rhino','P-996 Lazer / Rhino','Especial','AfrozPlays: referencia sin calibrar','reported'),
('meerwunder_wreck','Meerwunder Wreck','Especial','AfrozPlays: referencia sin calibrar','reported'),
('vamos','Vamos','Especial','AfrozPlays: referencia sin calibrar','reported'),
('mt_kalaga','Mt. Kalaga National Park (vehículo no indicado)','Especial','AfrozPlays: referencia sin calibrar','reported'),
('observatory_wreck','Observatory Wreck','Especial','AfrozPlays: referencia sin calibrar','reported'),
('transgressor67','Transgressor ’67','Especial','AfrozPlays: referencia sin calibrar','reported'),
('nightblade','Nightblade','Especial','AfrozPlays: referencia sin calibrar','reported'),
('bf_bandito','BF Bandito','4x4','AfrozPlays: referencia sin calibrar','reported'),
('soaring_phoenix','Soaring Phoenix','Especial','AfrozPlays: referencia sin calibrar','reported'),
('duster','Duster','Especial','AfrozPlays: referencia sin calibrar','reported'),
('dodo_maverick','Dodo + Maverick','Especial','AfrozPlays: referencia sin calibrar','reported'),
('enduro_kayak','Enduro + Kayak','Especial','AfrozPlays: referencia sin calibrar','reported'),
('vitello','Vitello','Lujo','AfrozPlays: referencia sin calibrar','reported'),
('brimstone_golfer','Brimstone Golfer','Especial','AfrozPlays: referencia sin calibrar','reported'),
('squalo','Squalo','Especial','AfrozPlays: referencia sin calibrar','reported'),
('stanier55','Stanier ’55','Especial','AfrozPlays: referencia sin calibrar','reported'),
('banshee','Banshee','Lujo','AfrozPlays: referencia sin calibrar','reported'),
('cheetah95','Cheetah ’95','Lujo','AfrozPlays: referencia sin calibrar','reported'),
('piccia_furia','Piccia Furia','Lujo','AfrozPlays: referencia sin calibrar','reported'),
('emerus','Emerus','Lujo','AfrozPlays: referencia sin calibrar','reported')
on conflict(id) do nothing;
insert into public.radar_findings(id,vehicle_id,reference,title,zone,source_label,description) values
('futo','futo','DISC-002 · 3','Futo','Leonida · mapa AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Transcripción de la captura; puede ser vehículo, transporte o punto de interés. Sin coordenada calibrada.'),
('sultan','sultan','DISC-002 · 4','Sultan (recompensa)','Leonida · mapa AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Transcripción de la captura; puede ser vehículo, transporte o punto de interés. Sin coordenada calibrada.'),
('wild_hog_planes','wild_hog_planes','DISC-002 · 5','Wild Hog Planes','Leonida · mapa AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Transcripción de la captura; puede ser vehículo, transporte o punto de interés. Sin coordenada calibrada.'),
('wyman_wreck','wyman_wreck','DISC-002 · 6','Wyman Wreck','Leonida · mapa AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Transcripción de la captura; puede ser vehículo, transporte o punto de interés. Sin coordenada calibrada.'),
('reynolds_kit','reynolds_kit','DISC-002 · 7','Reynolds Kit Car','Leonida · mapa AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Transcripción de la captura; puede ser vehículo, transporte o punto de interés. Sin coordenada calibrada.'),
('dominator_buggy','dominator_buggy','DISC-002 · 8','Dominator Buggy','Leonida · mapa AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Transcripción de la captura; puede ser vehículo, transporte o punto de interés. Sin coordenada calibrada.'),
('lazer_rhino','lazer_rhino','DISC-002 · 9','P-996 Lazer / Rhino','Leonida · mapa AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Transcripción de la captura; puede ser vehículo, transporte o punto de interés. Sin coordenada calibrada.'),
('meerwunder_wreck','meerwunder_wreck','DISC-002 · 10','Meerwunder Wreck','Leonida · mapa AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Transcripción de la captura; puede ser vehículo, transporte o punto de interés. Sin coordenada calibrada.'),
('vamos','vamos','DISC-002 · 11','Vamos','Leonida · mapa AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Transcripción de la captura; puede ser vehículo, transporte o punto de interés. Sin coordenada calibrada.'),
('mt_kalaga','mt_kalaga','DISC-002 · 12','Mt. Kalaga National Park (vehículo no indicado)','Leonida · mapa AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Transcripción de la captura; puede ser vehículo, transporte o punto de interés. Sin coordenada calibrada.'),
('observatory_wreck','observatory_wreck','DISC-002 · 13','Observatory Wreck','Leonida · mapa AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Transcripción de la captura; puede ser vehículo, transporte o punto de interés. Sin coordenada calibrada.'),
('transgressor67','transgressor67','DISC-002 · 14','Transgressor ’67','Leonida · mapa AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Transcripción de la captura; puede ser vehículo, transporte o punto de interés. Sin coordenada calibrada.'),
('nightblade','nightblade','DISC-002 · 18','Nightblade','Leonida · mapa AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Transcripción de la captura; puede ser vehículo, transporte o punto de interés. Sin coordenada calibrada.'),
('bf_bandito','bf_bandito','DISC-002 · 19','BF Bandito','Leonida · mapa AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Transcripción de la captura; puede ser vehículo, transporte o punto de interés. Sin coordenada calibrada.'),
('soaring_phoenix','soaring_phoenix','DISC-002 · 23','Soaring Phoenix','Leonida · mapa AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Transcripción de la captura; puede ser vehículo, transporte o punto de interés. Sin coordenada calibrada.'),
('duster','duster','DISC-002 · 25','Duster','Leonida · mapa AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Transcripción de la captura; puede ser vehículo, transporte o punto de interés. Sin coordenada calibrada.'),
('dodo_maverick','dodo_maverick','DISC-002 · 27','Dodo + Maverick','Leonida · mapa AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Transcripción de la captura; puede ser vehículo, transporte o punto de interés. Sin coordenada calibrada.'),
('enduro_kayak','enduro_kayak','DISC-002 · 28','Enduro + Kayak','Leonida · mapa AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Transcripción de la captura; puede ser vehículo, transporte o punto de interés. Sin coordenada calibrada.'),
('vitello','vitello','DISC-002 · 29','Vitello','Leonida · mapa AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Transcripción de la captura; puede ser vehículo, transporte o punto de interés. Sin coordenada calibrada.'),
('brimstone_golfer','brimstone_golfer','DISC-002 · 31','Brimstone Golfer','Leonida · mapa AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Transcripción de la captura; puede ser vehículo, transporte o punto de interés. Sin coordenada calibrada.'),
('squalo','squalo','DISC-002 · 32','Squalo','Leonida · mapa AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Transcripción de la captura; puede ser vehículo, transporte o punto de interés. Sin coordenada calibrada.'),
('stanier55','stanier55','DISC-002 · 33','Stanier ’55','Leonida · mapa AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Transcripción de la captura; puede ser vehículo, transporte o punto de interés. Sin coordenada calibrada.'),
('banshee','banshee','DISC-002 · extra','Banshee','Leonida · mapa AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Transcripción de la captura; puede ser vehículo, transporte o punto de interés. Sin coordenada calibrada.'),
('cheetah95','cheetah95','DISC-002 · extra','Cheetah ’95','Leonida · mapa AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Transcripción de la captura; puede ser vehículo, transporte o punto de interés. Sin coordenada calibrada.'),
('piccia_furia','piccia_furia','DISC-002 · extra','Piccia Furia','Leonida · mapa AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Transcripción de la captura; puede ser vehículo, transporte o punto de interés. Sin coordenada calibrada.'),
('emerus','emerus','DISC-002 · sin punto','Emerus','Leonida · mapa AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','La fuente indica sin punto de aparición; condición no verificada.'),
('capri_supercar','capri_supercar','DISC-009','Superdeportivo de Capri','Capri / Capri Sound','Captura Instagram @siidv2','Destino señalado en sector noroeste de Capri. Modelo y precio sin verificar.'),
('skyline_report','skyline_report','DISC-008','Nissan Skyline estilo Paul Walker','Zona urbana junto a autopista y canal; región pendiente','Captura Instagram @tacolive','Marcador al oeste de autopista curva, al sur de canal e intercambiador. Modelo exacto y aparición sin verificar.'),
('leonard_bike','leonard_bike','DISC-007','Motocicleta rápida (modelo pendiente)','Leonard County','Captura Instagram @itsmagicalnova','Al este de una carretera norte-sur, cerca de una intersección. Modelo, velocidad y aparición sin verificar.'),
('sf90_report','sf90_report','DISC-004','Ferrari SF90 Stradale (reportado)','Extremo norte de Vespucci Island','Captura Instagram @incitabletv','Marcador visible en la publicación; coordenadas sin calibrar y aparición no verificada.'),
('turbo_ruiner','turbo_ruiner','DISC-005','Imponte Turbo Ruiner NOS','Costa oriental de Key Lento','Captura Instagram @brayan.zanelatto','Marcador visible en la publicación; coordenadas sin calibrar y aparición no verificada.'),
('purple_supercar','purple_supercar','DISC-006','Supercar morado (modelo pendiente)','Sector occidental de Waxman Island','Captura Instagram @brayan.zanelatto','Marcador visible en la publicación; coordenadas sin calibrar y aparición no verificada.'),
('dom_charger','dom_charger','DISC-003','Charger estilo Dom','Grayson · San Malo Bay','Captura Instagram @wiildeyy (enlace original pendiente)','Buscar cobertizo abierto cerca de San Malo Bay. El Reel indica Slim Jim y repintado negro; verificar condiciones en tu partida.'),
('crawler','crawler','#15','Canis Crawler ’82','Leonida · imagen de AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Posición aproximada en la captura; sin coordenada calibrada. Verificar en el juego.'),
('yosemite1500','yosemite1500','#16','Yosemite 1500','Leonida · imagen de AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Posición aproximada en la captura; sin coordenada calibrada. Verificar en el juego.'),
('hellion','hellion','#17','Hellion','Leonida · imagen de AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Posición aproximada en la captura; sin coordenada calibrada. Verificar en el juego.'),
('infernus','infernus','#20','Infernus','Leonida · imagen de AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Posición aproximada en la captura; sin coordenada calibrada. Verificar en el juego.'),
('tempesta','tempesta','#21','Tempesta','Leonida · imagen de AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Posición aproximada en la captura; sin coordenada calibrada. Verificar en el juego.'),
('toros','toros','#22','Toros','Leonida · imagen de AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Posición aproximada en la captura; sin coordenada calibrada. Verificar en el juego.'),
('hellfire','hellfire','#24','Gauntlet Hellfire','Leonida · imagen de AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Posición aproximada en la captura; sin coordenada calibrada. Verificar en el juego.'),
('riata70','riata70','#26','Riata ’70','Leonida · imagen de AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Posición aproximada en la captura; sin coordenada calibrada. Verificar en el juego.'),
('mamba_gt','mamba_gt','#30','Mamba GT','Leonida · imagen de AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Posición aproximada en la captura; sin coordenada calibrada. Verificar en el juego.'),
('paragon','paragon','#34','Paragon','Leonida · imagen de AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Posición aproximada en la captura; sin coordenada calibrada. Verificar en el juego.'),
('growler','growler','#35','Growler','Leonida · imagen de AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Posición aproximada en la captura; sin coordenada calibrada. Verificar en el juego.'),
('zorrusso','zorrusso','#36','Zorrusso','Leonida · imagen de AfrozPlays','https://www.instagram.com/p/DgCK6zBETx8/','Posición aproximada en la captura; sin coordenada calibrada. Verificar en el juego.')
on conflict(id) do nothing;
insert into public.radar_map_assets values ('master','Leonida — recorte privado',709,886,'master-v11') on conflict(id) do nothing;
insert into public.radar_locations(id,finding_id,map_id,x,y,precision_level,note) values
('dom_charger','dom_charger','master','0.38081805359661497','0.19977426636568849','regional','Centro de localidad según nombre visible en mapa maestro; cobertizo exacto pendiente.'),
('turbo_ruiner','turbo_ruiner','master','0.5669957686882934','0.8532731376975169','regional','Centro de localidad; la costa oriental concreta requiere una referencia adicional.'),
('leonard_bike','leonard_bike','master','0.6840620592383639','0.3476297968397291','regional','Etiqueta regional; no representa una intersección ni punto de aparición.'),
('capri_supercar','capri_supercar','master','0.2863187588152327','0.5225733634311512','regional','Sector aproximado de la localidad; destino exacto pendiente.')
on conflict(id) do nothing;
insert into public.cheat_catalog(id,category,title,sequence,source_label) values
('1','Armas','Set de armas 1 – Armas de matón','R1 R2 L1 L2 ↑ ↑ ↓ ↓ ← →','Captura Instagram @idelt4; transcripción pendiente de validación'),
('2','Armas','Set de armas 2 – Profesional','R1 R1 L1 L1 ← → ← → ↑ ↑','Captura Instagram @idelt4; transcripción pendiente de validación'),
('3','Armas','Set de armas 3 – Armas de loco','R2 R2 L1 L2 ← ← ↑ ↑ → →','Captura Instagram @idelt4; transcripción pendiente de validación'),
('4','Jugador','Dar salud, armadura y $250K','R2 L1 R2 R2 ? △ △ ○ ○','Captura Instagram @idelt4; transcripción pendiente de validación'),
('5','Jugador','Salud y armadura al máximo','L1 R1 L1 R2 ? ← ← → → △','Captura Instagram @idelt4; transcripción pendiente de validación'),
('6','Armas','Munición infinita','L1 R1 ○ ○ ? □ ↑ ↓ ↓','Captura Instagram @idelt4; transcripción pendiente de validación'),
('7','Policía','Subir nivel de búsqueda','R1 R1 R2 R2 ○ ○ ○ ○','Captura Instagram @idelt4; transcripción pendiente de validación'),
('8','Policía','Bajar nivel de búsqueda','R1 R1 L1 L2 ○ ○ □ □','Captura Instagram @idelt4; transcripción pendiente de validación'),
('9','Policía','Quitar nivel de búsqueda','R2 R1 L1 L1 → → ← ←','Captura Instagram @idelt4; transcripción pendiente de validación'),
('10','Policía','Quitar nivel de búsqueda (alternativo)','R1 R2 L2 L1 △ △ △ △','Captura Instagram @idelt4; transcripción pendiente de validación'),
('11','Policía','Desaparece la policía','R1 L1 R1 L2 ○ ○ → ↑','Captura Instagram @idelt4; transcripción pendiente de validación'),
('12','Vehículos','Generar Buzzard','△ △ L1 L1 ○ ○ ○','Captura Instagram @idelt4; transcripción pendiente de validación'),
('13','Vehículos','Generar Comet','R1 R2 L1 L2 → → △ △','Captura Instagram @idelt4; transcripción pendiente de validación'),
('14','Vehículos','Generar PCJ-600','R1 L1 R2 R2 ← ← ○ ○','Captura Instagram @idelt4; transcripción pendiente de validación'),
('15','Vehículos','Generar Sanchez','R2 L2 R1 R1 ↑ ↑ → →','Captura Instagram @idelt4; transcripción pendiente de validación'),
('16','Vehículos','Generar tanque','L1 L2 R1 R2 ○ ○ △ △','Captura Instagram @idelt4; transcripción pendiente de validación'),
('17','Vehículos','Generar jetpack','R1 L1 R2 L2 ↑ ↑ ↑ ↑','Captura Instagram @idelt4; transcripción pendiente de validación'),
('18','Vehículos','Conseguir un helicóptero','△ R1 L1 L2 ← → △ ○','Captura Instagram @idelt4; transcripción pendiente de validación'),
('19','Vehículos','Conseguir un bote','R1 R1 L1 L2 ← ← → →','Captura Instagram @idelt4; transcripción pendiente de validación'),
('20','Vehículos','Conseguir un camión de basura','R2 L1 L2 R1 △ △ ← ←','Captura Instagram @idelt4; transcripción pendiente de validación'),
('21','Vehículos','Conseguir una limusina','L1 R2 R1 L1 → → ○ ○','Captura Instagram @idelt4; transcripción pendiente de validación'),
('22','Vehículos','Conseguir un Caddy','R2 L2 L1 R1 ↑ ↑ △ △','Captura Instagram @idelt4; transcripción pendiente de validación'),
('23','Entorno','Cambiar el clima','R1 L1 R2 L2 □ □ ○ ○','Captura Instagram @idelt4; transcripción pendiente de validación'),
('24','Entorno','Tormenta eléctrica','R2 R1 L2 L1 ↑ ↑ □ □','Captura Instagram @idelt4; transcripción pendiente de validación'),
('25','Jugador','Cámara lenta','L2 R1 L1 L1 ○ ○ △ △','Captura Instagram @idelt4; transcripción pendiente de validación'),
('26','Jugador','Nado rápido','L1 L2 R1 R2 → → ○ ○','Captura Instagram @idelt4; transcripción pendiente de validación'),
('27','Jugador','Super salto','△ △ R1 R2 ↑ ↑ ○ ○','Captura Instagram @idelt4; transcripción pendiente de validación'),
('28','Vehículos','Nitro','L1 R1 R2 L2 ← ← △ ?','Captura Instagram @idelt4; transcripción pendiente de validación')
on conflict(id) do nothing;
COMMIT;
select (select count(*) from public.vehicles) as vehicles,(select count(*) from public.radar_findings) as findings,(select count(*) from public.radar_locations) as regional_locations,(select count(*) from public.cheat_catalog) as cheats;
