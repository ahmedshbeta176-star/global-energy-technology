# Voltronic / Axpert gateway contract

This folder defines the first application-side integration boundary.

## Important limitation

The browser application does not connect directly to inverter serial ports. A trusted local gateway is required to communicate with the specific Axpert model and its supported interface (for example, model-dependent serial/USB, Wi-Fi, or Modbus options). Confirm the exact model and protocol before implementing a transport driver.

## Gateway JSON contract

Send a JSON object containing:

```json
{
  "measured_at": "2026-11-28T01:00:00Z",
  "pv_power_kw": 2.4,
  "battery_soc_pct": 87,
  "battery_voltage_v": 51.8,
  "ac_output_power_kw": 1.1,
  "grid_voltage_v": 230.2,
  "frequency_hz": 50
}
```

Required fields: `measured_at`, `pv_power_kw`, `battery_soc_pct`, `battery_voltage_v`.
Optional fields: `ac_output_power_kw`, `grid_voltage_v`, `frequency_hz`.

The normalizer validates values and units, then produces metric records suitable for a trusted ingestion service. It does not write to Supabase and does not authenticate a gateway. Gateway authentication, device-to-station authorization, replay protection, rate limits, and secure secret storage must be implemented server-side before live ingestion.

## Tests

Run with Node.js 20 or later:

```sh
node --test integrations/voltronic/normalize-telemetry.test.js
```

These tests validate the JSON normalization contract only. They do not prove communication with a physical inverter.

## Current status

No physical inverter has been connected. No real readings are being received. No Supabase schema or production data has been changed.
