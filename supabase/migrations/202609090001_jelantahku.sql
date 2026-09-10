-- JelantahKu Supabase production-ready schema
-- Run this file once in Supabase SQL Editor.

create extension if not exists pgcrypto;

create type public.user_role as enum ('warga', 'owner', 'admin');
create type public.transaction_type as enum ('deposit', 'withdrawal');
create type public.transaction_status as enum ('pending', 'success', 'failed');

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null default 'Pengguna JelantahKu',
  email text,
  village text,
  role public.user_role not null default 'warga',
  balance numeric(14,2) not null default 0 check (balance >= 0),
  subscription_active boolean not null default false,
  subscription_expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.transactions (
  id text primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  tube_id text not null,
  weight_kg numeric(12,3) not null check (weight_kg >= 0),
  price_per_kg numeric(14,2) not null check (price_per_kg >= 0),
  total_value numeric(14,2) not null check (total_value >= 0),
  type public.transaction_type not null,
  status public.transaction_status not null default 'pending',
  created_at timestamptz not null default now()
);

create index if not exists transactions_user_created_idx
  on public.transactions(user_id, created_at desc);

create table if not exists public.payments (
  order_id text primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  amount numeric(14,2) not null,
  status text not null default 'pending',
  fraud_status text,
  provider text not null default 'midtrans',
  raw_response jsonb,
  paid_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.payments add column if not exists paid_at timestamptz;

create table if not exists public.notification_tokens (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  token text not null,
  platform text,
  created_at timestamptz not null default now(),
  unique(user_id, token)
);

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists payments_set_updated_at on public.payments;
create trigger payments_set_updated_at before update on public.payments
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles(id, name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', new.raw_user_meta_data->>'full_name', split_part(coalesce(new.email, 'Pengguna'), '@', 1)),
    new.email
  )
  on conflict (id) do update set email = excluded.email;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- Atomic + idempotent transaction creation. Client cannot directly mutate balance.
create or replace function public.create_transaction(
  p_id text,
  p_user_id uuid,
  p_tube_id text,
  p_weight_kg numeric,
  p_price_per_kg numeric,
  p_total_value numeric,
  p_type public.transaction_type,
  p_status public.transaction_status,
  p_created_at timestamptz
)
returns public.transactions
language plpgsql
security definer set search_path = public
as $$
declare
  existing_tx public.transactions;
  result_tx public.transactions;
  delta numeric := 0;
begin
  if auth.uid() is null or auth.uid() <> p_user_id then
    raise exception 'not authorized';
  end if;

  select * into existing_tx from public.transactions where id = p_id;
  if found then
    return existing_tx;
  end if;

  if p_status = 'success' then
    if p_type = 'deposit' then delta := p_total_value;
    elsif p_type = 'withdrawal' then delta := -p_total_value;
    end if;
  end if;

  if delta < 0 then
    update public.profiles
    set balance = balance + delta
    where id = p_user_id and balance + delta >= 0;
    if not found then raise exception 'insufficient balance'; end if;
  elsif delta > 0 then
    update public.profiles set balance = balance + delta where id = p_user_id;
  end if;

  insert into public.transactions(id, user_id, tube_id, weight_kg, price_per_kg, total_value, type, status, created_at)
  values(p_id, p_user_id, p_tube_id, p_weight_kg, p_price_per_kg, p_total_value, p_type, p_status, p_created_at)
  returning * into result_tx;

  return result_tx;
end;
$$;

-- RLS
alter table public.profiles enable row level security;
alter table public.transactions enable row level security;
alter table public.payments enable row level security;
alter table public.notification_tokens enable row level security;

revoke all on public.profiles from anon;
revoke all on public.transactions from anon;
revoke all on public.payments from anon;
revoke all on public.notification_tokens from anon;

grant select, insert, update on public.profiles to authenticated;
grant select on public.transactions to authenticated;
grant select on public.payments to authenticated;
grant select, insert, update, delete on public.notification_tokens to authenticated;
grant execute on function public.create_transaction(text, uuid, text, numeric, numeric, numeric, public.transaction_type, public.transaction_status, timestamptz) to authenticated;

create policy profiles_select_own on public.profiles for select to authenticated using (id = auth.uid());
create policy profiles_insert_own on public.profiles for insert to authenticated with check (id = auth.uid());
create policy profiles_update_own on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

create policy transactions_select_own on public.transactions for select to authenticated using (user_id = auth.uid());
create policy payments_select_own on public.payments for select to authenticated using (user_id = auth.uid());
create policy notification_tokens_own on public.notification_tokens for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Realtime for transaction/balance updates.
alter table public.profiles replica identity full;
alter table public.transactions replica identity full;
do $$ begin
  alter publication supabase_realtime add table public.profiles;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.transactions;
exception when duplicate_object then null; end $$;

-- Prevent clients from changing privileged financial fields directly through normal updates.
create or replace function public.protect_profile_financial_fields()
returns trigger language plpgsql as $$
begin
  if auth.uid() = old.id then
    new.balance := old.balance;
    new.role := old.role;
    new.subscription_active := old.subscription_active;
    new.subscription_expires_at := old.subscription_expires_at;
  end if;
  return new;
end;
$$;

drop trigger if exists protect_profile_financial_fields on public.profiles;
create trigger protect_profile_financial_fields before update on public.profiles
for each row execute function public.protect_profile_financial_fields();
