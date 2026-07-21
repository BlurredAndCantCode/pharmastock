-- Run in Supabase > SQL Editor. Safe to re-run.
create table if not exists cycles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  title text,
  start_date date,
  end_date date,
  cost text,
  notes text,
  rows jsonb default '[]',
  created_at timestamptz default now()
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
