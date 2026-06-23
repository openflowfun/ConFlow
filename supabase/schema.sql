-- ============================================================
--  ConFlow — Supabase Database Schema
--  Use this when migrating from localStorage to Supabase
--  Run this in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ── Profiles (extends Supabase auth.users) ────────────────
create table public.profiles (
  id          uuid references auth.users(id) on delete cascade primary key,
  name        text not null,
  company     text,
  initials    text,
  email       text,
  created_at  timestamptz default now()
);
alter table public.profiles enable row level security;
create policy "Users can view own profile"   on public.profiles for select using (auth.uid() = id);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);
create policy "Users can insert own profile" on public.profiles for insert with check (auth.uid() = id);

-- ── Projects ──────────────────────────────────────────────
create table public.projects (
  id          uuid default uuid_generate_v4() primary key,
  user_id     uuid references auth.users(id) on delete cascade not null,
  name        text not null,
  client      text,
  address     text,
  status      text default 'active',   -- active | planning | complete | on-hold
  progress    int  default 0,
  budget      numeric(12,2) default 0,
  start_date  date,
  due_date    date,
  description text,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);
alter table public.projects enable row level security;
create policy "Users manage own projects" on public.projects for all using (auth.uid() = user_id);
create index on public.projects(user_id);

-- ── Quotes ────────────────────────────────────────────────
create table public.quotes (
  id          uuid default uuid_generate_v4() primary key,
  user_id     uuid references auth.users(id) on delete cascade not null,
  quote_ref   text,                          -- e.g. Q-001
  title       text not null,
  client      text,
  status      text default 'draft',          -- draft | sent | accepted | declined
  total       numeric(12,2) default 0,
  line_items  jsonb default '[]',
  date        date default current_date,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);
alter table public.quotes enable row level security;
create policy "Users manage own quotes" on public.quotes for all using (auth.uid() = user_id);
create index on public.quotes(user_id);

-- ── Invoices ──────────────────────────────────────────────
create table public.invoices (
  id          uuid default uuid_generate_v4() primary key,
  user_id     uuid references auth.users(id) on delete cascade not null,
  invoice_num text,                          -- e.g. INV-2026-001
  client      text,
  project     text,
  type        text default 'Tax Invoice',    -- Tax Invoice | Progress Claim
  amount      numeric(12,2) default 0,
  gst         numeric(12,2) default 0,
  status      text default 'Draft',          -- Draft | Pending | Paid | Overdue
  date        date default current_date,
  due_date    date,
  notes       text,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);
alter table public.invoices enable row level security;
create policy "Users manage own invoices" on public.invoices for all using (auth.uid() = user_id);
create index on public.invoices(user_id);

-- ── Crew Members ──────────────────────────────────────────
create table public.crew_members (
  id          uuid default uuid_generate_v4() primary key,
  user_id     uuid references auth.users(id) on delete cascade not null,
  name        text not null,
  role        text,
  site        text,
  phone       text,
  email       text,
  color       text,                          -- Tailwind class for avatar
  status      text default 'active',         -- active | inactive
  notes       text,
  created_at  timestamptz default now()
);
alter table public.crew_members enable row level security;
create policy "Users manage own crew" on public.crew_members for all using (auth.uid() = user_id);
create index on public.crew_members(user_id);

-- ── Variations ────────────────────────────────────────────
create table public.variations (
  id          uuid default uuid_generate_v4() primary key,
  user_id     uuid references auth.users(id) on delete cascade not null,
  var_num     text,                          -- e.g. #VAR-027
  title       text not null,
  description text,
  site        text,
  amount      numeric(12,2) default 0,
  status      text default 'pending',        -- pending | approved | rejected
  date        date default current_date,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);
alter table public.variations enable row level security;
create policy "Users manage own variations" on public.variations for all using (auth.uid() = user_id);
create index on public.variations(user_id);

-- ── Compliance / Documents ────────────────────────────────
create table public.documents (
  id          uuid default uuid_generate_v4() primary key,
  user_id     uuid references auth.users(id) on delete cascade not null,
  name        text not null,
  category    text,                          -- Plans & Drawings | Contracts | Photos | etc.
  project     text,
  file_url    text,                          -- Supabase Storage URL
  file_size   text,
  version     int default 1,
  date        date default current_date,
  icon        text,
  color       text,
  bg          text,
  created_at  timestamptz default now()
);
alter table public.documents enable row level security;
create policy "Users manage own documents" on public.documents for all using (auth.uid() = user_id);
create index on public.documents(user_id);

-- ── Chat Messages ─────────────────────────────────────────
create table public.chat_messages (
  id          uuid default uuid_generate_v4() primary key,
  user_id     uuid references auth.users(id) on delete cascade not null,
  contact     text not null,                 -- e.g. 'Site Foreman', 'Sparky'
  direction   text not null,                 -- 'me' | 'them'
  content     text not null,
  sent_at     timestamptz default now()
);
alter table public.chat_messages enable row level security;
create policy "Users manage own messages" on public.chat_messages for all using (auth.uid() = user_id);
create index on public.chat_messages(user_id, contact);

-- ── Updated-at trigger (auto-updates updated_at columns) ──
create or replace function public.handle_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger set_updated_at before update on public.projects    for each row execute function handle_updated_at();
create trigger set_updated_at before update on public.quotes      for each row execute function handle_updated_at();
create trigger set_updated_at before update on public.invoices    for each row execute function handle_updated_at();
create trigger set_updated_at before update on public.variations  for each row execute function handle_updated_at();

-- ── New user profile trigger ───────────────────────────────
-- Automatically creates a profile row when someone signs up via Supabase Auth
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, email, name, company)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email,'@',1)),
    coalesce(new.raw_user_meta_data->>'company', '')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
