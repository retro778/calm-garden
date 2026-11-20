# Development phases

| Phase | Status | Content |
|---|---|---|
| 1 Foundation | done | structure, SDL2 window, UI + keyboard focus, localisation (en/he, bidi + HarfBuzz), settings, menu, About, build scripts, tests |
| 2 Breathing & meditation | done | 4 breathing exercises, meditation timer, animation engine, session flow |
| 3 Mindfulness & relaxation | done | 6 relaxation programmes (step player, narration hook), 5 mindfulness activities |
| 4 Simulated biofeedback | done | engine + source abstraction, 4 labelled visualisations, explanation |
| 5 Mini-games | done | Zen Garden, Balloon Journey, Floating Leaves, Night Sky, Peaceful Aquarium |
| 6 Audio & progress | done | BASS (run-time), synthesised sounds, file overrides, progress screen & chart |
| 7 Polish & testing | done | auto-fitting text, focus-following scroll, GUI tests, failure tests, docs, Windows build |

## Known limitations / unfinished
* **No recorded narration is included** – the system plays recordings placed in
  `assets/narration/` (format documented), but recording voices was out of scope.
  Written instructions are always available.
* No ambient **recordings** are included; all sounds are synthesised (simple but
  original). Real CC0 recordings can be dropped into `assets/sounds/`.
* Hebrew text is shaped by HarfBuzz; strings with niqqud were not tested
  visually (the interface text does not use them).
* The text field supports typing and Backspace at the end only (no cursor
  movement or selection) – enough for short notes.
* Keyboard focus scrolling in Settings is implemented but at 1024x768 the panels
  fit, so it was not exercised in an automated test.
* Windows was tested only under Wine. BASS is free for non-commercial use only.

## Next steps (ideas)
* Optional CC0 nature recordings and recorded narration in both languages.
* More languages (Arabic would reuse the bidi/HarfBuzz pipeline; needs a font).
* An installer for Windows and a .deb/AppImage for Linux.
