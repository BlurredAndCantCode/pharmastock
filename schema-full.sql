-- ================================================================
-- PharmaStock — COMPLETE schema. Idempotent & safe to run anytime.
-- Does NOT delete or overwrite any of your existing data.
-- Run this whole thing in Supabase → SQL Editor → New query → Run.
-- ================================================================

-- 1) ITEMS (your inventory) --------------------------------------
create table if not exists items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  name text not null,
  category text, form text, qty text, unit text, dose text, uses text,
  price numeric, status text default 'In Stock', reorder text, expiry text, notes text,
  created_at timestamptz default now()
);
-- columns added by later features (safe if they already exist)
alter table items add column if not exists source   text;
alter table items add column if not exists effect   text;
alter table items add column if not exists priority text;
alter table items add column if not exists tags     text;

alter table items enable row level security;
drop policy if exists own_select on items;
drop policy if exists own_insert on items;
drop policy if exists own_update on items;
drop policy if exists own_delete on items;
create policy own_select on items for select using (auth.uid() = user_id);
create policy own_insert on items for insert with check (auth.uid() = user_id);
create policy own_update on items for update using (auth.uid() = user_id);
create policy own_delete on items for delete using (auth.uid() = user_id);

-- 2) CYCLES (your cycle planner) ---------------------------------
create table if not exists cycles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  title text, start_date date, end_date date, cost text, notes text,
  rows jsonb default '[]', created_at timestamptz default now()
);
alter table cycles enable row level security;
drop policy if exists cy_select on cycles;
drop policy if exists cy_insert on cycles;
drop policy if exists cy_update on cycles;
drop policy if exists cy_delete on cycles;
create policy cy_select on cycles for select using (auth.uid() = user_id);
create policy cy_insert on cycles for insert with check (auth.uid() = user_id);
create policy cy_update on cycles for update using (auth.uid() = user_id);
create policy cy_delete on cycles for delete using (auth.uid() = user_id);
