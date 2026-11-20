#!/bin/sh
# Calm Garden - native Linux x86_64 build.
#   ./build_linux.sh          build the program and the tests
#   ./build_linux.sh test     build, then run the automated tests
# Needs: FreeBASIC >= 1.10 (fbc), libsdl2-dev, libsdl2-ttf-dev (2.20+, HarfBuzz enabled).
# Optional at run time: lib/linux64/libbass.so (sound). libfribidi is used only by one test.
set -e
cd "$(dirname "$0")"
FBC="${FBC:-fbc}"
FLAGS="-w all -gen gcc -O 2"
CORE="src/settings.bas src/localization.bas src/progress.bas src/bidi.bas"
GFX="src/graphics.bas src/text.bas src/scene.bas src/platform.bas src/app_state.bas src/audio.bas src/ui.bas src/animation.bas src/session.bas src/simulated_biofeedback.bas"
SCREENS="src/menu.bas src/settings_screen.bas src/breathing.bas src/relaxation.bas src/mindfulness.bas src/biofeedback_screen.bas src/minigames.bas src/meditation_timer.bas src/progress_screen.bas"

EXIST=""
for f in $SCREENS $GFX; do [ -f "$f" ] && EXIST="$EXIST $f"; done

echo "Building calm_garden..."
$FBC $FLAGS -x calm_garden src/main.bas $CORE $EXIST

if [ -d tests ]; then
    echo "Building tests..."
    for t in tests/test_*.bas; do
        name=$(basename "$t" .bas)
        deps=$(sed -n "s/^' deps: //p" "$t")
        $FBC $FLAGS -x "tests/$name" "$t" $deps
    done
fi

if [ "$1" = "test" ]; then
    fails=0
    for t in tests/test_*.bas; do
        name=$(basename "$t" .bas)
        echo "== $name"
        if ! (cd tests && "./$name"); then fails=$((fails+1)); fi
    done
    echo "Test programs failed: $fails"
    [ $fails -eq 0 ] || exit 1
fi
echo "Done."
