#!/bin/sh
# gui_test.sh - drives the REAL program window on a private virtual display (Xvfb)
# with xdotool and checks the state the program reports via CALM_TRACE.
# It never touches your desktop: everything happens on display :$DISP.
#
#   tests/gui_test.sh                 test ./calm_garden (Linux)
#   tests/gui_test.sh wine            test build/win32/calm_garden.exe under Wine
#
# Needs: Xvfb, xdotool, ImageMagick (import).
cd "$(dirname "$0")/.."
DISP=${DISP:-87}
TMP=${TMPDIR:-/tmp}/calm_gui_$$
mkdir -p "$TMP/data"
TRACE="$TMP/trace.txt"
pass=0; fail=0
ok()   { pass=$((pass+1)); echo "  ok   $1"; }
bad()  { fail=$((fail+1)); echo "  FAIL $1"; [ -f "$TRACE" ] && echo "       trace: $(cat "$TRACE")"; }
field(){ sed -n "s/.*\b$1=\([^ ]*\).*/\1/p" "$TRACE" 2>/dev/null; }
waitfor() {   # waitfor key value seconds
    i=0
    while [ $i -lt $(( $3 * 10 )) ]; do
        [ "$(field "$1")" = "$2" ] && return 0
        sleep 0.1; i=$((i+1))
    done
    return 1
}
# real (XTEST) key presses; without a window manager the focus follows the pointer,
# so the pointer is parked inside the program window first
key() { xdotool mousemove --window "$WIN" 20 400 key --delay 120 "$@"; sleep 0.3; }

Xvfb :$DISP -screen 0 1600x1000x24 >/dev/null 2>&1 &
XPID=$!
sleep 1
export DISPLAY=:$DISP
export CALM_TRACE="$TRACE" CALM_NOAUDIO=1

if [ "$1" = "wine" ]; then
    export WINEPREFIX="${WINEPREFIX:-$HOME/.wine32}" WINEDEBUG=-all
    # Wine passes the environment through; the trace path must be a Windows path
    export CALM_TRACE="Z:$(echo "$TRACE" | tr '/' '\\')"
    (cd build/win32 && wine ./calm_garden.exe --data "Z:$(echo "$TMP/data" | tr '/' '\\')" --size 1024x768) >/dev/null 2>&1 &
else
    ./calm_garden --data "$TMP/data" --size 1024x768 >/dev/null 2>&1 &
fi
APID=$!

echo "== start-up"
if waitfor scr 0 30; then ok "program started on the main menu"; else bad "start-up"; fi
WIN=""
i=0
while [ -z "$WIN" ] && [ $i -lt 50 ]; do
    if [ "$1" = "wine" ]; then
        WIN=$(xdotool search --onlyvisible --classname "calm_garden.exe" 2>/dev/null | head -1)
    else
        WIN=$(xdotool search --onlyvisible --pid $APID 2>/dev/null | head -1)
    fi
    [ -z "$WIN" ] && sleep 0.2
    i=$((i+1))
done
[ -n "$WIN" ] && ok "window found ($WIN)" || bad "window not found"
xdotool mousemove --window "$WIN" 20 400; xdotool windowfocus "$WIN" 2>/dev/null; sleep 1
[ "$(field w)" = "1024" ] && [ "$(field h)" = "768" ] && ok "initial size 1024x768" || bad "initial size"

echo "== keyboard navigation"
key Tab Return
waitfor scr 1 5 && ok "Tab + Enter opened Breathing (keyboard only)" || bad "keyboard open breathing"
key Tab Return
waitfor scr 2 5 && ok "opened the first breathing exercise" || bad "open exercise"
key Escape
waitfor scr 1 5 && ok "Esc goes back" || bad "Esc back"
key Escape
waitfor scr 0 5 && ok "Esc back to the menu" || bad "Esc to menu"

echo "== mouse"
# Settings tile = 8th tile (row 3, middle column) at 1024x768
xdotool mousemove --window "$WIN" 512 610 click 1; sleep 0.5
waitfor scr 12 5 && ok "mouse click opened Settings" || bad "click settings"

echo "== language switching"
# focus order in Settings: (first Tab skips the header) 4 tabs, reset, language
key Tab Tab Tab Tab Tab Tab Right
waitfor lang he 5 && ok "language switched to Hebrew" || bad "switch to Hebrew"
[ "$(field rtl)" = "1" ] && ok "layout is right-to-left" || bad "RTL flag"
import -display :$DISP -window "$WIN" "$TMP/settings_he.png" 2>/dev/null && ok "screenshot of Hebrew settings" || bad "screenshot"
key Left
waitfor lang en 5 && ok "language switched back to English" || bad "switch back"
key Escape
waitfor scr 0 5 && ok "back to the menu" || bad "menu after settings"

echo "== resizing"
xdotool windowsize "$WIN" 1400 900; sleep 1.5
waitfor w 1400 5 && [ "$(field h)" = "900" ] && ok "window resized to 1400x900, canvas follows" || bad "resize"
xdotool windowsize "$WIN" 1024 768; sleep 1.5
waitfor w 1024 5 && ok "resized back" || bad "resize back"

echo "== fullscreen"
key F11
sleep 1.5
waitfor full 1 5 && ok "F11 entered fullscreen ($(field w)x$(field h))" || bad "fullscreen on"
key F11
sleep 1.5
waitfor full 0 5 && ok "F11 left fullscreen" || bad "fullscreen off"

echo "== sound toggle"
key ctrl+m
waitfor sound 0 5 && ok "Ctrl+M muted" || bad "mute"
key ctrl+m
waitfor sound 1 5 && ok "Ctrl+M unmuted" || bad "unmute"

echo "== timing"
f1=$(field frame); sleep 3; f2=$(field frame)
fps=$(( (f2 - f1) / 3 ))
[ "$fps" -ge 40 ] && ok "animation runs at about $fps frames/s (target 60)" || bad "frame rate $fps"

echo "== quit"
key ctrl+q
i=0; while kill -0 $APID 2>/dev/null && [ $i -lt 50 ]; do sleep 0.2; i=$((i+1)); done
kill -0 $APID 2>/dev/null && { bad "Ctrl+Q did not quit"; kill $APID; } || ok "Ctrl+Q quit"
grep -q "^win_w = 1024" "$TMP/data/settings.txt" 2>/dev/null && ok "settings saved on exit" || bad "settings file"

kill $XPID 2>/dev/null
echo "gui_test: $pass passed, $fail failed"
rm -rf "$TMP"
[ $fail -eq 0 ]
