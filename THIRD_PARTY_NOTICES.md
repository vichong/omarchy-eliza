# Third-party notices

This plugin's own code (QML, `Model.js`, `ConfigStore.js`, tests, docs) is MIT,
© 2026 Vic Hong. Everything below belongs to someone else and keeps its own terms.

| What | Where | Author | Terms |
|---|---|---|---|
| ELIZA engine | `Eliza.js` | Anthony Hay and Max Hay, 2023, from `src/eliza.html` v1.00 in https://github.com/anthay/ELIZA | CC0 1.0 (text in `licenses/CC0-1.0.txt`). Local changes are marked `// omarchy-eliza:` and listed in `docs/ENGINE.md`. |
| DOCTOR script | `scripts/doctor-1966.txt` | Joseph Weizenbaum. Transcribed by Anthony Hay from the appendix of the paper cited below | © 1966 Association for Computing Machinery, as Hay's project also notes. Reproduced here, as there, as the historical text the program exists to run |
| Macintosh engine | `Hayden.js` | A JavaScript port of Charles Hayden's 1998 Java Eliza, itself a rework of his 1985 Macintosh program. http://www.chayden.net/eliza/Eliza.html | Hayden's page: "You are welcome to make use of it however you want." |
| Macintosh script | `scripts/hayden-1985.txt` | Charles Hayden, Eliza 1.3 for Macintosh, 1 August 1985 | Same author and permission as above; recovered from the 1985 application |
| Demo prompts | `Demo.js`, `tests/fixtures/classic-inputs.txt` | The patient's fifteen lines from the conversation printed in Weizenbaum's 1966 paper (pp. 36–37) | © 1966 ACM; short quotation of a published conversation, cited below |
| CTSS login text | `Model.js` (`bootLines`) | Modelled on the session transcript in Lane, Hay, Schwarz, Berry and Shrager, "ELIZA Reanimated", arXiv:2501.06707 (2025) | Short factual system output, adapted; cited here as the source |
| VT323 font | `fonts/VT323-Regular.ttf` | © 2011 The VT323 Project Authors (Peter Hull) | SIL Open Font License 1.1 (`fonts/VT323-OFL.txt`) |
| ChicagoFLF font | `fonts/ChicagoFLF.ttf` | Robin Casady | Public domain by the author's statement (`fonts/ChicagoFLF-LICENSE.txt`) |

## References

- Joseph Weizenbaum, "ELIZA — A Computer Program For the Study of Natural
  Language Communication Between Man And Machine", Communications of the ACM
  9(1), January 1966, pp. 36–45.
- Joseph Weizenbaum, *Computer Power and Human Reason*, W. H. Freeman, 1976
  (the quotation in About).
- The ELIZA Archaeology Project, https://findingeliza.org/ — the recovery of the
  original MAD-SLIP source from Weizenbaum's papers at MIT.
- Rupert Lane, Anthony Hay, Arthur Schwarz, David M. Berry, Jeff Shrager,
  "ELIZA Reanimated: The world's first chatbot restored on the world's first
  time sharing system", arXiv:2501.06707, 2025.

## Homage, not affiliation

The 1985 era imitates the look of the original Macintosh system software:
the striped title bar, and pixel redrawings of the disk-with-question-mark and
smiling-Macintosh startup icons designed by Susan Kare for Apple. They are
redrawn here as a tribute; the designs remain Apple's. Macintosh is a trademark
of Apple Inc. This plugin is not affiliated with or endorsed by Apple, MIT,
the Weizenbaum estate, Charles Hayden, or the Omarchy project.
