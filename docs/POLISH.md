> **Archived design note.** This describes an earlier build (three eras, a script
> switcher and a centred overlay). The plugin now has two eras, 1966 and 1985, in a
> drop-down panel. `README.md` is the current description.

# Polish pass 1 (2026-09-09, from a side-by-side with the shell's emoji overlay)

Reference: `/usr/share/omarchy/shell/plugins/emojis/Emojis.qml` and the shell UI
kit in `/usr/share/omarchy/shell/Ui` (`Toggle`, `ButtonGroup`, `Button`,
`TextField`, `NumberField`, `PanelSectionHeader`). Match their heights, padding
and states rather than inventing controls. Frame rules in `docs/SPEC.md` still
apply: header, screen inset, input row, footer never move.

1. **Header.** One row, 28 px: `ELIZA` (heading, bold) · caption (`IBM 7094 ·
   1966` / `Macintosh · 1985` / `DOCTOR · 1966` or `Hayden · 1985` in Omarchy)
   · spacer · **era switch** as a `Ui.ButtonGroup`-style segmented control with
   `Style.space(10)` horizontal padding per segment and `Style.space(22)` height
   · gear. Remove the script switch from this row.
2. **Script switch (Omarchy only).** A caption-sized row directly under the
   header, right-aligned: `Script  DOCTOR 1966 · Hayden 1985`, the active one in
   `Color.menu.selectedText`, the other muted, both clickable, `Ctrl+E` still
   flips. 18 px tall; the screen inset shrinks by that much only in Omarchy.
3. **Transcript scrolling.** Only call `positionViewAtEnd` when
   `contentHeight > height`; never let the first entry sit above the top. Same
   in all three eras.
4. **Footer legend.** `Esc close · ^T thoughts · ^N new · ^E script · ^1 ^2 ^3 era`
   (1966: `Esc finish · ^T trace …`; 1985: no `^T`, no `^E`). Must not elide at
   the card width; measure with `TextMetrics` and drop the `^E` item first if
   it does.
5. **Settings tab.** Tabs row in sentence case (`Chat · Settings · About`),
   same segmented style as the era switch. Content lives **inside the screen
   inset** in a `Flickable` with the same 12 px padding as the chat, scrolls,
   clips. Rows: label left, control right, `Style.space(30)` tall, `Style.spacing.md`
   between. Booleans use `Ui.Toggle`. Era and script use the same segmented
   control as the header (full labels, never elided). Phosphor is a three-segment
   control. Teletype speed is `Ui.NumberField`. Two `Ui.Button`s at the end:
   `New conversation`, `Copy transcript`. No "Settings" heading; the tab is the
   heading. Captions under a row only where they add something ("Switching
   starts a new conversation." once, at the top).
6. **About tab.** Inside the screen inset, same padding, `lineHeight` 1.35,
   paragraphs separated by `Style.spacing.lg`. The three links in accent.
7. **1966 CRT.** Drop the two-line banner at the top of the transcript (the
   boot covers it). Trace lines wrap at the screen width (`Text.Wrap`), still
   14 px at 55 %.
8. **Rhythm.** Card padding `Style.spacing.panelPadding` (18) on all sides;
   header → screen → input → footer gaps `Style.space(8)`; input row
   `Style.space(30)`; footer caption `Style.font.caption`. Screen inset border
   stays 1 px at 40 % foreground; the card border stays the menu border.
9. **Gear.** Same size as the era switch height, `Style.space(4)` after it,
   muted, brightens on hover, becomes a cross on the Settings/About tabs (as now).
