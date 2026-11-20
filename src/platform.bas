' platform.bas - SDL2 implementation of the platform layer
#include once "SDL2/SDL.bi"
#include once "platform.bi"

Dim Shared As SDL_Window Ptr gWin
Dim Shared As SDL_Renderer Ptr gRen
Dim Shared As SDL_Texture Ptr gTex
Dim Shared As Long gTexW, gTexH
Dim Shared As SDL_Cursor Ptr gCursors(0 To 2)
Dim Shared As Long gCurCursor = -1
Dim Shared As Long gFull

' window icon from a BMP file (SDL reads BMP without extra libraries); missing file: no icon
Sub Plat_SetIcon(ByRef bmpPath As String)
    If gWin = 0 Then Exit Sub
    Dim As SDL_Surface Ptr icn = SDL_LoadBMP(StrPtr(bmpPath))
    If icn = 0 Then Exit Sub
    SDL_SetWindowIcon(gWin, icn)
    SDL_FreeSurface(icn)
End Sub

Function Plat_Init(ByRef title As String, ByVal w As Long, ByVal h As Long, ByVal fullscreen As Long) As Boolean
    SDL_SetHint(SDL_HINT_VIDEO_X11_NET_WM_BYPASS_COMPOSITOR, "0")
    If SDL_Init(SDL_INIT_VIDEO Or SDL_INIT_EVENTS) <> 0 Then Return False
    Dim As ULong flags = SDL_WINDOW_RESIZABLE Or SDL_WINDOW_SHOWN
    If fullscreen Then flags Or= SDL_WINDOW_FULLSCREEN_DESKTOP
    gWin = SDL_CreateWindow(title, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, w, h, flags)
    If gWin = 0 Then Return False
    gFull = IIf(fullscreen, 1, 0)
    SDL_SetWindowMinimumSize(gWin, 800, 560)
    gRen = SDL_CreateRenderer(gWin, -1, SDL_RENDERER_ACCELERATED Or SDL_RENDERER_PRESENTVSYNC)
    If gRen = 0 Then gRen = SDL_CreateRenderer(gWin, -1, SDL_RENDERER_SOFTWARE)
    If gRen = 0 Then Return False
    gCursors(0) = SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_ARROW)
    gCursors(1) = SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_HAND)
    gCursors(2) = SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_IBEAM)
    SDL_StopTextInput()
    Return True
End Function

Sub Plat_Shutdown()
    If gTex Then SDL_DestroyTexture(gTex): gTex = 0
    If gRen Then SDL_DestroyRenderer(gRen): gRen = 0
    If gWin Then SDL_DestroyWindow(gWin): gWin = 0
    SDL_Quit()
End Sub

Function Plat_Active() As Boolean
    Return gWin <> 0
End Function

Sub Plat_GetSize(ByRef w As Long, ByRef h As Long)
    If gWin = 0 Then Exit Sub
    Dim As Long ww, hh
    SDL_GetWindowSize(gWin, @ww, @hh)
    w = ww: h = hh
End Sub

Sub Plat_Present(ByRef cv As Canvas)
    If gRen = 0 Then Exit Sub
    If gTex = 0 OrElse gTexW <> cv.w OrElse gTexH <> cv.h Then
        If gTex Then SDL_DestroyTexture(gTex)
        gTex = SDL_CreateTexture(gRen, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, cv.w, cv.h)
        gTexW = cv.w: gTexH = cv.h
    End If
    SDL_UpdateTexture(gTex, 0, cv.px, cv.w * 4)
    SDL_RenderClear(gRen)
    SDL_RenderCopy(gRen, gTex, 0, 0)
    SDL_RenderPresent(gRen)
End Sub

Private Function MapKey(ByVal k As Long) As Long
    Select Case k
    Case SDLK_ESCAPE: Return KEY_ESC
    Case SDLK_RETURN, SDLK_KP_ENTER: Return KEY_ENTER
    Case SDLK_TAB: Return KEY_TAB
    Case SDLK_BACKSPACE: Return KEY_BACKSPACE
    Case SDLK_DELETE: Return KEY_DELETE
    Case SDLK_LEFT: Return KEY_LEFT
    Case SDLK_RIGHT: Return KEY_RIGHT
    Case SDLK_UP: Return KEY_UP
    Case SDLK_DOWN: Return KEY_DOWN
    Case SDLK_HOME: Return KEY_HOME
    Case SDLK_END: Return KEY_END
    Case SDLK_PAGEUP: Return KEY_PGUP
    Case SDLK_PAGEDOWN: Return KEY_PGDN
    Case SDLK_SPACE: Return KEY_SPACE
    Case SDLK_F1 To SDLK_F12: Return KEY_F1 + (k - SDLK_F1)
    End Select
    If k >= 33 AndAlso k < 127 Then
        If k >= 65 AndAlso k <= 90 Then k += 32
        Return k
    End If
    Return KEY_NONE
End Function

Sub Plat_Poll(ByRef ist As InputState, ByVal waitMs As Long)
    ist.mPressed = 0: ist.mReleased = 0: ist.rPressed = 0: ist.mDouble = 0
    ist.wheel = 0: ist.keyN = 0: ist.text = ""
    ist.resized = 0: ist.focusLost = 0: ist.activity = 0
    If gWin = 0 Then Exit Sub
    Dim As SDL_Event ev
    Dim As Long got
    If waitMs > 0 Then
        got = SDL_WaitEventTimeout(@ev, waitMs)
    Else
        got = SDL_PollEvent(@ev)
    End If
    While got
        ist.activity = 1
        Select Case ev.type
        Case SDL_QUIT_
            ist.quit = 1
        Case SDL_WINDOWEVENT
            Select Case ev.window.event
            Case SDL_WINDOWEVENT_SIZE_CHANGED, SDL_WINDOWEVENT_RESIZED
                ist.resized = 1
            Case SDL_WINDOWEVENT_FOCUS_LOST
                ist.focusLost = 1
            End Select
        Case SDL_MOUSEMOTION
            ist.mx = ev.motion.x: ist.my = ev.motion.y
        Case SDL_MOUSEBUTTONDOWN
            ist.mx = ev.button.x: ist.my = ev.button.y
            If ev.button.button = SDL_BUTTON_LEFT Then
                ist.mDown = 1: ist.mPressed = 1
                If ev.button.clicks >= 2 Then ist.mDouble = 1
            ElseIf ev.button.button = SDL_BUTTON_RIGHT Then
                ist.rPressed = 1
            End If
        Case SDL_MOUSEBUTTONUP
            ist.mx = ev.button.x: ist.my = ev.button.y
            If ev.button.button = SDL_BUTTON_LEFT Then ist.mDown = 0: ist.mReleased = 1
        Case SDL_MOUSEWHEEL
            ist.wheel += ev.wheel.y
        Case SDL_KEYDOWN
            Dim As Long k = MapKey(ev.key.keysym.sym)
            Dim As Long m = 0
            If ev.key.keysym.mod_ And KMOD_SHIFT Then m Or= KM_SHIFT
            If ev.key.keysym.mod_ And KMOD_CTRL Then m Or= KM_CTRL
            If ev.key.keysym.mod_ And KMOD_ALT Then m Or= KM_ALT
            ist.mods = m
            If k <> KEY_NONE AndAlso ist.keyN < 32 Then
                ist.keys(ist.keyN) = k
                ist.keyMods(ist.keyN) = m
                ist.keyN += 1
            End If
        Case SDL_KEYUP
            Dim As Long m = 0
            If ev.key.keysym.mod_ And KMOD_SHIFT Then m Or= KM_SHIFT
            If ev.key.keysym.mod_ And KMOD_CTRL Then m Or= KM_CTRL
            If ev.key.keysym.mod_ And KMOD_ALT Then m Or= KM_ALT
            ist.mods = m
        Case SDL_TEXTINPUT
            ist.text &= *CPtr(ZString Ptr, @ev.text.text)
        End Select
        got = SDL_PollEvent(@ev)
    Wend
End Sub

Sub Plat_SetFullscreen(ByVal onOff As Long)
    If gWin = 0 Then Exit Sub
    SDL_SetWindowFullscreen(gWin, IIf(onOff, SDL_WINDOW_FULLSCREEN_DESKTOP, 0))
    gFull = IIf(onOff, 1, 0)
End Sub

Function Plat_IsFullscreen() As Long
    Return gFull
End Function

Sub Plat_SetWindowSize(ByVal w As Long, ByVal h As Long)
    If gWin = 0 Then Exit Sub
    If gFull Then Plat_SetFullscreen(0)
    SDL_SetWindowSize(gWin, w, h)
    SDL_SetWindowPosition(gWin, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED)
End Sub

Function Plat_DesktopSize(ByRef w As Long, ByRef h As Long) As Boolean
    Dim As SDL_DisplayMode dm
    If SDL_GetDesktopDisplayMode(0, @dm) <> 0 Then Return False
    w = dm.w: h = dm.h
    Return True
End Function

Function Plat_GetClipboard() As String
    If gWin = 0 Then Return ""
    Dim As ZString Ptr p = SDL_GetClipboardText()
    If p = 0 Then Return ""
    Dim As String s = *p
    SDL_free(p)
    Return s
End Function

Sub Plat_SetClipboard(ByRef s As String)
    If gWin = 0 Then Exit Sub
    SDL_SetClipboardText(s)
End Sub

Sub Plat_TextInput(ByVal onOff As Long)
    If gWin = 0 Then Exit Sub
    If onOff Then SDL_StartTextInput() Else SDL_StopTextInput()
End Sub

Sub Plat_SetCursor(ByVal kind As Long)
    If gWin = 0 OrElse kind = gCurCursor OrElse kind < 0 OrElse kind > 2 Then Exit Sub
    If gCursors(kind) Then SDL_SetCursor(gCursors(kind))
    gCurCursor = kind
End Sub

Function Plat_Time() As Double
    Return Timer
End Function

Sub Plat_SetTitle(ByRef title As String)
    If gWin Then SDL_SetWindowTitle(gWin, title)
End Sub

Sub Plat_ErrorBox(ByRef title As String, ByRef msg As String)
    ' always reported on stderr; the dialog is skipped for automated tests
    Dim As Long fe = FreeFile
    If Open Err(For Output As #fe) = 0 Then Print #fe, title & ": " & msg: Close #fe
    If Environ("CALM_NOERRORBOX") = "1" Then Exit Sub
    SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, title, msg, gWin)
End Sub
