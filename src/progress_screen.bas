' progress_screen.bas - "My Progress": totals, a 14-day chart with the optional
' self-ratings, recent sessions, favourites, and the privacy controls.
' Wording avoids any claim that practice proves a change in physiological stress.
#include once "screens.bi"
#include once "scene.bi"
#include once "localization.bi"
#include once "progress.bi"
#include once "bidi.bi"

Dim Shared As Long prConfirm, prScroll

Private Sub StatCard(ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long, ByRef value As String, ByRef label As String, ByVal icon As Long, ByVal tint As ULong)
    Ui_Panel(x, y, w, h, 230)
    Dim As Long isz = h * 40 \ 100
    Dim As Long ix = IIf(gApp.rtl, x + w - Ui_S(16) - isz, x + Ui_S(16))
    Cv_SoftCircle(gCv, ix + isz / 2, y + h / 2, isz * 0.9, Col_Alpha(tint, 120))
    Icon_Draw(icon, ix + isz / 2, y + h / 2, isz, IIf(gSet.highContrast, gTheme.accent, Col_Mix(tint, &hFF000000, 0.35)), 0)
    Dim As Long tx = IIf(gApp.rtl, x + Ui_S(12), x + Ui_S(24) + isz)
    Dim As Long tw = w - isz - Ui_S(40)
    Dim As Long fsV = Ui_FS(FS_TITLE - 4), fsL = Ui_FS(FS_SMALL)
    If Val(value) = 0 AndAlso Left(value, 1) <> "0" Then fsV = Ui_FS(FS_BODY)    ' a name, not a number
    fsV = Txt_FitSize(value, FACE_BOLD, fsV, tw, fsV * 6 \ 10, App_DirText())
    fsL = Txt_FitSize(label, FACE_REGULAR, fsL, tw, fsL * 6 \ 10, App_DirText())
    Dim As Long lhV = Txt_LineHeight(FACE_BOLD, fsV), lhL = Txt_LineHeight(FACE_REGULAR, fsL)
    Dim As Long ty = y + (h - lhV - lhL) \ 2
    Ui_Label(tx, ty, tw, value, fsV, gTheme.title, ALIGN_START, FACE_BOLD)
    Ui_Label(tx, ty + lhV, tw, label, fsL, gTheme.textSoft, ALIGN_START)
End Sub

Private Sub Chart(ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long)
    Ui_Panel(x, y, w, h, 230)
    Dim As Long pad = Ui_S(16)
    Dim As Long fs = Ui_FS(FS_BODY - 1), fsS = Ui_FS(FS_SMALL - 2)
    Ui_Label(x + pad, y + Ui_S(8), w - 2 * pad, L("prog.chart"), fs, gTheme.title, ALIGN_START, FACE_BOLD)
    Const ND = 14
    Dim As Single mins(Any), ab(Any), aa(Any)
    Dim As String labels(Any)
    Progress_Daily(ND, mins(), ab(), aa(), labels())
    Dim As Single mx = 10
    For i As Long = 0 To ND - 1
        If mins(i) > mx Then mx = mins(i)
    Next
    mx = (Int(mx / 10) + 1) * 10
    Dim As Long lhS = Txt_LineHeight(FACE_REGULAR, fsS)
    Dim As Long gx = x + pad + Ui_S(36), gw = w - 2 * pad - Ui_S(72)
    Dim As Long gy = y + Ui_S(14) + Txt_LineHeight(FACE_BOLD, fs), gh = y + h - gy - lhS * 2 - Ui_S(12)
    ' axes: minutes on the start side, ratings 1..5 on the end side
    For k As Long = 0 To 2
        Dim As Long yy = gy + gh - gh * k \ 2
        Cv_FillRect(gCv, gx, yy, gw, 1, Col_Alpha(gTheme.track, 200))
        Dim As String mv = Str(CLng(mx * k / 2))
        Txt_DrawLine(gCv, IIf(gApp.rtl, gx + gw + Ui_S(4), gx - Ui_S(38)), yy - lhS \ 2, Ui_S(34), mv, FACE_REGULAR, fsS, gTheme.textSoft, IIf(gApp.rtl, ALIGN_LEFT, ALIGN_RIGHT), DIR_LTR)
        Txt_DrawLine(gCv, IIf(gApp.rtl, gx - Ui_S(38), gx + gw + Ui_S(4)), yy - lhS \ 2, Ui_S(34), Str(1 + k * 2), FACE_REGULAR, fsS, gTheme.sim, IIf(gApp.rtl, ALIGN_RIGHT, ALIGN_LEFT), DIR_LTR)
    Next
    Dim As Long slot = gw \ ND
    Dim As Single pbx = -1, pby = 0, pax = -1, pay = 0
    For i As Long = 0 To ND - 1
        Dim As Long k = IIf(gApp.rtl, ND - 1 - i, i)    ' time runs in reading direction
        Dim As Long cx = gx + k * slot + slot \ 2
        Dim As Long bh = CLng(gh * mins(i) / mx)
        Dim As Long bw = slot * 55 \ 100
        If bh > 0 Then Cv_FillRoundRect(gCv, cx - bw \ 2, gy + gh - bh, bw, bh, Ui_S(4), IIf(gSet.highContrast, &hFF00FFFF, &hFF9FD8C8))
        ' self-ratings (optional): before = hollow, after = filled
        If ab(i) > 0 Then
            Dim As Single ry = gy + gh - gh * (ab(i) - 1) / 4
            Cv_Ring(gCv, cx, ry, Ui_S(5), 2, gTheme.sim)
        End If
        If aa(i) > 0 Then
            Dim As Single ry = gy + gh - gh * (aa(i) - 1) / 4
            Cv_FillCircle(gCv, cx, ry, Ui_S(5), gTheme.sim)
        End If
        ' day label: day of month, today emphasised
        If i Mod 2 = 1 OrElse i = ND - 1 Then
            Txt_DrawLine(gCv, cx - slot, gy + gh + Ui_S(4), slot * 2, Str(ValInt(Right(labels(i), 2))), IIf(i = ND - 1, FACE_BOLD, FACE_REGULAR), fsS, gTheme.textSoft, ALIGN_CENTER, DIR_LTR)
        End If
    Next
    ' legend
    Dim As Long ly = gy + gh + lhS + Ui_S(6)
    Ui_Label(x + pad, ly, w - 2 * pad, L("prog.legend"), Txt_FitSize(L("prog.legend"), FACE_REGULAR, fsS, w - 2 * pad, fsS * 7 \ 10, App_DirText()), gTheme.textSoft, ALIGN_CENTER)
End Sub

Sub ProgressScr_Frame()
    If gApp.entering Then prConfirm = 0: prScroll = 0: Progress_Reload()
    Scr_Background()
    If Ui_Header(L("menu.progress")) Then App_Go(SCR_MENU): Exit Sub
    Dim As Long margin = Ui_S(20), gap = Ui_S(14)
    Dim As Long top = Ui_HeaderH() + Ui_S(6)
    Dim As Long fs = Ui_FS(FS_BODY)
    If Progress_Tracking() = 0 Then
        ' tracking is off: explain and offer to switch it on
        Dim As Long pw = Ui_S(680)
        If pw > gApp.w - 2 * margin Then pw = gApp.w - 2 * margin
        Dim As Long px = (gApp.w - pw) \ 2
        Dim As Long th = Ui_ParaHeight(L("prog.off"), pw - Ui_S(48), fs)
        Ui_Panel(px, top + Ui_S(40), pw, th + Ui_S(120))
        Ui_Para(px + Ui_S(24), top + Ui_S(64), pw - Ui_S(48), L("prog.off"), fs, gTheme.text)
        If Ui_Toggle("pr.track", px + Ui_S(24), top + Ui_S(64) + th + Ui_S(16), pw - Ui_S(48), Ui_S(50), L("settings.tracking"), gSet.trackingOn) Then
            Progress_SetTracking(gSet.trackingOn): App_SaveSettings()
        End If
        Exit Sub
    End If
    ' summary cards
    Dim As Long cardW = (gApp.w - 2 * margin - 3 * gap) \ 4
    Dim As Long cardH = Txt_LineHeight(FACE_BOLD, Ui_FS(FS_TITLE - 4)) + Txt_LineHeight(FACE_REGULAR, Ui_FS(FS_SMALL)) + Ui_S(24)
    If cardH < Ui_S(96) Then cardH = Ui_S(96)
    Dim As String topAct = Progress_TopAct()
    Dim As Long ta = App_ActFromKey(topAct)
    Dim As String favName = IIf(ta >= 0, App_ActName(ta), "—")
    Dim As String vals(0 To 3) = {Str(Progress_CompletedCount()), Str(Progress_TotalMinutes()), Str(Progress_StreakDays()), favName}
    Dim As String lbls(0 To 3) = {L("prog.sessions.label"), L("prog.minutes.label"), L("prog.days.label"), L("prog.top.label")}
    Dim As Long icons(0 To 3) = {ICON_CHECK, ICON_TIMER, ICON_SUN, ICON_HEART}
    Dim As ULong tints(0 To 3) = {&hFF86D3B4, &hFF8FD3FF, &hFFFFE07A, &hFFFF9EB5}
    For i As Long = 0 To 3
        StatCard(Ui_MX(margin + i * (cardW + gap), cardW), top, cardW, cardH, vals(i), lbls(i), icons(i), tints(i))
    Next
    ' chart
    Dim As Long y = top + cardH + gap
    Dim As Long bottomBar = Ui_S(64)
    Dim As Long avail = gApp.h - y - bottomBar - gap
    Dim As Long chartH = avail * 55 \ 100
    Chart(margin, y, gApp.w - 2 * margin, chartH)
    y += chartH + gap
    ' recent sessions (start side) and favourites (end side)
    Dim As Long listH = avail - chartH - gap
    Dim As Long lw = (gApp.w - 2 * margin - gap) * 62 \ 100, fw = gApp.w - 2 * margin - gap - lw
    Dim As Long lx = Ui_MX(margin, lw), fx = Ui_MX(margin + lw + gap, fw)
    Ui_Panel(lx, y, lw, listH, 230)
    Ui_Panel(fx, y, fw, listH, 230)
    Dim As Long fsS = Ui_FS(FS_SMALL)
    Dim As Long lh = Txt_LineHeight(FACE_REGULAR, fsS) + Ui_S(4)
    Ui_Label(lx + Ui_S(14), y + Ui_S(8), lw - Ui_S(28), L("prog.recent"), fs, gTheme.title, ALIGN_START, FACE_BOLD)
    Dim As Long ry = y + Ui_S(12) + Txt_LineHeight(FACE_BOLD, fs)
    Dim As Long n = Progress_Count()
    If n = 0 Then Ui_Label(lx + Ui_S(14), ry, lw - Ui_S(28), L("prog.empty"), fsS, gTheme.textSoft)
    ' newest first (by date, whatever order the file is in)
    Dim As Long ord(0 To IIf(n > 0, n - 1, 0))
    For i As Long = 0 To n - 1: ord(i) = i: Next
    For i As Long = 1 To n - 1
        Dim As Long k = ord(i), j = i - 1
        Dim As String sk = Progress_Get(k).stamp
        While j >= 0 AndAlso Progress_Get(ord(j)).stamp < sk
            ord(j + 1) = ord(j): j -= 1
        Wend
        ord(j + 1) = k
    Next
    Dim As Long shown = 0
    For oi As Long = 0 To n - 1
        If ry + lh > y + listH - Ui_S(6) Then Exit For
        Dim As SessionRec r = Progress_Get(ord(oi))
        Dim As Long a = App_ActFromKey(r.act)
        Dim As String nm = IIf(a >= 0, App_ActName(a), r.act)
        Dim As String dur = Str(CLng(r.seconds / 60 + 0.4)) & " " & L("unit.min")
        If r.seconds < 60 Then dur = r.seconds & " " & L("unit.s")
        Dim As String rate = ""
        If r.before > 0 OrElse r.after > 0 Then rate = "  " & Bidi_Iso(IIf(r.before > 0, Str(r.before), "–") & "→" & IIf(r.after > 0, Str(r.after), "–"))
        Dim As String dateTxt = Mid(r.stamp, 9, 2) & "/" & Mid(r.stamp, 6, 2) & " " & Mid(r.stamp, 12, 5)
        ' date, name, duration in three columns
        Dim As Long c1 = Txt_Width("00/00 00:00", FACE_REGULAR, fsS, DIR_LTR) + Ui_S(12)
        Dim As Long c3 = Txt_Width("00 " & L("unit.min") & "  0→0", FACE_REGULAR, fsS, DIR_LTR) + Ui_S(8)
        Dim As Long rowX = lx + Ui_S(14), rowW = lw - Ui_S(28)
        Txt_DrawLine(gCv, IIf(gApp.rtl, rowX + rowW - c1, rowX), ry, c1, dateTxt, FACE_REGULAR, fsS, gTheme.textSoft, IIf(gApp.rtl, ALIGN_RIGHT, ALIGN_LEFT), DIR_LTR)
        Ui_Label(IIf(gApp.rtl, rowX + c3, rowX + c1), ry, rowW - c1 - c3, nm & IIf(r.completed, "", " (" & L("prog.partial") & ")"), fsS, gTheme.text)
        Txt_DrawLine(gCv, IIf(gApp.rtl, rowX, rowX + rowW - c3), ry, c3, dur & rate, FACE_REGULAR, fsS, gTheme.textSoft, IIf(gApp.rtl, ALIGN_LEFT, ALIGN_RIGHT), App_DirText())
        ry += lh
        shown += 1
    Next
    ' favourites
    Ui_Label(fx + Ui_S(14), y + Ui_S(8), fw - Ui_S(28), L("prog.favs"), fs, gTheme.title, ALIGN_START, FACE_BOLD)
    Dim As Long fy = y + Ui_S(12) + Txt_LineHeight(FACE_BOLD, fs)
    Dim As Long nf = 0
    For a As Long = 0 To ACT_COUNT - 1
        If Progress_IsFav(App_ActKey(a)) Then
            If fy + lh > y + listH - Ui_S(6) Then Exit For
            Dim As Long hx = IIf(gApp.rtl, fx + fw - Ui_S(30), fx + Ui_S(16))
            Icon_Draw(ICON_HEART, hx + Ui_S(7), fy + lh \ 2, Ui_S(14), &hFFFF8FB1, 0)
            Ui_Label(IIf(gApp.rtl, fx + Ui_S(14), fx + Ui_S(40)), fy, fw - Ui_S(56), App_ActName(a), fsS, gTheme.text)
            fy += lh
            nf += 1
        End If
    Next
    If nf = 0 Then Ui_Para(fx + Ui_S(14), fy, fw - Ui_S(28), L("prog.nofavs"), fsS, gTheme.textSoft)
    ' bottom bar: honest note + delete
    Dim As Long by = gApp.h - bottomBar + Ui_S(6)
    Dim As Long bw = Txt_Width(L("settings.delete"), FACE_BOLD, Ui_FS(FS_BODY), App_DirText()) + Ui_S(90)
    If prConfirm = 0 Then
        If Ui_Button("pr.delete", Ui_MX(gApp.w - margin - bw, bw), by, bw, Ui_S(50), L("settings.delete"), BTN_SOFT, ICON_TRASH) Then prConfirm = 1
        Ui_Label(Ui_MX(margin, gApp.w - 2 * margin - bw - gap), by + Ui_S(4), gApp.w - 2 * margin - bw - gap, L("prog.note"), Ui_FS(FS_SMALL - 1), IIf(gSet.highContrast, &hFFFFFFFF, gTheme.textSoft))
    Else
        Dim As Long bw2 = Ui_S(200)
        Ui_Label(Ui_MX(margin, gApp.w - 2 * margin - 2 * bw2 - 2 * gap), by + Ui_S(12), gApp.w - 2 * margin - 2 * bw2 - 2 * gap, L("prog.delete.ask"), fs, gTheme.text)
        If Ui_Button("pr.delyes", Ui_MX(gApp.w - margin - 2 * bw2 - gap, bw2), by, bw2, Ui_S(50), L("settings.delete.yes"), BTN_PRIMARY, ICON_TRASH) Then
            Progress_DeleteAll(): prConfirm = 0: Ui_Toast(L("settings.delete.done"))
        End If
        If Ui_Button("pr.delno", Ui_MX(gApp.w - margin - bw2, bw2), by, bw2, Ui_S(50), L("btn.cancel"), BTN_NORMAL) Then prConfirm = 0
    End If
End Sub
