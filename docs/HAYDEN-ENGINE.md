# Task: port Charles Hayden's ELIZA engine to `Hayden.js`

## Why

The Mac ELIZA this plugin pays homage to is Charles Hayden's **Eliza 1.3 (1 August 1985)**.
Its script (`scripts/hayden-1985.txt`) uses Hayden's own line-based
format, not Weizenbaum's 1966 S-expressions, and his matcher works on characters
(substring wildcards), not words. Converting the script to the 1966 format would change
behaviour. So the plugin carries two engines, each running its own script verbatim:

- `Eliza.js` — Anthony Hay's 1966 CACM engine (ported separately).
- `Hayden.js` — this task. A faithful JavaScript port of Hayden's 1998 Java rework of
  the 1985 program. Source: his Java sources at http://www.chayden.net/eliza/Eliza.html (kept locally in the git-ignored `research/hayden-java/`) (his permission: "You are
  welcome to make use of it however you want"), format doc: `instructions.txt` on the same page.

## Deliverables

1. `Hayden.js` — a QML `.pragma library` module. Constraints that come from the Qt V4
   JavaScript engine (see `docs/ENGINE.md` for the ones we hit porting Hay's code):
   - No `BigInt`, no `TextEncoder`, no `setTimeout`, no `async`/`await`.
   - No implicit globals: declare every variable (`let`/`const`), QML rejects the write.
   - Top-level `class`/`const` are invisible to importers. End the file with
     `var api = { ... }` exposing the public surface.
   - Plain ES2017 otherwise is fine (classes, arrow functions, template literals, `Map`).
   Public surface:
   ```js
   api.readScript(text)            // -> { ok: true, script } | { ok: false, error }
   new api.Hayden(script, tracer?) // engine instance
   engine.initial()                // the `initial:` line
   engine.response(input)          // -> { text, finished }  (finished after a quit word; text is `final:`)
   engine.trace                    // last-response trace text ('' when no tracer)
   ```
   Keep Hayden's algorithm exactly as `ElizaMain.processInput` / `sentence` / `decompose` /
   `assemble` do it, including:
   - input lowercasing, punctuation translation and `compress`, sentence splitting on `.`;
   - `pre:` substitutions before keyword scan; `post:` substitutions applied to the
     captured `(n)` pieces at reassembly time (not to the whole reply);
   - keyword stack ordered by rank, stable for equal ranks (`KeyStack.pushKey`);
   - `@synon` classes counting as a `*` for `(n)` numbering (`SynList.matchDecomp`);
   - `$` decompositions that save the reply to memory and continue; memory recall when
     nothing matched, then `xnone`, then "I am at a loss for words.";
   - `goto key` reassembly rules, including goto chains;
   - reassembly rules cycling in order per decomposition (`Decomp.stepRule`/`nextRule`);
   - the character-level matcher `EString.matchA` / `amatch` / `findPat` semantics, so
     `am*` in `* i am* @sad *` behaves exactly as in Java.
   Unrecognised script lines (`font:`, `size:`) are ignored, as Java does (it just prints).
   Do not "improve" the algorithm. Where Java behaviour looks odd, reproduce it and add a
   `// hayden:` comment.

2. `tests/test_hayden.js` — Node tests using `tests/helpers.js` (`loadModule("Hayden.js")`).
   Must cover:
   - the script loads: 42 keys, 8 synonym lists, 18 pre, 9 post, 4 quit words, initial/final text;
   - the 15 inputs in `tests/fixtures/classic-inputs.txt` produce replies without
     "I am at a loss for words."; record the actual replies as a golden fixture in
     `tests/fixtures/hayden-classic.json` so later changes are caught;
   - every line of `tests/fixtures/hayden-test-inputs.txt` produces a reply
     (this is Hayden's own per-rule smoke list);
   - a quit word returns `finished: true` with the `final:` text;
   - a `$` memory case: say "my x" a few times then something with no keyword and get a
     saved memory reply back;
   - a goto chain: "apologise" routes to the `sorry` rule.

3. `tests/qml/harness-hayden.qml` — copy the shape of `tests/qml/harness.qml`; load the
   script via XMLHttpRequest from `scripts/hayden-1985.txt`, run the
   first three classic lines, print them, exit 0 on success. Run it with:
   ```
   QML_XHR_ALLOW_FILE_READ=1 QT_QPA_PLATFORM=offscreen QT_FORCE_STDERR_LOGGING=1 \
     QT_LOGGING_RULES="*.debug=true;qt.*=false" qml6 tests/qml/harness-hayden.qml
   ```
   Wrap the body in try/catch and `Qt.exit(1)` on exception or the run hangs.

4. Copy the 1985 script to `scripts/hayden-1985.txt` unchanged.

## Done when

`node tests/test_hayden.js` prints `test_hayden: ok`, the QML harness prints the three
replies and exits 0, and `node tests/test_engine.js` still passes.

## Oracle result (2026-09-09)

`tests/hayden-oracle` compiles Hayden's Java with JDK 17 and diffs its transcript
against `Hayden.js` over the same inputs. Run on the classic conversation and on
Hayden's own per-rule list (`tests/fixtures/hayden-test-inputs.txt`), every reply
matched except memory recalls, where `Decomp.stepRule` picks a random reassembly in
Java and the JS run pins `Math.random` to 0. The Java also prints
"Unrecognized input" for the script's `font:`/`size:` lines, which the port ignores
silently as specified.

## Local resource limits

1. The keyword stack still holds 20 entries with stable rank ordering and
   duplicates, but ignores subsequent keywords instead of throwing an overflow.
2. The matcher takes the first literal match without backtracking. Nevertheless,
   `findPat` can retry long partial literals at successive positions (quadratic
   character comparisons even within 500 characters). A response-wide budget
   charges literal comparisons, candidate positions, wildcard/pattern iterations,
   numeric scans, and goto hops: 100,000 operations plus a 1,000-operation xnone
   reserve. Exhaustion returns through the script fallback, or the existing
   `I am at a loss for words.` fallback. The budget is cleared in `finally` so
   script parsing and subsequent responses are unaffected.
3. Service supplies no tracer callback. Trace call sites guard string construction
   as well as accumulation when no callback is given; when requested, accumulated
   trace is capped at 8,192 characters by `Model.capTrace`. Hayden's original memory
   limit remains 20 entries; the new 64-entry limit belongs to Anthony Hay's
   separate 1966 engine.

These changes are marked `// omarchy-eliza:` in the engine. Bounds and keyword
handling are covered by `tests/test_bounds.js`; service turn/history/row and
exception consistency are covered by `tests/test_service.js`.
