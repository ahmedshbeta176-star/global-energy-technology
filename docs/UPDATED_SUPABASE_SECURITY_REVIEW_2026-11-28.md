# Updated Supabase Security Review — 2026-11-28

Project ref: dagjfsqnfrzcmtjqmypy
Branch: development/rls-security
Status: read-only review; no database changes applied.

## Correction to prior notes

A prior conversational update mentioned a public `customers` table without a verified catalog result. A fresh direct catalog query found exactly five application tables in the `public` schema and did not find `customers` there. The earlier statement about a `customers` table being unprotected is therefore withdrawn. Do not create policies for a table that has not been confirmed to exist.

## Current public application tables

| Table | RLS enabled | FORCE RLS |
|---|---:|---:|
| profiles | yes | no |
| stations | yes | no |
| station_members | yes | no |
| station_member_permissions | yes | no |
| station_activity_logs | yes | no |

## Current policies

The only public policy returned by `pg_policies` is:

- `station_members` — authenticated SELECT where `user_id = auth.uid()`.

No policies were returned for `profiles`, `stations`, `station_member_permissions`, or `station_activity_logs`.

## Founder account verification

The intended personal email corresponds to one confirmed Supabase Auth user with a successful sign-in timestamp. The account UUID was verified against the live project. The email and UUID are intentionally omitted from this repository document.

This verifies the Auth account only. It does not yet make the account a Founder in the application authorization model.

## Function review

The public function `is_station_member(uuid)` is SECURITY DEFINER, owned by postgres, with `search_path=public`. It checks for an active membership belonging to `auth.uid()`.

The function is executable by authenticated users and also effectively executable by PUBLIC/anon through its default PUBLIC EXECUTE grant. This should be narrowed before relying on the function in policies. Any future policy helper should use a fixed safe search path and schema-qualified object references, and its execute grants should be explicit and minimal.

## Important implementation sequencing

1. Verify complete table grants and role privileges before granting any client access.
2. Revoke unintended PUBLIC/anon function execution where safe, after checking dependencies.
3. Establish a protected Founder identity using the verified Auth UUID in a server-controlled mechanism; never use editable user metadata.
4. Define least-privilege policies table by table.
5. Test both permitted and denied access for anon, unrelated users, station owners, active/inactive members, and Founder.
6. Take a backup and review a migration before any production application.

## Not yet decided

- Whether station owners can invite and manage station members.
- Which station-scoped permissions engineers and technicians require.
- Whether customers should have station records in this schema or a separate customer table.
- Whether logs should be readable by station owners, members, or both.

## Safety status

No table, row, policy, grant, function, trigger, or schema was changed during this review. Do not treat RLS being enabled as proof that application authorization is complete.
