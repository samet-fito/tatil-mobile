-- Rezervasyon detay snapshot + yerel ID eşlemesi (giriş sonrası sync)
alter table public.travel_bookings
  add column if not exists detail_json jsonb not null default '{}'::jsonb;

alter table public.travel_bookings
  add column if not exists local_ref text;

create unique index if not exists travel_bookings_local_ref_uidx
  on public.travel_bookings (local_ref)
  where local_ref is not null;
