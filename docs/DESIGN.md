> **Archived design note.** This describes an earlier build (three eras, a script
> switcher and a centred overlay). The plugin now has two eras, 1966 and 1985, in a
> drop-down panel. `README.md` is the current description.

# Design brief

This is a **homage widget**. Its one job: let you talk to ELIZA, the 1966
program, from the bar of a 2026 desktop that ships with agents, and have the
conversation feel like the era it claims. Every UI decision is judged against
the three priorities below, in this order. When they conflict, the higher one
wins.

Mock: docs/mockup (three era artboards plus the bar mark), published as the
"ELIZA for Omarchy" design canvas on 2026-09-09.

## Priorities, ranked

1. **The era is real, not a costume.** What ELIZA says is produced by the
   genuine engine and script for that era, verbatim, and the text behaves the
   way it did: 1966 is uppercase at teletype pace; 1985 is Hayden's script in
   sentence case with his exact spacing quirks; Omarchy is the 1966 engine in
   sentence case. We never edit a reply, add punctuation, or "fix" a script.
   Authenticity lives in the words and their timing before it lives in chrome.
2. **Omarchy fit.** The same 400×500 card the shell's own overlays use
   (`Color.menu.*`, `Style.font.*`, panel padding 18, 2 px border in the
   active-border foreground, corner radius from the theme), the shell's
   monospace family, the same control heights. The bar mark is a flat block
   at the built-in glyph metrics and never carries colour except while the
   overlay is open. Era skins recolour with the theme: 1966 and Omarchy use
   the theme text and background; 1985 draws its 1-bit chrome in theme ink
   on theme paper, with true black-on-white as a setting for the purists.
3. **The joke stays out of the way.** The "Thinking…" panel is the sharpest
   part of the homage, so it has to look exactly like a modern reasoning
   disclosure: a small muted caption with a chevron, collapsed by default,
   the newest one open when thoughts are on. It never pushes the reply off
   screen and it is one keystroke to hide.

A skin detail that makes the era more convincing but breaks the shell's card
geometry loses. A shell convention that would make ELIZA's words look wrong
for the era (rounded corners on the 1985 window, a proportional font in 1966)
also loses.

## Glance rules

- **ELIZA's lines are the primary.** Theme foreground, full width. The
  user's lines are secondary: brighter foreground, indented behind a 1 px
  muted rule in Omarchy; plain in 1966 (the teletype had no distinction, only
  turn order). 1985 inverts it the way the Mac program did: ELIZA bold, the
  user plain, both in the monospace.
- **One input line**, bottom of the card, always focused while the overlay is
  open. Prompt glyph in accent. In 1966 the input is disabled and greyed
  while ELIZA is typing; Escape finishes the line instantly.
- **Thoughts are captions.** 10 px, muted, monospace, in a darker inset
  block. In 1966 they are the engine's raw ` | ` trace lines. In 1985 there
  is no trace, only "Memory: n" in the status strip, because the Mac had a
  Memory menu and nothing else.
- **One frame, three screens.** Header, era switch, input row and footer never
  move. The era only changes what is inside the screen inset, so switching is
  never disorienting. Boot sequences play inside the screen too.
- **Footer caption carries the keys**, not the header. Script and year on the
  right.

## Contrast rule

Body text is theme foreground on theme background, which every Omarchy theme
already guarantees. Muted captions use the theme's dark foreground and must
measure at least 3:1 on the card; if a theme's muted colour fails that, fall
back to foreground at 55% alpha the way the departures plugin does.

## Patterns borrowed

- Omarchy emojis overlay: card size, header height, scrim, keyboard focus.
- Departures plugin: bar mark placement off a reference glyph, overlay
  settings layout, IPC handler shape, config file handling.
- Hay's browser ELIZA: trace text format and the teletype pacing idea.
- Hayden's Eliza 1.3 and a System 7 ELIZA screenshot: menu bar, striped title
  bar, scrollbar, bold ELIZA lines, the Memory count. Chicago via the public
  domain ChicagoFLF (bundled in `fonts/`); Monaco's part is
  played by the shell's own monospace.
