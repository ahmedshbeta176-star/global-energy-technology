# Software Foundation Completion Plan

Date: 2026-11-28
Branch: development/rls-security
Status: implementation roadmap; items below are not claimed complete unless marked verified in the repository.

## Already present on the development branch
- Arabic login page using Supabase Auth password sign-in and password reset.
- Admin page fails closed: sign-in alone does not grant admin access.
- Founder role registry migration draft in the private schema; not applied.
- RLS policy design and approved access-model test specification.
- Station/device/telemetry/maintenance data-model proposal.
- Voltronic JSON telemetry normalizer and unit tests. This is a normalization boundary only, not a serial/USB/Modbus/cloud driver.
- Documentation for on-grid, off-grid, and hybrid operation.

## Software foundation still required before production

### Priority 1 — Database foundation
1. Convert the proposed data model into reviewed migrations: station devices, telemetry, maintenance work orders, and integration metadata.
2. Confirm exact existing column types, foreign keys, indexes, and grants before migration.
3. Add RLS policies and SQL grants together; test as anon, ordinary user, owner, engineer, technician, and Founder.
4. Review SECURITY DEFINER functions and restrict default PUBLIC execution.
5. Keep telemetry ingestion server-only; never accept browser-submitted readings as trusted device data.

### Priority 2 — Identity and invitations
1. Verify the intended Founder Auth UUID independently before applying the Founder migration.
2. Apply the Founder migration only after backup and staging verification.
3. Implement email invitations through a trusted server-side Edge Function using server-held Auth Admin credentials. Never expose the service-role key in the browser or repository.
4. Enforce station-scoped roles and allowlisted permissions; prevent self-promotion and cross-station access.

### Priority 3 — Application integration
1. Replace localStorage station CRUD with Supabase reads/writes under RLS.
2. Add station and device registration screens.
3. Add telemetry dashboard states: live, stale, disconnected, unavailable, and error.
4. Keep missing readings distinct from measured zero.
5. Add maintenance work-order create, assign, update, and close flows.
6. Add audit history for membership and configuration changes.

### Priority 4 — Integration readiness
1. Finish a model-neutral gateway ingestion endpoint with authentication, device-to-station binding, rate limits, timestamp checks, and replay protection.
2. Confirm Voltronic model and its documented read-only protocol before writing a transport driver.
3. Validate on-grid, off-grid, and hybrid metric availability; do not assume every inverter provides every metric.
4. Add connector adapters for other manufacturers only after each vendor/model interface is confirmed.

### Priority 5 — Release readiness
1. Run automated unit and authorization tests.
2. Run staging end-to-end tests with representative roles and sample data.
3. Check mobile layout, error handling, backups, logging, and recovery.
4. Publish only after review and explicit approval; keep the production branch unchanged until then.

## Suggested execution order
- First: schema migrations + RLS/grants + authorization tests.
- Second: replace localStorage with Supabase for station management.
- Third: implement maintenance workflows and the gateway ingestion endpoint.
- Fourth: tomorrow, connect a real inverter read-only and verify actual telemetry.
- Fifth: expose live dashboard values only after the readings pass validation.

## Tomorrow's device session checklist
- Exact inverter brand/model and firmware label.
- System topology: on-grid, off-grid, or hybrid.
- Communication interface and adapter/gateway model.
- Read-only sample response with credentials and personal identifiers removed.
- Confirm units and compare values against the inverter display.

## Safety and truthfulness
The branch currently contains code and design artifacts, but the database migrations have not been applied, no live inverter has been connected, and the updated site has not been deployed. No telemetry should be described as live until a physical device has been read and its values independently checked.
