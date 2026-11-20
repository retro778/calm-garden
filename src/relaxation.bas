' relaxation.bas - guided relaxation programmes and the shared step player.
'
' A programme is a list of written steps in the language files:
'   relax.<prog>.1, relax.<prog>.2, ...   (child-friendly variants: relax.<prog>.<n>.child)
' Optional narration for step n: assets/narration/<lang>/<prog>_<n>.(ogg|mp3|wav).
' When narration plays, the step waits for it before moving on. New programmes
' and languages can therefore be added without changing the code.
#include once "screens.bi"
#include once "session.bi"
#include once "scene.bi"
#include once "localization.bi"
#include once "audio.bi"
#include once "relaxation.bi"

Const RP_PMR = 0
Const RP_BODYSCAN = 1
Const RP_BREATH = 2
Const RP_PLACE = 3
Const RP_BEDTIME = 4
Const RP_BREAK = 5

Dim Shared As SessFlow sSess
Dim Shared As String sProg
Dim Shared As Long sStep, sSteps, sNarr
Dim Shared As Double sStepT
Dim Shared As Single sStepDur

Private Function ProgKey(ByVal p As Long) As String
    Select Case p
    Case RP_BODYSCAN: Return "bodyscan"
    Case RP_BREATH: Return "breath_aware"
    Case RP_PLACE: Return "place"
    Case RP_BEDTIME: Return "bedtime"
    Case RP_BREAK: Return "break5"
    Case Else: Return "pmr"
    End Select
End Function

Private Function ProgAct(ByVal p As Long) As Long
    Select Case p
    Case RP_BODYSCAN: Return ACT_BODYSCAN
    Case RP_BREATH: Return ACT_BREATH_AWARE
    Case RP_PLACE: Return ACT_PLACE
    Case RP_BEDTIME: Return ACT_BEDTIME
    Case RP_BREAK: Return ACT_BREAK5
    Case Else: Return ACT_PMR
    End Select
End Function

Function Steps_Count(ByRef prog As String) As Long
    Dim As Long n = 0
    While Loc_Has("relax." & prog & "." & (n + 1)) OrElse Loc_Has("relax." & prog & "." & (n + 1) & ".child")
        n += 1
        If n > 60 Then Exit While
    Wend
    ' the current language may be incomplete: count English too
    Return n
End Function

Private Function StepText(ByRef prog As String, ByVal i As Long) As String
    Return L("relax." & prog & "." & i)
End Function

' reading time: slow and unhurried
Function Steps_Duration(ByRef prog As String, ByVal i As Long) As Single
    If prog = "break5" Then Return 55
    Dim As String t = StepText(prog, i)
    Dim As Long words = 1
    For k As Long = 1 To Len(t)
        If Mid(t, k, 1) = " " Then words += 1
    Next
    Dim As Single d = 9 + words * 0.55
    If prog = "bedtime" Then d *= 1.35
    If prog = "moments" Then d = 8 + words * 0.5
    If d < 12 Then d = 12
    If d > 60 Then d = 60
    Return d
End Function

Function Steps_Total(ByRef prog As String) As Single
    Dim As Single t = 0
    For i As Long = 1 To Steps_Count(prog)
        t += Steps_Duration(prog, i)
    Next
    Return t
End Function

' Body regions highlighted in the progressive muscle relaxation picture
Private Function PmrRegion(ByVal stp As Long) As Long
    Select Case stp
    Case 2: Return 1      ' hands
    Case 3: Return 2      ' arms
    Case 4: Return 3      ' shoulders
    Case 5: Return 4      ' face
    Case 6: Return 5      ' tummy
    Case 7: Return 6      ' legs
    Case 8: Return 7      ' feet
    Case 9: Return 8      ' whole body
    End Select
    Return 0
End Function

' Friendly figure with an optional highlighted region; scanY (0..1) draws a soft scanning band.
Private Sub DrawFigure(ByVal cx As Single, ByVal cy As Single, ByVal s As Single, ByVal region As Long, ByVal scanY As Single, ByVal glow As Single)
    Dim As ULong body = IIf(gSet.highContrast, &hFFFFFFFF, &hFFB8D8F0)
    Dim As ULong hi = IIf(gSet.highContrast, &hFFFFFF00, &hFFFFC48A)
    Dim As ULong hiA = Col_Alpha(hi, CLng(150 + 100 * glow))
    Dim As Single hh = 330 * s      ' figure height
    Dim As Single top = cy - hh / 2
    ' scanning band behind the figure
    If scanY >= 0 Then
        Dim As Single by = top + scanY * hh
        Cv_SoftCircle(gCv, cx, by, 120 * s, Col_Alpha(hi, 120))
    End If
    ' head, body, arms, legs
    Cv_FillCircle(gCv, cx, top + 38 * s, 36 * s, IIf(region = 4 OrElse region = 8, hiA, body))
    Cv_FillRoundRect(gCv, cx - 52 * s, top + 84 * s, 104 * s, 130 * s, 40 * s, IIf(region = 5 OrElse region = 8, hiA, body))
    If region = 3 Then Cv_FillRoundRect(gCv, cx - 60 * s, top + 80 * s, 120 * s, 34 * s, 17 * s, hiA)
    Dim As ULong armC = IIf(region = 2 OrElse region = 8, hiA, body)
    Cv_Line(gCv, cx - 50 * s, top + 100 * s, cx - 92 * s, top + 190 * s, 24 * s, armC)
    Cv_Line(gCv, cx + 50 * s, top + 100 * s, cx + 92 * s, top + 190 * s, 24 * s, armC)
    Dim As ULong handC = IIf(region = 1 OrElse region = 8, hiA, body)
    Cv_FillCircle(gCv, cx - 96 * s, top + 200 * s, 17 * s, handC)
    Cv_FillCircle(gCv, cx + 96 * s, top + 200 * s, 17 * s, handC)
    Dim As ULong legC = IIf(region = 6 OrElse region = 8, hiA, body)
    Cv_Line(gCv, cx - 26 * s, top + 205 * s, cx - 34 * s, top + 305 * s, 28 * s, legC)
    Cv_Line(gCv, cx + 26 * s, top + 205 * s, cx + 34 * s, top + 305 * s, 28 * s, legC)
    Dim As ULong footC = IIf(region = 7 OrElse region = 8, hiA, body)
    Cv_FillEllipse(gCv, cx - 42 * s, top + 318 * s, 24 * s, 12 * s, 0, footC)
    Cv_FillEllipse(gCv, cx + 42 * s, top + 318 * s, 24 * s, 12 * s, 0, footC)
    ' calm face
    Dim As ULong ink = IIf(gSet.highContrast, &hFF000000, &hFF4A5A7A)
    Cv_Line(gCv, cx - 18 * s, top + 34 * s, cx - 8 * s, top + 34 * s, 2.5 * s, ink)
    Cv_Line(gCv, cx + 8 * s, top + 34 * s, cx + 18 * s, top + 34 * s, 2.5 * s, ink)
    Cv_FillEllipse(gCv, cx, top + 52 * s, 9 * s, 3 * s, 0, ink)
End Sub

Private Sub DrawRelaxScene(ByRef prog As String, ByVal stp As Long, ByVal stepFrac As Single, ByVal tm As Double)
    Dim As Single w = gApp.w, h = gApp.h, s = gApp.sc, mo = App_Motion()
    Dim As Single cx = w / 2, cy = h * 0.42
    Select Case prog
    Case "pmr", "bodyscan"
        If gSet.highContrast Then
            Cv_Clear(gCv, &hFF000000)
        Else
            Cv_VGradient3(gCv, 0, 0, w, h, &hFFE8E4FA, &hFFF3EEFA, &hFFFCEFE8)
        End If
        Dim As Single breathe = 0.5 + 0.5 * Sin(tm * 0.6 * mo)
        ' figure sits above the text panel
        Dim As Single fs_ = s * 0.72
        cy = Ui_HeaderH() + 175 * fs_ + 10 * s
        If prog = "pmr" Then
            DrawFigure(cx, cy, fs_, PmrRegion(stp), -1, breathe)
        Else
            Dim As Long n = Steps_Count(prog)
            Dim As Single pos_ = IIf(n > 2, (stp - 2 + stepFrac) / (n - 3), 0)
            If stp <= 1 OrElse stp >= n Then pos_ = -1
            If pos_ > 1 Then pos_ = 1
            DrawFigure(cx, cy, fs_, 0, pos_, breathe)
        End If
    Case "breath_aware"
        If gSet.highContrast Then Cv_Clear(gCv, &hFF000000) Else Cv_VGradient3(gCv, 0, 0, w, h, &hFFD8F0EC, &hFFE8F6F2, &hFFF6F2E6)
        Dim As Single b = 0.5 + 0.5 * Sin(tm * 0.55)
        Cv_SoftCircle(gCv, cx, cy, (150 + 40 * b) * s, Col_Alpha(IIf(gSet.highContrast, &hFF00FFFF, &hFF7CC9B0), 140))
        Cv_FillCircle(gCv, cx, cy, (60 + 18 * b) * s, IIf(gSet.highContrast, &hFF00FFFF, &hFFA8E0CC))
    Case "place"
        If gSet.highContrast Then
            Cv_Clear(gCv, &hFF000000)
        Else
            Cv_VGradient3(gCv, 0, 0, w, h, &hFFFFD9C2, &hFFFFE9D6, &hFFE3F3DA)
            Cv_SoftCircle(gCv, w * 0.5, h * 0.42, 160 * s, &h80FFF0C0)
            Cv_FillCircle(gCv, w * 0.5, h * 0.42, 48 * s, &hFFFFE7A8)
            Scene_Hill(gCv, h * 0.55, 30 * s, 700 * s, 0.4, &hFFB5D9A8)
            Scene_Wave(gCv, h * 0.66, 3 * s, 500 * s, tm * 0.3 * mo, &hFF9CCBE6)
            Scene_Hill(gCv, h * 0.8, 14 * s, 600 * s, 2.0, &hFF96CC8A)
            For i As Long = 0 To 2
                Scene_Tree(gCv, w * (0.12 + i * 0.36) + IIf(i = 1, w * 0.35, 0), h * 0.62, 150 * s, 1, &hFF7DBE7A, Sin(tm * 0.5 * mo + i) * 4 * s)
            Next
            Scene_Bird(gCv, w * 0.3 + Sin(tm * 0.1 * mo) * 80 * s, h * 0.2, 10 * s, tm * mo, &hFF8A7A70)
        End If
    Case "bedtime"
        If gSet.highContrast = 0 Then Cv_VGradient3(gCv, 0, 0, w, h, &hFF0F1230, &hFF1E2350, &hFF2E2A55) Else Cv_Clear(gCv, &hFF000000)
        ' stars dim one by one as the programme goes on
        Dim As Long n = Steps_Count(prog)
        Dim As Single progr = IIf(n > 0, (stp - 1 + stepFrac) / n, 0)
        For i As Long = 0 To 60
            Dim As Single fade = 1 - Clamp01((progr * 1.2 - Scene_Rand(i + 3)) * 3)
            If fade <= 0 Then Continue For
            Dim As Single tw = 0.6 + 0.4 * Sin(tm * 0.5 * mo + i)
            Cv_FillCircle(gCv, Scene_Rand(i) * w, Scene_Rand(i + 90) * h * 0.8, (0.8 + Scene_Rand(i + 9) * 1.4) * s, Col_Alpha(&hFFFFF4D8, CLng(170 * tw * fade)))
        Next
        Cv_SoftCircle(gCv, w * 0.8, h * 0.18, 90 * s, &h30FFF4D0)
        Icon_Draw(ICON_MOON, w * 0.8, h * 0.18, 90 * s, &hFFFFF4D0, 0)
    Case "break5"
        Scr_Background()
    Case Else ' moments
        If gSet.highContrast Then Cv_Clear(gCv, &hFF000000) Else Cv_VGradient3(gCv, 0, 0, w, h, &hFFE2F1FF, &hFFF1F7FF, &hFFFFF6EC)
        For k As Long = 0 To 3
            Dim As Single ph = ((tm * 0.08 * mo + k / 4) Mod 1)
            Cv_Ring(gCv, cx, cy, ph * 260 * s + 10, 2 * s, Col_Alpha(IIf(gSet.highContrast, &hFFFFFFFF, &hFF9BB8E8), CLng(180 * (1 - ph))))
        Next
        Scene_Leaf(gCv, cx, cy + Sin(tm * 0.4 * mo) * 6 * s, 26 * s, -0.6 + Sin(tm * 0.3 * mo) * 0.2, IIf(gSet.highContrast, &hFF00FF00, &hFF7DBE7A))
    End Select
End Sub

Private Sub StartStep(ByVal i As Long)
    sStep = i
    sStepT = 0
    sStepDur = Steps_Duration(sProg, i)
    sNarr = IIf(Audio_PlayNarration(Loc_Code(), sProg & "_" & i), 1, 0)
End Sub

' The step player shared by relaxation programmes and "Calm Moments".
' Returns 1 when the user leaves the screen.
Function Steps_Frame(ByRef prog As String, ByVal act As Long, ByRef title As String, ByRef desc As String) As Long
    If gApp.entering Then
        sProg = prog
        Sess_Reset(sSess, act)
        sSteps = Steps_Count(prog)
        sStep = 1: sStepT = 0
    End If
    Dim As Single stepF = IIf(sStepDur > 0, Clamp01(sStepT / sStepDur), 0)
    DrawRelaxScene(prog, IIf(sSess.state = SS_RUN, sStep, 0), IIf(sSess.state = SS_RUN, stepF, 0), gApp.anim)
    Dim As Long backScr = 0
    If Ui_Header(title) Then
        Sess_Leave(sSess)
        Return 1
    End If
    Dim As Long fs = Ui_FS(FS_BODY)
    Select Case sSess.state
    Case SS_INTRO
        Dim As Long pw = Ui_S(680)
        If pw > gApp.w - Ui_S(40) Then pw = gApp.w - Ui_S(40)
        Dim As Long pad = Ui_S(26)
        Dim As String info = desc & !"\n" & Loc_F("relax.length", Str(CLng(Steps_Total(prog) / 60 + 0.5)), Str(sSteps))
        Dim As Long hDesc = Ui_ParaHeight(info, pw - 2 * pad, fs)
        Dim As Long ph = pad + hDesc + Ui_S(16) + Sess_BeforeRatingH() + Ui_S(60) + pad
        Dim As Long px = (gApp.w - pw) \ 2, py = gApp.h - ph - Ui_S(20)
        If py < Ui_HeaderH() Then py = Ui_HeaderH()
        Ui_Panel(px, py, pw, ph, 235)
        Dim As Long y = py + pad
        y += Ui_Para(px + pad, y, pw - 2 * pad, info, fs, gTheme.text) + Ui_S(16)
        y += Sess_BeforeRating(sSess, px + pad, y, pw - 2 * pad)
        Dim As Long favW = (pw - 2 * pad) * 38 \ 100
        Sess_FavButton(sSess, IIf(gApp.rtl, px + pw - pad - favW, px + pad), y + Ui_S(5), favW)
        Dim As Long sw = pw - 2 * pad - favW - Ui_S(12)
        If Ui_Button("st.start", IIf(gApp.rtl, px + pad, px + pad + favW + Ui_S(12)), y, sw, Ui_S(56), L("btn.start"), BTN_PRIMARY, ICON_PLAY) Then
            Sess_Begin(sSess, 0)
            StartStep(1)
        End If
        If gApp.entering Then Ui_SetFocus("st.start")
    Case SS_RUN
        Sess_Tick(sSess)
        If sSess.clk.paused = 0 Then sStepT += gApp.dt
        ' step text panel
        Dim As Long pw = Ui_S(760)
        If pw > gApp.w - Ui_S(40) Then pw = gApp.w - Ui_S(40)
        Dim As Long pad = Ui_S(26)
        Dim As Long fsL = Ui_FS(FS_LARGE)
        Dim As String txt = StepText(prog, sStep)
        Dim As Long th = Ui_ParaHeight(txt, pw - 2 * pad, fsL)
        Dim As Long ph = th + 2 * pad + Ui_S(30)
        Dim As Long px = (gApp.w - pw) \ 2
        Dim As Long py = gApp.h - Sess_ControlsH() - ph - Ui_S(16)
        If py < Ui_HeaderH() Then py = Ui_HeaderH()
        ' gentle fade-in of each step
        Dim As Single fade = Clamp01(sStepT / 0.8)
        If gSet.reducedMotion Then fade = 1
        Ui_Panel(px, py, pw, ph, CLng(200 + 35 * fade))
        Ui_Para(px + pad, py + pad, pw - 2 * pad, txt, fsL, Col_Alpha(gTheme.text, CLng(255 * fade)), ALIGN_CENTER)
        ' step dots
        Dim As Long dot = Ui_S(10), dg = Ui_S(8)
        Dim As Long dw = sSteps * dot + (sSteps - 1) * dg
        Dim As Long dx = (gApp.w - dw) \ 2, dy = py + ph - pad + Ui_S(4)
        For i As Long = 1 To sSteps
            Dim As Long k = IIf(gApp.rtl, sSteps - i, i - 1)
            Dim As ULong c = IIf(i < sStep, gTheme.primary, IIf(i = sStep, gTheme.accent, gTheme.track))
            Cv_FillCircle(gCv, dx + k * (dot + dg) + dot / 2, dy, dot / 2, c)
        Next
        ' controls: previous / pause / next / finish
        Dim As Long bh = Ui_S(56), gap = Ui_S(12)
        Dim As Long bw = Ui_S(190)
        Dim As Long total = 4 * bw + 3 * gap
        If total > gApp.w - Ui_S(30) Then bw = (gApp.w - Ui_S(30) - 3 * gap) \ 4: total = 4 * bw + 3 * gap
        Dim As Long x0 = (gApp.w - total) \ 2, by = gApp.h - bh - Ui_S(18)
        Dim As Long go = 0
        If Ui_Button("st.prev", Ui_MX(x0, bw), by, bw, bh, L("btn.prev"), BTN_SOFT, IIf(gApp.rtl, ICON_ARROW_RIGHT, ICON_ARROW_LEFT)) Then go = -1
        If Ui_Button("st.pause", Ui_MX(x0 + bw + gap, bw), by, bw, bh, L(IIf(sSess.clk.paused, "btn.resume", "btn.pause")), BTN_SOFT, IIf(sSess.clk.paused, ICON_PLAY, ICON_PAUSE)) OrElse Ui_Key(KEY_SPACE) Then
            sSess.clk.paused = IIf(sSess.clk.paused, 0, 1)
            If sSess.clk.paused Then Audio_StopNarration()
        End If
        If Ui_Button("st.next", Ui_MX(x0 + 2 * (bw + gap), bw), by, bw, bh, L("btn.next"), BTN_SOFT, IIf(gApp.rtl, ICON_ARROW_LEFT, ICON_ARROW_RIGHT)) Then go = 1
        If Ui_Button("st.finish", Ui_MX(x0 + 3 * (bw + gap), bw), by, bw, bh, L("btn.finish"), BTN_SOFT, ICON_CHECK) Then go = 99
        ' automatic advance (waits for narration to finish)
        If go = 0 AndAlso sSess.clk.paused = 0 AndAlso sStepT >= sStepDur Then
            If sNarr = 0 OrElse Not Audio_NarrationPlaying() Then go = 1
        End If
        If go = -1 AndAlso sStep > 1 Then StartStep(sStep - 1)
        If go = 1 Then
            If sStep < sSteps Then
                StartStep(sStep + 1)
                Audio_Play(SND_POP)
            Else
                Sess_Finish(sSess, 1)
            End If
        End If
        If go = 99 Then Audio_StopNarration(): Sess_Finish(sSess, IIf(sStep * 2 >= sSteps, 1, 0))
    Case SS_DONE
        Select Case Sess_DonePanel(sSess, "")
        Case 1: sSess.state = SS_INTRO: sStep = 1
        Case 2: Sess_Leave(sSess): Return 1
        End Select
    End Select
    Return 0
End Function

' ---------------- screens ----------------

Sub RelaxList_Frame()
    Scr_Background()
    If Ui_Header(L("relax.title")) Then App_Go(SCR_MENU): Exit Sub
    Dim As String labels(0 To 5), descs(0 To 5)
    Dim As Long icons(0 To 5) = {ICON_HAND, ICON_BODY, ICON_WIND, ICON_SUN, ICON_MOON, ICON_LEAF}
    Dim As ULong tints(0 To 5) = {&hFFFFC48A, &hFFB9A2FF, &hFF86D3B4, &hFFFFE07A, &hFF9FA8E8, &hFF9FD8C8}
    For i As Long = 0 To 5
        labels(i) = L("relax." & ProgKey(i) & ".name")
        descs(i) = L("relax." & ProgKey(i) & ".desc")
    Next
    Dim As Long pick = Scr_TileGrid("rl.", labels(), icons(), tints(), 6, 3, Ui_HeaderH() + Ui_S(20), descs())
    If pick >= 0 Then App_Go(SCR_RELAX, pick)
End Sub

Sub Relax_Frame()
    Dim As Long p = gApp.arg
    If p < 0 OrElse p > 5 Then p = 0
    Dim As String k = ProgKey(p)
    If Steps_Frame(k, ProgAct(p), L("relax." & k & ".name"), L("relax." & k & ".desc")) Then App_Go(SCR_RELAX_LIST)
End Sub
