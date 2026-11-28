-- Additive schema foundation for station equipment, telemetry, and maintenance.
-- Apply only after review. RLS is enabled with no client policies yet (fail closed).
-- No existing tables or rows are modified.

create table if not exists public.station_devices (
  id uuid primary key default gen_random_uuid(),
  station_id uuid not null references public.stations(id) on delete restrict,
  device_type text not null check (device_type in ('inverter','battery','meter','gateway','sensor')),
  manufacturer text,
  model text,
  serial_number text,
  display_name text,
  rated_power_kw numeric(12,3) check (rated_power_kw is null or rated_power_kw >= 0),
  communication_protocol text,
  external_device_id text,
  is_active boolean not null default true,
  installed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (station_id, id)
);

create unique index if not exists station_devices_station_serial_uidx
  on public.station_devices(station_id, serial_number)
  where serial_number is not null;

create index if not exists station_devices_station_id_idx
  on public.station_devices(station_id);

create table if not exists public.device_telemetry (
  id bigint generated always as identity primary key,
  station_id uuid not null,
  device_id uuid not null,
  measured_at timestamptz not null,
  received_at timestamptz not null default now(),
  metric_key text not null check (length(metric_key) between 1 and 100),
  metric_value numeric not null,
  unit text not null check (length(unit) between 1 and 24),
  quality text not null default 'valid'
    check (quality in ('valid','estimated','missing','invalid')),
  source text not null,
  created_at timestamptz not null default now(),
  constraint device_telemetry_device_station_fkey
    foreign key (station_id, device_id)
    references public.station_devices(station_id, id)
    on delete restrict
);

create index if not exists device_telemetry_station_measured_idx
  on public.device_telemetry(station_id, measured_at desc);

create index if not exists device_telemetry_device_measured_idx
  on public.device_telemetry(device_id, measured_at desc);

create table if not exists public.maintenance_work_orders (
  id uuid primary key default gen_random_uuid(),
  station_id uuid not null references public.stations(id) on delete restrict,
  device_id uuid,
  created_by uuid not null references auth.users(id) on delete restrict,
  assigned_to uuid references auth.users(id) on delete set null,
  title text not null check (length(title) between 1 and 200),
  description text,
  priority text not null default 'normal'
    check (priority in ('low','normal','high','urgent')),
  status text not null default 'open'
    check (status in ('open','assigned','in_progress','completed','cancelled')),
  reported_at timestamptz not null default now(),
  scheduled_at timestamptz,
  completed_at timestamptz,
  resolution_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint maintenance_device_station_fkey
    foreign key (station_id, device_id)
    references public.station_devices(station_id, id)
    on delete restrict
);

create index if not exists maintenance_work_orders_station_status_idx
  on public.maintenance_work_orders(station_id, status, created_at desc);

create index if not exists maintenance_work_orders_assigned_to_idx
  on public.maintenance_work_orders(assigned_to);

-- Enable RLS immediately. Until reviewed policies are added, client access is denied.
alter table public.station_devices enable row level security;
alter table public.device_telemetry enable row level security;
alter table public.maintenance_work_orders enable row level security;

comment on table public.station_devices is
  'Registered physical equipment belonging to a station; secrets must not be stored here.';
comment on table public.device_telemetry is
  'Normalized time-series readings; ingestion must use a trusted server-side path.';
comment on table public.maintenance_work_orders is
  'Station-scoped maintenance jobs and service reports.';
