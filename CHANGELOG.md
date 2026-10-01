# Changelog

Versions follow the `version` in `manifest.json`; every release is a git tag `vX.Y.Z` on the commit it describes.

## 0.3.3 (2026-10-02)

- Quit ELIZA now uses Omarchy's persistent Disable Plugin operation, removing the bar widget and unloading its service instead of only closing/resetting the conversation. The Quit shortcut and IPC command use the same operation.
- Re-enable ELIZA through **Setup → Plugins → Enable Plugin**. Escape still only closes the panel.
- Settings controls, including Quit, remain clickable during startup; Ctrl+Q is no longer consumed by boot-skip handling.
- Run disable detached so plugin unloading cannot interrupt it, and show a notification if the command fails.
- Add isolated runtime regression tests for Quit, disable-command dispatch, and failure feedback. Verified the actual Settings Quit button and IPC against the live shell, then restored the plugin.
- Document stale QML with symlinked development checkouts: file watching/rescan may not load edits; a shell restart may be needed.

## 0.3.2 (2026-09-21)

- About: the opening paragraph gets a heading, "The program", like the sections after it.
- Screenshots recaptured as full 1600×1000 desktops; `preview.png`, the plugin directory's listing image, is now the 1966 one instead of a portrait crop of the panel.
- No change to the plugin's behaviour since 0.3.0.

## 0.3.1 (2026-09-19)

- README: desktop screenshots of both eras.
- No change to the plugin's behaviour since 0.3.0.

## 0.3.0 (2026-09-19)

First public release.

- ELIZA in a drop-down panel under the `ELIZA▮` bar mark.
- Two eras: the 1966 DOCTOR script on a CTSS teletype (Anthony Hay's CC0 engine) and Charles Hayden's 1985 Macintosh Eliza.
- Demo that replays the conversation printed in Weizenbaum's 1966 paper, with the engine answering live.
- Power button, Quit, a Trace switch for the 1966 era (off by default), green, amber or theme phosphor.
- Enforced limits on input length, matcher work, rows, traces, engine memory and every external read; clipboard copy over stdin.
