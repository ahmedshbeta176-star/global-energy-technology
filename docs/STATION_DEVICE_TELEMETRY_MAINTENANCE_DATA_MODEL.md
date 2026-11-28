# Station, Inverter, Telemetry and Maintenance Data Model
Date: 2026-11-28
Branch: development/rls-security
Status: architecture proposal only; no database migration applied.

## 1. Existing live schema (preserve)

The current public schema already contains:
- `stations(id, name, location, capacity_kw, system_type, owner_id, created_at)`
- `station_members(id, station_id, user_id, role_label, is_active, created_at, status, role)`
- `station_member_permissions(id, station_member_id, permission_key, enabled)`
- `station_activity_logs(id, station_id, actor_id, action, details, created_at)`
- `profiles(id, full_name, phone, created_at)`

Do not replace or rename these tables as part of the first expansion. Existing IDs and relationships must be preserved.

## 2. Proposed new tables

### A. `station_devices` — registered equipment

One row per physical device installed at a station.

Proposed columns:
- `id uuid primary key`
- `station_id uuid not null references public.stations(id)`
- `device_type text not null` (initial allowlist: inverter, battery, meter, gateway, sensor)
- `manufacturer text`
- `model text`
- `serial_number text`
- `display_name text`
- `rated_power_kw numeric`
- `communication_protocol text` (e.g. vendor API, Modbus TCP/RTU, MQTT; confirm supported integrations before enabling)
- `external_device_id text` (provider-side identifier; do not store API secrets here)
- `is_active boolean not null default true`
- `installed_at timestamptz`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Constraints/indexes:
- index `station_id`
- unique `(station_id, serial_number)` when serial_number is not null
- avoid assuming serial numbers are globally unique across manufacturers.

### B. `device_telemetry` — time-series readings

Append-only measurements received from a device.

Proposed columns:
- `id bigint generated always as identity primary key`
- `station_id uuid not null references public.stations(id)`
- `device_id uuid not null references public.station_devices(id)`
- `measured_at timestamptz not null` (device/event time in UTC)
- `received_at timestamptz not null default now()` (server ingestion time)
- `metric_key text not null` (e.g. pv_power_kw, energy_today_kwh, battery_soc_pct, grid_voltage_v)
- `metric_value numeric not null`
- `unit text not null`
- `quality text` (valid, estimated, missing, invalid; finalize enum/check)
- `source text` (vendor API, gateway, manual import)
- `raw_payload_ref text` (optional pointer only; avoid storing secrets or oversized payloads in row)
 
Constraints/indexes:
- index `(station_id, measured_at desc)`
- index `(device_id, measured_at desc)`
- optional unique idempotency key after connector behavior is known.
- design for time partitioning/retention only after expected volume and query patterns are measured.
- keep raw vendor payloads in a separately secured storage path if needed.

### C. `maintenance_work_orders` — service and maintenance

One row per maintenance request/job.

Proposed columns:
- `id uuid primary key`
- `station_id uuid not null references public.stations(id)`
- `device_id uuid references public.station_devices(id)`
- `created_by uuid not null references auth.users(id)`
- `assigned_to uuid references auth.users(id)`
- `title text not null`
- `description text`
- `priority text not null default 'normal'` (allowlist: low, normal, high, urgent)
- `status text not null default 'open'` (allowlist: open, assigned, in_progress, completed, cancelled)
- `reported_at timestamptz not null default now()`
- `scheduled_at timestamptz`
- `completed_at timestamptz`
- `resolution_notes text`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Maintenance events, photos, parts, labor, and customer sign-off may later be separate child tables; do not overload activity logs for these records.

### D. `device_integrations` — optional integration metadata

Use only when a station/device connector is selected. Store non-secret provider identifiers and connection status here. API tokens, passwords, refresh tokens, and service credentials must be stored in a trusted secret store or server-side encrypted secret mechanism, never in browser-visible tables or repository files.

## 3. Relationships

- `stations 1 → many station_devices`
- `station_devices 1 → many device_telemetry`
- `stations 1 → many device_telemetry` (denormalized station_id for policy/query efficiency; enforce that device belongs to the same station via trigger/composite FK or trusted ingestion path)
- `stations 1 → many maintenance_work_orders`
- `station_devices 0/1 → many maintenance_work_orders`
- `auth.users 1 → many maintenance_work_orders` as creator/assignee.

## 4. Access rules to carry into RLS

- Founder: platform-wide access.
- Station owner: access only where `stations.owner_id = auth.uid()`.
- Active engineer/technician: access only to stations with active `station_members` membership.
- Engineer: technical configuration writes only when explicit permission is enabled for that member and permission key.
- Technician: telemetry/device read and maintenance reporting only; no device configuration writes.
- Revoked/inactive members lose station access.
- Telemetry should normally be read-only to clients; ingestion uses a trusted server/gateway path.
- No client may write integration secrets or choose arbitrary station_id/device_id values without server-side ownership validation.

## 5. Device and telemetry ingestion architecture

1. Register device and its station association.
2. Establish a vendor-specific connector or approved gateway; each manufacturer may have different API/protocol support.
3. Ingest readings through a trusted server-side service/edge function.
4. Validate station/device association, units, timestamps, ranges, and source identity.
5. Store normalized metrics in `device_telemetry`; retain raw payload only where needed and safely.
6. Expose dashboard queries/views with RLS and aggregation; do not let the browser write telemetry as if it came from an inverter.

No real inverter integration is active merely because the tables are designed. Vendor API access and device credentials are still required.

## 6. Decisions needed before executable migration

- Confirm the initial device types and required inverter fields (brand, model, serial, rated kW, firmware, protocol).
- Choose the first integration family/vendor for MVP.
- Define telemetry sampling frequency and retention target.
- Confirm whether customers can create maintenance requests or only owners/team members.
- Define photo/file evidence storage and retention.
- Confirm whether battery, meter, and gateway devices are in MVP scope.

## 7. Migration safety plan

- Add new tables without altering existing rows.
- Add foreign keys and indexes after validating existing ID types and relationships.
- Add RLS and grants in the same reviewed migration as the new tables.
- Test with separate anon, ordinary user, station owner, active engineer, active technician, and Founder sessions.
- Apply first in staging; take and verify a backup before production.
- Do not expose UI controls until ingestion and authorization paths are implemented.

## Status

This document is an architecture proposal, not executable SQL. No live tables, rows, policies, grants, functions, triggers, or schema were changed.
