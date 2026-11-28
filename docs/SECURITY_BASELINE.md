# GLOBAL ENERGY & TECHNOLOGY — Security Baseline

Date: 2026-11-28
Branch: development/rls-security
Status: planning and repository audit only; no production database changes have been applied.

## Confirmed repository findings

- The public landing page initializes the Supabase browser client.
- The admin page explicitly identifies itself as a local demo and stores records in browser localStorage.
- The station monitoring page also stores station records in localStorage; its production, consumption, battery, and inverter indicators are placeholders.
- The repository currently does not establish that authentication, database-backed station records, or role-based access control are implemented.

## Agreed implementation order

1. Inspect the existing Supabase schema, policies, triggers, functions, and current data before changing anything.
2. Back up the database schema and data using the Supabase dashboard/CLI before applying migrations.
3. Define and document the minimum data model for profiles, stations, station membership/ownership, technicians, traders, products, service requests, subscriptions, and audit events.
4. Enable Row Level Security on every exposed table and write least-privilege policies:
   - users can read and update only their own profile fields;
   - station owners and explicitly authorized members can access their stations;
   - technicians can access only work requests assigned to them;
   - trader records and products follow the intended public/private visibility rules;
   - privileged administrative actions are enforced server-side, never by trusting a browser-supplied role.
5. Add authentication and server-verified role assignment. Do not allow users to promote themselves to admin or owner.
6. Move admin and monitoring screens from localStorage/demo records to authenticated database queries.
7. Add automated policy tests and verify anonymous, ordinary-user, technician, trader, and admin access separately.
8. Only after the above is reviewed, apply migrations to the intended Supabase project and test the deployed site.

## Safety constraints

- Do not modify the `main` branch as part of this work.
- Do not run destructive SQL, drop tables, reset the project, or overwrite existing records.
- Never place a Supabase service-role key in frontend code, GitHub, or client-side environment variables. A publishable/anon key may be used in the browser only with correct RLS policies.
- Do not claim that RLS is active until the actual Supabase policies have been inspected and tested.
- The inverter integrations (SMA, Voltronic/Axpert, GoodWe, Solis, Huawei, Growatt, Deye, DYA) require separate vendor/API or gateway work; placeholder readings must remain clearly marked as unavailable.

## Required inspection before writing the first database migration

Obtain the current Supabase schema and the definitions of existing tables, RLS policies, database functions, triggers, and grants. Compare them with the intended model and prepare a non-destructive migration for review. This repository branch alone does not grant database access and does not apply SQL to Supabase.
