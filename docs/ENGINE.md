# Engine notes

`Eliza.js` is Anthony Hay's JavaScript ELIZA, taken verbatim from
`src/eliza.html` v1.00 in https://github.com/anthay/ELIZA (CC0 1.0), lines from
the opening `<script>` up to the browser console code. It reproduces the 1966
CACM ELIZA exactly, including SLIP's HASH and a recreated YMATCH bug, and
ships Hay's unit tests (`elizaTest`) which we run under Node and QML.

Every local change is marked in the file with an `// omarchy-eliza:` comment.

| Change | Why |
|---|---|
| `.pragma library` header and credit block | QML shared library module. |
| `response()` and `testDoctor()` made synchronous; `await delay()` and the interrupt check removed | The `await` only let the browser repaint and honour an interrupt command. QML JS has no `setTimeout`, and replies are now subject to an operation budget. |
| `utf8ArrayFromString` hand-rolled | No `TextEncoder` in QML JS (or Node's `vm`). |
| `hash()` reimplemented with 18-bit limbs in doubles; `lastChunkAsBcd()` returns a Number; test constants use `parseInt(s, 8)` / hex literals | No `BigInt` in QML JS. A 36-bit datum is exact in a double; the 72-bit square is computed exactly in base-2^18 digits. Hay's `testHash` and `testLastChunkAsBcd` still pass. |
| `let success;` in `match()` and `applyTransformation()`, `let response;` in `testDoctor()` | Implicit globals from sloppy mode. QML rejects the write ("Invalid write to global property"). |
| `Tokenizer.peektok()` rewritten without `return this.t = this.readtok()` | Under Qt 6.11's V4 engine the original form skipped the bare `START` marker incorrectly and the script failed with "malformed rule" on the next rule. A minimal reproduction did not trigger it; the conventional form works. |
| `var api = { ... }` export block at the end | Top-level `class` and `const` are not visible to QML importers, only `var` and `function`. |

## Running the tests

```
node tests/test_engine.js
QML_XHR_ALLOW_FILE_READ=1 QT_QPA_PLATFORM=offscreen QT_FORCE_STDERR_LOGGING=1 \
  QT_LOGGING_RULES="*.debug=true;qt.*=false" qml6 tests/qml/harness.qml
```

The QML harness needs the XHR flag only to read the script file; the plugin
reads scripts through Quickshell's `FileView`.

## Scripts

`scripts/doctor-1966.txt` is Hay's verbatim transcription of the DOCTOR script
from the January 1966 CACM appendix (© 1966 ACM, published as part of the paper).

## Local resource limits

1. `match()` charges each recursive entry against a shared 10,000-step budget
   reset by `response()`, before copying arrays. Exhaustion unwinds wildcard
   searches and skips remaining keywords. NONE gets an independent 1,000-step
   reserve (11,000 successful charged entries maximum per response); on exhaustion
   it receives empty input so the bundled `(0)` fallback needs only two steps.
   A malformed fallback returns `PLEASE GO ON`, without throwing.
2. Hay's memory queue retains at most 64 entries, dropping the oldest before
   adding a new memory. FIFO recall is unchanged.
3. The tracer itself is unchanged: a trace is rebuilt for every response, so its
   size follows the 500-character input and the matcher budget. `Service.say()`
   caps what is kept per row at `Model.MAX_TRACE_CHARS` (8,192 UTF-16 code
   units, ending `… trace truncated`). An earlier setter-based cap inside
   `Tracer` threw a TypeError under Qt's QML JavaScript engine and was removed.

`Service.say()` slices input to `Model.MAX_INPUT_CHARS` (500 UTF-16 code units)
prior to history, rows, or engine invocation; the input field uses the same
constant. `tests/test_bounds.js` exercises the original 2,400-BELIEVE attack
without that input slice, asserts budget exhaustion and the actual NONE reply,
and checks latency below 500 ms. `tests/test_service.js` checks the central slice,
row/trace limits, and exception recovery including teletype state.

Foreign config reads use `head -c` with 1,048,576-byte (`shell.json`) and
65,536-byte (`config.json`) ceilings; reaching the ceiling is invalid, including
an exactly-sized file. UTF-8 byte counting happens before parsing (replacement
characters from invalid UTF-8 can conservatively reject a smaller file).
FileView watchers have `preload: false`, `blockLoading: false`, no adapters,
and never call `text()`, `data()`, or `reload()`. Only the owned atomic config
write uses `setText()`. This follows the [FileView loading documentation](https://quickshell.org/docs/v0.3.1/types/Quickshell.Io/FileView/).
The [Process stdin API](https://quickshell.org/docs/v0.3.0/types/Quickshell.Io/Process/)
writes the copied transcript then closes stdin via `stdinEnabled = false`.
`tests/test_io.js` executes oversized read/boot fixtures and checks the watcher
and clipboard wiring; it does not exercise a real Wayland clipboard manager.
