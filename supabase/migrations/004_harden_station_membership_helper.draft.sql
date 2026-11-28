-- Draft hardening for the existing station membership helper.
-- Review and test before applying. This changes no table rows.
create or replace function public.is_station_member(p_station_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog
as $$
  select exists (
    select 1
    from public.station_members sm
    where sm.station_id = p_station_id
      and sm.user_id = (select auth.uid())
      and sm.is_active is true
      and coalesce(sm.status, 'active') = 'active'
  );
$$;

revoke all on function public.is_station_member(uuid) from public, anon;
grant execute on function public.is_station_member(uuid) to authenticated;
