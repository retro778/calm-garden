# Test results (last run: 2026-11-20)

Environment: MX Linux x86_64, FreeBASIC 1.20.0 (Linux), FreeBASIC 1.10.1 winlibs
`fbc32.exe` under Wine 10.0 (32-bit prefix), SDL2 2.32 / SDL2_ttf 2.24 (Linux),
SDL2 2.30.9 / SDL2_ttf 2.22.0 (Windows), BASS 2.4.

Both builds compile with **zero warnings** (`-w all`).

| Test program | Linux x86_64 | Windows x86 (Wine) |
|---|---|---|
| test_animation (breathing model safety, easing, clock) | 12020 / 0 | 12020 / 0 |
| test_audio (synthesis levels, loop seams, no-BASS safety) | 34 / 0 | 34 / 0 |
| test_bidi (Unicode BidiCharacterTest: 91 626 cases) | pass | pass |
| test_biofeedback (labelling, model, sources) | 7222 / 0 | 7222 / 0 |
| test_fribidi (383 Hebrew lines + samples vs GNU FriBidi) | 403 / 0 | skipped (Linux only) |
| test_localization (complete translations, UTF-8, fallbacks) | 15 / 0 | 15 / 0 |
| test_progress (persistence, corruption, privacy switch) | 25 / 0 | 25 / 0 |
| test_settings (validation, invalid files) | 14 / 0 | 14 / 0 |
| test_text (HarfBuzz runs, widths, wrapping, drawing) | 17 / 0 | 17 / 0 |

## GUI tests (`tests/gui_test.sh`, real window on Xvfb, xdotool)
Linux: **22 / 22** (three consecutive runs). Windows .exe under Wine: **21 / 22**.

Covered: start-up, keyboard-only navigation, Esc, mouse click, switching to
Hebrew (RTL) and back, window resize (1400x900 and back), F11 fullscreen on/off,
Ctrl+M mute, frame rate (~61–65 FPS measured), Ctrl+Q quit, settings saved.
The Wine failure is the external resize: without a window manager Wine ignores
`xdotool windowsize`. Resizing on Windows is covered by fullscreen on/off
(1024x768 → 1600x1000 → back) and by starting at 1400x900 (`--size`).

## Screenshot review (`--shots`)
All 102 screens (51 per language, including running exercises) rendered on Linux
and on Windows/Wine and were reviewed, also with high contrast + 160 % text +
child mode + reduced motion, and at 1920x1080 in adult style.

## Failure handling
* No assets folder → clear error on stderr (+ dialog), exit code 1.
* Missing Hebrew file / missing fonts → English and fallback fonts, no crash.
* Corrupted settings.txt / progress.txt → invalid values replaced, bad lines skipped.
* BASS missing (`bass.dll` removed) → "runs silently", everything else works.
* `--audio-check`: BASS initialised and all six ambient loops started (silently)
  on Linux and under Wine.

## Not tested
* Real Windows hardware (only Wine). Wine reports Windows XP; SDL2 2.30 needs
  Windows XP or later in principle, Windows 7+ is recommended.
* Real loudspeaker listening of every sound (levels are checked numerically).
* Screen readers (SDL2 offers no accessibility API).
