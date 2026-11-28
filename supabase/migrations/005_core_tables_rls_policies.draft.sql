-- Draft RLS policies for existing core tables.
-- Review/test only: do not apply to production until validated with separate test users.
-- Existing RLS stays enabled. No public/anon access is granted.

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

-- PROFILES: users may read and update only their own profile.
drop policy if exists "profiles_select_self" on public.profiles;
create policy "profiles_select_self"
on public.profiles for select to authenticated
using (id = (select auth.uid()));

drop policy if exists "profiles_insert_self" on public.profiles;
create policy "profiles_insert_self"
on public.profiles for insert to authenticated
with check (id = (select auth.uid()));

drop policy if exists "profiles_update_self" on public.profiles;
create policy "profiles_update_self"
on public.profiles for update to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

-- STATIONS: owner controls station; active members can read only.
drop policy if exists "stations_select_owner_or_member" on public.stations;
create policy "stations_select_owner_or_member"
on public.stations for select to authenticated
using ((select public.can_access_station(id)));

drop policy if exists "stations_insert_owner_self" on public.stations;
create policy "stations_insert_owner_self"
on public.stations for insert to authenticated
with check (owner_id = (select auth.uid()));

drop policy if exists "stations_update_owner" on public.stations;
create policy "stations_update_owner"
on public.stations for update to authenticated
using ((select public.is_station_owner(id)))
with check ((select public.is_station_owner(id)));

drop policy if exists "stations_delete_owner" on public.stations;
create policy "stations_delete_owner"
on public.stations for delete to authenticated
using ((select public.is_station_owner(id)));

-- MEMBERS: member can see own membership; station owner can manage members.
drop policy if exists "station_members_select_self_or_owner" on public.station_members;
create policy "station_members_select_self_or_owner"
on public.station_members for select to authenticated
using (
  user_id = (select auth.uid())
  or (select public.is_station_owner(station_id))
);

drop policy if exists "station_members_insert_owner" on public.station_members;
create policy "station_members_insert_owner"
on public.station_members for insert to authenticated
with check ((select public.is_station_owner(station_id)));

drop policy if exists "station_members_update_owner" on public.station_members;
create policy "station_members_update_owner"
on public.station_members for update to authenticated
using ((select public.is_station_owner(station_id)))
with check ((select public.is_station_owner(station_id)));

drop policy if exists "station_members_delete_owner" on public.station_members;
create policy "station_members_delete_owner"
on public.station_members for delete to authenticated
using ((select public.is_station_owner(station_id)));

-- PERMISSIONS: user can inspect own permissions; station owner manages them.
drop policy if exists "member_permissions_select_self_or_owner" on public.station_member_permissions;
create policy "member_permissions_select_self_or_owner"
on public.station_member_permissions for select to authenticated
using (
  exists (
    select 1
    from public.station_members sm
    where sm.id = station_member_id
      and (
        sm.user_id = (select auth.uid())
        or (select public.is_station_owner(sm.station_id))
      )
  )
);

drop policy if exists "member_permissions_insert_owner" on public.station_member_permissions;
create policy "member_permissions_insert_owner"
on public.station_member_permissions for insert to authenticated
with check (
  exists (
    select 1
    from public.station_members sm
    where sm.id = station_member_id
      and (select public.is_station_owner(sm.station_id))
  )
);

drop policy if exists "member_permissions_update_owner" on public.station_member_permissions;
create policy "member_permissions_update_owner"
on public.station_member_permissions for update to authenticated
using (
  exists (
    select 1 from public.station_members sm
    where sm.id = station_member_id
      and (select public.is_station_owner(sm.station_id))
  )
)
with check (
  exists (
    select 1 from public.station_members sm
    where sm.id = station_member_id
      and (select public.is_station_owner(sm.station_id))
  )
);

drop policy if exists "member_permissions_delete_owner" on public.station_member_permissions;
create policy "member_permissions_delete_owner"
on public.station_member_permissions for delete to authenticated
using (
  exists (
    select 1 from public.station_members sm
    where sm.id = station_member_id
      and (select public.is_station_owner(sm.station_id))
  )
);

-- ACTIVITY LOGS: station owner and active members can read.
-- Authenticated members may append an event only as themselves.
drop policy if exists "activity_logs_select_station_access" on public.station_activity_logs;
create policy "activity_logs_select_station_access"
on public.station_activity_logs for select to authenticated
using ((select public.can_access_station(station_id)));

drop policy if exists "activity_logs_insert_actor_self" on public.station_activity_logs;
create policy "activity_logs_insert_actor_self"
on public.station_activity_logs for insert to authenticated
with check (
  actor_id = (select auth.uid())
  and (select public.can_access_station(station_id))
);

-- No update/delete policies for audit logs.
