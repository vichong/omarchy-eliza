> **Archived design note.** This describes an earlier build (three eras, a script
> switcher and a centred overlay). The plugin now has two eras, 1966 and 1985, in a
> drop-down panel. `README.md` is the current description.

# omarchy-eliza — build spec (v0.2: one frame, three screens, boot sequences)

An Omarchy (Quickshell) shell plugin: talk to ELIZA from the bar. Three eras,
two genuine engines, one overlay. Plugin id `io.github.vichong.eliza`, IPC
target `eliza`, MIT.

Read `docs/DESIGN.md` first. The mock is in `docs/mockup/*.dc.html`; match it.
v0.2 supersedes the v0.1 layout: the era no longer restyles the whole card.

## v0.2 frame (applies to every era)

The card is one fixed frame; only the **screen** inside changes with the era
(`docs/mockup/Main.dc.html`, `Teletype1966.dc.html`, `Mac1985.dc.html`).

| Region | Spec |
|---|---|
| Header, 28 px | "ELIZA" `Style.font.heading` bold, then a caption in `Style.font.caption` muted: `IBM 7094 · 1966` / `Macintosh · 1985`; **in the Omarchy era the caption is a two-segment script switch** `DOCTOR · 1966 │ Eliza 1.3 · 1985` styled like the era switch at caption size, selected segment in `selectedBackground` + `selectedText`. Right: one **segmented control** `1966 │ 1985 │ Omarchy`, 1 px border at 40 % foreground, selected segment `Color.menu.selectedBackground` fill + `selectedText`. |
| Screen | Fills the middle. 1 px border at 40 % foreground. Background: Omarchy `Qt.darker(Color.menu.background, 1.25)`; 1966 `#050806` with 6 px radius; 1985 theme paper (or white with `macPaper`). Everything era-specific lives inside. |
| Input row, 30 px | Same in every era: 1 px border, `›` prompt in accent, `Ui.TextField` unframed inside, block caret. Disabled with the placeholder "ELIZA is typing at N characters a second" while the 1966 reveal runs. |
| Footer, caption size | Left: `Esc close · Ctrl+T thoughts · Ctrl+N new · Ctrl+1 2 3 era` (1966: `Esc finish line · Ctrl+T trace …`). Right: `turn N`, and in 1985 `turn N · Memory: M`. |

Screens:
- **Omarchy**: transcript as v0.1 (user lines behind a 1 px muted rule, Thinking captions), padding 12.
- **1966 CRT**: `fonts/VT323-Regular.ttf` via `FontLoader`, 16 px, line height 18, letter spacing 0.3; phosphor colour from the `phosphor` setting (`green` `#5dff8a`/glow `#2fbf5e`, `amber` `#ffb347`/`#b8781f`, `theme` = foreground/muted); text glow with a `MultiEffect` or layered `Text` shadow (2 px and 8 px); scanline overlay = `Repeater` of 1 px rows at 28 % black every 3 px; vignette = radial gradient `Rectangle` overlay at 55 % black edges. User lines prefixed `> `. Trace lines at 14 px, 55 % opacity. Reveal at `teletypeCps`.
- **1985 Mac**: the Eliza window only, no menu bar (removed after review). 1 px ink border, 2 px hard shadow, 19 px striped title bar with close box, "Eliza" in Chicago, two boxes right; transcript in **Chicago** (`fonts/ChicagoFLF.ttf`) 12 px, ELIZA bold and user plain, the whole window in the Mac's own face as Vic asked; 15 px scrollbar with arrow boxes and hatched track. Chicago = `fonts/ChicagoFLF.ttf` via `FontLoader` (public domain, bundled). `macPaper` flips ink/paper to black on white.

## Boot sequences (`docs/mockup/Boot*.dc.html`)

Shown in the screen on every overlay open with an empty transcript and on
every era switch; any key press or click skips to the end; the input is
disabled until the boot finishes. All values are live, gathered once at
service start by a single bounded `Process` running
`printf '%s\n' "$USER" "$(hostname)" "$(omarchy-version 2>/dev/null)" "$(uname -r)"`
(5 s deadline; blanks fall back to `vic`-free generic text: `USER`, `OMARCHY`, `4`, `linux`).
- **1966** (CTSS dialogue from the ELIZA Reanimated project). Pacing: lines the
  *user* typed (`login <user>`, `r eliza`, `100`) are typed at `teletypeCps`;
  every other line is system output and appears whole, one line every 120 ms,
  so the whole boot takes about 6 s. No line may wrap at the card width: use
  the compact spacing below (single spaces) and drop the CRT boot text to 15 px
  only if a line still wraps.
  ```
  login <user>
  W <HHMM.m wall clock>
  Password
   <USER>  6 LOGGED IN <MM/DD/YY> <HHMM.m> FROM 200000
   LAST LOGOUT WAS <8 January 1966, regional order> 1915.9 FROM 200000
   HOME FILE DIRECTORY IS <USER> OMARCHY

  OMARCHY TIME-SHARING SYSTEM. IBM 7094.
  VERSION: <omarchy version>

   CTSS BEING USED IS: <HOSTNAME uppercased>
  R .033+.000

  r eliza
  W <HHMM.m>
  EXECUTION.
  WHICH SCRIPT DO YOU WISH TO PLAY
  100
  ```
  then the real greeting from the engine. Day and month are today's; **the year is always 66** (Vic's call, 2026-09-09): `09/09/66` today.
  **Day/month order follows Omarchy's regional setting**, not a hard-coded
  American `MM/DD`: read the clock widget's `format` from
  `~/.config/omarchy/shell.json` (`bar.layout.*[].id == "omarchy.clock"`, key
  `format`; the departures plugin's `Service.qml` shows the `FileView` +
  `clockFormatFromShellConfig` pattern to copy). If the format has a day token
  (`d`, `dd`) before a month token (`M`, `MM`, `MMM`, `MMMM`) the boot dates
  are `DD/MM/YY`; month first gives `MM/DD/YY`. With no clock format, fall
  back to `Qt.locale().dateFormat(Locale.ShortFormat)` and apply the same rule.
  Implement as `Model.dateOrder(clockFormat, localeFormat)` → `"dmy" | "mdy"`
  and `Model.bootDate(date, order)` → `"09/09/66"`, both unit-tested
  (`"ddd d MMM h:mm AP"` → `dmy`, `"MM/dd/yyyy"` → `mdy`, `"HH:mm"` → falls
  through to the locale argument). Times stay 24-hour `HHMM.m`, as CTSS printed them.
- **Omarchy** (one line every 120 ms, 11 px, `[  OK  ]` in green `#9ece6a`, `[ WARN ]` in yellow `#e0af68`; no line may clip, `wrapMode: NoWrap` with these lengths fits the card):
  ```
  Omarchy <version> · Linux <kernel>
  <user>@<hostname> is booting ELIZA, the 1966 program

  [  OK  ] Mounted plugin eliza <manifest version>
  [  OK  ] Loaded script doctor-1966 (<keyword count> keywords)
  [  OK  ] Started engine hay-1966 (CC0)
  [  OK  ] Reached target Rogerian psychotherapist
  [ WARN ] No memory of previous sessions (by design)

  Weizenbaum 1966 · recovered 2021 · reanimated 2025
  ```
  then the greeting.
- **1985**, monochrome, from Vic's reference video stills, four beats
  (`docs/mockup/BootMac1985Floppy.dc.html`, `BootMac1985Happy.dc.html`,
  `BootMac1985.dc.html`; pixel paths for the icons are in
  `docs/mockup/mac-icons.json`, keys `floppy` 24×24 and `happy` 32×30):
  1. **Floppy** (1.2 s): flat 1-bit grey screen (2 px checker of ink at 50 %),
     centred 24 px floppy icon drawn at 3× (72 px) in ink, the `?` in its label
     blinking at 500 ms.
  2. **Happy Omarchy Mac** (1.0 s): the compact Mac icon, 32×30 at 3×, with the
     Omarchy glyph on its screen where the smiling face was.
  3. **Welcome** (1.4 s): a wide box across the screen (14 px side margins,
     132 px tall, 40 px from the top) with a double border: 1 px ink, 2 px paper,
     1 px ink. Top-left, a hand-drawn compact Mac in a loose single stroke with
     the Omarchy glyph on its screen and a pointing hand below-left (the SVG in
     the mock, as a `Shape`). Centred in Chicago 16 px: "Welcome to Omarchy."
     Never "Macintosh".
  4. The Eliza window appears and the greeting is written.

Fonts live in `fonts/` with their licences (`fonts/VT323-OFL.txt`,
`fonts/ChicagoFLF-LICENSE.txt`); load them with `FontLoader { source: Qt.resolvedUrl("fonts/…") }`
and use `loader.name`.

Config gains `phosphor` ∈ `green | amber | theme` (default `green`),
`boot` (default `true`) and `omarchyScript` ∈ `doctor-1966 | hayden-1985`
(default `doctor-1966`).

## Reference implementation to copy patterns from

`vichong/omarchy-tfnsw-departures` is a finished plugin by the same
author on the same shell. Copy its structure where the problem is the same:

| Departures file | Reuse as | Notes |
|---|---|---|
| `Panel.qml` | `Panel.qml` | `Ui.WidgetButton` in the bar, `IpcHandler` owning the `eliza` target with `manageIpc: false`, the **glyphRef / TextMetrics placement** of a vector mark at the painted box of a reference glyph. Our mark is a filled rectangle, not a Shape. No popup: left click summons the overlay, right click summons it on the settings tab. |
| `Overlay.qml` | `Overlay.qml` | Full-screen `PanelWindow` on `WlrLayer.Overlay` with exclusive keyboard focus, `open(payloadJson)` / `close()` / `dismiss()`, scrim, centred card, `controlHeight` trick. |
| `Service.qml` | `Service.qml` | `FileView` config with `mkdir -p`, `statusLine()` for bug reports. No network, no credentials, no polling. |
| `ConfigStore.js` + `tests/test_config.js` | same | Shrunk to our keys. |
| `manifest.json`, `tests/helpers.js` | already here | |

The first-party emojis overlay (`/usr/share/omarchy/shell/plugins/emojis/Emojis.qml`)
is the canonical card: `Color.menu.background/text/border/scrim/selectedBackground/selectedText`,
`Border.surfaceSpec("menu", "border", …, Style.space(2))`, `Style.cornerRadius`,
card `min(Style.space(400), …) × min(Style.space(500), …)`, header
`max(Style.space(34), Style.font.title + controlPaddingY*2)`, content margin
`Style.spacing.panelPadding`. Use exactly those.

The shell UI kit is at `/usr/share/omarchy/shell/Ui`, tokens at
`/usr/share/omarchy/shell/Commons` (`Style`, `Color`, `Border`). Plugin docs:
`/usr/share/omarchy/shell/README.md`, `/usr/share/omarchy/shell/plugins/README.md`.

## Already written — do not change, keep tests green

- `Eliza.js` — Hay's 1966 engine. API: `E.api.readScript(text)` → `["success", script] | [errorMessage]`;
  `new E.api.Eliza(script.rules, script.memoryRule, tracer)`; `eliza.response(text)` → uppercase string;
  `tracer` is `new E.api.Tracer()` (text in `eliza.tracer.text()` after each response) or `new E.api.nullTracer()`;
  `script.helloMessage` is a word array. See `docs/ENGINE.md`.
- `Hayden.js` — Hayden's 1985 engine. API: `H.api.readScript(text)` → `{ok, script | error}`;
  `new H.api.Hayden(script, tracerFn?)`; `engine.initial()`; `engine.response(text)` → `{text, finished}`;
  `engine.memory.length` is the saved-memory count. See `docs/HAYDEN-ENGINE.md`.
- `scripts/doctor-1966.txt`, `scripts/hayden-1985.txt` — data, loaded at runtime with `FileView`.
- `tests/test_engine.js`, `tests/test_hayden.js`, `tests/test_scripts.js`.

QML JavaScript constraints for anything new (learned the hard way, see
`docs/ENGINE.md`): no `BigInt`, `TextEncoder`, `setTimeout`, `async`/`await`;
declare every variable; `.pragma library` modules export through `var`/`function`.

## Files to write

| File | Job |
|---|---|
| `Model.js` (`.pragma library`) | Pure functions: `sentenceCase(upper)`, `eraFor(id)`, `transcriptAppend(list, entry)`, `traceLines(text)`, `isQuitReply(...)`. Tested in `tests/test_model.js`. |
| `ConfigStore.js` | `parse/merge/serialize`, keys below. `tests/test_config.js`. |
| `Service.qml` | Owns engines, scripts, transcript, era, settings. |
| `Overlay.qml` | The card: header, transcript, thoughts, input, footer; settings and about tabs. |
| `Panel.qml` | Bar mark + IPC. |
| `EraOmarchy.qml`, `EraTeletype.qml`, `EraMac.qml` | Transcript renderers, one per era, same interface (`model`, `thoughtsOn`, `typing`). Keep the card frame in `Overlay.qml`; eras only style what is inside the frame. The 1985 era additionally replaces the header with the Mac title bar + menu bar from the mock. |
| `README.md` | Extend the existing one with usage and settings. |

## Config

`~/.config/omarchy/eliza/config.json`:

```json
{ "era": "omarchy", "thoughts": true, "blink": true, "showLabel": true, "macPaper": false, "teletypeCps": 15 }
```

`era` ∈ `omarchy | 1966 | 1985`. `macPaper` true draws the 1985 era in black on
white instead of theme ink on theme paper. `teletypeCps` 5..60.

## Behaviour

### Service (`Service.qml`, kind `service`)

- Loads both scripts with `FileView` from `Qt.resolvedUrl("scripts/…")` at
  startup; `ready` when both parsed. Parse failure → `error` string, overlay
  shows it in place of the transcript.
- **Era → engine binding:** `1966` uses `Eliza.js` with `doctor-1966.txt`;
  `1985` uses `Hayden.js` with `hayden-1985.txt`; **`omarchy` uses whichever
  the `omarchyScript` setting names** (`doctor-1966` default, or
  `hayden-1985`), so the modern era can compare the two approaches.
  `setOmarchyScript(id)` saves and starts a new conversation (both engines
  carry state). `Ctrl+E` flips it. Display rules follow the engine: Hay output
  is sentence-cased, Hayden output is shown verbatim. The Thinking panel shows
  Hay's trace for `doctor-1966` and, for `hayden-1985`, the lines Hayden.js
  logs through its tracer callback (`key:`, `decomp:`, `reasmb:`, `memory save:`,
  `memory recall:`), so thoughts work for both. The Omarchy boot log names the
  script and engine actually loaded (`Loaded script hayden-1985 (42 keywords)`,
  `Started engine hayden-1985 (Charles Hayden)`).
- **Conversation** is a `ListModel` of `{ role: "eliza"|"user", text, trace, at }`.
  A new conversation starts with the script's greeting: for 1966/omarchy
  `script.helloMessage.join(" ")` (uppercase in 1966, `Model.sentenceCase` in
  omarchy); for 1985 `engine.initial()`.
- `say(text)`: append the user entry, get the reply, append the eliza entry.
  Display text per era: 1966 verbatim uppercase; omarchy `Model.sentenceCase`
  (first letter and the pronoun I capitalised, everything else lowercase,
  **no punctuation added or removed**); 1985 verbatim including Hayden's
  double spaces. `trace` is `tracer.text()` for the Hay engine, `""` for
  Hayden. In 1985, a reply with `finished: true` ends the conversation: the
  input shows "Conversation over. Enter starts a new one." and the next Enter
  calls `newConversation()`.
- `setEra(id)` switches era, saves it, and **starts a new conversation**
  (engines have state; mixing them mid-transcript would be a lie).
  `newConversation()` re-instantiates the engine for the current era.
- Settings setters save through `ConfigStore`. `statusLine()` returns
  `era, script, turns, thoughts, engine version`.
- Nothing leaves the machine. No `Process` except `mkdir -p` for the config dir.

### Overlay (`Overlay.qml`, kind `overlay`)

- Tabs: `chat` (default), `settings`, `about`. Summon payload `{ "tab": … }`.
- **Header**: "ELIZA" in `Style.font.heading` bold, era switch on the right as
  a `Ui.ButtonGroup` (or three `Ui.Button`s) with labels `1966 · 1985 · Omarchy`,
  selected = `Color.menu.selectedBackground` fill + `selectedText`.
- **1985 chrome** (see `docs/mockup/Mac1985.dc.html`, modelled on a System 7
  screenshot): the card becomes a Mac screen. Top: a 20 px menu bar with the
  Omarchy glyph (draw `/usr/share/omarchy/icon.png`'s bracket shape as a
  `Shape`/`Canvas` in ink, 13 px) where the Apple sat, then `File Edit Special
  Font Size Style Eliza Help`. Menu font: `ChicagoFLF` if `Qt.fontFamilies()`
  has it, else `Style.font.family` bold. Only `Eliza` opens a menu: `New
  conversation`, `1966`, `1985`, `Omarchy` (era switch), `Settings…`, `About
  Eliza…`; the others are decoration and do nothing. Below, inset 8 px: the
  Eliza window with a 1 px ink border and a 2 px hard shadow, a 19 px title
  bar (close box, stripes, "Eliza" centred on paper, two boxes right), the
  transcript, a 15 px scrollbar on the right with arrow boxes and a hatched
  track, and a 16 px status strip with `Eliza 1.3 · Charles Hayden · 1 August
  1985` left and `Memory: n` right.
- **Transcript**: `ListView` bound to the conversation, scrolled to the end on
  append, PgUp/PgDn scroll, mouse wheel works. Per-era delegate as in the
  mock: omarchy user lines indented behind a 1 px muted rule; 1966 all lines
  uppercase, plain, `letter-spacing: 0.5`; 1985 in `Style.font.family`
  (Monaco's stand-in) with **ELIZA's lines bold and the user's plain**,
  2 px between lines, no indent, exactly like the screenshot.
- **Thoughts** (omarchy + 1966 only): under each eliza entry with a trace, a
  caption row `chevron + "Thought for N ms"` where N is measured around the
  `response()` call (`Date.now()` before/after, show one decimal, minimum 0.1).
  Click or `Ctrl+T` toggles. The newest entry starts expanded when `thoughts`
  is on; older ones collapsed. Expanded shows the trace in a `Color.background`
  darker inset (`Qt.darker(Color.menu.background, 1.25)`), 10 px, `white-space: pre`.
  In omarchy the trace is reformatted by `Model.traceLines`: keep only the
  lines for selected keyword, matching decompose pattern, selected reassemble
  rule, and memory use; strip the ` | ` prefix; join key/precedence as
  `keyword: ALIKE (10) → DIT` when a link keyword follows. In 1966 show the
  raw trace lines untouched.
- **Teletype pacing (1966 only)**: reveal the reply at `teletypeCps`
  characters per second with a `Timer`; the input is disabled and its
  placeholder reads "ELIZA is typing at 15 characters a second"; the bar mark
  stays solid accent meanwhile. `Escape` during typing completes the line
  instead of closing. Omarchy and 1985 are instant.
- **Input**: `Ui.TextField`, always focused while open, prompt glyph `›` in
  accent (omarchy/1966). In 1985 there is no separate field: the user types
  on the next transcript line inside the window with a blinking 1 px I-beam,
  as the Mac did (an unframed `TextInput` as the last row of the list). Enter sends non-empty text; the field
  clears. Up/Down recall the last 20 user lines.
- **Footer**: left `Enter send · Esc close · Ctrl+T thoughts · Ctrl+N new`,
  right `DOCTOR, 1966`. In 1985 the footer is the window's status strip.
- **Keys**: Escape closes (or finishes typing), `Ctrl+T` thoughts, `Ctrl+N`
  new conversation, `Ctrl+1/2/3` eras, `Ctrl+,` settings, `F1` about.
- **Settings tab**: era, thoughts, blink, showLabel, macPaper, teletype speed
  (`Ui.NumberField` 5–60), "New conversation" and "Copy transcript" buttons
  (`wl-copy` via `Quickshell.execDetached`). Use the departures overlay's
  `FieldLabel/Caption/SectionTitle` pattern.
- **About tab**: text only, in this order: what ELIZA is (two sentences);
  Weizenbaum's warning, quoted from *Computer Power and Human Reason* (1976):
  "I had not realized that extremely short exposures to a relatively simple
  computer program could induce powerful delusional thinking in quite normal
  people."; the code recovery in one sentence (found in his MIT papers 2021,
  released CC0 by his estate); credits: Anthony and Max Hay (engine, CC0),
  Charles Hayden (Eliza 1.3 for Macintosh, 1985), the ELIZA Archaeology
  Project; links as plain text URLs (`findingeliza.org`,
  `github.com/anthay/ELIZA`, `chayden.net/eliza`). No headings larger than
  `Style.font.title`.

### Bar (`Panel.qml`, kind `bar-widget`)

- `Ui.WidgetButton`, `labelVisible: false`, tooltip "ELIZA" or the last
  ELIZA line when a conversation exists. Left click toggles the overlay,
  right click opens settings, middle click starts a new conversation.
- **Mark**: a filled `Rectangle` 7 px wide (scale with `Style.space`) whose
  height and baseline come from the painted box of a reference glyph exactly
  as in the departures `Panel.qml` (`glyphRef` + `TextMetrics.tightBoundingRect`).
  Colour `bar.barForeground`; solid `Color.accent` while the overlay is open;
  blinks 600 ms on / 600 ms off when `blink` is on and the overlay is closed
  (`Timer`, no animations framework). `showLabel` (default on) puts "ELIZA"
  in the bar font **before** the block, so the bar reads `ELIZA▮` with the
  block blinking after the A, like a prompt waiting for you.
- IPC target `eliza`: `open() close() toggle() settings() about() new()
  era(name) thoughts() say(text): string` (returns ELIZA's reply, so shell
  scripts can talk to it), `status(): string`.

## Tests and verification

- `node tests/test_model.js`: `sentenceCase("IN WHAT WAY")` → `"In what way"`,
  `sentenceCase("YOU SAY I AM DEPRESSED")` → `"You say I am depressed"`,
  `sentenceCase("I'M NOT SURE")` → `"I'm not sure"`, `traceLines(...)` on a
  real trace captured from `Eliza.js`, `eraFor` defaults.
- `node tests/test_config.js`: defaults, merge, bad values clamp.
- The plugin is symlinked at `~/.config/omarchy/plugins/io.github.vichong.eliza`;
  the shell hot-reloads. Verification is by screenshot of the real overlay in
  each era against the mock (Fable does this; leave the transcript shown in
  the mock reproducible: type the classic lines from `research/mac-1985-hayden/eliza.classic.txt`).

## Out of scope for v0.1

Script picker, PARRY replay, transcript export to the vault, CLI shim,
speech, idle notifications. Do not stub them.
