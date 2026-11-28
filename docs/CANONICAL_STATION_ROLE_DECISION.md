# Canonical station membership role decision

Decision approved by project owner on 2026-11-28:
- `station_members.role` is the single authoritative station-scoped role field.
- Allowed values: `owner`, `engineer`, `technician`.
- Platform roles (Founder, Platform Admin, Super Admin) must never be stored in station_members.
- `role_label` is legacy compatibility data only and must not be used for authorization. It will be synchronized from `role` during the transition, then removed in a later migration after application references are updated.

## Why this is the preferred choice
- `role` is a concise machine-readable field suitable for authorization checks and constraints.
- `role_label` is better treated as presentation/legacy text, not a security source.
- A single canonical field avoids disagreements between UI labels and authorization decisions.

## Live inspection
- `station_members.role` is nullable.
- `station_members.role_label` is NOT NULL.
- The grouped role/status query returned no membership rows at inspection time, so there were no existing memberships to reconcile.
- The schema includes both `is_active` and `status`; access checks should require `is_active = true` and `status = 'active'`.

## Migration draft
`supabase/migrations/006_canonical_station_member_role.draft.sql`

The draft:
- backfills missing/invalid role values using a valid legacy role_label where possible, otherwise the least-privileged default technician;
- sets default and NOT NULL on role;
- constrains role to owner/engineer/technician;
- synchronizes role_label from role temporarily for backward compatibility;
- does not drop role_label yet.

## Required follow-up
1. Update every application query/form to read/write `role` only.
2. Ensure only the station owner (or trusted server workflow) can assign station roles.
3. Prevent users from changing their own role or activating themselves.
4. Verify owner assignment cannot create a platform role.
5. Test owner, engineer, technician, inactive member, and unrelated user sessions.
6. Remove role_label in a later reviewed migration after confirming no old app version depends on it.

No database changes were applied. This is a documented decision and migration draft on the development branch.
