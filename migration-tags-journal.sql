-- Run in Supabase > SQL Editor. Safe to re-run.

-- Tags on items
alter table items add column if not exists tags text;

-- Usage Journal table
create table if not exists usage_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  item_id uuid references items on delete set null,
  item_name text,
  amount text,
  note text,
  ts timestamptz default now()
);
alter table usage_log enable row level security;
drop policy if exists ul_select on usage_log;
drop policy if exists ul_insert on usage_log;
drop policy if exists ul_delete on usage_log;
create policy ul_select on usage_log for select using (auth.uid() = user_id);
create policy ul_insert on usage_log for insert with check (auth.uid() = user_id);
create policy ul_delete on usage_log for delete using (auth.uid() = user_id);
