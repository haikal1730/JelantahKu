-- Fitur pengambilan minyak: tetap 3 role (warga, admin, owner).
create table if not exists public.pickup_requests (
  id uuid primary key default gen_random_uuid(),
  resident_id uuid not null references public.profiles(id) on delete cascade,
  location text,
  fill_percentage numeric(5,2) not null default 90,
  status text not null default 'menunggu' check (status in ('menunggu','dijadwalkan','sudah_diambil','dibatalkan')),
  scheduled_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.pickup_requests enable row level security;

create policy pickup_select_own on public.pickup_requests
for select to authenticated using (resident_id = auth.uid());

create policy pickup_insert_own on public.pickup_requests
for insert to authenticated with check (resident_id = auth.uid());

-- Admin/owner dapat membaca seluruh permintaan melalui backend/service role.
