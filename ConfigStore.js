.pragma library
var KEYS = ["era", "thoughts", "blink", "showLabel", "macPaper", "teletypeCps", "phosphor", "boot", "demoIdle"]
function defaults() { return {era: "1966", thoughts: false, blink: true, showLabel: true, macPaper: false, teletypeCps: 15, phosphor: "green", boot: true, demoIdle: true} }
function normalize(raw) {
  var out = defaults()
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) return out
  if (raw.era === "1985") out.era = raw.era
  for (var i = 1; i < 5; i++) if (typeof raw[KEYS[i]] === "boolean") out[KEYS[i]] = raw[KEYS[i]]
  if (typeof raw.teletypeCps === "number" && isFinite(raw.teletypeCps)) out.teletypeCps = Math.max(5, Math.min(60, Math.round(raw.teletypeCps)))
  if (raw.phosphor === "amber" || raw.phosphor === "theme") out.phosphor = raw.phosphor
  if (typeof raw.boot === "boolean") out.boot = raw.boot
  if (typeof raw.demoIdle === "boolean") out.demoIdle = raw.demoIdle
  return out
}
function parse(text) {
  try {
    var raw = text ? JSON.parse(text) : {}
    if (!raw || typeof raw !== "object" || Array.isArray(raw)) throw new Error("Expected an object")
    return {config: normalize(raw), error: ""}
  } catch (e) { return {config: defaults(), error: "config.json must contain a valid JSON object"} }
}
function merge(current, patch) {
  var out = normalize(current)
  for (var i = 0; i < KEYS.length; i++) if (Object.prototype.hasOwnProperty.call(patch || {}, KEYS[i])) out[KEYS[i]] = patch[KEYS[i]]
  return normalize(out)
}
function serialize(config) { return JSON.stringify(normalize(config), null, 2) + "\n" }
