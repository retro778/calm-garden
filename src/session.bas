' session.bas - see session.bi
#include once "session.bi"
#include once "screens.bi"
#include once "localization.bi"
#include once "audio.bi"
#include once "progress.bi"
#include once "scene.bi"

Sub Sess_Reset(ByRef s As SessFlow, ByVal act As Long)
    s.act = act
    s.state = SS_INTRO
    s.before = 0: s.after = 0
    s.recorded = 0: s.completed = 0: s.natural = 0
    s.afterSaved = 0
    s.clk.running = 0: s.clk.paused = 0: s.clk.elapsed = 0
End Sub

Function Sess_Minutes(ByVal configured As Long) As Long
    If gSet.childMode AndAlso configured > 3 Then Return 3
    Return configured
End Function

Sub Sess_Begin(ByRef s As SessFlow, ByVal totalSec As Single, ByVal chime As Long = 1)
    Clock_Start(s.clk, totalSec)
    s.state = SS_RUN
    s.recorded = 0: s.completed = 0: s.natural = 0: s.after = 0: s.afterSaved = 0
    If chime Then Audio_Play(SND_CHIME)
    If gSet.ambientOn Then Audio_SetAmbient(gSet.ambientId) Else Audio_SetAmbient(-1)
End Sub

Sub Sess_Tick(ByRef s As SessFlow)
    If s.state = SS_RUN Then Clock_Tick(s.clk, gApp.dt)
End Sub

Private Sub Record(ByRef s As SessFlow)
    If s.recorded Then Exit Sub
    Progress_AddSession(App_ActKey(s.act), CLng(s.clk.elapsed), s.before, s.after, s.completed)
    s.recorded = 1
End Sub

Sub Sess_Finish(ByRef s As SessFlow, ByVal completed As Long, ByVal chime As Long = 1)
    If s.state <> SS_RUN Then Exit Sub
    s.completed = IIf(completed, 1, 0)
    s.state = SS_DONE
    s.msgIdx = 1 + (gApp.frame Mod 6)
    s.clk.running = 0
    If chime Then Audio_Play(SND_CHIME_END)
    ' recorded when the panel closes, so that the optional "after" rating is included
End Sub

Sub Sess_Leave(ByRef s As SessFlow)
    If s.state = SS_RUN Then
        s.completed = 0
        Record(s)
    ElseIf s.state = SS_DONE Then
        Record(s)
    End If
    s.state = SS_INTRO
    Audio_StopNarration()
    Audio_SetAmbient(IIf(gSet.musicOn, AMB_MUSIC, -1))
End Sub

Function Sess_BeforeRatingH() As Long
    If gSet.askRatings = 0 Then Return 0
    Return Txt_LineHeight(FACE_REGULAR, Ui_FS(FS_BODY)) + Ui_S(64) + Ui_S(30) + Ui_S(10)
End Function

Function Sess_BeforeRating(ByRef s As SessFlow, ByVal x As Long, ByVal y As Long, ByVal w As Long) As Long
    If gSet.askRatings = 0 Then Return 0
    Dim As Long fs = Ui_FS(FS_BODY)
    Ui_Label(x, y, w, L("rate.before"), fs, gTheme.text)
    Dim As Long lh = Txt_LineHeight(FACE_REGULAR, fs)
    Scr_RatingRow("rate.b", x, y + lh + Ui_S(6), w, s.before)
    Return Sess_BeforeRatingH()
End Function

Function Sess_ControlsH() As Long
    Return Ui_S(84)
End Function

Function Sess_Controls(ByRef s As SessFlow, ByVal showNatural As Long) As Long
    Dim As Long bh = Ui_S(56), gap = Ui_S(16)
    Dim As Long n = IIf(showNatural, 3, 2)
    ' wide enough for the longest label (+ icon)
    Dim As Long fsB = Ui_FS(FS_BODY)
    Dim As String lbls(0 To 2) = {L("btn.resume"), L("btn.natural"), L("btn.finish")}
    Dim As Long bw = Ui_S(200)
    For i As Long = 0 To 2
        Dim As Long need = Txt_Width(lbls(i), FACE_BOLD, fsB, App_DirText()) + Ui_S(80)
        If need > bw Then bw = need
    Next
    If showNatural Then
        Dim As Long need2 = Txt_Width(L("btn.guided"), FACE_BOLD, fsB, App_DirText()) + Ui_S(80)
        If need2 > bw Then bw = need2
    End If
    Dim As Long total = n * bw + (n - 1) * gap
    If total > gApp.w - Ui_S(40) Then bw = (gApp.w - Ui_S(40) - (n - 1) * gap) \ n: total = n * bw + (n - 1) * gap
    Dim As Long x0 = (gApp.w - total) \ 2
    Dim As Long y = gApp.h - bh - Ui_S(18)
    Dim As Long res = 0
    Dim As Long k = 0
    If Ui_Button("sess.pause", Ui_MX(x0 + k * (bw + gap), bw), y, bw, bh, L(IIf(s.clk.paused, "btn.resume", "btn.pause")), BTN_SOFT, IIf(s.clk.paused, ICON_PLAY, ICON_PAUSE)) OrElse Ui_Key(KEY_SPACE) Then
        s.clk.paused = IIf(s.clk.paused, 0, 1)
        If s.clk.paused Then Audio_StopNarration()
    End If
    k += 1
    If showNatural Then
        If Ui_Button("sess.natural", Ui_MX(x0 + k * (bw + gap), bw), y, bw, bh, L(IIf(s.natural, "btn.guided", "btn.natural")), BTN_SOFT, ICON_LEAF) OrElse Ui_Key(Asc("n")) Then
            s.natural = IIf(s.natural, 0, 1)
        End If
        k += 1
    End If
    If Ui_Button("sess.finish", Ui_MX(x0 + k * (bw + gap), bw), y, bw, bh, L("btn.finish"), BTN_SOFT, ICON_CHECK) Then res = 1
    Return res
End Function

Sub Sess_Progress(ByRef s As SessFlow, ByVal y As Long)
    If s.clk.total <= 0 Then Exit Sub
    Dim As Long w = gApp.w * 40 \ 100, h = Ui_S(8)
    Dim As Long x = (gApp.w - w) \ 2
    Cv_FillRoundRect(gCv, x, y, w, h, h / 2, Col_Alpha(&hFFFFFFFF, 120))
    Dim As Long fw = CLng(w * Clock_Frac(s.clk))
    If gApp.rtl Then
        Cv_FillRoundRect(gCv, x + w - fw, y, fw, h, h / 2, Col_Alpha(gTheme.primary, 220))
    Else
        Cv_FillRoundRect(gCv, x, y, fw, h, h / 2, Col_Alpha(gTheme.primary, 220))
    End If
    Dim As Long fs = Ui_FS(FS_SMALL)
    Dim As String t
    If s.clk.paused Then
        t = L("sess.paused")
    Else
        Dim As Long m = CLng(Int(Clock_Left(s.clk) / 60 + 0.999))
        t = IIf(m <= 1, L("sess.left1"), Loc_F("sess.leftn", Str(m)))
    End If
    Dim As Long tw = Txt_Width(t, FACE_REGULAR, fs, App_DirText()) + Ui_S(24)
    Dim As Long th = Txt_LineHeight(FACE_REGULAR, fs) + Ui_S(6)
    Cv_FillRoundRect(gCv, (gApp.w - tw) \ 2, y + h + Ui_S(6), tw, th, th / 2, Col_Alpha(gTheme.panel, 170))
    Ui_Label(0, y + h + Ui_S(9), gApp.w, t, fs, gTheme.text, ALIGN_CENTER)
End Sub

Sub Sess_FavButton(ByRef s As SessFlow, ByVal x As Long, ByVal y As Long, ByVal w As Long)
    Dim As String k = App_ActKey(s.act)
    Dim As Long fav = IIf(Progress_IsFav(k), 1, 0)
    If Ui_Button("sess.fav", x, y, w, Ui_S(46), L(IIf(fav, "fav.on", "fav.off")), BTN_SOFT, ICON_HEART, IIf(fav, &hFFFF9EB5, 0)) Then
        Progress_ToggleFav(k)
        If Progress_Tracking() = 0 Then Ui_Toast(L("fav.notracking"))
    End If
End Sub

Function Sess_DonePanel(ByRef s As SessFlow, ByRef extra As String) As Long
    Dim As Long pw = Ui_S(640), fs = Ui_FS(FS_BODY)
    If pw > gApp.w - Ui_S(40) Then pw = gApp.w - Ui_S(40)
    Dim As Long pad = Ui_S(28)
    Dim As String msg = L("done.msg" & s.msgIdx)
    If Len(extra) Then msg &= !"\n" & extra
    Dim As Long fsT = Ui_FS(FS_TITLE)
    Dim As Long hTitle = Txt_LineHeight(FACE_BOLD, fsT)
    Dim As Long hMsg = Ui_ParaHeight(msg, pw - 2 * pad, fs)
    Dim As Long hRate = IIf(gSet.askRatings, Txt_LineHeight(FACE_REGULAR, fs) + Ui_S(110), 0)
    Dim As Long bh = Ui_S(56)
    Dim As Long ph = pad + hTitle + Ui_S(10) + hMsg + Ui_S(16) + hRate + bh + pad
    Dim As Long px = (gApp.w - pw) \ 2, py = (gApp.h - ph) \ 2
    If py < Ui_HeaderH() Then py = Ui_HeaderH()
    Ui_Panel(px, py, pw, ph, 240)
    Dim As Long y = py + pad
    ' a little sparkle of stars above the title
    For i As Long = 0 To 2
        Dim As Single tw = 0.6 + 0.4 * Sin(gApp.anim * 2 * App_Motion() + i * 2)
        Scene_Star(gCv, px + pw / 2 + (i - 1) * Ui_S(40), py - Ui_S(4) + Abs(i - 1) * Ui_S(10), Ui_S(12) * tw, 0, IIf(gSet.highContrast, &hFFFFFF00, &hFFFFD36E))
    Next
    Ui_Label(px + pad, y, pw - 2 * pad, L("done.title"), fsT, gTheme.title, ALIGN_CENTER, FACE_BOLD)
    y += hTitle + Ui_S(10)
    y += Ui_Para(px + pad, y, pw - 2 * pad, msg, fs, gTheme.text, ALIGN_CENTER) + Ui_S(16)
    If gSet.askRatings Then
        Ui_Label(px + pad, y, pw - 2 * pad, L("rate.after"), fs, gTheme.text, ALIGN_CENTER)
        Scr_RatingRow("rate.a", px + pad, y + Txt_LineHeight(FACE_REGULAR, fs) + Ui_S(6), pw - 2 * pad, s.after)
        y += hRate
    End If
    Dim As Long bw = (pw - 2 * pad - Ui_S(16)) \ 2
    Dim As Long res = 0
    If Ui_Button("done.again", IIf(gApp.rtl, px + pw - pad - bw, px + pad), y, bw, bh, L("btn.again"), BTN_NORMAL, ICON_PLAY) Then res = 1
    If Ui_Button("done.back", IIf(gApp.rtl, px + pad, px + pad + bw + Ui_S(16)), y, bw, bh, L("btn.done"), BTN_PRIMARY, ICON_CHECK) Then res = 2
    If Ui_Key(KEY_ENTER) Then res = 2
    If res <> 0 Then
        Record(s)
        If res = 1 Then s.state = SS_INTRO
    End If
    Return res
End Function
