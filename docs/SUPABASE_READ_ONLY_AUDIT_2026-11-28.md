# Supabase Read-Only Audit — 2026-11-28

Project: `global-energy-tech`
Project ref: `dagjfsqnfrzcmtjqmypy`
Project status at inspection: `ACTIVE_HEALTHY`
Inspection mode: read-only; no database objects, grants, policies, or data were changed.

## Public schema

The project has five application tables:

| Table | RLS enabled |
|---|---:|
| profiles | yes |
| stations | yes |
| station_members | yes |
| station_member_permissions | yes |
| station_activity_logs | yes |

The tables reported zero rows in the table listing at inspection time.

## Existing policies

Only one public-schema policy was returned:

- `station_members` — `Members can view their own membership`
- Command: SELECT
- Role: authenticated
- Predicate: `user_id = auth.uid()`

No policies were returned for `profiles`, `stations`, `station_member_permissions`, or `station_activity_logs`.

## Security advisor findings

Supabase security advisor returned:

1. Four `RLS Enabled No Policy` findings for `profiles`, `stations`, `station_member_permissions`, and `station_activity_logs`.
2. Two warnings concerning `public.is_station_member(uuid)`: the function is `SECURITY DEFINER` and executable by both `anon` and `authenticated`.

The function body checks whether the current user has an active membership in a station. Its execute grants and security-definer behavior should be reviewed before any policy relies on it.

## Functions and triggers

- Public application function found: `is_station_member(p_station_id uuid)`.
- It is declared `SECURITY DEFINER` with `search_path=public`.
- No triggers were returned in the public schema.
- The initial migration listing returned no migrations. This should be reconciled with the live schema before relying on migration history.

## Recommended next actions — not yet applied

1. Review the complete function definition, ownership, grants, and intended callers.
2. Confirm whether the four no-policy tables are intended to be exposed through the Data API. Keep access blocked until explicit least-privilege policies are designed.
3. Design policies for profiles, station ownership, station membership, permissions, and activity logs using the actual schema and roles.
4. Add tests for anonymous, authenticated owner, station member, unrelated authenticated user, and administrative access.
5. Prepare a migration for review and backup before applying any database changes.

## Safety note

RLS being enabled does not mean the application has complete authorization policies. Do not assume the project is secure solely because the RLS flag is on. No changes have been applied during this audit.
