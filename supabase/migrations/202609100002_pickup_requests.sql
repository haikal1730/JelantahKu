-- JelantahKu: pickup requests for communal oil tubes.
-- This does NOT add a fourth login role. Field collectors remain operational personnel,
-- while Admin Desa creates/schedules/confirms the pickup.

create table if not exists public.pickup_requests (
  id uuid primary key default gen_random_uuid(),
  tube_id text not null,
  location text not null,
  capacity_liters numeric(12,2) not null check (capacity_liters > 0),
  fill_liters numeric(12,2) not null check (fill_liters >= 0),
  fill_percent numeric(5,2) not null check (fill_percent >= 0 and fill_percent <= 100),
  status text not null default 'menunggu'
    check (status in ('menunggu', 'dijadwalkan', 'selesai', 'dibatalkan')),
  created_by uuid not null references public.profiles(id) on delete restrict,
  scheduled_at timestamptz,
  completed_at timestamptz,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists pickup_requests_status_created_idx
  on public.pickup_requests(status, created_at desc);

create index if not exists pickup_requests_tube_idx
  on public.pickup_requests(tube_id, created_at desc);

create or replace function public.protect_pickup_request_fields()
returns trigger language plpgsql as $$
begin
  new.created_by := old.created_by;
  new.tube_id := old.tube_id;
  new.location := old.location;
  new.capacity_liters := old.capacity_liters;
  new.fill_liters := old.fill_liters;
  new.fill_percent := old.fill_percent;
  return new;
end;
$$;

drop trigger if exists protect_pickup_request_fields on public.pickup_requests;
create trigger protect_pickup_request_fields
before update on public.pickup_requests
for each row execute function public.protect_pickup_request_fields();

-- Keep updated_at in sync.
drop trigger if exists pickup_requests_set_updated_at on public.pickup_requests;
create trigger pickup_requests_set_updated_at
before update on public.pickup_requests
for each row execute function public.set_updated_at();

alter table public.pickup_requests enable row level security;

revoke all on public.pickup_requests from anon;
grant select, insert, update on public.pickup_requests to authenticated;

-- Admin/owner can monitor the operational queue; warga is intentionally excluded
-- because these records represent communal village-tube operations.
create policy pickup_requests_admin_owner_select
on public.pickup_requests
for select to authenticated
using (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role in ('admin', 'owner')
  )
);

create policy pickup_requests_admin_insert
on public.pickup_requests
for insert to authenticated
with check (
  created_by = auth.uid()
  and exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  )
);

create policy pickup_requests_admin_update
on public.pickup_requests
for update to authenticated
using (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  )
)
with check (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  )
);

alter table public.pickup_requests replica identity full;
do $$ begin
  alter publication supabase_realtime add table public.pickup_requests;
exception when duplicate_object then null; end $$;
