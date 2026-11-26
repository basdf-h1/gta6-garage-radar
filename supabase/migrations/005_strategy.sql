-- v0.15 strategic memory; independent of 004; requires Supabase Auth.
begin;
create table if not exists public.radar_strategy (
 user_id uuid primary key references auth.users(id) on delete cascade,
 payload jsonb not null check(jsonb_typeof(payload)='object' and octet_length(payload::text)<=1000000),
 revision bigint not null default 1 check(revision>0),
 updated_at timestamptz not null default now()
);
alter table public.radar_strategy enable row level security;
revoke all on public.radar_strategy from anon,authenticated;
grant select,insert,update on public.radar_strategy to authenticated;
drop policy if exists strategy_owner on public.radar_strategy;
create policy strategy_owner on public.radar_strategy for all to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
commit;
select relrowsecurity as rls_enabled from pg_class where oid='public.radar_strategy'::regclass;
