/**
 * Voltronic/Axpert telemetry normalization boundary.
 *
 * This module does NOT speak serial/USB/RS-232/Modbus directly.
 * A trusted local gateway must translate the device/vendor protocol into
 * the documented JSON contract before sending readings here.
 */
export const VOLTRONIC_SOURCE = "voltronic_gateway";

const REQUIRED = ["measured_at", "pv_power_kw", "battery_soc_pct", "battery_voltage_v"];

function finiteNumber(value, name) {
  const number = Number(value);
  if (!Number.isFinite(number)) throw new TypeError(name + " must be a finite number");
  return number;
}

function isoTimestamp(value) {
  const date = new Date(value);
  if (!Number.isFinite(date.getTime())) throw new TypeError("measured_at must be a valid timestamp");
  return date.toISOString();
}

export function normalizeVoltronicReading(payload) {
  if (!payload || typeof payload !== "object" || Array.isArray(payload)) {
    throw new TypeError("payload must be an object");
  }
  for (const field of REQUIRED) {
    if (payload[field] === undefined || payload[field] === null) {
      throw new TypeError("missing required field: " + field);
    }
  }

  const pvPower = finiteNumber(payload.pv_power_kw, "pv_power_kw");
  const batterySoc = finiteNumber(payload.battery_soc_pct, "battery_soc_pct");
  const batteryVoltage = finiteNumber(payload.battery_voltage_v, "battery_voltage_v");

  if (pvPower < 0 || pvPower > 10000) throw new RangeError("pv_power_kw outside accepted safety bounds");
  if (batterySoc < 0 || batterySoc > 100) throw new RangeError("battery_soc_pct must be between 0 and 100");
  if (batteryVoltage < 0 || batteryVoltage > 2000) throw new RangeError("battery_voltage_v outside accepted safety bounds");

  const normalized = {
    measured_at: isoTimestamp(payload.measured_at),
    received_at: new Date().toISOString(),
    source: VOLTRONIC_SOURCE,
    quality: "valid",
    metrics: [
      { metric_key: "pv_power_kw", metric_value: pvPower, unit: "kW" },
      { metric_key: "battery_soc_pct", metric_value: batterySoc, unit: "%" },
      { metric_key: "battery_voltage_v", metric_value: batteryVoltage, unit: "V" }
    ]
  };

  for (const [field, key, unit, min, max] of [
    ["ac_output_power_kw", "ac_output_power_kw", "kW", 0, 10000],
    ["grid_voltage_v", "grid_voltage_v", "V", 0, 1000],
    ["frequency_hz", "frequency_hz", "Hz", 0, 100]
  ]) {
    if (payload[field] !== undefined && payload[field] !== null) {
      const value = finiteNumber(payload[field], field);
      if (value < min || value > max) throw new RangeError(field + " outside accepted safety bounds");
      normalized.metrics.push({ metric_key: key, metric_value: value, unit });
    }
  }

  return normalized;
}
