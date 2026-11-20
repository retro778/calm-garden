# Architecture

```
main.bas            start-up, data folder, main loop (delta time, ~60 FPS), dispatch, test modes
app_state.bas/.bi   shared state (gApp, gSet, gCv, gIn), screen and activity ids
platform.bas/.bi    the only SDL2 user: window, input, fullscreen, presenting the canvas
graphics.bas/.bi    software canvas (32-bit), anti-aliased shapes, coverage rasteriser
text.bas/.bi        bidi layout + SDL2_ttf/HarfBuzz shaping, run cache, wrapping   (sdlttf.bi = binding)
bidi.bas/.bi        Unicode Bidirectional Algorithm (UAX #9)
scene.bas/.bi       procedural icons and nature artwork
ui.bas/.bi          immediate-mode widgets, keyboard focus, themes, header, toasts
animation.bas/.bi   easing, the breathing model (safety rules), session clock      [pure logic]
session.bas/.bi     shared activity flow: intro -> run -> done, ratings, recording
audio.bas/.bi       BASS loaded at run time; sound synthesis; ambient/narration
localization.bas/.bi  UTF-8 string files, fallbacks, child variants, {n} formatting  [pure logic]
settings.bas/.bi    load/save/validate preferences                                  [pure logic]
progress.bas/.bi    practice history, favourites, gratitude, chart data             [pure logic]
simulated_biofeedback.bas/.bi  simulation engine + sensor-source abstraction        [pure logic]
menu.bas            main menu, About, tile grid / rating helpers
settings_screen.bas, breathing.bas, relaxation.bas (+ step player), mindfulness.bas,
biofeedback_screen.bas, minigames.bas, meditation_timer.bas, progress_screen.bas
```

* **Rendering**: every frame is drawn into one software canvas at window size and
  uploaded as a texture (`Plat_Present`). Layout uses a scale factor
  `gApp.sc = min(w/1024, h/768)` so 1024x768 is the design size and larger windows
  scale up; backgrounds always fill the whole window.
* **Right-to-left**: layouts are written left-to-right and mirrored with `Ui_MX`;
  text alignment "start/end" follows the paragraph direction.
* **Timing**: `gApp.dt` is the real frame time (clamped to 0.1 s); breathing and
  timers use real time; decorative motion uses `gApp.anim`, scaled by the
  animation-speed setting and slowed by reduced motion.
* **Separation**: simulation, persistence and localisation have no drawing code and
  are what the unit tests link against. Screens call them.
* **Data**: `assets/lang/*.txt` (all text and relaxation scripts), `assets/fonts`,
  optional `assets/sounds` and `assets/narration`. User data: settings.txt,
  progress.txt (see `progress.bi` for the format).
* **Test hooks**: `--shots DIR`, `--frames N`, `--audio-check`, `CALM_TRACE`,
  `CALM_NOAUDIO`, `CALM_NOERRORBOX` (see README).
