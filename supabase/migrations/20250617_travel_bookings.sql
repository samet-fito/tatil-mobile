-- Tatil rezervasyonları (mobil TravelBookingService)
create table if not exists public.travel_bookings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete set null,
  origin_iata text,
  destination_iata text not null,
  city_name text not null,
  country text,
  departure_date date not null,
  return_date date not null,
  adults int not null default 1,
  children int not null default 0,
  total_price_tl int not null default 0,
  flight_price_tl int not null default 0,
  hotel_price_tl int not null default 0,
  transfer_price_tl int not null default 0,
  extras_price_tl int not null default 0,
  insurance_included boolean not null default false,
  booking_scope text not null default 'package',
  passenger_name text,
  passenger_email text,
  payment_method text,
  passengers jsonb default '[]'::jsonb,
  flight_offer_id text,
  hotel_id text,
  flight_source text,
  hotel_source text,
  status text not null default 'confirmed',
  created_at timestamptz not null default now()
);

create index if not exists travel_bookings_user_id_idx
  on public.travel_bookings (user_id, created_at desc);

alter table public.travel_bookings enable row level security;

drop policy if exists "travel_bookings_select_own" on public.travel_bookings;
create policy "travel_bookings_select_own"
  on public.travel_bookings for select
  using (auth.uid() = user_id);

drop policy if exists "travel_bookings_insert_own" on public.travel_bookings;
create policy "travel_bookings_insert_own"
  on public.travel_bookings for insert
  with check (auth.uid() = user_id or user_id is null);
