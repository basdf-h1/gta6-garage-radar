-- Garage Radar v0.7.1 — explicit Data API grants (Supabase 2026)
-- Run once in Supabase SQL Editor. RLS remains enabled.
grant usage on schema public to anon, authenticated;

-- Public read-only catalog and evidence.
grant select on table public.vehicles, public.vehicle_sources to anon, authenticated;

-- Private user tables: authenticated API sessions only.
revoke all privileges on table public.user_garage, public.farming_attempts from anon;
grant select, insert, update, delete on table public.user_garage, public.farming_attempts to authenticated;

-- Assert RLS remains active on private tables.
do $$
begin
  if exists (
    select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname in ('user_garage','farming_attempts')
    and not c.relrowsecurity
  ) then
    raise exception 'Private user table is missing RLS';
  end if;
end $$;

-- Verify API grants and RLS settings (results should show two private rows).
select c.relname as table_name, c.relrowsecurity as rls_enabled,
       has_table_privilege('authenticated', c.oid, 'SELECT') as authenticated_can_select,
       has_table_privilege('authenticated', c.oid, 'INSERT') as authenticated_can_insert,
       has_table_privilege('anon', c.oid, 'SELECT') as anonymous_can_select
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname='public' and c.relname in ('user_garage','farming_attempts')
order by c.relname;
