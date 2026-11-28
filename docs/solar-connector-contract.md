# Solar monitoring connector contract (pre-integration)

Status: DESIGN ONLY. No vendor authorization, credentials, live endpoint or ingestion worker is installed.

## Separation of concerns
- Browser: read authorized station telemetry only; never hold vendor credentials or service-role keys.
- Server connector: vendor-approved authentication and scheduled polling/webhook handling, with secret storage outside public GitHub and public browser code.
- Normalizer: map approved vendor fields to station_telemetry_samples fields (solar_power_kw, load_power_kw, battery_soc, battery_power_kw, grid_power_kw, device_status, sampled_at).
- Station identity: verify vendor device identity maps to a station_inverters row and its station_id before any write. Do not accept arbitrary station_id from vendor payload.
- Deduplication: store vendor sample IDs / stable timestamps and reject duplicates; preserve original timestamps and units.
- Validation: enforce per-field ranges, units, source provenance, and reasonable time drift; log rejected readings separately.
- Source integrity: only trusted server-side connectors may write source='verified_connector'; authenticated end users may insert source='manual_test' only. Never allow a client to relabel manual data as verified.
- Alerts: latest verified reading may be used for operational alerts only after freshness and completeness checks. Manual readings are simulations, not live incident reports.
- Remote control: OUT OF SCOPE; require explicit owner authorization, vendor-supported protocol, operation approval, audit, and emergency-safe design.

## Vendor adapters
- DYA: pending verification of officially supported integration method, API availability, consent and rate limits.
- GoodWe: pending verification of officially supported integration method, API availability, consent and rate limits.
- Others: no assumption of supported APIs.

## Acceptance checklist
1. Verify vendor documentation and lawful access path.
2. Obtain owner consent and test device in a non-production pilot.
3. Create server-side adapter and least-privilege secrets.
4. Verify cross-station isolation and malformed payload handling.
5. Check freshness, backfill, deduplication and alert false positives.
6. Run read-only pilot before enabling any remote control.
