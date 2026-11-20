' biofeedback_screen.bas - SIMULATED biofeedback: graphs and calm visualisation.
' The "Simulation only - no physiological sensors connected." banner is drawn
' on every frame of this screen (intro, running, finished, help).
#include once "screens.bi"
#include once "session.bi"
#include once "scene.bi"
#include once "localization.bi"
#include once "audio.bi"
#include once "simulated_biofeedback.bi"

Dim Shared As SessFlow bfSess
Dim Shared As BreathPattern bfPat
Dim Shared As Double bfT
Dim Shared As Long bfSelf, bfHelp
Dim Shared As Double bfLastMove, bfClickT(0 To 7)
Dim Shared As Long bfClickI
Dim Shared As BioSample bfS

Private Sub GraphCard(ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long, ByRef title As String, ByRef note As String, ByVal which As Long, ByVal lo As Single, ByVal hi As Single, ByVal col As ULong, ByVal win As Long = BIO_HIST)
    Ui_Panel(x, y, w, h, 230)
    Dim As Long pad = Ui_S(14)
    Dim As Long fs = Ui_FS(FS_BODY - 1), fsN = Ui_FS(FS_SMALL - 1)
    Ui_Label(x + pad, y + Ui_S(8), w - 2 * pad, title, fs, gTheme.title, ALIGN_START, FACE_BOLD)
    Ui_Label(x + pad, y + Ui_S(8), w - 2 * pad, note, fsN, gTheme.sim, ALIGN_END)
    Dim As Long gy = y + Ui_S(8) + Txt_LineHeight(FACE_BOLD, fs) + Ui_S(4)
    Dim As Long gh = y + h - Ui_S(10) - gy
    Dim As Long gx = x + pad, gw = w - 2 * pad
    ' baseline grid
    For k As Long = 0 To 2
        Cv_FillRect(gCv, gx, gy + gh * k \ 2, gw, 1, Col_Alpha(gTheme.track, 160))
    Next
    Dim As BioHistory Ptr hp = Bio_History()
    Dim As Long n = hp->count
    If n < 2 Then Exit Sub
    Dim As Single px = 0, py = 0
    For i As Long = 0 To win - 1
        If i >= n Then Exit For
        Dim As Single v = Bio_HistGet(*hp, which, i)
        Dim As Single f = (v - lo) / (hi - lo)
        If f < 0 Then f = 0
        If f > 1 Then f = 1
        Dim As Single xx = IIf(gApp.rtl, gx + gw * i / (win - 1), gx + gw - gw * i / (win - 1))
        Dim As Single yy = gy + gh - f * gh
        If i > 0 Then Cv_Line(gCv, px, py, xx, yy, Ui_S(2.5) + 0.5, col)
        px = xx: py = yy
    Next
    ' newest point
    Dim As Single v0 = Bio_HistGet(*hp, which, 0)
    Dim As Single f0 = Clamp01((v0 - lo) / (hi - lo))
    Cv_FillCircle(gCv, IIf(gApp.rtl, gx, gx + gw), gy + gh - f0 * gh, Ui_S(5), col)
End Sub

' colour-changing calm picture + relaxation animation meter
Private Sub CalmCard(ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long)
    Ui_Panel(x, y, w, h, 230)
    Dim As Long pad = Ui_S(14)
    Dim As Long fs = Ui_FS(FS_BODY - 1), fsN = Ui_FS(FS_SMALL - 1)
    Ui_Label(x + pad, y + Ui_S(8), w - 2 * pad, L("bio.calm"), fs, gTheme.title, ALIGN_START, FACE_BOLD)
    Ui_Para(x + pad, y + Ui_S(8) + Txt_LineHeight(FACE_BOLD, fs), w - 2 * pad, L("bio.calm.note"), fsN, gTheme.sim, ALIGN_START)
    Dim As Single c = bfS.calm / 100
    ' warm orange -> soft green -> calm blue
    Dim As ULong col
    If c < 0.5 Then col = Col_Mix(&hFFFFB38A, &hFF9FDCB0, c * 2) Else col = Col_Mix(&hFF9FDCB0, &hFF8FC3F5, (c - 0.5) * 2)
    If gSet.highContrast Then col = Col_Mix(&hFFFFFF00, &hFF00FFFF, c)
    Dim As Single cx = x + w / 2, cy = y + h * 0.48
    Dim As Single r = h * 0.2
    Dim As Single pulse = 0.5 + 0.5 * bfS.breath
    Cv_SoftCircle(gCv, cx, cy, r * (1.9 + 0.3 * pulse), Col_Alpha(col, 130))
    Scene_Flower(gCv, cx, cy, r * (0.85 + 0.15 * pulse), 8, col, &hFFFFE7A0, 0.5 + 0.5 * c, gApp.anim * 0.05 * App_Motion())
    ' meter
    Dim As Long mw = w - 2 * pad - Ui_S(20), mh = Ui_S(16)
    Dim As Long mx = x + (w - mw) \ 2, my = y + h - Ui_S(54)
    For i As Long = 0 To mw - 1 Step 2
        Dim As Single f = i / mw
        Dim As ULong cc
        If f < 0.5 Then cc = Col_Mix(&hFFFFB38A, &hFF9FDCB0, f * 2) Else cc = Col_Mix(&hFF9FDCB0, &hFF8FC3F5, (f - 0.5) * 2)
        Cv_FillRect(gCv, IIf(gApp.rtl, mx + mw - i - 2, mx + i), my, 2, mh, Col_Alpha(cc, 200))
    Next
    Cv_RoundRectOutline(gCv, mx, my, mw, mh, mh / 2, 1.5, gTheme.panelEdge)
    Dim As Single kx = IIf(gApp.rtl, mx + mw - c * mw, mx + c * mw)
    Cv_FillCircle(gCv, kx, my + mh / 2, Ui_S(11), &hFFFFFFFF)
    Cv_Ring(gCv, kx, my + mh / 2, Ui_S(11), 2, gTheme.title)
    Ui_Label(x + pad, my + mh + Ui_S(6), w - 2 * pad, L("bio.meter.lo"), fsN, gTheme.textSoft, ALIGN_START)
    Ui_Label(x + pad, my + mh + Ui_S(6), w - 2 * pad, L("bio.meter.hi"), fsN, gTheme.textSoft, ALIGN_END)
End Sub

' focus game: rest the pointer inside the slowly drifting circle (or simply keep still)
Private Function FocusCard(ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long) As Long
    Ui_Panel(x, y, w, h, 230)
    Dim As Long pad = Ui_S(14)
    Dim As Long fs = Ui_FS(FS_BODY - 1), fsN = Ui_FS(FS_SMALL - 1)
    Ui_Label(x + pad, y + Ui_S(8), w - 2 * pad, L("bio.focus"), fs, gTheme.title, ALIGN_START, FACE_BOLD)
    Ui_Label(x + pad, y + Ui_S(8), w - 2 * pad, L("bio.focus.note"), fsN, gTheme.sim, ALIGN_END)
    Dim As Long ay = y + Ui_S(8) + Txt_LineHeight(FACE_BOLD, fs) + Ui_S(4)
    Dim As Long ah = y + h - Ui_S(10) - ay
    Dim As Long ax = x + pad, aw = w - 2 * pad
    Cv_FillRoundRect(gCv, ax, ay, aw, ah, Ui_S(12), Col_Alpha(gTheme.track, 90))
    Dim As Double t = bfT * IIf(gSet.reducedMotion, 0.3, 1)
    Dim As Single r = ah * 0.32
    Dim As Single cx = ax + aw / 2 + Sin(t * 0.23) * (aw / 2 - r - 4)
    Dim As Single cy = ay + ah / 2 + Sin(t * 0.31 + 1) * (ah / 2 - r - 4)
    Dim As Single dx = gIn.mx - cx, dy = gIn.my - cy
    Dim As Long inside = IIf(dx * dx + dy * dy <= r * r, 1, 0)
    ' keyboard users and anyone who prefers to keep still: stillness counts as resting attention
    If gApp.now - bfLastMove > 3 Then inside = 1
    Dim As Single fv = bfS.focus / 100
    Cv_SoftCircle(gCv, cx, cy, r * 1.6, Col_Alpha(IIf(gSet.highContrast, &hFF00FFFF, &hFFB9A2FF), CLng(60 + 120 * fv)))
    Cv_FillCircle(gCv, cx, cy, r, Col_Alpha(IIf(gSet.highContrast, &hFF00FFFF, &hFFD9CCFF), 200))
    Cv_Ring(gCv, cx, cy, r, Ui_S(2), IIf(inside, gTheme.primary, gTheme.textSoft))
    ' focus level bar along the bottom of the card
    Dim As Long bw = CLng((aw - Ui_S(20)) * fv)
    Cv_FillRoundRect(gCv, IIf(gApp.rtl, ax + aw - Ui_S(10) - bw, ax + Ui_S(10)), ay + ah - Ui_S(12), bw, Ui_S(6), Ui_S(3), gTheme.primary)
    Return inside
End Function

Private Sub HelpOverlay()
    Cv_FillRect(gCv, 0, 0, gApp.w, gApp.h, &h80000000)
    Dim As Long pw = Ui_S(760), fs = Ui_FS(FS_BODY)
    If pw > gApp.w - Ui_S(40) Then pw = gApp.w - Ui_S(40)
    Dim As Long pad = Ui_S(26)
    Dim As String t = L("bio.explain")
    Dim As Long th = Scr_Section(0, 0, pw - 2 * pad, t, fs, 0)
    Dim As Long ph = th + 2 * pad + Ui_S(70)
    If ph > gApp.h - Ui_S(140) Then ph = gApp.h - Ui_S(140)
    Dim As Long px = (gApp.w - pw) \ 2, py = (gApp.h - ph) \ 2 + Ui_S(30)
    Ui_Panel(px, py, pw, ph, 250)
    Cv_PushClip(gCv, px, py, pw, ph - Ui_S(70))
    Scr_Section(px + pad, py + pad, pw - 2 * pad, t, fs)
    Cv_PopClip(gCv)
    If Ui_Button("bio.helpclose", px + (pw - Ui_S(220)) \ 2, py + ph - Ui_S(66), Ui_S(220), Ui_S(52), L("btn.close"), BTN_PRIMARY, ICON_CHECK) OrElse Ui_Key(KEY_ESC) Then bfHelp = 0
    Ui_SimBanner((gApp.w - gApp.w * 70 \ 100) \ 2, Ui_HeaderH(), gApp.w * 70 \ 100)
End Sub

Sub Bio_Frame()
    If gApp.entering Then
        Sess_Reset(bfSess, ACT_BIO)
        Bio_Reset(CULng(Timer * 1000))
        bfSelf = 0: bfHelp = 0: bfT = 0
        bfLastMove = gApp.now
    End If
    Scr_Background()
    If bfHelp Then
        ' keep everything still underneath while reading
        If Ui_Header(L("menu.bio"), 1) Then bfHelp = 0
        HelpOverlay()
        Exit Sub
    End If
    If Ui_Header(L("menu.bio"), 1) Then Sess_Leave(bfSess): App_Go(SCR_MENU): Exit Sub
    Dim As Long top = Ui_HeaderH() + Ui_S(56)
    Dim As Long fs = Ui_FS(FS_BODY)
    Select Case bfSess.state
    Case SS_INTRO
        Dim As Long pw = Ui_S(740)
        If pw > gApp.w - Ui_S(40) Then pw = gApp.w - Ui_S(40)
        Dim As Long pad = Ui_S(26)
        Dim As String t = L("bio.intro")
        Dim As Long th = Ui_ParaHeight(t, pw - 2 * pad, fs)
        Dim As Long ph = th + 2 * pad + Ui_S(16) + Sess_BeforeRatingH() + Ui_S(60)
        Dim As Long px = (gApp.w - pw) \ 2, py = top + Ui_S(10)
        Ui_Panel(px, py, pw, ph, 235)
        Dim As Long y = py + pad
        y += Ui_Para(px + pad, y, pw - 2 * pad, t, fs, gTheme.text) + Ui_S(16)
        y += Sess_BeforeRating(bfSess, px + pad, y, pw - 2 * pad)
        Dim As Long bw = (pw - 2 * pad - Ui_S(12)) \ 2
        If Ui_Button("bio.start", IIf(gApp.rtl, px + pad, px + pw - pad - bw), y, bw, Ui_S(56), L("bio.start"), BTN_PRIMARY, ICON_PLAY) Then
            Breath_MakePattern(bfPat, gSet.inhaleSec, gSet.exhaleSec, gSet.pauseOn, gSet.pauseSec)
            Sess_Begin(bfSess, Sess_Minutes(3) * 60)
            bfSelf = bfSess.before
            bfT = 0
        End If
        If Ui_Button("bio.help", IIf(gApp.rtl, px + pw - pad - bw, px + pad), y, bw, Ui_S(56), L("bio.how"), BTN_NORMAL, ICON_INFO) Then bfHelp = 1
        If gApp.entering Then Ui_SetFocus("bio.start")
    Case SS_RUN
        Sess_Tick(bfSess)
        If bfSess.clk.paused = 0 Then bfT += gApp.dt
        ' inputs for the simulation
        Static As Long lmx, lmy
        If gIn.mx <> lmx OrElse gIn.my <> lmy Then bfLastMove = gApp.now
        lmx = gIn.mx: lmy = gIn.my
        If gIn.mPressed Then bfClickT(bfClickI) = gApp.now: bfClickI = (bfClickI + 1) Mod 8
        Dim As Long recent = 0
        For i As Long = 0 To 7
            If gApp.now - bfClickT(i) < 1.5 Then recent += 1
        Next
        Dim As BreathState st
        Breath_Eval(bfPat, bfT, st)
        ' layout: graphs on the start side, calm picture on the end side
        Dim As Long margin = Ui_S(18), gap = Ui_S(14)
        Dim As Long bottom = gApp.h - Sess_ControlsH() - Ui_S(8)
        Dim As Long colW = (gApp.w - 2 * margin - gap) * 58 \ 100
        Dim As Long col2W = gApp.w - 2 * margin - gap - colW
        Dim As Long cardH = (bottom - top - 2 * gap) \ 3
        Dim As Long gx = Ui_MX(margin, colW)
        GraphCard(gx, top, colW, cardH, L("bio.breath"), L("bio.breath.note"), 0, -1.1, 1.1, IIf(gSet.highContrast, &hFF00FFFF, &hFF4FA3D9))
        GraphCard(gx, top + cardH + gap, colW, cardH, L("bio.heart"), L("bio.heart.note"), 1, -0.4, 1.1, IIf(gSet.highContrast, &hFFFF66CC, &hFFE0708A), 240)
        Dim As Long inside = FocusCard(gx, top + 2 * (cardH + gap), colW, cardH)
        Dim As Long cx2 = Ui_MX(margin + colW + gap, col2W)
        Dim As Long rateH = Txt_LineHeight(FACE_REGULAR, Ui_FS(FS_SMALL)) * 2 + Ui_S(78)
        CalmCard(cx2, top, col2W, bottom - top - rateH - gap)
        ' the user's own rating (it influences the animation; it is never "measured")
        Dim As Long ry = bottom - rateH
        Ui_Panel(cx2, ry, col2W, rateH, 230)
        Ui_Label(cx2 + Ui_S(12), ry + Ui_S(6), col2W - Ui_S(24), L("bio.self"), Ui_FS(FS_SMALL), gTheme.text, ALIGN_CENTER)
        Scr_RatingRow("bio.r", cx2 + Ui_S(8), ry + Ui_S(8) + Txt_LineHeight(FACE_REGULAR, Ui_FS(FS_SMALL)), col2W - Ui_S(16), bfSelf)
        ' step the simulation
        Dim As BioInputs bioIn
        bioIn.breathAmount = st.amount
        bioIn.breathing = 1
        bioIn.selfReport = bfSelf
        bioIn.pointerInside = inside
        bioIn.activity = recent / 6.0
        bioIn.paused = bfSess.clk.paused
        Bio_Step(gApp.dt, bioIn, bfS)
        ' controls
        Dim As Long hb = Ui_S(48)
        If Ui_Button("bio.help2", Ui_MX(gApp.w - margin - hb, hb), gApp.h - hb - Ui_S(22), hb, hb, "", BTN_SOFT, ICON_INFO) Then bfHelp = 1
        If Sess_Controls(bfSess, 0) Then Sess_Finish(bfSess, IIf(bfSess.clk.elapsed >= 60, 1, 0))
        If Clock_Done(bfSess.clk) Then Sess_Finish(bfSess, 1)
    Case SS_DONE
        Select Case Sess_DonePanel(bfSess, L("bio.done"))
        Case 1: bfSess.state = SS_INTRO
        Case 2: Sess_Leave(bfSess): App_Go(SCR_MENU)
        End Select
    End Select
End Sub
