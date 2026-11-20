# Calm Garden — Mindfulness & Relaxation Studio

**גן השלווה — סטודיו לקשיבות ולהרפיה**

Calm Garden is a friendly, colourful, completely offline desktop program for
breathing exercises, guided relaxation, mindfulness activities, gentle games, a
meditation timer and a clearly labelled **simulated** biofeedback demo. It is
suitable for children and adults, in English and Hebrew.

> Calm Garden is an educational relaxation tool. It is **not a medical device**
> and not a substitute for professional care. It does not diagnose, treat or
> cure anything, and it has no physiological sensors: the biofeedback section
> is a simulation and says so on every frame.

Written in **FreeBASIC**, using SDL2, SDL2_ttf (HarfBuzz shaping) and, optionally,
the BASS audio library. MIT licence (third-party parts keep their own licences).

## Features

| Area | What is included |
|---|---|
| Breathing | Breathing Flower, Breathing Balloon, Ocean Breathing, Star Breathing. Adjustable breathing-in (2–8 s) and breathing-out (2–10 s) times, an optional *rest after breathing out*, session length, picture theme. **No breath holding**, a minimum 5-second cycle (no fast breathing), a "breathe naturally" switch and pause at any time. |
| Guided relaxation | Progressive muscle relaxation, body scan, breathing awareness, a peaceful place, bedtime relaxation, five-minute break. Written steps (child-friendly variants), automatic or manual stepping, optional recorded narration per step. |
| Mindfulness | Five Senses (5-4-3-2-1), Mindful Observation, Thought Clouds (typed thoughts are never saved), Gratitude Garden (each note grows a flower), Calm Moments. |
| Simulated biofeedback | Breathing-guide waveform, heart-*like* demonstration waveform, focus game, colour-changing calm picture with an animation meter. Banner: *"Simulation only — no physiological sensors connected."* Engine with a source abstraction for future sensors (none required). |
| Games | Zen Garden (grows with completed sessions), Balloon Journey, Floating Leaves, Night Sky, Peaceful Aquarium. No scores, no countdowns, no losing. |
| Meditation timer | 1/3/5/10/15/20/30-minute presets, custom 1–120 min, ambient sounds, start/end chimes, pause/resume, four full-window visualisations, optional real fullscreen, summary. |
| Sound | Rain, ocean, wind, forest, birds, gentle music, chimes — all synthesised by the program (original, nothing to license). Gentle fades, moderate levels. Runs silently if BASS or a sound device is missing. |
| Progress | Local only: sessions, minutes, days in a row, most practised, favourites, optional before/after self-ratings, 14-day chart, recent history. Tracking can be switched off; everything can be deleted. |
| Accessibility | Text size 80–160 %, high contrast, reduced motion, full keyboard control, mute (Ctrl+M), no flashing, child-friendly mode (larger text, simpler words, shorter sessions), calm adult style, resizable window and fullscreen (F11). |
| Languages | English and Hebrew from UTF-8 files in `assets/lang/`. Real bidirectional layout (Unicode UAX #9) and HarfBuzz shaping; right-to-left mirroring of the whole interface. |

## Building

### Linux (x86_64)

Requirements: FreeBASIC ≥ 1.10, `libsdl2-dev`, `libsdl2-ttf-dev` (2.20+, built
with HarfBuzz — the Debian/Ubuntu/MX package is). Optional: `libfribidi` (only
for one comparison test), Xvfb + xdotool + ImageMagick (GUI tests).

```sh
./build_linux.sh          # builds ./calm_garden and the tests
./build_linux.sh test     # ... and runs all automated tests
./run_linux.sh            # starts the program
```

BASS for Linux is in `lib/linux64/libbass.so` and is loaded at run time.

### Windows (32-bit), cross-built under Wine

Requirements: the Windows FreeBASIC "winlibs" package (`fbc32.exe`), the SDL2 and
SDL2_ttf MinGW development files for i686, and a 32-bit Wine prefix.

```sh
./build_win32.sh          # -> build/win32/calm_garden.exe + DLLs + assets
./build_win32.sh test     # ... and runs the tests under Wine
```

Paths are set at the top of the script (`FBW`, `SDLW`, `WINEPREFIX`). The
folder `build/win32/` is a complete, portable Windows program: copy it
anywhere and run `calm_garden.exe`. Put an empty file `portable.txt` next to the
`.exe` to keep settings in a `userdata` folder beside it.

## Running

```
calm_garden [--lang en|he] [--size WxH] [--fullscreen] [--data DIR]
```

Settings and progress are stored in `~/.local/share/calm_garden/` (Linux) or
`%APPDATA%\CalmGarden\` (Windows) as small UTF-8 text files.

Keyboard: Tab/arrow keys move, Enter/Space choose, Esc goes back, Space pauses an
exercise, N switches to natural breathing, F11 fullscreen, Ctrl+M sound, Ctrl+Q quit.

## Testing

* `./build_linux.sh test` — settings validation, localisation completeness
  (every key in both languages, valid UTF-8), progress persistence and corrupted
  files, the breathing model's safety rules, biofeedback labelling, audio levels
  and loop seams, the bidi algorithm against Unicode's 91 000-case
  `BidiCharacterTest.txt`, our bidi against GNU FriBidi for every Hebrew string,
  and text shaping/wrapping through SDL2_ttf.
* `tests/gui_test.sh` — starts the real program on a private Xvfb display and
  drives it with real key presses and clicks: keyboard navigation, mouse,
  language switching, resizing, fullscreen, mute, frame rate, quitting.
* `./calm_garden --shots DIR` — renders every screen (both languages, also while
  exercises run) to BMP files for visual review.
* `./calm_garden --audio-check` — loads BASS and starts every sound silently.

See `docs/TESTING.md` for the results of the last run and `docs/PROGRESS.md` for
the development phases.

## Documentation

* `docs/USER_GUIDE.md` — how to use the program (also suitable for parents/teachers)
* `docs/ARCHITECTURE.md` — modules, text pipeline, data files
* `docs/LOCALIZATION.md` — adding languages, strings and narration
* `docs/SENSORS.md` — the simulation and the (optional) sensor interface
* `docs/THIRD_PARTY.md` — libraries, fonts and their licences
