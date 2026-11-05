-- LeadLoop schema (Supabase / Postgres)
-- One owner per row; RLS keeps every user inside their own data.
-- Follow-up ladder: a lead is due on day 1, day 3 and day 7 after the last
-- contact (or after creation). The app stores next_follow_up_at explicitly
-- so "due today" is a simple indexed query.

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  business_name text,
  whatsapp_number text,
  created_at timestamptz not null default now()
);

create table if not exists public.leads (
  id uuid primary key default gen_random_uuid(),
  owner uuid not null references public.profiles (id) on delete cascade,
  name text not null,
  phone text,                       -- WhatsApp number, international format
  source text,                      -- where the lead came from (Facebook, referral, ...)
  notes text,
  status text not null default 'new'
    check (status in ('new', 'contacted', 'interested', 'won', 'lost')),
  value numeric(12, 2),             -- expected deal value
  currency text not null default 'BDT',
  created_at timestamptz not null default now(),
  last_contacted_at timestamptz,
  next_follow_up_at timestamptz not null default now()
);

create index if not exists leads_owner_due_idx
  on public.leads (owner, next_follow_up_at)
  where status not in ('won', 'lost');

create table if not exists public.follow_up_events (
  id uuid primary key default gen_random_uuid(),
  lead_id uuid not null references public.leads (id) on delete cascade,
  owner uuid not null references public.profiles (id) on delete cascade,
  kind text not null
    check (kind in ('whatsapp', 'call', 'note', 'status_change', 'payment')),
  body text,
  created_at timestamptz not null default now()
);

create index if not exists events_lead_idx
  on public.follow_up_events (lead_id, created_at desc);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  lead_id uuid not null references public.leads (id) on delete cascade,
  owner uuid not null references public.profiles (id) on delete cascade,
  amount numeric(12, 2) not null,
  currency text not null default 'BDT',
  due_date date not null,
  paid_at timestamptz,
  note text,
  created_at timestamptz not null default now()
);

create index if not exists payments_owner_due_idx
  on public.payments (owner, due_date)
  where paid_at is null;

-- Row level security: owner-only access on every table.
alter table public.profiles enable row level security;
alter table public.leads enable row level security;
alter table public.follow_up_events enable row level security;
alter table public.payments enable row level security;

create policy "own profile" on public.profiles
  for all using (id = auth.uid()) with check (id = auth.uid());

create policy "own leads" on public.leads
  for all using (owner = auth.uid()) with check (owner = auth.uid());

create policy "own events" on public.follow_up_events
  for all using (owner = auth.uid()) with check (owner = auth.uid());

create policy "own payments" on public.payments
  for all using (owner = auth.uid()) with check (owner = auth.uid());

-- Create the profile row automatically when a user signs up.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1)))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
