import test from "node:test";
import assert from "node:assert/strict";
import { normalizeVoltronicReading } from "./normalize-telemetry.js";

test("normalizes a gateway payload and retains explicit units", () => {
  const result = normalizeVoltronicReading({
    measured_at: "2026-11-28T01:00:00Z",
    pv_power_kw: 2.4,
    battery_soc_pct: 87,
    battery_voltage_v: 51.8,
    ac_output_power_kw: 1.1
  });
  assert.equal(result.source, "voltronic_gateway");
  assert.equal(result.quality, "valid");
  assert.equal(result.metrics.find(x => x.metric_key === "pv_power_kw").unit, "kW");
  assert.equal(result.metrics.find(x => x.metric_key === "battery_soc_pct").metric_value, 87);
});

test("rejects missing required fields", () => {
  assert.throws(() => normalizeVoltronicReading({ pv_power_kw: 1 }), /missing required field/);
});

test("rejects impossible battery state of charge", () => {
  assert.throws(() => normalizeVoltronicReading({
    measured_at: "2026-11-28T01:00:00Z",
    pv_power_kw: 1,
    battery_soc_pct: 140,
    battery_voltage_v: 52
  }), /battery_soc_pct/);
});
