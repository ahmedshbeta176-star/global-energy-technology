# RLS Implementation Plan — Review Before Migration

Date: 2026-11-28
Project: GLOBAL ENERGY & TECHNOLOGY
Branch: development/rls-security
Status: design only. This file is not an executable migration.

## Verified founder account (private verification)

The intended founder email has exactly one row in Supabase Auth. The account is confirmed and has a successful sign-in timestamp. Its Auth UUID was verified against the live project. The email and UUID are deliberately not copied into this repository.

The founder identity must be pinned in a protected database-side configuration or migration constant only after the migration is reviewed. Never trust editable profile fields or client-supplied role metadata.

## Live schema confirmed

- `profiles`: id, full_name, phone, created_at
- `stations`: id, name, location, capacity_kw, system_type, owner_id, created_at
- `station_members`: id, station_id, user_id, role_label, is_active, created_at, status, role
- `station_member_permissions`: id, station_member_id, permission_key, enabled
- `station_activity_logs`: id, station_id, actor_id, action, details, created_at

The live database reports RLS enabled on all five tables. Only one policy was returned: authenticated users may SELECT their own rows in `station_members` where `user_id = auth.uid()`. No policies were returned for the other four tables.

## Required policy design

### profiles
- Authenticated users may SELECT their own profile.
- Users may UPDATE only `full_name` and `phone`; immutable identity columns must not be client-editable.
- Founder-only support and role administration must use a protected server-side path.

### stations
- Founder may administer all stations.
- A station owner may SELECT and UPDATE only rows where `owner_id = auth.uid()`.
- Active station members may SELECT only stations linked through their active membership.
- Station creation must require the authenticated caller to be the owner; no caller may assign another user's identity as owner.
- Deletion remains Founder-only until retention and audit behavior is defined.

### station_members
- A user may SELECT their own membership.
- A station owner may create, update, deactivate, or remove memberships only for stations they own.
- Owner-managed membership may assign only station-scoped roles (engineer or technician); it may never grant platform admin or Founder.
- A member may not self-enroll, reactivate, or change their own role.

### station_member_permissions
- A station owner may manage only an allowlist of station-scoped permission keys for memberships in stations they own.
- Members may read only their own effective permissions.
- Permission keys must never confer platform-wide administrative authority.

### station_activity_logs
- Authorized station participants may read logs only within stations they are allowed to access.
- Writes should be made through a trusted database/server path that derives `actor_id` from the authenticated session.
- Ordinary clients must not update or delete audit records.

## Function and grants review

The existing `public.is_station_member(uuid)` function is SECURITY DEFINER and currently has EXECUTE grants for anon and authenticated. Before policies rely on it:
- review the full body, owner, and ACL;
- restrict EXECUTE to the minimum required role(s);
- use a fixed safe search_path and schema-qualified object references;
- ensure the helper cannot be abused to expose membership or privilege data.
Do not create a second broad SECURITY DEFINER helper as a shortcut.

## Test cases required before deployment

1. Anonymous requests cannot read or write private application data.
2. User A cannot read or update User B's profile.
3. Station owner A cannot access station B unless explicitly made a member.
4. Active members can read only assigned stations; deactivated members lose access.
5. Owners can manage station-scoped membership only for stations they own.
6. Members cannot self-enroll, reactivate, or escalate roles.
7. Platform Admin cannot assign Founder or change the protected Founder identity.
8. Ordinary users cannot forge, edit, or delete activity logs.
9. Founder can perform the intended platform-wide administrative operations.

## Operational sequence

1. Take and verify a database backup.
2. Review this design and confirm product-level owner/member behavior.
3. Prepare a reversible, non-destructive migration and test it in a non-production environment.
4. Apply only after review and explicit approval.
5. Re-run policy, grants, and negative-access tests against the live project.

## Important status

No tables, rows, policies, grants, functions, or triggers were changed by this review. RLS remains enabled with the currently observed policy state.