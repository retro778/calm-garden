' mindfulness.bas - Five Senses, Mindful Observation, Thought Clouds,
' Gratitude Garden and Calm Moments.
' Nothing here asks the user to push thoughts or feelings away: the wording
' invites noticing, with kindness, and every activity can be left at any time.
#include once "screens.bi"
#include once "session.bi"
#include once "scene.bi"
#include once "localization.bi"
#include once "audio.bi"
#include once "progress.bi"
#include once "relaxation.bi"

Const MA_SENSES = 0
Const MA_OBSERVE = 1
Const MA_CLOUDS = 2
Const MA_GRATITUDE = 3
Const MA_MOMENTS = 4

Dim Shared As SessFlow mfSess

Private Function MKey(ByVal m As Long) As String
    Select Case m
    Case MA_OBSERVE: Return "observe"
    Case MA_CLOUDS: Return "clouds"
    Case MA_GRATITUDE: Return "gratitude"
    Case MA_MOMENTS: Return "moments"
    Case Else: Return "senses"
    End Select
End Function

Private Function MAct(ByVal m As Long) As Long
    Select Case m
    Case MA_OBSERVE: Return ACT_OBSERVE
    Case MA_CLOUDS: Return ACT_CLOUDS
    Case MA_GRATITUDE: Return ACT_GRATITUDE
    Case MA_MOMENTS: Return ACT_MOMENTS
    Case Else: Return ACT_SENSES
    End Select
End Function

Sub MindList_Frame()
    Scr_Background()
    If Ui_Header(L("mind.title")) Then App_Go(SCR_MENU): Exit Sub
    Dim As String labels(0 To 4), descs(0 To 4)
    Dim As Long icons(0 To 4) = {ICON_HAND, ICON_EYE, ICON_CLOUD, ICON_FLOWER, ICON_SUN}
    Dim As ULong tints(0 To 4) = {&hFFFFC48A, &hFF8FD3FF, &hFFC8D6F0, &hFFFF9EB5, &hFFFFE07A}
    For i As Long = 0 To 4
        labels(i) = L("mind." & MKey(i))
        descs(i) = L("mind." & MKey(i) & ".desc")
    Next
    Dim As Long pick = Scr_TileGrid("ml.", labels(), icons(), tints(), 5, 3, Ui_HeaderH() + Ui_S(20), descs())
    If pick >= 0 Then App_Go(SCR_MIND, pick)
End Sub

' ---------------- common: intro panel for the interactive activities ----------------

Private Function IntroPanel(ByRef desc As String) As Boolean
    Dim As Long pw = Ui_S(680), fs = Ui_FS(FS_BODY)
    If pw > gApp.w - Ui_S(40) Then pw = gApp.w - Ui_S(40)
    Dim As Long pad = Ui_S(26)
    Dim As Long hDesc = Ui_ParaHeight(desc, pw - 2 * pad, fs)
    Dim As Long ph = pad + hDesc + Ui_S(16) + Sess_BeforeRatingH() + Ui_S(60) + pad
    Dim As Long px = (gApp.w - pw) \ 2, py = (gApp.h - ph) \ 2 + Ui_S(20)
    If py < Ui_HeaderH() Then py = Ui_HeaderH()
    Ui_Panel(px, py, pw, ph, 235)
    Dim As Long y = py + pad
    y += Ui_Para(px + pad, y, pw - 2 * pad, desc, fs, gTheme.text) + Ui_S(16)
    y += Sess_BeforeRating(mfSess, px + pad, y, pw - 2 * pad)
    Dim As Long favW = (pw - 2 * pad) * 38 \ 100
    Sess_FavButton(mfSess, IIf(gApp.rtl, px + pw - pad - favW, px + pad), y + Ui_S(5), favW)
    Dim As Long sw = pw - 2 * pad - favW - Ui_S(12)
    If gApp.entering Then Ui_SetFocus("mf.start")
    Return Ui_Button("mf.start", IIf(gApp.rtl, px + pad, px + pad + favW + Ui_S(12)), y, sw, Ui_S(56), L("btn.start"), BTN_PRIMARY, ICON_PLAY)
End Function

' Finish button (top end side under the header) for open-ended activities
Private Function FinishButton() As Boolean
    Dim As Long bw = Ui_S(170), bh = Ui_S(50)
    Return Ui_Button("mf.finish", Ui_MX(gApp.w - bw - Ui_S(16), bw), gApp.h - bh - Ui_S(16), bw, bh, L("btn.finish"), BTN_SOFT, ICON_CHECK)
End Function

' ---------------- Five Senses (5-4-3-2-1) ----------------

Dim Shared As Long fsStage, fsCount
Dim Shared As String fsNote

Private Sub SensesFrame()
    Dim As Single w = gApp.w, h = gApp.h, s = gApp.sc
    If gSet.highContrast Then Cv_Clear(gCv, &hFF000000) Else Cv_VGradient3(gCv, 0, 0, w, h, &hFFFFF1E0, &hFFFDF6EE, &hFFE9F5EC)
    If Ui_Header(L("mind.senses")) Then Sess_Leave(mfSess): App_Go(SCR_MIND_LIST): Exit Sub
    Select Case mfSess.state
    Case SS_INTRO
        If IntroPanel(L("mind.senses.intro")) Then Sess_Begin(mfSess, 0): fsStage = 0: fsCount = 0: fsNote = ""
    Case SS_RUN
        Sess_Tick(mfSess)
        Dim As Long need = 5 - fsStage
        Dim As String senseKey = "senses.s" & fsStage
        Dim As Long icons(0 To 4) = {ICON_EYE, ICON_HAND, ICON_SOUND, ICON_FLOWER, ICON_HEART}
        Dim As ULong cols(0 To 4) = {&hFF8FD3FF, &hFFFFC48A, &hFFB9A2FF, &hFFFF9EB5, &hFF86D3B4}
        ' big number + sense
        Dim As Long cy = Ui_HeaderH() + Ui_S(110)
        Cv_SoftCircle(gCv, w / 2, cy, Ui_S(120), Col_Alpha(cols(fsStage), 150))
        Icon_Draw(icons(fsStage), w / 2, cy, Ui_S(110), IIf(gSet.highContrast, &hFFFFFF00, Col_Mix(cols(fsStage), &hFF000000, 0.35)), gApp.anim)
        Dim As Long fsT = Ui_FS(FS_TITLE)
        Dim As Long y = cy + Ui_S(80)
        Ui_Label(Ui_S(20), y, gApp.w - Ui_S(40), L(senseKey), fsT, gTheme.title, ALIGN_CENTER, FACE_BOLD)
        y += Txt_LineHeight(FACE_BOLD, fsT) + Ui_S(4)
        y += Ui_Para(Ui_S(60), y, gApp.w - Ui_S(120), L(senseKey & ".hint"), Ui_FS(FS_BODY), gTheme.textSoft, ALIGN_CENTER) + Ui_S(14)
        ' dots for what has been noticed so far
        Dim As Long d = Ui_S(40), g = Ui_S(16)
        Dim As Long dw = need * d + (need - 1) * g
        For i As Long = 0 To need - 1
            Dim As Long k = IIf(gApp.rtl, need - 1 - i, i)
            Dim As Single dx = (w - dw) / 2 + k * (d + g) + d / 2
            If i < fsCount Then
                Scene_Flower(gCv, dx, y + d / 2, d * 0.45, 6, cols(fsStage), &hFFFFD86B, 1, gApp.anim * 0.2)
            Else
                Cv_Ring(gCv, dx, y + d / 2, d * 0.4, 2, gTheme.track)
            End If
        Next
        y += d + Ui_S(20)
        ' optional private note (not saved)
        Dim As Long fw = Ui_S(520)
        If fw > w - Ui_S(40) Then fw = w - Ui_S(40)
        Dim As Long entered = Ui_TextField("fs.note", (w - fw) / 2, y, fw, Ui_S(52), fsNote, L("senses.note.hint"), 50)
        y += Ui_S(52) + Ui_S(14)
        Dim As Long bw = Ui_S(300)
        If Ui_Button("fs.noticed", (w - bw) / 2, y, bw, Ui_S(58), L("senses.noticed"), BTN_PRIMARY, ICON_CHECK) OrElse (entered <> 0) Then
            fsCount += 1
            fsNote = ""
            Audio_Play(SND_POP)
            If fsCount >= need Then
                fsStage += 1: fsCount = 0
                Audio_Play(SND_SPARKLE)
                If fsStage > 4 Then Sess_Finish(mfSess, 1)
            End If
        End If
        If gApp.entering = 0 AndAlso mfSess.clk.elapsed < 0.1 Then Ui_SetFocus("fs.noticed")
        If FinishButton() Then Sess_Finish(mfSess, IIf(fsStage >= 3, 1, 0))
    Case SS_DONE
        Select Case Sess_DonePanel(mfSess, L("senses.done"))
        Case 1: mfSess.state = SS_INTRO
        Case 2: Sess_Leave(mfSess): App_Go(SCR_MIND_LIST)
        End Select
    End Select
End Sub

' ---------------- Mindful Observation ----------------

Dim Shared As Long obWander
Dim Shared As Double obWanderT

Private Sub ObserveFrame()
    Dim As Single w = gApp.w, h = gApp.h, s = gApp.sc
    Dim As Double t = gApp.anim * IIf(gSet.reducedMotion, 0.35, 1)
    If gSet.highContrast Then Cv_Clear(gCv, &hFF000000) Else Cv_VGradient3(gCv, 0, 0, w, h, &hFFDDEBFA, &hFFEAF2FB, &hFFF6EFF8)
    ' a feather-like leaf drifting on a slow, smooth path
    Dim As Single px = w / 2 + Sin(t * 0.13) * w * 0.28 + Sin(t * 0.07) * w * 0.06
    Dim As Single py = h * 0.48 + Sin(t * 0.19 + 1) * h * 0.14
    Dim As Single ang = Sin(t * 0.21) * 0.6
    For k As Long = 6 To 1 Step -1
        Dim As Double tk = t - k * 0.35
        Dim As Single qx = w / 2 + Sin(tk * 0.13) * w * 0.28 + Sin(tk * 0.07) * w * 0.06
        Dim As Single qy = h * 0.48 + Sin(tk * 0.19 + 1) * h * 0.14
        Cv_FillCircle(gCv, qx, qy, (8 - k) * s, Col_Alpha(IIf(gSet.highContrast, &hFFFFFFFF, &hFFB0C8F0), 20 + (6 - k) * 12))
    Next
    Cv_SoftCircle(gCv, px, py, 90 * s, Col_Alpha(IIf(gSet.highContrast, &hFF00FFFF, &hFFFFFFFF), 150))
    Scene_Leaf(gCv, px, py, 46 * s, ang, IIf(gSet.highContrast, &hFF00FF00, &hFF8CC9A0))
    If Ui_Header(L("mind.observe")) Then Sess_Leave(mfSess): App_Go(SCR_MIND_LIST): Exit Sub
    Select Case mfSess.state
    Case SS_INTRO
        If IntroPanel(L("mind.observe.intro")) Then Sess_Begin(mfSess, Sess_Minutes(3) * 60): obWander = 0
    Case SS_RUN
        Sess_Tick(mfSess)
        ' a gentle prompt that changes every 25 seconds
        Dim As Long pi_ = (CLng(mfSess.clk.elapsed) \ 25) Mod 6
        Dim As String prompt = L("observe.p" & pi_)
        If gApp.now - obWanderT < 6 Then prompt = L("observe.wander.reply")
        Dim As Long fs = Ui_FS(FS_LARGE)
        Dim As Long pw = Ui_S(760)
        If pw > w - Ui_S(40) Then pw = w - Ui_S(40)
        Dim As Long th = Ui_ParaHeight(prompt, pw - Ui_S(40), fs) + Ui_S(24)
        Dim As Long py2 = Ui_HeaderH() + Ui_S(14)
        Cv_FillRoundRect(gCv, (w - pw) / 2, py2, pw, th, Ui_S(20), Col_Alpha(gTheme.panel, 200))
        Ui_Para((w - pw) / 2 + Ui_S(20), py2 + Ui_S(12), pw - Ui_S(40), prompt, fs, gTheme.text, ALIGN_CENTER)
        Sess_Progress(mfSess, h - Sess_ControlsH() - Ui_S(56))
        ' "my mind wandered" - always answered kindly, never counted against the user
        Dim As Long bw = Ui_S(300)
        If Ui_Button("ob.wander", (w - bw) / 2, h - Sess_ControlsH() - Ui_S(120), bw, Ui_S(50), L("observe.wander"), BTN_SOFT, ICON_CLOUD) Then
            obWanderT = gApp.now: obWander += 1
        End If
        If Sess_Controls(mfSess, 0) Then Sess_Finish(mfSess, IIf(mfSess.clk.elapsed >= mfSess.clk.total * 0.5, 1, 0))
        If Clock_Done(mfSess.clk) Then Sess_Finish(mfSess, 1)
    Case SS_DONE
        Select Case Sess_DonePanel(mfSess, IIf(obWander > 0, L("observe.done.wandered"), ""))
        Case 1: mfSess.state = SS_INTRO
        Case 2: Sess_Leave(mfSess): App_Go(SCR_MIND_LIST)
        End Select
    End Select
End Sub

' ---------------- Thought Clouds ----------------

Const MAXCL = 16
Type ThoughtCloud
    txt As String
    x As Single
    y As Single
    spd As Single
    size As Single
    alive As Long
End Type
Dim Shared As ThoughtCloud tc(0 To MAXCL - 1)
Dim Shared As String tcInput
Dim Shared As Double tcNextAuto

Private Sub AddCloud(ByRef txt As String)
    For i As Long = 0 To MAXCL - 1
        If tc(i).alive = 0 Then
            tc(i).txt = txt
            tc(i).size = (70 + Rnd * 30) * gApp.sc
            tc(i).x = IIf(gApp.rtl, gApp.w + tc(i).size * 2, -tc(i).size * 2)
            tc(i).y = gApp.h * (0.22 + Rnd * 0.4)
            tc(i).spd = (18 + Rnd * 10) * gApp.sc
            tc(i).alive = 1
            Exit Sub
        End If
    Next
End Sub

Private Sub CloudsFrame()
    Dim As Single w = gApp.w, h = gApp.h, s = gApp.sc
    If gSet.highContrast Then Cv_Clear(gCv, &hFF000000) Else Cv_VGradient3(gCv, 0, 0, w, h, &hFF9FD3F5, &hFFCDE9FA, &hFFF1F8FD)
    If gSet.highContrast = 0 Then Scene_Hill(gCv, h * 0.9, 12 * s, 800 * s, 0.6, &hFFA8E0A0)
    ' clouds drift slowly across; they leave on their own - nothing to do with them
    Dim As Single dir_ = IIf(gApp.rtl, -1, 1)
    For i As Long = 0 To MAXCL - 1
        With tc(i)
            If .alive = 0 Then Continue For
            If mfSess.clk.paused = 0 Then .x += dir_ * .spd * gApp.dt * IIf(gSet.reducedMotion, 0.6, 1)
            Dim As Single bob = Sin(gApp.anim * 0.5 + i) * 4 * s * App_Motion()
            Scene_Cloud(gCv, .x, .y + bob, .size, IIf(gSet.highContrast, &hFFFFFFFF, &hF0FFFFFF))
            If Len(.txt) Then
                Dim As Long fs = Ui_FS(FS_BODY)
                Dim As Long tw = .size * 2.1
                Txt_DrawLine(gCv, .x - tw / 2, .y + bob - .size * 0.2 - Txt_LineHeight(FACE_REGULAR, fs) / 2, tw, .txt, FACE_REGULAR, fs, IIf(gSet.highContrast, &hFF000000, &hFF5A6A88), ALIGN_CENTER, DIR_AUTO)
            End If
            If (dir_ > 0 AndAlso .x > w + .size * 2) OrElse (dir_ < 0 AndAlso .x < -.size * 2) Then .alive = 0
        End With
    Next
    If Ui_Header(L("mind.clouds")) Then Sess_Leave(mfSess): App_Go(SCR_MIND_LIST): Exit Sub
    Select Case mfSess.state
    Case SS_INTRO
        If gApp.entering Then
            For i As Long = 0 To MAXCL - 1: tc(i).alive = 0: Next
            For i As Long = 0 To 2
                AddCloud("")
                tc(i).x = w * (0.2 + i * 0.3)
            Next
        End If
        If IntroPanel(L("mind.clouds.intro")) Then Sess_Begin(mfSess, Sess_Minutes(3) * 60): tcInput = "": tcNextAuto = gApp.now + 6
    Case SS_RUN
        Sess_Tick(mfSess)
        Dim As Long fs = Ui_FS(FS_BODY)
        Dim As Long pw = Ui_S(720)
        If pw > w - Ui_S(40) Then pw = w - Ui_S(40)
        Dim As Long py = Ui_HeaderH() + Ui_S(10)
        Dim As String hint = L("clouds.hint")
        Dim As Long th = Ui_ParaHeight(hint, pw - Ui_S(40), fs) + Ui_S(20)
        Cv_FillRoundRect(gCv, (w - pw) / 2, py, pw, th, Ui_S(18), Col_Alpha(gTheme.panel, 200))
        Ui_Para((w - pw) / 2 + Ui_S(20), py + Ui_S(10), pw - Ui_S(40), hint, fs, gTheme.text, ALIGN_CENTER)
        ' typing a thought is optional; it is never saved anywhere
        Dim As Long fw = Ui_S(460), bw = Ui_S(170), gap = Ui_S(12)
        If fw + bw + gap > w - Ui_S(40) Then fw = w - Ui_S(40) - bw - gap
        Dim As Long fx = (w - fw - bw - gap) / 2
        Dim As Long fy = h - Sess_ControlsH() - Ui_S(80)
        Dim As Long ent = Ui_TextField("tc.in", IIf(gApp.rtl, fx + bw + gap, fx), fy, fw, Ui_S(52), tcInput, L("clouds.input.hint"), 40)
        If Ui_Button("tc.add", IIf(gApp.rtl, fx, fx + fw + gap), fy, bw, Ui_S(52), L("clouds.add"), BTN_PRIMARY, ICON_CLOUD) OrElse (ent <> 0) Then
            AddCloud(IIf(Len(Trim(tcInput)), Trim(tcInput), L("clouds.default")))
            tcInput = ""
            Audio_Play(SND_POP)
        End If
        ' quiet background clouds keep drifting by
        If gApp.now > tcNextAuto AndAlso mfSess.clk.paused = 0 Then AddCloud(""): tcNextAuto = gApp.now + 9 + Rnd * 6
        Sess_Progress(mfSess, fy - Ui_S(56))
        If Sess_Controls(mfSess, 0) Then Sess_Finish(mfSess, IIf(mfSess.clk.elapsed >= mfSess.clk.total * 0.5, 1, 0))
        If Clock_Done(mfSess.clk) Then Sess_Finish(mfSess, 1)
    Case SS_DONE
        Select Case Sess_DonePanel(mfSess, L("clouds.done"))
        Case 1: mfSess.state = SS_INTRO
        Case 2: Sess_Leave(mfSess): App_Go(SCR_MIND_LIST)
        End Select
    End Select
End Sub

' ---------------- Gratitude Garden ----------------

Dim Shared As String grInput
Dim Shared As Long grSel = -1
Dim Shared As Double grBloom
Dim Shared As Long grSession     ' notes kept only for this session when tracking is off
Dim Shared As String grTemp(0 To 39)
Dim Shared As Long grTempN

Private Function GrCount() As Long
    If Progress_Tracking() Then Return Progress_GratitudeCount()
    Return grTempN
End Function

Private Function GrText(ByVal i As Long) As String
    If Progress_Tracking() Then Return Progress_Gratitude(i)
    Return grTemp(i)
End Function

Private Sub GratitudeFrame()
    Dim As Single w = gApp.w, h = gApp.h, s = gApp.sc
    If gSet.highContrast Then Cv_Clear(gCv, &hFF000000) Else Cv_VGradient3(gCv, 0, 0, w, h, &hFFCDEBFF, &hFFEAF6FF, &hFFFFF3E3)
    Dim As Single groundY = h * 0.72
    If gSet.highContrast = 0 Then
        Scene_Hill(gCv, groundY, 16 * s, 900 * s, 0.2, &hFFA8E0A0)
        Scene_Hill(gCv, groundY + 50 * s, 10 * s, 700 * s, 1.7, &hFF8CD38F)
    End If
    If Ui_Header(L("mind.gratitude")) Then Sess_Leave(mfSess): App_Go(SCR_MIND_LIST): Exit Sub
    If gApp.entering Then
        grSel = -1: grInput = ""
        Sess_Begin(mfSess, 0, 0)
    End If
    Sess_Tick(mfSess)
    ' one flower per note, planted in rows
    Dim As Long n = GrCount()
    Dim As ULong pcs(0 To 5) = {&hFFFF9EB5, &hFFFFD36E, &hFFB9A2FF, &hFFFF8C8C, &hFF8FD3FF, &hFFFFB38A}
    Dim As Long perRow = CLng(w / (70 * s))
    If perRow < 6 Then perRow = 6
    Dim As Long hoverIdx = -1
    For i As Long = 0 To n - 1
        Dim As Long row = (i \ perRow) Mod 3, col = i Mod perRow
        Dim As Single fx = (col + 0.5 + IIf(row Mod 2, 0.5, 0)) * w / (perRow + 0.5)
        If gApp.rtl Then fx = w - fx
        Dim As Single gy = groundY + 30 * s + row * 40 * s
        Dim As Single fh = (55 + Scene_Rand(i + 7) * 30) * s
        Dim As Single grow = 1
        If i = n - 1 AndAlso gApp.now - grBloom < 1.5 Then grow = Ease_OutCubic((gApp.now - grBloom) / 1.5)
        Dim As Single sway = Sin(gApp.anim * 0.8 + i) * 4 * s * App_Motion()
        Scene_FlowerStem(gCv, fx, gy, gy - fh * grow, sway, &hFF5DAE6A)
        Dim As Single fr = 17 * s * grow
        If Ui_Hover(fx - fr * 1.5, gy - fh * grow - fr * 1.5, fr * 3, fr * 3) Then hoverIdx = i: Plat_SetCursor(CURSOR_HAND)
        Scene_Flower(gCv, fx + sway, gy - fh * grow, fr * IIf(i = grSel OrElse i = hoverIdx, 1.25, 1), 5 + (i Mod 3), pcs(i Mod 6), &hFFFFD86B, 1, i)
        If gIn.mPressed AndAlso hoverIdx = i Then grSel = i
    Next
    If n = 0 Then Ui_Label(0, groundY + Ui_S(50), gApp.w, L("gratitude.empty"), Ui_FS(FS_BODY), gTheme.textSoft, ALIGN_CENTER)
    ' intro + input
    Dim As Long fs = Ui_FS(FS_BODY)
    Dim As Long pw = Ui_S(760)
    If pw > w - Ui_S(40) Then pw = w - Ui_S(40)
    Dim As Long px = (w - pw) / 2, py = Ui_HeaderH() + Ui_S(8)
    Dim As String intro = L("mind.gratitude.intro")
    If Progress_Tracking() = 0 Then intro &= " " & L("gratitude.notsaved")
    Dim As Long ih = Ui_ParaHeight(intro, pw - Ui_S(40), fs)
    Dim As Long ph = ih + Ui_S(20) + Ui_S(52) + Ui_S(24)
    Ui_Panel(px, py, pw, ph, 225)
    Ui_Para(px + Ui_S(20), py + Ui_S(12), pw - Ui_S(40), intro, fs, gTheme.text)
    Dim As Long bw = Ui_S(160), gap = Ui_S(12)
    Dim As Long fw = pw - Ui_S(40) - bw - gap
    Dim As Long fy = py + Ui_S(12) + ih + Ui_S(10)
    Dim As Long ent = Ui_TextField("gr.in", IIf(gApp.rtl, px + Ui_S(20) + bw + gap, px + Ui_S(20)), fy, fw, Ui_S(52), grInput, L("gratitude.hint"), 70)
    If gApp.entering Then Ui_SetFocus("gr.in")
    If (Ui_Button("gr.add", IIf(gApp.rtl, px + Ui_S(20), px + Ui_S(20) + fw + gap), fy, bw, Ui_S(52), L("btn.add"), BTN_PRIMARY, ICON_PLUS) OrElse (ent <> 0)) AndAlso Len(Trim(grInput)) > 0 Then
        If Progress_Tracking() Then
            Progress_AddGratitude(grInput)
        ElseIf grTempN < 40 Then
            grTemp(grTempN) = Progress_Clean(grInput): grTempN += 1
        End If
        grInput = ""
        grBloom = gApp.now
        grSel = GrCount() - 1
        Audio_Play(SND_SPARKLE)
    End If
    ' the selected / hovered note
    Dim As Long show = IIf(hoverIdx >= 0, hoverIdx, grSel)
    If show >= 0 AndAlso show < n Then
        Dim As String note = GrText(show)
        Dim As Long nw = Txt_Width(note, FACE_REGULAR, Ui_FS(FS_LARGE), DIR_AUTO) + Ui_S(60)
        If nw > w - Ui_S(40) Then nw = w - Ui_S(40)
        Dim As Long nh = Txt_LineHeight(FACE_REGULAR, Ui_FS(FS_LARGE)) + Ui_S(24)
        Dim As Long ny = groundY - Ui_S(180)
        Cv_FillRoundRect(gCv, (w - nw) / 2, ny, nw, nh, nh / 2, Col_Alpha(gTheme.panel, 235))
        Txt_DrawLine(gCv, (w - nw) / 2 + Ui_S(30), ny + Ui_S(12), nw - Ui_S(60), note, FACE_REGULAR, Ui_FS(FS_LARGE), gTheme.title, ALIGN_CENTER, DIR_AUTO)
    End If
    ' leaving records the visit (time spent) like any other activity
    If FinishButton() Then
        mfSess.completed = 1
        Sess_Finish(mfSess, 1, 0)
        Sess_Leave(mfSess)
        App_Go(SCR_MIND_LIST)
    End If
End Sub

' ---------------- dispatcher ----------------

Sub Mind_Frame()
    Dim As Long m = gApp.arg
    If m < 0 OrElse m > 4 Then m = 0
    If gApp.entering Then Sess_Reset(mfSess, MAct(m))
    Select Case m
    Case MA_SENSES: SensesFrame()
    Case MA_OBSERVE: ObserveFrame()
    Case MA_CLOUDS: CloudsFrame()
    Case MA_GRATITUDE: GratitudeFrame()
    Case MA_MOMENTS
        If Steps_Frame("moments", ACT_MOMENTS, L("mind.moments"), L("mind.moments.desc")) Then App_Go(SCR_MIND_LIST)
    End Select
End Sub
