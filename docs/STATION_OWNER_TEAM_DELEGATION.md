# Station Owner Team Delegation Decision

Date: 2026-11-28
Project: GLOBAL ENERGY & TECHNOLOGY
Branch: development/rls-security
Status: approved product rule; implementation not applied.

## Approved behavior

A station owner may manage the operational team for stations they own:
- add/invite technicians and engineers to their own station;
- view the memberships for their own station;
- change or revoke a member's station access;
- assign only station-scoped capabilities approved by the platform.

A station owner may not:
- grant Platform Admin, Founder, or Super Admin privileges;
- manage users or memberships belonging to another owner's station;
- change global platform settings or security configuration;
- grant permissions outside the platform-approved station permission allowlist.

## Role boundaries

- Founder / Super Admin: sole platform-wide authority.
- Platform Admin: only explicitly delegated platform operations.
- Station Owner: team management limited to owned stations.
- Engineer / Technician: access limited to assigned stations and assigned work.
- Customer / Trader: separate product scopes; no implied station-team administration.

## Implementation requirements

1. Membership changes must be enforced by database policies/server-side checks, not frontend visibility.
2. Validate station ownership against `stations.owner_id = auth.uid()`.
3. Reject self-enrollment, self-reactivation, and role escalation.
4. Restrict owner-assigned roles to station-scoped `engineer` and `technician`; platform roles are never assignable through station membership.
5. Membership revocation must immediately remove station access.
6. Audit every add, role change, permission change, and revocation.
7. Permission keys must come from a defined allowlist. Until that allowlist is agreed, do not grant arbitrary permission keys.
8. The existing SECURITY DEFINER membership helper and its EXECUTE grants must be reviewed and narrowed before policies depend on it.

## Open design detail

The exact station permission allowlist (for example, whether technicians may edit station configuration, submit maintenance reports, or view financial data) is not yet specified. Keep permissions deny-by-default until those capabilities are explicitly defined.

## Status

This is an approved design rule only. No database schema, RLS policy, grant, function, trigger, or data row was changed.
