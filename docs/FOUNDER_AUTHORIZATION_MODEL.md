# Founder and Platform Authorization Decision

Date: 2026-11-28
Project: GLOBAL ENERGY & TECHNOLOGY
Status: approved design decision; implementation not yet applied.

## Decision

The platform will have exactly one Founder / Super Admin: the project owner.

No other account, including Platform Admin, Engineer, Technician, Trader, or Customer, may grant itself or another account Founder / Super Admin privileges.

## Role model

- Founder / Super Admin: sole ultimate authority over platform configuration, role assignment, security settings, and delegation.
- Platform Admin: operational administration only, limited to explicitly granted capabilities.
- Engineer: engineering workflows and assigned work.
- Technician: only stations and work orders explicitly assigned or authorized.
- Trader: management of their own trader profile, listings, and orders within platform rules.
- Customer: own profile, stations where authorized, and own requests/orders.

## Security requirements

1. Founder identity must be established server-side using a trusted, immutable identifier or protected allowlist; never trust a client-submitted role, metadata field, or UI state.
2. No self-service path may create or promote a Founder.
3. Platform Admin permissions must be granular and must exclude Founder-only operations.
4. Sensitive role changes and administrative actions must be audited.
5. Protect against changing the founder identity through profile edits, public APIs, or ordinary role-management flows.
6. Recovery procedures for loss of the founder account must be documented separately and protected by strong account security; do not create a second routine Super Admin as a shortcut.
7. RLS policies and function EXECUTE grants must enforce these rules in the database/server, not only in the frontend.

## Implementation status

This is an approved design decision only. No Supabase schema, policies, grants, functions, or user roles have been changed. The next step is to design and review a non-destructive migration and test matrix against the current schema before applying anything.
