' menu.bas - main menu, About screen and helpers shared by the list screens
#include once "screens.bi"
#include once "scene.bi"
#include once "localization.bi"
#include once "audio.bi"
#include once "progress.bi"

' A text section whose first line is a bold heading; returns the height used
Function Scr_Section(ByVal x As Long, ByVal y As Long, ByVal w As Long, ByRef txt As String, ByVal fs As Long, ByVal doDraw As Long = 1) As Long
    Dim As Long p = InStr(txt, !"\n")
    Dim As String head = IIf(p > 0, Left(txt, p - 1), txt)
    Dim As String body = IIf(p > 0, Mid(txt, p + 1), "")
    Dim As Long h = 0
    If doDraw Then
        h = Txt_Wrap(gCv, x, y, w, head, FACE_BOLD, fs + 2, gTheme.title, ALIGN_START, App_DirText())
        If Len(body) Then h += Txt_Wrap(gCv, x, y + h, w, body, FACE_REGULAR, fs, gTheme.text, ALIGN_START, App_DirText())
    Else
        h = Txt_WrapHeight(head, w, FACE_BOLD, fs + 2, App_DirText())
        If Len(body) Then h += Txt_WrapHeight(body, w, FACE_REGULAR, fs, App_DirText())
    End If
    Return h
End Function

Sub Scr_Background()
    Scene_MenuBackground(gCv, gApp.anim, gSet.theme, App_Motion(), gSet.highContrast)
End Sub

' Grid of big tiles centred below "top". Returns the index chosen, or -1.
Function Scr_TileGrid(ByRef idPrefix As String, labels() As String, icons() As Long, tints() As ULong, ByVal n As Long, ByVal cols As Long, ByVal top As Long, descs() As String) As Long
    Dim As Long rows = (n + cols - 1) \ cols
    Dim As Long gap = Ui_S(20)
    Dim As Long availW = gApp.w - Ui_S(80)
    Dim As Long availH = gApp.h - top - Ui_S(70)
    Dim As Long tw = (availW - gap * (cols - 1)) \ cols
    Dim As Long th = (availH - gap * (rows - 1)) \ rows
    If tw > Ui_S(300) Then tw = Ui_S(300)
    If th > Ui_S(200) Then th = Ui_S(200)
    If th > tw Then th = tw
    Dim As Long gridW = cols * tw + (cols - 1) * gap
    Dim As Long x0 = (gApp.w - gridW) \ 2
    Dim As Long chosen = -1
    Dim As Long hovered = -1
    For i As Long = 0 To n - 1
        Dim As Long cx = i Mod cols, cy = i \ cols
        Dim As Long x = Ui_MX(x0 + cx * (tw + gap), tw)
        Dim As Long y = top + cy * (th + gap)
        If Ui_Button(idPrefix & i, x, y, tw, th, labels(i), BTN_TILE, icons(i), tints(i)) Then chosen = i
        If Ui_Hover(x, y, tw, th) OrElse Ui_HasFocus(idPrefix & i) Then hovered = i
    Next
    ' description of the hovered/focused tile at the bottom
    If hovered >= 0 AndAlso Len(descs(hovered)) Then
        Dim As Long fs = Ui_FS(FS_BODY)
        Dim As Long y = top + rows * (th + gap) + Ui_S(4)
        If y + Txt_LineHeight(FACE_REGULAR, fs) < gApp.h Then
            Dim As Long w = gApp.w - Ui_S(120)
            Dim As Long bh = Txt_LineHeight(FACE_REGULAR, fs) + Ui_S(12)
            Cv_FillRoundRect(gCv, Ui_S(60), y, w, bh, bh / 2, Col_Alpha(gTheme.panel, 200))
            Ui_Label(Ui_S(60), y + Ui_S(6), w, descs(hovered), fs, gTheme.text, ALIGN_CENTER)
        End If
    End If
    Return chosen
End Function

' Simple drawn faces 1 (not so good) .. 5 (very calm). Child-friendly, no judgement.
Sub Scr_DrawRatingFace(ByVal cx As Single, ByVal cy As Single, ByVal r As Single, ByVal v As Long, ByVal col As ULong)
    Cv_FillCircle(gCv, cx, cy, r, col)
    Dim As ULong ink = &hFF3B3A5A
    Cv_FillCircle(gCv, cx - r * 0.33, cy - r * 0.2, r * 0.1, ink)
    Cv_FillCircle(gCv, cx + r * 0.33, cy - r * 0.2, r * 0.1, ink)
    ' mouth: curvature from -1 (down) to +1 (smile)
    Dim As Single curv = (v - 3) / 2.0
    Dim As Single px = 0, py = 0
    For i As Long = 0 To 10
        Dim As Single f = i / 10 * 2 - 1
        Dim As Single xx = cx + f * r * 0.42
        Dim As Single yy = cy + r * 0.32 + (1 - f * f) * curv * r * 0.22 - curv * r * 0.05
        If i > 0 Then Cv_Line(gCv, px, py, xx, yy, r * 0.08 + 1, ink)
        px = xx: py = yy
    Next
End Sub

Function Scr_RatingRow(ByRef id As String, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByRef current As Long) As Long
    Dim As ULong cols(1 To 5) = {&hFFB9C6E8, &hFFC9DDF2, &hFFE6EEC6, &hFFC7EBCB, &hFFA8E3C0}
    Dim As Long sz = Ui_S(64)
    Dim As Long gap = (w - 5 * sz) \ 4
    If gap > Ui_S(30) Then gap = Ui_S(30)
    Dim As Long total = 5 * sz + 4 * gap
    Dim As Long x0 = x + (w - total) \ 2
    Dim As Long picked = 0
    For v As Long = 1 To 5
        Dim As Long bx = Ui_MX(x0 + (v - 1) * (sz + gap), sz)
        If gApp.rtl Then bx = x0 + (5 - v) * (sz + gap)
        If Ui_Button(id & "." & v, bx, y, sz, sz, "", BTN_SOFT) Then picked = v: current = v
        Dim As Single sc = IIf(current = v, 1.0, 0.82)
        Scr_DrawRatingFace(bx + sz / 2, y + sz / 2, sz * 0.4 * sc, v, IIf(gSet.highContrast, IIf(current = v, &hFFFFFF00, &hFFFFFFFF), cols(v)))
        If current = v Then Cv_Ring(gCv, bx + sz / 2, y + sz / 2, sz * 0.47, Ui_S(3), gTheme.primary)
    Next
    Dim As Long fs = Ui_FS(FS_SMALL)
    Dim As Long ly = y + sz + Ui_S(4)
    Ui_Label(x0, ly, total, L("rate.low") & "   " & Chr(&hE2, &h80, &hA6) & "   " & L("rate.high"), fs, gTheme.textSoft, ALIGN_CENTER)
    Return picked
End Function

' ---------------- main menu ----------------

Sub Menu_Frame()
    If gApp.entering Then
        Audio_SetAmbient(IIf(gSet.musicOn, AMB_MUSIC, -1))
    End If
    Scr_Background()
    ' title
    Dim As Long fsT = Ui_FS(FS_HUGE)
    Dim As Long ty = Ui_S(26)
    Dim As Single bob = Sin(gApp.anim * 0.8) * Ui_S(3) * App_Motion()
    Dim As String title = L("app.name")
    Dim As Long tw = Txt_Width(title, FACE_BOLD, fsT, App_DirText())
    Dim As Long iconSz = Ui_S(54)
    Dim As Long tx = (gApp.w - tw - iconSz - Ui_S(14)) \ 2
    Dim As Long fx = IIf(gApp.rtl, tx + tw + Ui_S(14), tx), lx = IIf(gApp.rtl, tx, tx + iconSz + Ui_S(14))
    Scene_Flower(gCv, fx + iconSz / 2, ty + Txt_LineHeight(FACE_BOLD, fsT) / 2 + bob, iconSz * 0.48, 7, IIf(gSet.highContrast, &hFFFFFF00, &hFFFF9EB5), &hFFFFD86B, 1, gApp.anim * 0.15 * App_Motion())
    Txt_Draw(gCv, lx, ty + CLng(bob), title, FACE_BOLD, fsT, gTheme.title, App_DirText())
    Dim As Long fsS = Ui_FS(FS_BODY)
    Dim As Long sy = ty + Txt_LineHeight(FACE_BOLD, fsT)
    Ui_Label(0, sy, gApp.w, L("app.tagline"), fsS, gTheme.textSoft, ALIGN_CENTER)

    Dim As String labels(0 To 8), descs(0 To 8)
    Dim As String keys(0 To 8) = {"breath", "relax", "mind", "bio", "games", "timer", "progress", "settings", "about"}
    Dim As Long icons(0 To 8) = {ICON_WIND, ICON_MOON, ICON_LOTUS, ICON_WAVE, ICON_KITE, ICON_TIMER, ICON_CHART, ICON_GEAR, ICON_INFO}
    Dim As ULong tints(0 To 8) = {&hFF8FD3FF, &hFFB9A2FF, &hFFFF9EB5, &hFFFFC48A, &hFF86D3B4, &hFFFFE07A, &hFF9FD8C8, &hFFC8C8E0, &hFFD8C8F0}
    For i As Long = 0 To 8
        labels(i) = L("menu." & keys(i))
        descs(i) = L("menu." & keys(i) & ".desc")
    Next
    Dim As Long top = sy + Txt_LineHeight(FACE_REGULAR, fsS) + Ui_S(18)
    Dim As Long pick = Scr_TileGrid("menu.", labels(), icons(), tints(), 9, 3, top, descs())
    Select Case pick
    Case 0: App_Go(SCR_BREATH_LIST)
    Case 1: App_Go(SCR_RELAX_LIST)
    Case 2: App_Go(SCR_MIND_LIST)
    Case 3: App_Go(SCR_BIO)
    Case 4: App_Go(SCR_GAME_LIST)
    Case 5: App_Go(SCR_TIMER)
    Case 6: App_Go(SCR_PROGRESS)
    Case 7: App_Go(SCR_SETTINGS)
    Case 8: App_Go(SCR_ABOUT)
    End Select
    ' small, always-visible disclaimer
    Dim As Long fsD = Ui_FS(FS_SMALL)
    Ui_Label(Ui_S(20), gApp.h - Txt_LineHeight(FACE_REGULAR, fsD) - Ui_S(10), gApp.w - Ui_S(40), L("disclaimer.short"), fsD, IIf(gSet.highContrast, &hFFFFFFFF, gTheme.textSoft), ALIGN_CENTER)
    If Ui_Key(KEY_ESC) Then Ui_Toast(L("menu.quit_hint"))
End Sub

' ---------------- About ----------------

Sub About_Frame()
    Scr_Background()
    If Ui_Header(L("about.title")) Then App_Go(SCR_MENU): Exit Sub
    Dim As Long hh = Ui_HeaderH()
    Dim As Long pw = gApp.w - Ui_S(120)
    If pw > Ui_S(900) Then pw = Ui_S(900)
    Dim As Long px = (gApp.w - pw) \ 2, py = hh + Ui_S(8)
    Dim As Long ph = gApp.h - py - Ui_S(24)
    Ui_Panel(px, py, pw, ph)
    Static As Long scrollY
    If gApp.entering Then scrollY = 0
    Dim As Long pad = Ui_S(28)
    Dim As Long fs = Ui_FS(FS_BODY)
    Dim As String secs(0 To 4) = {L("about.body"), L("disclaimer.full"), L("about.privacy"), L("about.keys"), L("about.credits")}
    Dim As Long fsT = Ui_FS(FS_TITLE)
    Dim As Long gapS = Ui_S(18)
    Dim As Long contentH = Txt_LineHeight(FACE_BOLD, fsT) + Ui_S(12)
    For i As Long = 0 To 4
        contentH += Scr_Section(0, 0, pw - 2 * pad, secs(i), fs, 0) + gapS
    Next
    Dim As Long viewH = ph - 2 * pad
    If Ui_Hover(px, py, pw, ph) Then scrollY -= gIn.wheel * Ui_S(50)
    If Ui_Key(KEY_PGDN) Then scrollY += viewH * 3 \ 4
    If Ui_Key(KEY_PGUP) Then scrollY -= viewH * 3 \ 4
    If Ui_Key(KEY_DOWN) Then scrollY += Ui_S(40)
    If Ui_Key(KEY_UP) Then scrollY -= Ui_S(40)
    If scrollY > contentH - viewH Then scrollY = contentH - viewH
    If scrollY < 0 Then scrollY = 0
    Cv_PushClip(gCv, px + 2, py + pad, pw - 4, viewH)
    Dim As Long y = py + pad - scrollY
    Ui_Label(px + pad, y, pw - 2 * pad, L("app.name") & "  1.0.0", fsT, gTheme.title, ALIGN_START, FACE_BOLD)
    y += Txt_LineHeight(FACE_BOLD, fsT) + Ui_S(12)
    For i As Long = 0 To 4
        y += Scr_Section(px + pad, y, pw - 2 * pad, secs(i), fs) + gapS
    Next
    Cv_PopClip(gCv)
    ' scroll indicator
    If contentH > viewH Then
        Dim As Long bh = viewH * viewH \ contentH
        Dim As Long by = py + pad + (viewH - bh) * scrollY \ (contentH - viewH)
        Dim As Long bx = IIf(gApp.rtl, px + Ui_S(8), px + pw - Ui_S(14))
        Cv_FillRoundRect(gCv, bx, by, Ui_S(6), bh, Ui_S(3), Col_Alpha(gTheme.textSoft, 120))
    End If
End Sub
