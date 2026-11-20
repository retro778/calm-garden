' breathing.bas - Breathing Flower, Breathing Balloon, Ocean Breathing, Star Breathing
#include once "screens.bi"
#include once "session.bi"
#include once "scene.bi"
#include once "localization.bi"
#include once "audio.bi"

Const EX_FLOWER = 0
Const EX_BALLOON = 1
Const EX_OCEAN = 2
Const EX_STAR = 3

Dim Shared As SessFlow bSess
Dim Shared As BreathPattern bPat
Dim Shared As Double bT              ' breathing clock (stops while paused)
Dim Shared As Long bLastPhase = -1
Dim Shared As Single bAmount         ' smoothed animation amount
Dim Shared As Long bCycles
Dim Shared As Single bCX          ' x of the main object (moves aside while the intro panel is shown)

Private Function ExKey(ByVal ex As Long) As String
    Select Case ex
    Case EX_BALLOON: Return "balloon"
    Case EX_OCEAN: Return "ocean"
    Case EX_STAR: Return "star"
    Case Else: Return "flower"
    End Select
End Function

Private Function ExAct(ByVal ex As Long) As Long
    Select Case ex
    Case EX_BALLOON: Return ACT_BALLOON
    Case EX_OCEAN: Return ACT_OCEAN
    Case EX_STAR: Return ACT_STAR
    Case Else: Return ACT_FLOWER
    End Select
End Function

' ---------------- scenes (amount 0 = breathed out .. 1 = breathed in) ----------------

Private Sub SkyFor(ByVal ex As Long)
    Dim As ULong t, m, b
    If gSet.highContrast Then Cv_Clear(gCv, &hFF000000): Exit Sub
    Select Case ex
    Case EX_OCEAN: Scene_ThemeSky(IIf(gSet.theme = 3, 3, 2), t, m, b)
    Case EX_STAR: Scene_ThemeSky(3, t, m, b)
    Case Else: Scene_ThemeSky(gSet.theme, t, m, b)
    End Select
    Cv_VGradient3(gCv, 0, 0, gApp.w, gApp.h, t, m, b)
End Sub

Private Sub DrawFlower(ByVal a As Single, ByVal tm As Double)
    SkyFor(EX_FLOWER)
    Dim As Single w = gApp.w, h = gApp.h, s = gApp.sc
    Dim As Single mo = App_Motion()
    If gSet.highContrast = 0 Then
        Scene_Hill(gCv, h * 0.78, 18 * s, 900 * s, 0.8, IIf(gSet.theme = 3, &hFF3E4E7A, &hFFA8E0A0))
        Scene_Hill(gCv, h * 0.86, 12 * s, 650 * s, 2.4, IIf(gSet.theme = 3, &hFF2E3B62, &hFF84CF8A))
    End If
    Dim As Single cx = bCX, cy = h * 0.47
    Dim As Single size = (95 + 85 * a) * s
    ' soft glow that grows with the breath
    Cv_SoftCircle(gCv, cx, cy, size * 2.1, Col_Alpha(IIf(gSet.highContrast, &hFFFFFF00, &hFFFFFFFF), CLng(60 + 80 * a)))
    Scene_FlowerStem(gCv, cx, h * 0.93, cy + size * 0.3, Sin(tm * 0.5) * 6 * s * mo, IIf(gSet.highContrast, &hFF00FF00, &hFF5DAE6A))
    Dim As ULong pc = IIf(gSet.highContrast, &hFFFF66CC, IIf(gSet.adultStyle, &hFFE7A3B5, &hFFFF8FB1))
    Scene_Flower(gCv, cx, cy, size, 8, pc, &hFFFFD36E, 0.25 + 0.75 * a, tm * 0.05 * mo)
    ' a few small flowers and butterflies around
    If gSet.highContrast = 0 Then
        Dim As ULong cols(0 To 3) = {&hFFFFD36E, &hFFB9A2FF, &hFF8FD3FF, &hFFFFB38A}
        For i As Long = 0 To 7
            Dim As Single fx = w * (0.06 + i * 0.125 + IIf(i >= 4, 0.0, 0.0))
            If Abs(fx - bCX) < 180 * s Then Continue For
            Dim As Single gy = h * 0.92
            Dim As Single fh = (50 + Scene_Rand(i + 3) * 40) * s
            Dim As Single sw = Sin(tm * 0.8 + i) * 5 * s * mo
            Scene_FlowerStem(gCv, fx, gy + 8 * s, gy - fh, sw, &hFF5DAE6A)
            Scene_Flower(gCv, fx + sw, gy - fh, (16 + 6 * a) * s, 6, cols(i Mod 4), &hFFFFE9A0, 0.6 + 0.4 * a, i)
        Next
        Scene_Butterfly(gCv, w * 0.2 + Sin(tm * 0.3 * mo) * w * 0.08, h * 0.32 + Sin(tm * 0.5 * mo) * 30 * s, 18 * s, tm * IIf(mo < 1, 0.2, 1), &hFFFFA6C9)
    End If
End Sub

Private Sub DrawBalloon(ByVal a As Single, ByVal tm As Double)
    SkyFor(EX_BALLOON)
    Dim As Single w = gApp.w, h = gApp.h, s = gApp.sc, mo = App_Motion()
    If gSet.highContrast = 0 Then
        For i As Long = 0 To 5
            Dim As Single sp = 10 + Scene_Rand(i) * 14
            Dim As Single x = ((Scene_Rand(i + 9) * (w + 400) + tm * sp * s * mo) Mod (w + 400)) - 200
            Scene_Cloud(gCv, x, h * (0.12 + Scene_Rand(i + 4) * 0.6), (35 + Scene_Rand(i + 2) * 40) * s, &hD8FFFFFF)
        Next
        Scene_Hill(gCv, h * 0.9, 14 * s, 800 * s, 1.0, &hFFA8E0A0)
    End If
    Dim As Single r = (60 + 75 * a) * s
    Dim As Single cx = bCX + Sin(tm * 0.4) * 10 * s * mo
    Dim As Single cy = h * 0.5 - a * 20 * s
    Dim As ULong bc = IIf(gSet.highContrast, &hFFFF4040, IIf(gSet.adultStyle, &hFFD98C7A, &hFFFF7A8A))
    Cv_SoftCircle(gCv, cx, cy, r * 1.8, Col_Alpha(&hFFFFFFFF, CLng(50 + 60 * a)))
    Scene_Balloon(gCv, cx, cy, r, bc, a)
End Sub

Private Sub DrawOcean(ByVal a As Single, ByVal tm As Double)
    SkyFor(EX_OCEAN)
    Dim As Single w = gApp.w, h = gApp.h, s = gApp.sc, mo = App_Motion()
    If gSet.highContrast = 0 Then
        Dim As ULong sun = IIf(gSet.theme = 3, &hFFFFF4D0, &hFFFFE38A)
        Cv_SoftCircle(gCv, w * 0.75, h * 0.22, 110 * s, Col_Alpha(sun, 100))
        Cv_FillCircle(gCv, w * 0.75, h * 0.22, 40 * s, sun)
        For i As Long = 0 To 2
            Dim As Single bx = ((Scene_Rand(i + 40) * w + tm * 14 * s * mo) Mod (w + 100)) - 50
            Scene_Bird(gCv, bx, h * (0.15 + i * 0.06), 9 * s, tm * mo + i, &hFF6A7A8A)
        Next
    End If
    ' the water line rises while breathing in and falls while breathing out
    Dim As Single level = h * (0.72 - 0.22 * a)
    Dim As Single ph = tm * 0.6 * mo
    Dim As ULong w1 = IIf(gSet.highContrast, &hFF0050FF, &hC07CC6E8)
    Dim As ULong w2 = IIf(gSet.highContrast, &hFF0030C0, &hD058AED8)
    Dim As ULong w3 = IIf(gSet.highContrast, &hFF001880, &hE0418FC4)
    Scene_Wave(gCv, level - 26 * s, 12 * s, 520 * s, ph, w1)
    Scene_Wave(gCv, level, 14 * s, 430 * s, ph * 1.3 + 1.5, w2)
    Scene_Wave(gCv, level + 30 * s, 10 * s, 360 * s, ph * 0.8 + 3, w3)
    ' sand
    If gSet.highContrast = 0 Then Scene_Hill(gCv, h * 0.93, 8 * s, 700 * s, 0.3, &hFFF3DDB0)
    ' foam sparkles on the crest
    If gSet.highContrast = 0 Then
        For i As Long = 0 To 8
            Dim As Single fx = (i + 0.5) * w / 9
            Cv_FillCircle(gCv, fx, level - 26 * s + Sin(fx / (520 * s) * 6.283 + ph) * 12 * s - 2 * s, 3 * s, &hB0FFFFFF)
        Next
    End If
End Sub

Private Sub DrawStar(ByVal a As Single, ByVal tm As Double)
    SkyFor(EX_STAR)
    Dim As Single w = gApp.w, h = gApp.h, s = gApp.sc, mo = App_Motion()
    For i As Long = 0 To 70
        Dim As Single tw = 0.55 + 0.45 * Sin(tm * (0.4 + Scene_Rand(i + 5) * 0.6) * mo + i)
        Cv_FillCircle(gCv, Scene_Rand(i) * w, Scene_Rand(i + 200) * h, (0.8 + Scene_Rand(i + 400) * 1.6) * s, Col_Alpha(&hFFFFF8E0, CLng(90 + 140 * tw)))
    Next
    If gSet.highContrast = 0 Then Scene_Hill(gCv, h * 0.92, 12 * s, 900 * s, 1.2, &hFF262D55)
    Dim As Single cx = bCX, cy = h * 0.47
    Dim As Single r = (55 + 70 * a) * s
    Dim As ULong sc = IIf(gSet.highContrast, &hFFFFFF00, &hFFFFE58A)
    Cv_SoftCircle(gCv, cx, cy, r * (2.4 + 0.8 * a), Col_Alpha(sc, CLng(40 + 90 * a)))
    Cv_SoftCircle(gCv, cx, cy, r * 1.5, Col_Alpha(&hFFFFFFFF, CLng(30 + 60 * a)))
    Scene_Star(gCv, cx, cy, r, tm * 0.03 * mo, sc)
    Scene_Star(gCv, cx, cy, r * 0.55, tm * 0.03 * mo, Col_Mix(sc, &hFFFFFFFF, 0.55))
End Sub

Private Sub DrawScene(ByVal ex As Long, ByVal a As Single, ByVal tm As Double)
    ' while the intro panel is open the picture sits in the free part of the window
    Dim As Single target = gApp.w / 2
    If bSess.state = SS_INTRO Then
        Dim As Long pw = gApp.w * 46 \ 100
        If pw < Ui_S(430) Then pw = Ui_S(430)
        Dim As Single freeW = gApp.w - pw - Ui_S(24)
        target = IIf(gApp.rtl, gApp.w - freeW / 2, freeW / 2)
    End If
    If gApp.entering OrElse bCX = 0 Then bCX = target
    bCX = Approach(bCX, target, 4, gApp.dt)
    Select Case ex
    Case EX_BALLOON: DrawBalloon(a, tm)
    Case EX_OCEAN: DrawOcean(a, tm)
    Case EX_STAR: DrawStar(a, tm)
    Case Else: DrawFlower(a, tm)
    End Select
End Sub

' ---------------- list ----------------

Sub BreathList_Frame()
    Scr_Background()
    If Ui_Header(L("breath.title")) Then App_Go(SCR_MENU): Exit Sub
    Dim As String labels(0 To 3), descs(0 To 3)
    Dim As Long icons(0 To 3) = {ICON_FLOWER, ICON_BALLOON, ICON_WAVE, ICON_STAR}
    Dim As ULong tints(0 To 3) = {&hFFFF9EB5, &hFFFF8C8C, &hFF8FD3FF, &hFFFFE07A}
    For i As Long = 0 To 3
        labels(i) = L("breath." & ExKey(i))
        descs(i) = L("breath." & ExKey(i) & ".desc")
    Next
    Dim As Long top = Ui_HeaderH() + Ui_S(40)
    Dim As Long fs = Ui_FS(FS_BODY)
    Ui_Label(Ui_S(40), Ui_HeaderH(), gApp.w - Ui_S(80), L("breath.intro"), fs, gTheme.textSoft, ALIGN_CENTER)
    Dim As Long pick = Scr_TileGrid("bl.", labels(), icons(), tints(), 4, 2, top, descs())
    If pick >= 0 Then App_Go(SCR_BREATH, pick)
End Sub

' ---------------- exercise ----------------

Private Function Instruction(ByVal ex As Long, ByVal phase As Long) As String
    Dim As String base_
    Select Case phase
    Case BP_IN: base_ = "in"
    Case BP_OUT: base_ = "out"
    Case BP_REST: base_ = "rest"
    Case Else: base_ = "natural"
    End Select
    Dim As String k = "breath." & ExKey(ex) & "." & base_
    If (gSet.childMode <> 0) AndAlso Loc_Has(k & ".child") Then Return L(k & ".child")
    If Loc_Has(k) Then Return L(k)
    Return L("breath." & base_)
End Function

Private Sub IntroPanel(ByVal ex As Long)
    Dim As Long pw = gApp.w * 46 \ 100
    If pw < Ui_S(430) Then pw = Ui_S(430)
    Dim As Long hh = Ui_HeaderH()
    Dim As Long px = Ui_MX(gApp.w - pw - Ui_S(24), pw)
    Dim As Long py = hh + Ui_S(6)
    Dim As Long ph = gApp.h - py - Ui_S(20)
    Ui_Panel(px, py, pw, ph, 235)
    Dim As Long pad = Ui_S(24), cw = pw - 2 * pad, x = px + pad
    Dim As Long y = py + pad
    Dim As Long fs = Ui_FS(FS_BODY)
    y += Ui_Para(x, y, cw, L("breath." & ExKey(ex) & ".desc"), fs, gTheme.text) + Ui_S(10)
    Dim As Long sh = Ui_S(70), gap = Ui_S(6)
    Dim As Long v = gSet.inhaleSec
    If Ui_Slider("b.in", x, y, cw, sh, L("settings.inhale"), v, 2, 8, 1, " " & L("unit.s")) Then gSet.inhaleSec = v: App_SaveSettings()
    y += sh + gap
    v = gSet.exhaleSec
    If Ui_Slider("b.out", x, y, cw, sh, L("settings.exhale"), v, 2, 10, 1, " " & L("unit.s")) Then gSet.exhaleSec = v: App_SaveSettings()
    y += sh + gap
    If Ui_Toggle("b.pause", x, y, cw, Ui_S(46), L("settings.pause"), gSet.pauseOn) Then App_SaveSettings()
    y += Ui_S(46) + gap
    v = gSet.sessionMin
    If Ui_Slider("b.len", x, y, cw, sh, L("settings.session"), v, 1, 20, 1, " " & L("unit.min")) Then gSet.sessionMin = v: App_SaveSettings()
    y += sh + gap
    Dim As Long th = gSet.theme
    If ex = EX_FLOWER OrElse ex = EX_BALLOON Then
        If Ui_Choice("b.theme", x, y, cw, Ui_S(46), L("settings.theme"), L("theme.garden") & "|" & L("theme.sunset") & "|" & L("theme.ocean") & "|" & L("theme.night"), th) Then gSet.theme = th: App_SaveSettings()
        y += Ui_S(46) + gap
    End If
    ' optional rating + start, pinned to the bottom of the panel
    Dim As Long bh = Ui_S(58)
    Dim As Long by = py + ph - pad - bh
    Dim As Long rh = Sess_BeforeRatingH()
    If y + rh <= by Then Sess_BeforeRating(bSess, x, by - rh, cw)
    Dim As Long favW = cw * 40 \ 100
    Sess_FavButton(bSess, IIf(gApp.rtl, x + cw - favW, x), by + (bh - Ui_S(46)) \ 2, favW)
    Dim As Long sw = cw - favW - Ui_S(12)
    If Ui_Button("b.start", IIf(gApp.rtl, x, x + favW + Ui_S(12)), by, sw, bh, L("btn.start"), BTN_PRIMARY, ICON_PLAY) Then
        Breath_MakePattern(bPat, gSet.inhaleSec, gSet.exhaleSec, gSet.pauseOn, gSet.pauseSec)
        bT = 0: bLastPhase = -1: bCycles = 0
        Sess_Begin(bSess, Sess_Minutes(gSet.sessionMin) * 60)
    End If
    If gApp.entering Then Ui_SetFocus("b.start")
End Sub

Sub Breath_Frame()
    Dim As Long ex = gApp.arg
    If ex < 0 OrElse ex > 3 Then ex = 0
    If gApp.entering Then
        Sess_Reset(bSess, ExAct(ex))
        bAmount = 0.3
    End If
    Dim As BreathState st
    Select Case bSess.state
    Case SS_INTRO
        ' a calm, unguided preview behind the settings panel
        Breath_Natural(gApp.anim, st)
        bAmount = Approach(bAmount, st.amount, 2, gApp.dt)
        DrawScene(ex, bAmount, gApp.anim)
        If Ui_Header(L("breath." & ExKey(ex))) Then App_Go(SCR_BREATH_LIST): Exit Sub
        IntroPanel(ex)
    Case SS_RUN
        Sess_Tick(bSess)
        If bSess.clk.paused = 0 Then bT += gApp.dt
        If bSess.natural Then
            Breath_Natural(gApp.anim, st)
        Else
            Breath_Eval(bPat, bT, st)
            If st.phase <> bLastPhase Then
                If st.phase = BP_IN Then Audio_Play(SND_IN): If bLastPhase >= 0 Then bCycles += 1
                If st.phase = BP_OUT Then Audio_Play(SND_OUT)
                bLastPhase = st.phase
            End If
        End If
        ' smooth any jump (pause, switching to/from natural breathing)
        bAmount = Approach(bAmount, st.amount, IIf(bSess.natural, 1.5, 12), gApp.dt)
        DrawScene(ex, bAmount, gApp.anim)
        If Ui_Header(L("breath." & ExKey(ex))) Then Sess_Leave(bSess): App_Go(SCR_BREATH_LIST): Exit Sub
        ' big, friendly instruction
        Dim As String ins = IIf(bSess.clk.paused, L("sess.paused.hint"), Instruction(ex, st.phase))
        Dim As Long fs = Ui_FS(FS_HUGE - 6)
        Dim As Long lh = Txt_LineHeight(FACE_BOLD, fs)
        Dim As Long iy = Ui_HeaderH() + Ui_S(46)
        Dim As Long tw = Txt_Width(ins, FACE_BOLD, fs, App_DirText()) + Ui_S(48)
        If tw > gApp.w - Ui_S(40) Then tw = gApp.w - Ui_S(40)
        Cv_FillRoundRect(gCv, (gApp.w - tw) \ 2, iy - Ui_S(6), tw, lh + Ui_S(12), (lh + Ui_S(12)) / 2, Col_Alpha(gTheme.panel, 190))
        Ui_Label(Ui_S(20), iy, gApp.w - Ui_S(40), ins, fs, gTheme.title, ALIGN_CENTER, FACE_BOLD)
        ' phase progress dots under the instruction
        If bSess.natural = 0 AndAlso bSess.clk.paused = 0 Then
            Dim As Long dw = Ui_S(160)
            Dim As Long dx = (gApp.w - dw) \ 2, dy = iy + lh + Ui_S(16)
            Cv_FillRoundRect(gCv, dx, dy, dw, Ui_S(6), Ui_S(3), Col_Alpha(&hFFFFFFFF, 140))
            Dim As Long pf = CLng(dw * st.phaseFrac)
            If gApp.rtl Then
                Cv_FillRoundRect(gCv, dx + dw - pf, dy, pf, Ui_S(6), Ui_S(3), Col_Alpha(gTheme.primary, 230))
            Else
                Cv_FillRoundRect(gCv, dx, dy, pf, Ui_S(6), Ui_S(3), Col_Alpha(gTheme.primary, 230))
            End If
        End If
        Sess_Progress(bSess, gApp.h - Sess_ControlsH() - Ui_S(56))
        If Sess_Controls(bSess, 1) Then Sess_Finish(bSess, IIf(bSess.clk.elapsed >= bSess.clk.total * 0.5, 1, 0))
        If Clock_Done(bSess.clk) Then Sess_Finish(bSess, 1)
    Case SS_DONE
        Breath_Natural(gApp.anim, st)
        bAmount = Approach(bAmount, st.amount, 1.5, gApp.dt)
        DrawScene(ex, bAmount, gApp.anim)
        If Ui_Header(L("breath." & ExKey(ex))) Then Sess_Leave(bSess): App_Go(SCR_BREATH_LIST): Exit Sub
        Dim As String extra = IIf(bCycles > 1, Loc_F("breath.done.cycles", Str(bCycles)), "")
        Select Case Sess_DonePanel(bSess, extra)
        Case 1: bSess.state = SS_INTRO
        Case 2: Sess_Leave(bSess): App_Go(SCR_BREATH_LIST)
        End Select
    End Select
End Sub
