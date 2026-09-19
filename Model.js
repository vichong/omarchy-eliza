.pragma library

var MAX_INPUT_CHARS = 500
var MAX_ROWS = 400
var MAX_TRACE_CHARS = 8192
function capTrace(text) {
  var suffix = "\n… trace truncated"
  return text.length > MAX_TRACE_CHARS ? text.slice(0, MAX_TRACE_CHARS - suffix.length) + suffix : text
}
function utf8Bytes(text) {
  var bytes = 0
  for (var i = 0; i < text.length; i++) {
    var c = text.charCodeAt(i)
    if (c < 128) bytes++
    else if (c < 2048) bytes += 2
    else if (c >= 0xd800 && c <= 0xdbff && i + 1 < text.length && text.charCodeAt(i + 1) >= 0xdc00 && text.charCodeAt(i + 1) <= 0xdfff) { bytes += 4; i++ }
    else bytes += 3
  }
  return bytes
}

function eraFor(id) { return id === "1985" ? "1985" : "1966" }
function transcriptAppend(list, entry) { return list.concat([Object.assign({}, entry)]) }
// The 1966 engine has no quit protocol. Never infer termination from prose.
function isQuitReply(reply) { return !!reply && reply.finished === true }
function unescapeTrace(text) {
  // Hay's tracer writes for a browser console and escapes < > &.
  return String(text || "").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&amp;/g, "&")
}
function luminance(c) {
  function linear(n) { return n <= 0.04045 ? n / 12.92 : Math.pow((n + 0.055) / 1.055, 2.4) }
  return 0.2126 * linear(c.r) + 0.7152 * linear(c.g) + 0.0722 * linear(c.b)
}
function contrast(a, b) { var x = luminance(a), y = luminance(b); return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05) }

// Boot data is plain text, never markup or shell input.
function bootValues(text) {
  var lines = String(text || "").split("\n"), fallback = ["USER", "OMARCHY", "4", "linux"], values = []
  for (var i = 0; i < 4; i++) values.push((lines[i] || "").trim().slice(0, 256) || fallback[i])
  return {user: values[0], host: values[1], version: values[2], kernel: values[3]}
}
// Same bar-layout lookup as the departures plugin; absent formats use the locale.
function clockFormatFromShellConfig(text) {
  var config
  try { config = JSON.parse(String(text || "")) } catch (e) { return "" }
  var layout = config && config.bar && config.bar.layout
  if (!layout || typeof layout !== "object") return ""
  var sections = Object.keys(layout)
  for (var s = 0; s < sections.length; s++) {
    var list = layout[sections[s]]
    if (!Array.isArray(list)) continue
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && entry.id === "omarchy.clock") return typeof entry.format === "string" ? entry.format : ""
    }
  }
  return ""
}
function dateOrder(clockFormat, localeFormat) {
  function order(format) {
    // Qt quotes literals with single quotes; ddd/dddd are weekdays, not dates.
    var tokens = String(format || "").replace(/'[^']*'/g, "").match(/d+|M+/g) || []
    var day = -1, month = -1
    for (var i = 0; i < tokens.length; i++) {
      if (day < 0 && /^(d|dd)$/.test(tokens[i])) day = i
      if (month < 0 && /^M{1,4}$/.test(tokens[i])) month = i
    }
    return day < 0 || month < 0 ? "" : day < month ? "dmy" : "mdy"
  }
  return order(clockFormat) || order(localeFormat) || "mdy"
}
function bootDate(date, order) {
  function pad(n) { return (n < 10 ? "0" : "") + n }
  var day = pad(date.getDate()), month = pad(date.getMonth() + 1)
  // Today's real date in the regional order, with a CTSS two-digit year.
  return (order === "dmy" ? day + "/" + month : month + "/" + day) + "/" + pad(date.getFullYear() % 100)
}
// CTSS reports the previous session after the login. Ours ended on Weizenbaum's
// birthday in the month of the CACM paper, at the minute of the ELIZA Reanimated demo login.
var LAST_LOGOUT = new Date(1966, 0, 8)
// Only these CTSS prompts are keyboard input; all other lines are system output.
function bootLineTyped(era, index) { return era === "1966" && (index === 0 || index === 13 || index === 17) }
// 1985 boots with a splash, not text.
function bootLines(era, values, date, order) {
  function pad(n) { return (n < 10 ? "0" : "") + n }
  if (era !== "1966") return []
  var clock = pad(date.getHours()) + pad(date.getMinutes()) + "." + Math.floor(date.getSeconds() / 6)
  var user = values.user.toUpperCase()
  return ["login " + values.user, "W " + clock, "Password",
    " " + user + "  6 LOGGED IN " + bootDate(date, order) + " " + clock + " FROM 200000",
    " LAST LOGOUT WAS " + bootDate(LAST_LOGOUT, order) + " 1915.9 FROM 200000",
    " HOME FILE DIRECTORY IS " + user + " OMARCHY", "",
    "OMARCHY TIME-SHARING SYSTEM. IBM 7094.", "VERSION: " + values.version,
    "", " CTSS BEING USED IS: " + values.host.toUpperCase(),
    "R .033+.000", "", "r eliza", "W " + clock, "EXECUTION.", "WHICH SCRIPT DO YOU WISH TO PLAY", "100"]
}
