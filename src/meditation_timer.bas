' meditation_timer.bas - configurable meditation timer with presets, chimes,
' ambient sound, pause/resume, a full-window visualisation and a summary.
#include once "screens.bi"
#include once "session.bi"
#include once "scene.bi"
#include once "localization.bi"
#include once "audio.bi"

Dim Shared As SessFlow mSess
Dim Shared As Long mMinutes = 5, mAmbient = 1, mStartChime = 1, mEndChime = 1, mVis, mUseFull = 0
Dim Shared As Long mWasFull
Dim Shared As Double mLastMove

Private Sub Visualise(ByVal v As Long, ByVal progF As Single, ByVal tm As Double)
    Dim As Single w = gApp.w, h = gApp.h, s = gApp.sc, mo = App_Motion()
    Dim As Single cx = w / 2, cy = h * 0.46
    If gSet.highContrast Then Cv_Clear(gCv, &hFF000000)
    Select Case v
    Case 0  ' soft glowing orb that breathes very slowly
        If gSet.highContrast = 0 Then Cv_VGradient3(gCv, 0, 0, w, h, &hFF2B2F5C, &hFF4B4C86, &hFF7A6BA6)
        Dim As Single pulse = 0.5 + 0.5 * Sin(tm * 0.35 * mo)
        Cv_SoftCircle(gCv, cx, cy, (200 + 40 * pulse) * s, &h50FFE3B0)
        Cv_SoftCircle(gCv, cx, cy, (110 + 20 * pulse) * s, &h90FFEFD0)
        Cv_FillCircle(gCv, cx, cy, (46 + 6 * pulse) * s, &hFFFFF6E6)
    Case 1  ' lotus on still water
        If gSet.highContrast = 0 Then Cv_VGradient3(gCv, 0, 0, w, h, &hFFFFE3D3, &hFFF5D0E6, &hFFB9D8F0)
        If gSet.highContrast = 0 Then Scene_Wave(gCv, h * 0.62, 3 * s, 600 * s, tm * 0.2 * mo, &hC09CC7E6)
        For k As Long = 0 To 2
            Dim As Single rr = ((tm * 18 * mo + k * 70) Mod 210) * s
            Cv_Ring(gCv, cx, h * 0.66, rr * 1.6 + 30 * s, 1.5, Col_Alpha(&hFFFFFFFF, CLng(150 * (1 - rr / (210 * s)))))
        Next
        Icon_Draw(ICON_LOTUS, cx, h * 0.6, 220 * s, IIf(gSet.highContrast, &hFFFF66CC, &hFFF08DB0), 0)
    Case 2  ' ripples
        If gSet.highContrast = 0 Then Cv_VGradient3(gCv, 0, 0, w, h, &hFFCDEFFB, &hFF9FD8F5, &hFF6FB8E0)
        For k As Long = 0 To 5
            Dim As Single ph = ((tm * 0.12 * mo + k / 6) Mod 1)
            Cv_Ring(gCv, cx, cy, ph * 330 * s + 10, 2 * s, Col_Alpha(&hFFFFFFFF, CLng(200 * (1 - ph))))
        Next
        Cv_FillCircle(gCv, cx, cy, 8 * s, &hE0FFFFFF)
    Case Else  ' night sky
        If gSet.highContrast = 0 Then Cv_VGradient3(gCv, 0, 0, w, h, &hFF141836, &hFF272C5C, &hFF453E78)
        For i As Long = 0 To 90
            Dim As Single tw = 0.5 + 0.5 * Sin(tm * (0.3 + Scene_Rand(i) * 0.5) * mo + i)
            Cv_FillCircle(gCv, Scene_Rand(i + 11) * w, Scene_Rand(i + 333) * h * 0.85, (0.8 + Scene_Rand(i + 77) * 1.5) * s, Col_Alpha(&hFFFFF8E0, CLng(80 + 150 * tw)))
        Next
        Cv_SoftCircle(gCv, w * 0.78, h * 0.2, 120 * s, &h40FFF4D0)
        Cv_FillCircle(gCv, w * 0.78, h * 0.2, 38 * s, &hFFFFF4D0)
    End Select
    ' gentle progress ring around the centre (no numbers unless the controls are shown)
    If progF > 0 Then
        Dim As Single r = 250 * s
        Dim As Long segs = 120
        Dim As Long lit = CLng(segs * progF)
        For i As Long = 0 To segs - 1
            Dim As Single a = -1.5708 + i / segs * 6.2832 * IIf(gApp.rtl, -1, 1)
            Cv_FillCircle(gCv, cx + Cos(a) * r, cy + Sin(a) * r, 2.2 * s, IIf(i < lit, &hC0FFFFFF, &h30FFFFFF))
        Next
    End If
End Sub

Private Sub StartTimer()
    Sess_Begin(mSess, mMinutes * 60, 0)
    If mStartChime Then Audio_Play(SND_CHIME)
    If mAmbient = 0 Then Audio_SetAmbient(-1) Else Audio_SetAmbient(mAmbient - 1)
    mWasFull = Plat_IsFullscreen()
    If mUseFull AndAlso mWasFull = 0 Then Plat_SetFullscreen(1)
    mLastMove = gApp.now
End Sub

Private Sub EndFullscreen()
    If mUseFull AndAlso mWasFull = 0 AndAlso Plat_IsFullscreen() Then Plat_SetFullscreen(0)
End Sub

Sub Timer_Frame()
    If gApp.entering Then
        Sess_Reset(mSess, ACT_TIMER)
        If gSet.childMode AndAlso mMinutes > 5 Then mMinutes = 3
    End If
    Select Case mSess.state
    Case SS_INTRO
        Visualise(mVis, 0, gApp.anim)
        If Ui_Header(L("timer.title")) Then App_Go(SCR_MENU): Exit Sub
        Dim As Long pw = Ui_S(760)
        If pw > gApp.w - Ui_S(40) Then pw = gApp.w - Ui_S(40)
        Dim As Long px = (gApp.w - pw) \ 2, py = Ui_HeaderH() + Ui_S(6)
        Dim As Long ph = gApp.h - py - Ui_S(16)
        Ui_Panel(px, py, pw, ph, 235)
        Dim As Long pad = Ui_S(24), x = px + pad, cw = pw - 2 * pad
        Dim As Long y = py + pad
        Dim As Long fs = Ui_FS(FS_BODY)
        Ui_Label(x, y, cw, L("timer.presets"), fs, gTheme.text)
        y += Txt_LineHeight(FACE_REGULAR, fs) + Ui_S(8)
        Dim As Long presets(0 To 6) = {1, 3, 5, 10, 15, 20, 30}
        Dim As Long gap = Ui_S(10)
        Dim As Long bw = (cw - 6 * gap) \ 7, bh = Ui_S(52)
        For i As Long = 0 To 6
            Dim As Long bx = IIf(gApp.rtl, x + cw - bw - i * (bw + gap), x + i * (bw + gap))
            If Ui_Button("tm.p" & i, bx, y, bw, bh, Str(presets(i)), IIf(mMinutes = presets(i), BTN_PRIMARY, BTN_NORMAL)) Then mMinutes = presets(i)
        Next
        y += bh + Ui_S(12)
        Dim As Long sh = Ui_S(70)
        If Ui_Slider("tm.custom", x, y, cw, sh, L("timer.custom"), mMinutes, 1, 120, 1, " " & L("unit.min")) Then
        End If
        y += sh + Ui_S(4)
        Dim As Long rh = Ui_S(46)
        Ui_Choice("tm.amb", x, y, cw, rh, L("settings.ambientsound"), L("amb.none") & "|" & L("amb.rain") & "|" & L("amb.ocean") & "|" & L("amb.wind") & "|" & L("amb.forest") & "|" & L("amb.birds") & "|" & L("amb.music"), mAmbient)
        y += rh + Ui_S(8)
        Ui_Choice("tm.vis", x, y, cw, rh, L("timer.visual"), L("timer.vis0") & "|" & L("timer.vis1") & "|" & L("timer.vis2") & "|" & L("timer.vis3"), mVis)
        y += rh + Ui_S(8)
        Dim As Long hw = (cw - Ui_S(16)) \ 2
        Ui_Toggle("tm.sc", IIf(gApp.rtl, x + cw - hw, x), y, hw, rh, L("timer.startchime"), mStartChime)
        Ui_Toggle("tm.ec", IIf(gApp.rtl, x, x + hw + Ui_S(16)), y, hw, rh, L("timer.endchime"), mEndChime)
        y += rh + Ui_S(8)
        Ui_Toggle("tm.full", x, y, cw, rh, L("timer.fullscreen"), mUseFull)
        y += rh + Ui_S(8)
        Dim As Long sbh = Ui_S(58)
        Dim As Long sby = py + ph - pad - sbh
        Dim As Long rr = Sess_BeforeRatingH()
        If y + rr <= sby Then Sess_BeforeRating(mSess, x, sby - rr, cw)
        If Ui_Button("tm.start", x + cw \ 4, sby, cw \ 2, sbh, Loc_F("timer.start", Str(mMinutes)), BTN_PRIMARY, ICON_PLAY) Then StartTimer()
        If gApp.entering Then Ui_SetFocus("tm.start")
    Case SS_RUN
        Sess_Tick(mSess)
        Visualise(mVis, Clock_Frac(mSess.clk), gApp.anim)
        ' controls fade out while sitting still and come back on any mouse movement or key
        Static As Long lastMx, lastMy
        If gIn.mx <> lastMx OrElse gIn.my <> lastMy OrElse gIn.keyN > 0 OrElse gIn.mPressed Then mLastMove = gApp.now
        lastMx = gIn.mx: lastMy = gIn.my
        Dim As Long showUi = IIf(gApp.now - mLastMove < 4 OrElse mSess.clk.paused <> 0, 1, 0)
        Dim As Long fin = 0
        If showUi Then
            If Ui_Header(L("timer.title")) Then fin = 2
            ' time shown only while the controls are visible
            ' remaining time on a soft pill below the centre picture
            Dim As Long fs = Ui_FS(FS_TITLE)
            Dim As String tt = Fmt_MinSec(Clock_Left(mSess.clk))
            If mSess.clk.paused Then tt = L("sess.paused") & " · " & tt
            Dim As Long lh = Txt_LineHeight(FACE_BOLD, fs)
            Dim As Long pwT = Txt_Width(tt, FACE_BOLD, fs, App_DirText()) + Ui_S(48)
            Dim As Long ty = gApp.h * 46 \ 100 + Ui_S(140)
            Cv_FillRoundRect(gCv, (gApp.w - pwT) \ 2, ty - Ui_S(6), pwT, lh + Ui_S(12), (lh + Ui_S(12)) / 2, Col_Alpha(gTheme.panel, 200))
            Ui_Label(0, ty, gApp.w, tt, fs, gTheme.title, ALIGN_CENTER, FACE_BOLD)
            If Sess_Controls(mSess, 0) Then fin = 1
        Else
            If Ui_Key(KEY_SPACE) Then mSess.clk.paused = 1: mLastMove = gApp.now
            If Ui_Key(KEY_ESC) Then fin = 2
        End If
        If Clock_Done(mSess.clk) Then
            EndFullscreen()
            Sess_Finish(mSess, 1, 0)
            If mEndChime Then Audio_Play(SND_CHIME_END)
        ElseIf fin Then
            EndFullscreen()
            Sess_Finish(mSess, IIf(mSess.clk.elapsed >= mSess.clk.total * 0.5, 1, 0), 0)
            If mEndChime Then Audio_Play(SND_CHIME_END)
        End If
    Case SS_DONE
        Visualise(mVis, 1, gApp.anim)
        If Ui_Header(L("timer.title")) Then Sess_Leave(mSess): App_Go(SCR_MENU): Exit Sub
        Dim As String extra = Loc_F("timer.summary", Fmt_MinSec(mSess.clk.elapsed))
        Select Case Sess_DonePanel(mSess, extra)
        Case 1: mSess.state = SS_INTRO
        Case 2: Sess_Leave(mSess): App_Go(SCR_MENU)
        End Select
    End Select
End Sub
