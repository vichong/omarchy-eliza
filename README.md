# ELIZA for Omarchy

Talk to ELIZA, the 1966 program that started it all, from the Omarchy bar.

A homage to the first thing that ever felt like AI to me, which I met on a
Macintosh in 1985. On an OS that ships with agents, ELIZA gets a "Thinking…"
panel too. It is four lines of pattern matching, and it always was.

## What is in here

| Part | Origin |
|---|---|
| `Eliza.js` | Anthony Hay's JavaScript recreation of the 1966 CACM ELIZA, CC0. Reproduces Weizenbaum's program exactly, SLIP bugs included. See `docs/ENGINE.md`. |
| `scripts/doctor-1966.txt` | The DOCTOR script as printed in the January 1966 CACM paper appendix. |
| `Hayden.js` | Port of Charles Hayden's Macintosh ELIZA engine (1985, via his 1998 Java rework). See `docs/HAYDEN-ENGINE.md`. |
| `scripts/hayden-1985.txt` | The script from Eliza 1.3 for Macintosh, 1 August 1985. |
| `Demo.js` | The patient's fifteen lines from the conversation printed in the 1966 paper. ELIZA's side is not stored; the engine produces it. |
| `fonts/` | VT323 (SIL OFL) and ChicagoFLF (public domain), with their licence files. |

## Status

Implemented: two era renderers, a shared conversation service, settings, bar mark, and IPC. Engines are verified under Node and Qt’s QML JavaScript engine.

## Credits

- Joseph Weizenbaum, ELIZA, MIT 1964 to 1966. Source released CC0 by his estate in 2021.
- Anthony Hay and Max Hay, the JavaScript engine, CC0. https://github.com/anthay/ELIZA
- Charles Hayden, Eliza for Macintosh 1985 and the Java version. http://www.chayden.net/eliza/Eliza.html
- The ELIZA Archaeology Project. https://findingeliza.org/
- Rupert Lane, Anthony Hay, Arthur Schwarz, David M. Berry and Jeff Shrager, "ELIZA Reanimated" (arXiv:2501.06707), the source of the CTSS login the 1966 era imitates.
- Fonts: VT323 by Peter Hull (SIL OFL 1.1) and ChicagoFLF by Robin Casady (public domain), both bundled in `fonts/`.
- The 1985 era redraws Susan Kare's Macintosh startup icons as a tribute. Not affiliated with Apple.

## Licence

MIT for this plugin's own code. Engines, scripts and fonts keep their own terms:
see `THIRD_PARTY_NOTICES.md` for each one's author, source, licence and the full references.

## Install

```bash
omarchy plugin add https://github.com/vichong/omarchy-eliza
omarchy plugin enable io.github.vichong.eliza
```

`omarchy plugin add` clones into `~/.config/omarchy/plugins/io.github.vichong.eliza`
and leaves the plugin disabled so you can read the code first. Enabling puts
**ELIZA** on the right of the bar. No sudo or pkexec is required. Nothing is
installed outside the plugin folder, and the plugin makes no network requests.

Requirements: Omarchy 4 (Quattro) with its Quickshell shell, which already
provides the Qt modules used (`QtQuick.Layouts`, `QtQuick.Effects`,
`QtQuick.Shapes`). **Copy transcript** needs `wl-copy` from `wl-clipboard`
(part of Omarchy). The boot sequence reads `$USER`, `hostname`,
`omarchy-version` and `uname -r` to fill in the login text, and falls back to
placeholders when one is missing. Both fonts are bundled. Node and a JDK 17
are only needed to run the developer tests.

## Remove

```bash
omarchy plugin remove io.github.vichong.eliza
rm -rf ~/.config/omarchy/eliza     # optional: your saved settings
```

The only thing ELIZA writes is `~/.config/omarchy/eliza/config.json`.
Conversations are never saved.

## Usage

Add **ELIZA** to the shell bar through the
shell’s widget picker. Left-click the block to toggle chat, right-click for
settings, and middle-click to start over. The block uses the bar foreground,
blinks every 600 ms, and holds accent while the panel is open or typing. The panel drops down under
the bar mark like other Omarchy bar panels; a click anywhere else closes it.

Choose **1966** or **1985** in the header. Every era switch starts fresh. The
1966 engine prints uppercase at teletype speed after a CTSS login: the login
line carries today's real date, a `LAST LOGOUT WAS` line stays on 8 January 1966, and
the login stays at the top of the transcript to scroll back to (it is left out
of **Copy transcript**). The Macintosh era preserves Hayden’s exact
words and spacing, and shows its memory count instead of a trace.

- Enter sends; Up/Down recall the last 20 user lines. PgUp/PgDn scroll.
- Escape finishes a teletype reply, then closes on the next press.
- Ctrl+T toggles the 1966 trace; click a caption to expand it. Only the newest
  reply starts expanded. Long traces scroll inside a bounded inset.
- Ctrl+N starts over; Ctrl+1/2 select 1966/1985.
- Ctrl+, opens settings; F1 opens About. The tabs return to chat.
- Ctrl+Q quits: the panel closes and the next open starts a fresh session,
  boot sequence included. The bar mark stays.
- After Hayden ends a conversation, Enter starts another.

Settings includes **New conversation** and **Copy transcript** (uses `wl-copy`).
Conversation text stays in memory and disappears when the shell restarts.
Nothing is sent over the network.

**Quit ELIZA** does the same as Ctrl+Q.

### Demo

**Play demo** in Settings (or `omarchy-shell eliza demo`) replays the
best-known ELIZA conversation there is: the one Joseph Weizenbaum printed on
pages 36 and 37 of "ELIZA — A Computer Program For the Study of Natural Language
Communication Between Man And Machine", Communications of the ACM 9(1), January
1966, which opens "Men are all alike." / "IN WHAT WAY". The demo prompts in
`Demo.js` are the patient's fifteen lines from that printed conversation, and
nothing else. It is a real session: the
patient's fifteen lines are typed into the live engine, which answers for
itself, word for word as published in the 1966 era. Any key takes over and the
conversation is yours from there. With **Play the 1966 conversation when idle**
on (the default), an untouched, empty conversation starts the demo after 30
seconds. Closing the panel or switching era stops it.

## Turning ELIZA off and on

ELIZA loads with the Omarchy shell for as long as it is enabled. There is no
in-app off switch; use the Omarchy plugin commands (or ask your AI agent to):

```bash
omarchy plugin disable io.github.vichong.eliza   # leaves the bar, stays off across restarts
omarchy plugin enable io.github.vichong.eliza    # back on the bar, right section by default
```

## Settings

Stored in `~/.config/omarchy/eliza/config.json`; changes save immediately and
external edits reload automatically. Unknown keys are discarded, invalid
values use defaults, and teletype speed is clamped to 5–60.

```json
{ "era": "1966", "thoughts": true, "blink": true, "showLabel": true, "macPaper": false,
  "teletypeCps": 15, "phosphor": "green", "boot": true, "demoIdle": true }
```

`era` is `1966` or `1985`. `phosphor` is `green`, `amber` or `theme` for the
1966 screen. `macPaper` selects true black on white for 1985; otherwise it uses
theme colours, set in the bundled ChicagoFLF. `boot` plays the start-up
sequences, `thoughts` shows the 1966 trace, `showLabel` adds ELIZA beside the
block, `blink` controls idle blinking, and `demoIdle` is the idle demo above.
Inputs are limited to 500 characters and a conversation keeps its latest 400
rows.

## IPC

```sh
omarchy-shell eliza open
omarchy-shell eliza close
omarchy-shell eliza toggle
omarchy-shell eliza quit
omarchy-shell eliza settings
omarchy-shell eliza about
omarchy-shell eliza newConversation
omarchy-shell eliza era 1985
omarchy-shell eliza thoughts
omarchy-shell eliza demo
omarchy-shell eliza copy
omarchy-shell eliza say "Men are all alike."
omarchy-shell eliza status
```

`newConversation` is the IPC spelling of the spec’s `new`: QML reserves `new`
and rejects it as a function name. `say` returns the complete reply immediately;
a 1966 reply continues revealing in the panel, and further input is ignored
until it finishes. `status` reports era, script, turns, thoughts, engine version,
and any configuration/script error.

## Verification

```sh
for test in tests/test_*.js; do node "$test"; done
PATH=/usr/lib/qt6/bin:$PATH QML_IMPORT_PATH=/usr/share/omarchy/shell qmllint Service.qml Console.qml Panel.qml Era*.qml
```

Use the Qt 6 linter: `/usr/bin/qmllint` on this machine belongs to Qt 5 and
exits 255 on the modern QML syntax without diagnostics. The Qt 6 linter
reports shell import/type-metadata warnings but completes successfully.

For a real-shell check, run `omarchy-shell eliza demo` in each era. The first
line is `Men are all alike.`; the first reply is `IN WHAT WAY` in 1966 and
`In what way ?` in 1985. `tests/hayden-oracle` compares `Hayden.js` with
Hayden's original Java and needs the upstream sources, which are not part of
this repository (see `docs/HAYDEN-ENGINE.md`).
The offscreen runtime harness verifies service and renderer construction;
Wayland layer-shell geometry, focus, clipboard, and live IPC still need the
real-shell visual pass described in the spec.

Clipboard managers may retain a copied conversation.
