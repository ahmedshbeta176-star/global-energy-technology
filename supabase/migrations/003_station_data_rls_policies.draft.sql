-- RLS policy draft for station equipment, telemetry and maintenance.
-- Review-only artifact. Do not apply to production until tested with real role accounts.
-- Uses the existing stations.owner_id and station_members columns observed in Supabase.

create or replace function public.can_access_station(p_station_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog
as $$
  select exists (
    select 1
    from public.stations s
    where s.id = p_station_id
      and (
        s.owner_id = (select auth.uid())
        or exists (
          select 1
          from public.station_members sm
          where sm.station_id = s.id
            and sm.user_id = (select auth.uid())
            and sm.is_active is true
            and coalesce(sm.status, 'active') = 'active'
        )
      )
  );
$$;

create or replace function public.is_station_owner(p_station_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog
as $$
  select exists (
    select 1
    from public.stations s
    where s.id = p_station_id
      and s.owner_id = (select auth.uid())
  );
$$;

revoke all on function public.can_access_station(uuid) from public, anon;
revoke all on function public.is_station_owner(uuid) from public, anon;
grant execute on function public.can_access_station(uuid) to authenticated;
grant execute on function public.is_station_owner(uuid) to authenticated;

-- Device inventory: station owners and active station members may read.
drop policy if exists "station_devices_select_station_access" on public.station_devices;
create policy "station_devices_select_station_access"
on public.station_devices for select
to authenticated
using ((select public.can_access_station(station_id)));

-- Device registration and metadata changes are owner-only for the first release.
drop policy if exists "station_devices_insert_owner" on public.station_devices;
create policy "station_devices_insert_owner"
on public.station_devices for insert
to authenticated
with check ((select public.is_station_owner(station_id)));

drop policy if exists "station_devices_update_owner" on public.station_devices;
create policy "station_devices_update_owner"
on public.station_devices for update
to authenticated
using ((select public.is_station_owner(station_id)))
with check ((select public.is_station_owner(station_id)));

drop policy if exists "station_devices_delete_owner" on public.station_devices;
create policy "station_devices_delete_owner"
on public.station_devices for delete
to authenticated
using ((select public.is_station_owner(station_id)));

-- Telemetry: users assigned to the station can read; no direct client writes.
drop policy if exists "device_telemetry_select_station_access" on public.device_telemetry;
create policy "device_telemetry_select_station_access"
on public.device_telemetry for select
to authenticated
using ((select public.can_access_station(station_id)));

-- Maintenance: active station members and owners can view and report work.
drop policy if exists "maintenance_select_station_access" on public.maintenance_work_orders;
create policy "maintenance_select_station_access"
on public.maintenance_work_orders for select
to authenticated
using ((select public.can_access_station(station_id)));

drop policy if exists "maintenance_insert_station_member" on public.maintenance_work_orders;
create policy "maintenance_insert_station_member"
on public.maintenance_work_orders for insert
to authenticated
with check (
  created_by = (select auth.uid())
  and (select public.can_access_station(station_id))
);

-- Owner or assigned technician/engineer may update a work order.
drop policy if exists "maintenance_update_owner_or_assignee" on public.maintenance_work_orders;
create policy "maintenance_update_owner_or_assignee"
on public.maintenance_work_orders for update
to authenticated
using (
  (select public.is_station_owner(station_id))
  or assigned_to = (select auth.uid())
)
with check (
  (select public.is_station_owner(station_id))
  or assigned_to = (select auth.uid())
);

-- No DELETE policy is intentionally provided for maintenance records (auditability).
