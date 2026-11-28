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

## Supported system topology: on-grid and off-grid

The application data model must support both operating modes. Do not assume that every inverter exposes every metric.

### Common metrics
- PV generation power (kW)
- AC output/load power (kW), when exposed
- Battery state of charge (%) and battery voltage (V), when a battery exists
- Inverter operating state and fault/alarm codes, when exposed
- Measurement timestamp and gateway receive timestamp

### On-grid-specific optional metrics
- Grid voltage (V), frequency (Hz), and power (kW)
- Grid import energy (kWh)
- Grid export energy (kWh)
- Grid connection / anti-islanding state, where supported

### Off-grid-specific optional metrics
- Load power (kW) and load percentage (%)
- Battery charge/discharge power (kW), where supported
- Generator input/state, if a generator is installed
- Output voltage and frequency

A metric that the model does not expose must be stored as unavailable/null, never fabricated as zero. A zero is a real measured value and must remain distinguishable from missing data.

## Tomorrow's field-connection checklist

For each inverter to be connected, capture:
1. Exact brand and model from the nameplate.
2. Whether the installation is on-grid or off-grid (or hybrid).
3. Available physical interface: RS-232, USB, RS-485/Modbus, Wi-Fi, Ethernet, or vendor cloud.
4. Gateway/adapter model and connection details, without sharing passwords or API secrets in chat.
5. A small sample of raw read-only query response with serial numbers and credentials redacted.

Start with read-only polling. Do not send configuration-change, reset, or firmware commands during initial integration. Validate the protocol and command set for the exact inverter model before writing a transport driver.

The current normalizer is only the JSON contract/validation layer. It is not yet a serial, USB, Modbus, Wi-Fi, or cloud connector.
