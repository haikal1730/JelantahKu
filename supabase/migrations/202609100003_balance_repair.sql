-- JelantahKu: balance consistency + repair
-- Run after 202609090001_jelantahku.sql.
-- Fixes profiles.balance so it is derived from successful ledger transactions.

-- Rebuild a user's balance from the transaction ledger.
create or replace function public.repair_my_balance()
returns numeric
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_balance numeric(14,2);
begin
  if v_user_id is null then
    raise exception 'not authorized';
  end if;

  select coalesce(
    sum(
      case
        when type = 'deposit' and status = 'success' then total_value
        when type = 'withdrawal' and status = 'success' then -total_value
        else 0
      end
    ), 0
  )::numeric(14,2)
  into v_balance
  from public.transactions
  where user_id = v_user_id;

  update public.profiles
  set balance = greatest(v_balance, 0)
  where id = v_user_id;

  if not found then
    raise exception 'profile not found';
  end if;

  return greatest(v_balance, 0);
end;
$$;

grant execute on function public.repair_my_balance() to authenticated;

-- Strengthen transaction creation: a missing profile must fail instead of
-- allowing a transaction to be inserted while the balance stays unchanged.
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
  v_profile_id uuid;
  delta numeric := 0;
begin
  if auth.uid() is null or auth.uid() <> p_user_id then
    raise exception 'not authorized';
  end if;

  select id into v_profile_id
  from public.profiles
  where id = p_user_id
  for update;

  if not found then
    raise exception 'profile not found';
  end if;

  -- Idempotency: retrying the same transaction must not credit twice.
  select * into existing_tx
  from public.transactions
  where id = p_id;

  if found then
    return existing_tx;
  end if;

  if p_status = 'success' then
    if p_type = 'deposit' then
      delta := p_total_value;
    elsif p_type = 'withdrawal' then
      delta := -p_total_value;
    end if;
  end if;

  if delta < 0 then
    update public.profiles
    set balance = balance + delta
    where id = p_user_id
      and balance + delta >= 0;
    if not found then
      raise exception 'insufficient balance';
    end if;
  elsif delta > 0 then
    update public.profiles
    set balance = balance + delta
    where id = p_user_id;
    if not found then
      raise exception 'profile not found';
    end if;
  end if;

  insert into public.transactions(
    id, user_id, tube_id, weight_kg, price_per_kg,
    total_value, type, status, created_at
  )
  values(
    p_id, p_user_id, p_tube_id, p_weight_kg, p_price_per_kg,
    p_total_value, p_type, p_status, p_created_at
  )
  returning * into result_tx;

  return result_tx;
end;
$$;

grant execute on function public.create_transaction(
  text, uuid, text, numeric, numeric, numeric,
  public.transaction_type, public.transaction_status, timestamptz
) to authenticated;

-- One-time backfill for existing accounts.
-- profiles.balance becomes the authoritative sum of successful ledger entries.
do $$
begin
  update public.profiles p
  set balance = greatest(coalesce(t.total_balance, 0), 0)
  from (
    select
      user_id,
      sum(
        case
          when type = 'deposit' and status = 'success' then total_value
          when type = 'withdrawal' and status = 'success' then -total_value
          else 0
        end
      )::numeric(14,2) as total_balance
    from public.transactions
    group by user_id
  ) t
  where p.id = t.user_id;

  update public.profiles p
  set balance = 0
  where not exists (
    select 1 from public.transactions tx where tx.user_id = p.id
  );
end;
$$;
