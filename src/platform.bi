' platform.bi - window, input, clipboard and timing (SDL2). The rest of the
' program only sees these declarations, never SDL itself.
#pragma once
#include once "graphics.bi"

Const KEY_NONE = 0
Const KEY_ESC = 1
Const KEY_ENTER = 2
Const KEY_TAB = 3
Const KEY_BACKSPACE = 4
Const KEY_DELETE = 5
Const KEY_LEFT = 6
Const KEY_RIGHT = 7
Const KEY_UP = 8
Const KEY_DOWN = 9
Const KEY_HOME = 10
Const KEY_END = 11
Const KEY_PGUP = 12
Const KEY_PGDN = 13
Const KEY_SPACE = 14
Const KEY_F1 = 21        ' F1..F12 = 21..32
Const KEY_F11 = 31
' printable keys use their lowercase ASCII code (e.g. Asc("f")), always >= 33

Const KM_SHIFT = 1
Const KM_CTRL = 2
Const KM_ALT = 4

Const CURSOR_ARROW = 0
Const CURSOR_HAND = 1
Const CURSOR_IBEAM = 2

Type InputState
    mx As Long
    my As Long
    mDown As Long
    mPressed As Long
    mReleased As Long
    mDouble As Long
    rPressed As Long
    wheel As Long
    keyN As Long
    keys(0 To 31) As Long
    keyMods(0 To 31) As Long
    mods As Long
    text As String
    quit As Long
    resized As Long
    focusLost As Long
    activity As Long
End Type

Declare Sub Plat_SetIcon(ByRef bmpPath As String)
Declare Function Plat_Init(ByRef title As String, ByVal w As Long, ByVal h As Long, ByVal fullscreen As Long) As Boolean
Declare Sub Plat_Shutdown()
Declare Function Plat_Active() As Boolean
Declare Sub Plat_Present(ByRef cv As Canvas)
Declare Sub Plat_Poll(ByRef ist As InputState, ByVal waitMs As Long)
Declare Sub Plat_GetSize(ByRef w As Long, ByRef h As Long)
Declare Sub Plat_SetFullscreen(ByVal onOff As Long)
Declare Function Plat_IsFullscreen() As Long
Declare Sub Plat_SetWindowSize(ByVal w As Long, ByVal h As Long)
Declare Function Plat_GetClipboard() As String
Declare Sub Plat_SetClipboard(ByRef s As String)
Declare Sub Plat_TextInput(ByVal onOff As Long)
Declare Sub Plat_SetCursor(ByVal kind As Long)
Declare Function Plat_Time() As Double
Declare Sub Plat_SetTitle(ByRef title As String)
Declare Function Plat_DesktopSize(ByRef w As Long, ByRef h As Long) As Boolean
Declare Sub Plat_ErrorBox(ByRef title As String, ByRef msg As String)
