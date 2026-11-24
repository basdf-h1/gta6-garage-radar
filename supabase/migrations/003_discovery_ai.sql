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
