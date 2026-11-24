-- Garage Radar v0.7 - initial Supabase schema
-- Apply in Supabase SQL Editor. Requires auth.users managed by Supabase Auth.
-- Never put Supabase secret/service_role keys into the public GitHub Pages code.
create extension if not exists pgcrypto;

create table if not exists public.vehicles (
  id text primary key,
  name text not null,
  category text not null check (category in ('Lujo','4x4','Especial')),
  description text,
  status text not null default 'unverified'
    check (status in ('unverified','reported','corroborated','verified')),
  updated_at timestamptz not null default now()
);

create table if not exists public.vehicle_sources (
  id uuid primary key default gen_random_uuid(),
  vehicle_id text not null references public.vehicles(id) on delete cascade,
  source_url text not null check (length(source_url) between 12 and 2048),
  title text,
  observation text,
  observed_on date,
  verification_status text not null default 'reported'
    check (verification_status in ('reported','corroborated','verified','disputed')),
  created_at timestamptz not null default now()
);

create table if not exists public.user_garage (
  user_id uuid not null references auth.users(id) on delete cascade,
  vehicle_id text not null references public.vehicles(id) on delete cascade,
  state text not null check (state in ('owned','wishlist')),
  notes text check (length(notes) <= 2000),
  updated_at timestamptz not null default now(),
  primary key (user_id, vehicle_id)
);

create table if not exists public.farming_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  vehicle_id text not null references public.vehicles(id) on delete cascade,
  attempted_at timestamptz not null default now(),
  zone text,
  found boolean not null default false,
  tracker_status text not null default 'unknown'
    check (tracker_status in ('unknown','none','standard','advanced')),
  registered boolean,
  sold boolean,
  proceeds numeric(12,2) check (proceeds is null or proceeds >= 0),
  expenses numeric(12,2) check (expenses is null or expenses >= 0),
  duration_minutes numeric(9,2) check (duration_minutes is null or duration_minutes > 0),
  respawn_observed boolean,
  notes text check (length(notes) <= 2000),
  created_at timestamptz not null default now()
);

create index if not exists idx_attempts_user_vehicle_time
  on public.farming_attempts (user_id,vehicle_id,attempted_at desc);
create index if not exists idx_sources_vehicle
  on public.vehicle_sources(vehicle_id);

alter table public.vehicles enable row level security;
alter table public.vehicle_sources enable row level security;
alter table public.user_garage enable row level security;
alter table public.farming_attempts enable row level security;

-- Shared catalog is readable, but cannot be edited by unauthenticated clients.
drop policy if exists "Read shared vehicle catalog" on public.vehicles;
create policy "Read shared vehicle catalog" on public.vehicles
  for select to anon, authenticated using (true);
drop policy if exists "Read source evidence" on public.vehicle_sources;
create policy "Read source evidence" on public.vehicle_sources
  for select to anon, authenticated using (true);

-- Personal data is strictly separated by authenticated user.
drop policy if exists "Garage select own" on public.user_garage;
create policy "Garage select own" on public.user_garage
  for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists "Garage insert own" on public.user_garage;
create policy "Garage insert own" on public.user_garage
  for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists "Garage update own" on public.user_garage;
create policy "Garage update own" on public.user_garage
  for update to authenticated using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
drop policy if exists "Garage delete own" on public.user_garage;
create policy "Garage delete own" on public.user_garage
  for delete to authenticated using ((select auth.uid()) = user_id);

drop policy if exists "Attempts select own" on public.farming_attempts;
create policy "Attempts select own" on public.farming_attempts
  for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists "Attempts insert own" on public.farming_attempts;
create policy "Attempts insert own" on public.farming_attempts
  for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists "Attempts update own" on public.farming_attempts;
create policy "Attempts update own" on public.farming_attempts
  for update to authenticated using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
drop policy if exists "Attempts delete own" on public.farming_attempts;
create policy "Attempts delete own" on public.farming_attempts
  for delete to authenticated using ((select auth.uid()) = user_id);

-- Idempotent catalog bootstrap. These are investigative candidates, not verified game facts.
insert into public.vehicles(id,name,category,description,status) values
 ('toros','Pegassi Charred Toros','Lujo','SUV premium; verify tracker and registration','reported'),
 ('firebug','Vapid Firebug Dominator','Especial','Reported near La Cascara Motel','reported'),
 ('montagne','Vapid Montagne XL','4x4','Exact spawn not corroborated','unverified'),
 ('crawler','Canis Crawler','4x4','Location not verified','unverified'),
 ('penumbra','Maibatsu Penumbra FF','Lujo','Location not verified','unverified'),
 ('caracara','Vapid Truth & Justice Caracara','Especial','Reported near June Warehouse','reported'),
 ('smuggler','Vapid Smuggler Caracara','4x4','Reported near Brooks Boatworks','reported'),
 ('thrax','Truffade Thrax','Lujo','Chapter 2 availability not verified','unverified')
on conflict (id) do nothing;

-- No seed records in user_garage or farming_attempts: personal data comes from signed-in users.
