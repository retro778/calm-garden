#!/bin/sh
# Calm Garden - Windows 32-bit (x86) cross-build with the Windows FreeBASIC compiler under Wine.
#   ./build_win32.sh          build build/win32/calm_garden.exe (+ tests) and copy the run-time files
#   ./build_win32.sh test     also run the tests under Wine
# Paths can be overridden:
#   FBW   = fbc32.exe of FreeBASIC for Windows (1.10+, "winlibs" package with its own gcc)
#   SDLW  = SDL2 MinGW development folder for i686 (SDL2 2.30 + SDL2_ttf 2.22 merged)
#   WINEPREFIX = a 32-bit Wine prefix
set -e
cd "$(dirname "$0")"
FBW="${FBW:-$HOME/freebasic/FreeBASIC-1.10.1-winlibs-gcc-9.3.0/fbc32.exe}"
SDLW="${SDLW:-$HOME/c_programming/SDL2-2.30.9/i686-w64-mingw32}"
export WINEPREFIX="${WINEPREFIX:-$HOME/.wine32}"
export WINEDEBUG=-all
W=build/win32
FLAGS="-w all -gen gcc -O 2"
mkdir -p $W/tests

CORE="src/settings.bas src/localization.bas src/progress.bas src/bidi.bas"
GFX="src/graphics.bas src/text.bas src/scene.bas src/platform.bas src/app_state.bas src/audio.bas src/ui.bas src/animation.bas src/session.bas src/simulated_biofeedback.bas"
SCREENS="src/menu.bas src/settings_screen.bas src/breathing.bas src/relaxation.bas src/mindfulness.bas src/biofeedback_screen.bas src/minigames.bas src/meditation_timer.bas src/progress_screen.bas"
EXIST=""
for f in $SCREENS $GFX; do [ -f "$f" ] && EXIST="$EXIST $f"; done

wfbc() { wine "$FBW" $FLAGS -p "$SDLW/lib" "$@"; }

echo "Cross-building $W/calm_garden.exe (wine + fbc32)..."
wfbc -s gui -x $W/calm_garden.exe src/main.bas $CORE $EXIST res/calm_garden.rc
[ -f $W/calm_garden.exe ] || { echo "Build FAILED"; exit 1; }

echo "Building tests..."
for t in tests/test_*.bas; do
    name=$(basename "$t" .bas)
    deps=$(sed -n "s/^' deps: //p" "$t")
    wfbc -x "$W/tests/$name.exe" "$t" $deps
done

# run-time files next to the program
cp "$SDLW/bin/SDL2.dll" "$SDLW/bin/SDL2_ttf.dll" $W/
cp lib/win32/bass.dll $W/
rm -rf $W/assets && cp -r assets $W/
cp README.md LICENSE $W/ 2>/dev/null || true
mkdir -p $W/tests/data $W/docs
cp tests/data/*.txt $W/tests/data/
cp -r docs/* $W/docs/ 2>/dev/null || true
# the release SDL2_ttf.dll carries ~60 MB of debug information: strip our copies
if command -v strip >/dev/null 2>&1; then strip --strip-debug $W/SDL2_ttf.dll $W/SDL2.dll 2>/dev/null || true; fi
# the tests look for ../assets relative to the test folder
cp $W/SDL2.dll $W/SDL2_ttf.dll $W/tests/

if [ "$1" = "test" ]; then
    fails=0
    for t in $W/tests/test_*.exe; do
        name=$(basename "$t")
        echo "== $name"
        out=$(cd $W/tests && wine "./$name" 2>&1 | tr -d '\r')
        echo "$out" | grep -v "^$" | tail -8
        echo "$out" | grep -qE " 0 failed" || fails=$((fails+1))
    done
    echo "Test programs failed: $fails"
fi
echo "Done (win32)."
