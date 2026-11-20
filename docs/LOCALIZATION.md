# Languages, strings and narration

## Interface strings
All interface text lives in `assets/lang/<code>.txt` (UTF-8):

```
_name = עברית
_dir = rtl
breath.in = שאיפה…
breath.in.child = שואפים לאט…        # used in child-friendly mode
timer.start = התחלה, {1} דק׳           # {1} {2} {3} are filled in by the program
about.body = First paragraph\nSecond paragraph
```

* Missing keys fall back to English, then to the key name (so gaps are visible).
* `tests/test_localization.bas` checks that every English key exists in every
  other file, that there are no extra keys and that every value is valid UTF-8.
* `tests/test_fribidi.bas` compares our bidi ordering of every Hebrew line with
  GNU FriBidi.

### Adding a language
1. Copy `en.txt` to `xx.txt`, translate the values, set `_name` and `_dir`.
2. Add the language to the choice in `src/settings_screen.bas` and to
   `Settings_Validate` in `src/settings.bas`.
3. If the script is not Latin or Hebrew, add a font to `assets/fonts` and to the
   font choice in `src/text.bas` (`ChooseFonts`, script name for HarfBuzz).

## Text rendering (why Hebrew is correct)
`src/text.bas`: code points → **UAX #9** levels (`src/bidi.bas`, isolates and
bracket pairs included; tested against Unicode's conformance file) → line
breaking → L1/L2 reordering → visual runs of one level and one font → each run
shaped by **HarfBuzz** (inside SDL2_ttf) with its own direction (RTL runs are
mirrored by HarfBuzz) and script (`Hebr`/`Latn`). Strings are never just reversed.
Text typed by the user uses the direction of its first strong character.

## Guided-relaxation steps
Programme steps are ordinary strings: `relax.<programme>.1`, `.2`, … — add or
remove steps by editing the language files; the player counts them.

## Narration
Optional recordings: `assets/narration/<code>/<programme>_<step>.ogg|mp3|wav`
(see `assets/narration/README.txt`). No online text-to-speech is used.
