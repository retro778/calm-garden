' main.bas - Calm Garden: start-up, main loop and screen dispatch
'
' Command line:
'   --data DIR          keep settings/progress in DIR (default: per-user data folder)
'   --lang en|he        start in this language (also saved)
'   --size WxH          initial window size
'   --fullscreen        start in fullscreen
'   --shots DIR         render every screen in both languages to DIR/*.bmp and exit (testing)
'   --frames N          quit after N frames (testing)
#include once "screens.bi"
#include once "localization.bi"
#include once "scene.bi"
#include once "audio.bi"
#include once "progress.bi"
#include once "file.bi"

Const APP_VERSION = "1.0.0"

Private Function DefaultDataDir() As String
    If FileExists(ExePath() & "/portable.txt") Then Return ExePath() & "/userdata"
#ifdef __FB_WIN32__
    Dim As String base_ = Environ("APPDATA")
    If Len(base_) = 0 Then base_ = ExePath()
    Return base_ & "\CalmGarden"
#else
    Dim As String base_ = Environ("XDG_DATA_HOME")
    If Len(base_) = 0 Then base_ = Environ("HOME") & "/.local/share"
    MkDir(base_)
    Return base_ & "/calm_garden"
#endif
End Function

Private Function FindResDir() As String
    Dim As String c(0 To 2) = {ExePath() & "/assets", ExePath() & "/../assets", CurDir() & "/assets"}
    For i As Long = 0 To 2
        If FileExists(c(i) & "/lang/en.txt") Then Return c(i)
    Next
    Return ExePath() & "/assets"
End Function

Private Sub UpdateSize()
    Dim As Long w = gCv.w, h = gCv.h
    If gApp.headless = 0 Then Plat_GetSize(w, h)
    If w < 320 Then w = 320
    If h < 240 Then h = 240
    If w <> gCv.w OrElse h <> gCv.h OrElse gCv.px = 0 Then
        Cv_Free(gCv)
        Cv_Create(gCv, w, h)
    End If
    gApp.w = w: gApp.h = h
    Dim As Single s = w / 1024.0
    If h / 768.0 < s Then s = h / 768.0
    If s < 0.62 Then s = 0.62
    gApp.sc = s
End Sub

Private Sub DispatchFrame()
    Select Case gApp.scr
    Case SCR_MENU: Menu_Frame()
    Case SCR_ABOUT: About_Frame()
    Case SCR_SETTINGS: SettingsScr_Frame()
    Case SCR_BREATH_LIST: BreathList_Frame()
    Case SCR_BREATH: Breath_Frame()
    Case SCR_RELAX_LIST: RelaxList_Frame()
    Case SCR_RELAX: Relax_Frame()
    Case SCR_MIND_LIST: MindList_Frame()
    Case SCR_MIND: Mind_Frame()
    Case SCR_BIO: Bio_Frame()
    Case SCR_GAME_LIST: GameList_Frame()
    Case SCR_GAME: Game_Frame()
    Case SCR_TIMER: Timer_Frame()
    Case SCR_PROGRESS: ProgressScr_Frame()
    Case Else: App_Go(SCR_MENU)
    End Select
End Sub

Private Sub GlobalKeys()
    If Ui_Key(KEY_F11) Then
        gSet.fullscreen = IIf(Plat_IsFullscreen(), 0, 1)
        Plat_SetFullscreen(gSet.fullscreen)
        App_SaveSettings()
    End If
    If Ui_Key(Asc("m"), KM_CTRL) Then
        gSet.soundOn = IIf(gSet.soundOn, 0, 1)
        Audio_ApplySettings()
        App_SaveSettings()
        Ui_Toast(L(IIf(gSet.soundOn, "toast.sound_on", "toast.sound_off")))
    End If
    If Ui_Key(Asc("q"), KM_CTRL) Then gApp.quit = 1
End Sub

' one frame: input already polled
Private Sub RunFrame()
    UpdateSize()
    Plat_SetCursor(CURSOR_ARROW)
    Ui_BeginFrame()
    GlobalKeys()
    Dim As Long serial = gApp.goSerial
    DispatchFrame()
    ' "entering" lasts exactly one frame unless App_Go was called again during this one
    If gApp.goSerial = serial Then gApp.entering = 0
    Ui_EndFrame()
    gApp.frame += 1
End Sub

' ---- screenshot test mode ----
Private Sub Shot(ByRef dir_ As String, ByRef name_ As String, ByVal scr As Long, ByVal arg As Long, ByVal frames As Long, ByRef press As String = "", ByVal keepScreen As Long = 0)
    If keepScreen = 0 Then App_Go(scr, arg)
    For i As Long = 1 To frames
        If i = 3 AndAlso Len(press) Then Ui_TestActivate(press)
        gIn.keyN = 0: gIn.mPressed = 0: gIn.text = ""
        gApp.now += 1 / 60.0
        gApp.dt = 1 / 60.0
        gApp.anim += gApp.dt
        RunFrame()
    Next
    Cv_SaveBMP(gCv, dir_ & "/" & name_ & ".bmp")
    If gApp.headless = 0 Then Plat_Present(gCv)
End Sub

Private Sub RunShots(ByRef dir_ As String)
    MkDir(dir_)
    gIn.mx = -100: gIn.my = -100
    Dim As String langs(0 To 1) = {"en", "he"}
    For li As Long = 0 To 1
        gSet.lang = langs(li)
        App_ApplyLanguage()
        Dim As String p = langs(li) & "_"
        Shot(dir_, p & "menu", SCR_MENU, 0, 30)
        Shot(dir_, p & "settings", SCR_SETTINGS, 0, 20)
        Shot(dir_, p & "about", SCR_ABOUT, 0, 10)
        Shot(dir_, p & "breath_list", SCR_BREATH_LIST, 0, 10)
        For k As Long = 0 To 3
            Shot(dir_, p & "breath_" & k, SCR_BREATH, k, 30)
            Shot(dir_, p & "breath_" & k & "_run", SCR_BREATH, k, 150, "b.start", 1)
        Next
        Shot(dir_, p & "relax_list", SCR_RELAX_LIST, 0, 10)
        For k As Long = 0 To 5
            Shot(dir_, p & "relax_" & k, SCR_RELAX, k, 20)
            Shot(dir_, p & "relax_" & k & "_run", SCR_RELAX, k, 60, "st.start", 1)
        Next
        Shot(dir_, p & "mind_list", SCR_MIND_LIST, 0, 10)
        For k As Long = 0 To 4
            Shot(dir_, p & "mind_" & k, SCR_MIND, k, 30)
            Shot(dir_, p & "mind_" & k & "_run", SCR_MIND, k, 120, IIf(k = 4, "st.start", "mf.start"), 1)
        Next
        Shot(dir_, p & "bio", SCR_BIO, 0, 20)
        Shot(dir_, p & "bio_run", SCR_BIO, 0, 400, "bio.start", 1)
        Shot(dir_, p & "game_list", SCR_GAME_LIST, 0, 10)
        For k As Long = 0 To 4
            Shot(dir_, p & "game_" & k, SCR_GAME, k, 20)
            If k > 0 Then Shot(dir_, p & "game_" & k & "_run", SCR_GAME, k, 400, "gm.start", 1)
        Next
        Shot(dir_, p & "timer", SCR_TIMER, 0, 20)
        Shot(dir_, p & "timer_run", SCR_TIMER, 0, 60, "tm.start", 1)
        Shot(dir_, p & "progress", SCR_PROGRESS, 0, 20)
    Next
End Sub

' ---------------- start ----------------
Dim As String argData, argLang, argShots
Dim As Long argW, argH, argFull = -1, argFrames = 0
Dim As Long ai = 1
While Len(Command(ai))
    Dim As String a = Command(ai)
    Select Case a
    Case "--data": ai += 1: argData = Command(ai)
    Case "--lang": ai += 1: argLang = Command(ai)
    Case "--shots": ai += 1: argShots = Command(ai)
    Case "--frames": ai += 1: argFrames = ValInt(Command(ai))
    Case "--fullscreen": argFull = 1
    Case "--size"
        ai += 1
        Dim As String sz = Command(ai)
        Dim As Long px = InStr(sz, "x")
        If px Then argW = ValInt(Left(sz, px - 1)): argH = ValInt(Mid(sz, px + 1))
    Case "--icon"
        ' render the program icon (256x256 BMP) with the same drawing code, then exit
        ai += 1
        Dim As Canvas ic
        Cv_Create(ic, 256, 256)
        Cv_Clear(ic, &hFFFFFFFF)
        Cv_FillCircle(ic, 128, 128, 124, &hFFDFF2FF)
        Cv_SoftCircle(ic, 128, 128, 120, &h80FFFFFF)
        Scene_SetIconCanvas(@ic)
        Scene_Flower(ic, 128, 120, 92, 7, &hFFFF9EB5, &hFFFFD86B, 1, 0.2)
        Scene_Leaf(ic, 70, 205, 34, -0.5, &hFF5DAE6A)
        Scene_Leaf(ic, 186, 205, 34, 0.5, &hFF5DAE6A)
        Cv_SaveBMP(ic, Command(ai) & ".bmp")
        ' Windows .ico with 16/32/48/64 px 32-bit images (box-filtered from 256 px)
        Dim As Long sizes(0 To 3) = {16, 32, 48, 64}
        Dim As String imgs(0 To 3)
        For k As Long = 0 To 3
            Dim As Long n = sizes(k), f = 256 \ n
            Dim As String d = MKL(40) & MKL(n) & MKL(n * 2) & MKShort(1) & MKShort(32) & MKL(0) & MKL(n * n * 4) & MKL(0) & MKL(0) & MKL(0) & MKL(0)
            For yy As Long = n - 1 To 0 Step -1
                For xx As Long = 0 To n - 1
                    Dim As Long r = 0, g = 0, b = 0, cnt = 0, inside = 0
                    For sy As Long = 0 To f - 1
                        For sx As Long = 0 To f - 1
                            Dim As Long px = xx * f + sx, py = yy * f + sy
                            Dim As ULong c = ic.px[py * 256 + px]
                            r += (c Shr 16) And 255: g += (c Shr 8) And 255: b += c And 255: cnt += 1
                            Dim As Single ddx = px - 127.5, ddy = py - 127.5
                            If ddx * ddx + ddy * ddy <= 124 * 124 Then inside += 1
                        Next
                    Next
                    d &= Chr(b \ cnt, g \ cnt, r \ cnt, inside * 255 \ cnt)
                Next
            Next
            Dim As Long maskRow = ((n + 31) \ 32) * 4
            d &= String(maskRow * n, Chr(0))
            imgs(k) = d
        Next
        Dim As String ico = MKShort(0) & MKShort(1) & MKShort(4)
        Dim As Long ofs = 6 + 16 * 4
        For k As Long = 0 To 3
            ico &= Chr(sizes(k), sizes(k), 0, 0) & MKShort(1) & MKShort(32) & MKL(Len(imgs(k))) & MKL(ofs)
            ofs += Len(imgs(k))
        Next
        For k As Long = 0 To 3: ico &= imgs(k): Next
        Dim As Long fo = FreeFile
        Open Command(ai) & ".ico" For Binary As #fo
        Put #fo, , ico
        Close #fo
        End 0
    Case "--audio-check"
        argShots = "#audio"
    Case "--version"
        Print "Calm Garden " & APP_VERSION
        End 0
    End Select
    ai += 1
Wend

gApp.dataDir = IIf(Len(argData), argData, DefaultDataDir())
MkDir(gApp.dataDir)
gApp.resDir = FindResDir()
Dim As Long setFix = Settings_Load(gSet, gApp.dataDir & "/settings.txt")
If argLang = "en" OrElse argLang = "he" Then gSet.lang = argLang
If argFull >= 0 Then gSet.fullscreen = argFull
If argW >= 640 AndAlso argH >= 480 Then gSet.winW = argW: gSet.winH = argH
If Len(argShots) Then gSet.fullscreen = 0
App_ApplyLanguage()
Ui_ApplyTheme()
Progress_Init(gApp.dataDir)

If Not Plat_Init(L("app.title"), gSet.winW, gSet.winH, gSet.fullscreen) Then
    Print "Calm Garden: could not open a window (SDL2). Is a display available?"
    End 1
End If
Plat_SetIcon(gApp.resDir & "/icon.bmp")
If Not Txt_Init(gApp.resDir & "/fonts") Then
    Plat_ErrorBox("Calm Garden", "Fonts could not be loaded: " & Txt_LastError() & !"\nPlease reinstall the program (the assets folder is missing or damaged).")
    Plat_Shutdown()
    End 1
End If
Scene_SetIconCanvas(@gCv)
gApp.audioOk = IIf(Audio_Init(gApp.resDir), 1, 0)
gApp.now = Timer
gApp.anim = 0
App_Go(SCR_MENU)
If setFix > 0 Then Ui_Toast(L("toast.settings_fixed"))

If argShots = "#audio" Then
    ' verifies that BASS loads and plays (silently: volume 0) - used by the tests
    Print "audio: " & Audio_Status() & " (" & L(Audio_Status()) & ")"
    If Audio_Available() Then
        gSet.sfxVol = 0: gSet.ambientVol = 0
        Audio_Play(SND_CHIME)
        For a As Long = 0 To AMB_COUNT - 1
            Audio_SetAmbient(a)
            Print "ambient " & a & ": " & IIf(Audio_CurrentAmbient() = a, "ok", "FAILED")
        Next
        Audio_SetAmbient(-1)
    End If
    Audio_Shutdown(): Txt_Shutdown(): Plat_Shutdown()
    Dim As Long rc = 0
    End rc
ElseIf Len(argShots) Then
    RunShots(argShots)
    Audio_Shutdown()
    Txt_Shutdown()
    Plat_Shutdown()
    End 0
End If

Dim As Double lastT = Timer
Dim As String traceFile = Environ("CALM_TRACE")
Dim As Double fpsAvg = 60
While gApp.quit = 0
    Plat_Poll(gIn, 0)
    If gIn.quit Then Exit While
    Dim As Double t = Timer
    Dim As Double dt = t - lastT
    If dt < 0 Then dt = 0
    If dt > 0.1 Then dt = 0.1          ' after a stall, never jump animations
    lastT = t
    If dt > 0 Then fpsAvg = fpsAvg * 0.95 + (1 / dt) * 0.05
    gApp.now = t
    gApp.dt = dt
    gApp.anim += dt * gSet.animPct / 100.0
    RunFrame()
    Plat_Present(gCv)
    ' optional state trace for automated GUI tests (CALM_TRACE=file)
    If Len(traceFile) AndAlso (gApp.frame Mod 15) = 0 Then
        Dim As Long tf = FreeFile
        If Open(traceFile For Output As #tf) = 0 Then
            Print #tf, "scr=" & gApp.scr & " arg=" & gApp.arg & " w=" & gApp.w & " h=" & gApp.h & " full=" & Plat_IsFullscreen() & " lang=" & Loc_Code() & " rtl=" & gApp.rtl & " sound=" & gSet.soundOn & " frame=" & gApp.frame & " fps=" & CLng(fpsAvg)
            Close #tf
        End If
    End If
    ' frame limiter in case vsync is unavailable (~60 FPS)
    Dim As Double spent = Timer - t
    If spent < 1 / 62.0 Then Sleep CLng((1 / 62.0 - spent) * 1000), 1
    If argFrames > 0 AndAlso gApp.frame >= argFrames Then Exit While
Wend

If gSet.fullscreen = 0 Then
    Dim As Long w, h
    Plat_GetSize(w, h)
    If w >= 640 AndAlso h >= 480 Then gSet.winW = w: gSet.winH = h
End If
App_SaveSettings()
Audio_Shutdown()
Txt_Shutdown()
Plat_Shutdown()
End 0
