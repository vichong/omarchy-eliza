# Changelog

Versions follow the `version` in `manifest.json`; every release is a git tag `vX.Y.Z` on the commit it describes.

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
