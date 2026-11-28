# Approved Station Access Decisions and RLS Acceptance Tests
Date: 2026-11-28
Branch: development/rls-security
Status: product decisions approved; test specification only; no production changes applied.

## Approved product decisions

1. A station owner can invite a technician or engineer by email. Invitations must be performed by a trusted server-side Auth Admin workflow; never expose the Supabase service-role/secret key in browser code.
2. An engineer may edit technical station/inverter settings only when the station owner has explicitly granted the corresponding station-scoped permission.
3. A technician may view the assigned station information needed for their work and submit maintenance/service records. A technician cannot edit inverter configuration or manage station membership.
4. Station owners manage membership only for stations they own.
5. Only the protected Founder identity has platform-wide Founder authority. Station owners and station members cannot grant Founder, Platform Admin, or Super Admin roles.

## Role and capability matrix

| Capability | Founder | Platform Admin | Station Owner | Engineer | Technician |
|---|---|---|---|---|---|
| Platform-wide administration | yes | delegated only | no | no | no |
| View owned station | yes | delegated only | yes | assigned only | assigned only |
| Invite engineer/technician to owned station | yes | delegated only | yes | no | no |
| Revoke station membership | yes | delegated only | yes, owned station only | no | no |
| View station telemetry/configuration | yes | delegated only | yes | assigned only | assigned only |
| Edit technical/inverter settings | yes | delegated only | according to product workflow | only with explicit permission | no |
| Submit maintenance report | yes | delegated only | yes | yes | yes |
| Manage station team | yes | delegated only | owned station only | no | no |
| Grant platform roles | Founder only | no | no | no | no |

Platform Admin permissions must be separately enumerated and must not imply Founder authority.

## Invitation workflow requirements

- Owner selects an email address and station-scoped role (engineer or technician).
- A trusted server-side function verifies the caller's authenticated identity and ownership of the target station.
- The function sends the Auth invitation using server-held credentials.
- The invited user's membership is created or activated only after a verified invitation/registration flow; do not accept a client-supplied user UUID as proof of identity.
- Duplicate invitations and existing memberships must be handled safely.
- Invitation, acceptance, role assignment, permission changes, and revocation should be audited.
- The invited user receives no access to any other station by default.

## Acceptance test matrix

### Authentication and platform role
1. Anonymous caller cannot read or mutate protected application rows.
2. A signed-in ordinary user is not treated as Founder.
3. The verified Founder account passes the Founder check.
4. A user cannot add or modify their own platform role.
5. A station owner cannot grant Founder, Platform Admin, or Super Admin.

### Profiles
6. User A cannot read or update User B's profile.
7. User A cannot change profile identity or creation timestamp.
8. A user's permitted profile fields can be updated without affecting other users.

### Stations
9. Owner A can read and update only stations with owner_id = auth.uid().
10. Owner A cannot read or update Owner B's station.
11. An active assigned member can read only the station(s) assigned to them.
12. An inactive/revoked member loses access.
13. A station insert cannot set owner_id to another user's UUID.

### Station memberships and permissions
14. Owner A can invite/add an engineer or technician only to Owner A's station.
15. Owner A cannot manage Owner B's station memberships.
16. A member cannot enroll themselves, reactivate themselves, or change their own role.
17. Technician cannot manage station membership or permission rows.
18. Engineer cannot manage station membership or permission rows.
19. Owner cannot assign platform-level roles or unknown permission keys.
20. Revocation removes station access immediately after the authorization state is refreshed/validated.

### Technical configuration and audit
21. Engineer without the explicit technical-settings permission cannot update inverter settings.
22. Engineer with that permission can update only the allowed technical fields for assigned station(s).
23. Technician cannot update inverter settings.
24. Authorized station users can submit maintenance records through the approved write path.
25. Ordinary clients cannot alter or delete audit records.
26. Activity records cannot be forged with another user's actor_id.

## Execution strategy

- Implement tests first in a non-production/staging project.
- Test through actual anon and authenticated sessions, not only SQL editor queries run as postgres.
- Verify both RLS policies and SQL grants; RLS does not grant table privileges by itself.
- Verify UPDATE policies include both USING and WITH CHECK, plus a SELECT policy.
- Inspect SECURITY DEFINER functions and restrict execution grants. Do not expose a privileged helper in the public schema.
- Capture expected/actual outcomes and retain a test report before any production migration.
- Take and verify a database backup before production deployment.

## Open implementation details (not assumed)

- The current schema has no dedicated maintenance/work-orders table. Maintenance submissions must not be implemented by writing arbitrary data into activity logs; define the correct table/workflow first.
- Current station schema has no dedicated inverter configuration columns beyond general station fields. Determine where live inverter settings/telemetry will live before writing those policies.
- Define the exact allowlist of engineer-editable technical fields.
- Decide invitation expiry, resend, cancellation, and duplicate-email behavior.

## Safety status

This file documents approved product behavior and required tests. It is not an executable migration. No live database tables, rows, policies, grants, functions, triggers, or schema were changed.
