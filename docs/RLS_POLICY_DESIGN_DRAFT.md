# RLS Policy Design — Review Draft
Date: 2026-11-28
Branch: development/rls-security
Status: design and test plan only. No database changes applied.

## Live schema used for this design

The live `public` schema currently contains these five tables, all with RLS enabled and FORCE RLS disabled:

- `profiles(id, full_name, phone, created_at)`
- `stations(id, name, location, capacity_kw, system_type, owner_id, created_at)`
- `station_members(id, station_id, user_id, role_label, is_active, created_at, status, role)`
- `station_member_permissions(id, station_member_id, permission_key, enabled)`
- `station_activity_logs(id, station_id, actor_id, action, details, created_at)`

Existing policy: authenticated users may SELECT their own `station_members` rows (`user_id = auth.uid()`). No other public-table policies were returned by the live inspection.

## Authorization model

- Founder: one protected account; platform-wide authority.
- Platform Admin: only specifically delegated platform operations; cannot create or replace Founder.
- Station Owner: manage only stations where `stations.owner_id = auth.uid()`; may manage team membership for those stations.
- Engineer: read assigned stations and record work; may update technical configuration only when explicitly granted an allowlisted permission.
- Technician: read assigned stations and submit maintenance records; no station-team or platform administration.
- Customer / Trader: no implicit station-team or platform administration.

## Policy intent by table

### profiles
- SELECT: user reads only row where `id = auth.uid()`; Founder may administer through trusted administrative paths.
- UPDATE: user may update only their own editable fields (`full_name`, `phone`). Protect `id` and `created_at`; column-level grants or a controlled RPC are needed because RLS alone cannot restrict individual columns.
- No client INSERT/DELETE until the profile creation and retention lifecycle is confirmed.

### stations
- SELECT: Founder; owner where `owner_id = auth.uid()`; active members through their own active `station_members` record.
- INSERT: authenticated user may create only when `owner_id = auth.uid()`; any additional station provisioning rules must be specified.
- UPDATE: Founder or owner only, with both USING and WITH CHECK preserving the owner boundary. Member users do not edit station core fields by default.
- DELETE: Founder-only pending retention and audit requirements.

### station_members
- SELECT: member sees own membership; station owner sees memberships only for owned stations; Founder can administer.
- INSERT: station owner may add a user only to a station they own, and only with station-scoped `engineer` or `technician` role values. Never accept `founder`, `platform_admin`, or `super_admin` from this path.
- UPDATE: owner may change only membership status/role within the station-scoped allowlist; preserve `station_id` and `user_id` identity boundaries. Prefer controlled RPC/column grants for immutable fields.
- DELETE: prefer setting `is_active=false` / `status='inactive'` rather than deleting audit-relevant membership rows.
- Self-enrollment, self-reactivation, and self-role changes are denied.

### station_member_permissions
- SELECT: member reads only permission rows attached to their own membership; owner reads only permission rows for memberships in their own stations.
- INSERT/UPDATE/DELETE: owner only, for memberships in stations they own, and only for an explicit permission-key allowlist. Until the allowlist is approved, deny writes by default.
- Permission keys must never grant platform-wide roles.

### station_activity_logs
- SELECT: owner and active station members may read logs only for stations they are authorized to access; Founder may administer.
- INSERT: trusted server/database path only, with actor identity derived from authenticated session. If client inserts are later permitted, require `actor_id = auth.uid()` and station access.
- UPDATE/DELETE: deny to ordinary clients; preserve audit integrity.

## Important implementation notes

1. The previous Founder draft was corrected: the role registry and SECURITY DEFINER helper belong in the non-exposed `private` schema, not `public`. The helper uses an empty search_path and schema-qualified references. The role table has no direct client grants.
2. The existing `public.is_station_member(uuid)` function is SECURITY DEFINER and currently has an EXECUTE ACL that includes PUBLIC plus authenticated. Before using it in policies, review dependencies and narrow its exposure; do not rely on a broadly callable helper.
3. Supabase RLS policies do not replace SQL grants. Revoke unnecessary client grants and grant only the operations required by the app.
4. UPDATE requires a SELECT policy and both USING and WITH CHECK conditions.
5. Use `TO authenticated` explicitly. Never authorize using user-editable `raw_user_meta_data`.
6. Add indexes for policy lookup columns where needed: `stations.owner_id`, `station_members.user_id`, `station_members.station_id`, and any additional columns measured in query plans.
7. Do not enable client writes to `station_activity_logs` or arbitrary permission keys before their workflow is defined.

## Required test matrix

- anon cannot read or write any private application table.
- User A cannot read/update User B's profile.
- Station owner A cannot read/update station B or its memberships.
- Active member can read only assigned station(s); inactive member loses access.
- Owner can add/revoke engineer/technician membership only for owned station(s).
- Owner cannot assign Founder/Platform Admin/Super Admin or arbitrary permission keys.
- Member cannot enroll themselves, reactivate themselves, or change their own role.
- Technician cannot update station configuration or manage team.
- Engineer can update technical settings only with explicit permission.
- Ordinary users cannot edit/delete audit logs.
- Founder can perform intended platform-wide administration.
- Verify grants as well as RLS policies; test through authenticated and anon API sessions.

## Open decisions before executable SQL

- Confirm whether a station owner may add a user by Auth UUID only, or whether invitation-by-email must be supported through a server-side Auth Admin workflow.
- Approve the exact engineer permission-key allowlist.
- Confirm whether station members may read all activity logs or only their own actions.
- Confirm profile creation flow and whether users may edit phone numbers.
- Confirm deletion/retention requirements.

## Status
This document is a policy design, not an executable migration. No table, row, policy, grant, function, trigger, or schema was changed during this review.
