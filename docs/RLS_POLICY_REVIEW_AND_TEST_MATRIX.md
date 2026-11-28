# RLS policy review and test matrix

Branch: development/rls-security
Status: draft only; not applied to Supabase.

## Facts verified in the connected Supabase project
- Existing public tables: profiles, stations, station_members, station_member_permissions, station_activity_logs.
- RLS is enabled on those five tables.
- Existing policy inventory returned one policy: authenticated users may SELECT their own station_members row.
- Existing helper public.is_station_member(uuid) is SECURITY DEFINER, but checks is_active only and uses search_path=public. Do not rely on it for the new policies without remediation.
- station_members has both is_active and status; new access checks require is_active=true and status='active'.
- Existing station ownership is stations.owner_id -> auth.users.id.

## Draft policies in 003_station_data_rls_policies.draft.sql
- station_devices: SELECT for station owner or active member; INSERT/UPDATE/DELETE owner only.
- device_telemetry: SELECT for station owner or active member; no client write policy.
- maintenance_work_orders: SELECT for station owner or active member; INSERT by owner/member only when created_by=auth.uid(); UPDATE by owner or assigned user, with station access required for the assigned-user path; no DELETE policy.
- SECURITY DEFINER helper functions use a fixed pg_catalog search_path and schema-qualified object names; execute revoked from PUBLIC/anon and granted to authenticated.

## Required tests before applying
Use separate test identities and seeded test stations in a non-production environment:
1. Anonymous user cannot read or write any of the three tables.
2. Unrelated authenticated user cannot read another station's devices, telemetry, or work orders.
3. Station owner can read and manage device inventory for their own station only.
4. Active technician can read device inventory and telemetry for their assigned station.
5. Active technician cannot insert/update/delete device inventory.
6. Active technician can create a maintenance work order only with created_by matching their own auth.uid().
7. Assigned technician can update a work order only while still an active member of that same station.
8. Inactive membership (is_active=false) is denied even if status says active.
9. Membership with status other than active is denied even if is_active=true.
10. Engineer without explicit device-configuration delegation cannot change device metadata or inverter settings.
11. Revoked/inactive assignee loses update access.
12. Telemetry cannot be inserted, updated, or deleted by browser-authenticated users.
13. Owner/member cannot move a device or work order to a different station by changing station_id.
14. Founder global access must be added only after the Founder identity/role registry is verified; no email or user UUID is hardcoded in policies.

## Known gaps / follow-up
- Current helper is_station_member(uuid) should be reviewed for fixed search_path and consistent status handling before reuse elsewhere.
- Existing station_members and station_member_permissions policies are incomplete for the intended owner-managed invitation workflow.
- Role naming must be normalized between role and role_label before engineer-specific permissions are activated.
- A secure server-side ingestion service is required for telemetry writes.
- A secure invitation Edge Function is required; never expose the service-role key in browser code.

## Release gate
Do not apply this draft to production. First test on a disposable/staging database with test users and sample stations, review the SQL, and confirm a restorable backup. No existing production table or row has been changed by this draft.


## Existing core-table policy draft
Draft file: supabase/migrations/005_core_tables_rls_policies.draft.sql

Proposed behavior:
- profiles: each signed-in user can read/create/update only their own profile.
- stations: owner can create/manage their own station; active station members can read it.
- station_members: member can see their own membership; station owner can manage memberships.
- station_member_permissions: member can read their own station permissions; station owner can manage permissions.
- station_activity_logs: owner and active members can read; authenticated station members can append entries only with actor_id=auth.uid(); no update/delete policies.

## Additional tests required for core tables
1. User A cannot read or update User B's profile.
2. A station owner can create a station only with owner_id=auth.uid().
3. A station member can read only stations where they have an active membership.
4. A member cannot add, update, or remove another member.
5. A station owner can invite/manage members only for stations they own.
6. A station member cannot grant or change permissions for themselves or others.
7. A station owner cannot grant platform Founder/Super Admin privileges through station membership or station_member_permissions.
8. A user cannot forge actor_id in activity logs.
9. Activity logs cannot be updated or deleted by browser users.
10. Inactive or non-active membership loses station access.

## Important schema limitation
station_members currently has both role and role_label columns, with defaults, and station_member_permissions.permission_key is free text. Before allowing owner-managed membership writes, normalize the role source and define an explicit allowlist of station-scoped permission keys. The SQL draft intentionally must not be treated as final authorization for assigning roles until that allowlist is agreed and tested.
