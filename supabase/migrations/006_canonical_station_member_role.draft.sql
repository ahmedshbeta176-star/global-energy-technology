-- Canonical station membership role: public.station_members.role
-- Review-only migration draft. Do not apply until UI/API references are updated and tested.
-- role_label is retained temporarily for backward compatibility; it is not authoritative.

begin;

-- The live station_members table was empty at inspection time, but backfill is
-- still included so the migration remains safe if rows are added before deployment.
update public.station_members
set role = case
  when role in ('owner','engineer','technician') then role
  when role_label in ('owner','engineer','technician') then role_label
  else 'technician'
end
where role is null
   or role not in ('owner','engineer','technician');

alter table public.station_members
  alter column role set default 'technician';

alter table public.station_members
  alter column role set not null;

alter table public.station_members
  add constraint station_members_role_allowlist
  check (role in ('owner','engineer','technician'));

-- Keep legacy role_label synchronized during the transition.
create or replace function public.sync_station_member_role_label()
returns trigger
language plpgsql
set search_path = pg_catalog
as $$
begin
  new.role_label := new.role;
  return new;
end;
$$;

drop trigger if exists station_members_sync_role_label on public.station_members;
create trigger station_members_sync_role_label
before insert or update of role on public.station_members
for each row execute function public.sync_station_member_role_label();

commit;

-- Follow-up release: update application reads/writes to use role only.
-- After confirming no legacy clients remain, remove role_label and this trigger/function
-- in a separate migration. Never use station-scoped role values for platform roles.
