' ui.bas - immediate-mode widgets (see ui.bi)
#include once "ui.bi"
#include once "scene.bi"
#include once "localization.bi"
#include once "audio.bi"
#include once "bidi.bi"

Dim Shared gTheme As UiTheme

' ---- focus bookkeeping ----
Const MAXF = 160
Const FK_BUTTON = 0
Const FK_SLIDER = 1
Const FK_TEXT = 2

Dim Shared As String fIds(0 To MAXF - 1), fPrevIds(0 To MAXF - 1)
Dim Shared As Long fKinds(0 To MAXF - 1), fPrevKinds(0 To MAXF - 1)
Dim Shared As Long fN, fPrevN
Dim Shared As String focusId, activateId
Dim Shared As Long focusVis
Dim Shared As Long keyUsed(0 To 31)
Dim Shared As Long sliderDelta     ' -1 / +1 for the focused slider/choice this frame
Dim Shared As String testAct
Dim Shared As String toastMsg
Dim Shared As Double toastT

' ---- animation values keyed by id ----
Const AN_SIZE = 512
Dim Shared As String anKey(0 To AN_SIZE - 1)
Dim Shared As Single anVal(0 To AN_SIZE - 1)

Private Function HashId(ByRef s As String) As ULong
    Dim As ULong v = 2166136261
    For i As Long = 0 To Len(s) - 1
        v = (v Xor s[i]) * 16777619
    Next
    Return v
End Function

Function Ui_Anim(ByRef id As String, ByVal target As Single, ByVal speed As Single = 8) As Single
    Dim As Long slot = HashId(id) And (AN_SIZE - 1)
    If anKey(slot) <> id Then anKey(slot) = id: anVal(slot) = target
    Dim As Single k = gApp.dt * speed
    If gSet.reducedMotion Then k = 1
    If k > 1 Then k = 1
    anVal(slot) += (target - anVal(slot)) * k
    Return anVal(slot)
End Function

Sub Ui_ApplyTheme()
    With gTheme
        If gSet.highContrast Then
            .bgTop = &hFF000000: .bgMid = &hFF000000: .bgBot = &hFF101010
            .panel = &hFF000000: .panelEdge = &hFFFFFFFF
            .text = &hFFFFFFFF: .textSoft = &hFFF0F0F0: .title = &hFFFFFF00
            .accent = &hFFFFFF00: .accent2 = &hFF00FFFF
            .btn = &hFF000000: .btnHover = &hFF303030: .btnText = &hFFFFFFFF
            .primary = &hFFFFFF00: .primaryText = &hFF000000
            .focus = &hFF00FFFF: .track = &hFF808080: .shadow = &h00000000
            .sim = &hFFFFFF00
            .playful = 0
        ElseIf gSet.adultStyle Then
            .bgTop = &hFFDCE6EA: .bgMid = &hFFEEF2F1: .bgBot = &hFFF6F3EE
            .panel = &hFFFBFBF9: .panelEdge = &hFFCCD6D6
            .text = &hFF2C3A40: .textSoft = &hFF56666C: .title = &hFF2F4F55
            .accent = &hFF6F9A96: .accent2 = &hFFB59E7D
            .btn = &hFFFFFFFF: .btnHover = &hFFEDF3F2: .btnText = &hFF2C3A40
            .primary = &hFF5E8C86: .primaryText = &hFFFFFFFF
            .focus = &hFF3F6FA8: .track = &hFFC8D2D2: .shadow = &h22000000
            .sim = &hFF9A6B2F
            .playful = 0
        Else
            .bgTop = &hFFBFE3FF: .bgMid = &hFFE6F4FF: .bgBot = &hFFFDE9F2
            .panel = &hFFFFFFFF: .panelEdge = &hFFE3D9F2
            .text = &hFF3B3A5A: .textSoft = &hFF5E5C80: .title = &hFF5A4B9A
            .accent = &hFFFF9EB5: .accent2 = &hFF86D3B4
            .btn = &hFFFFFFFF: .btnHover = &hFFFFF4DA: .btnText = &hFF3B3A5A
            .primary = &hFF5FBF98: .primaryText = &hFFFFFFFF
            .focus = &hFF5B7CFF: .track = &hFFE2DDF0: .shadow = &h28503C78
            .sim = &hFFB5651D
            .playful = 1
        End If
    End With
End Sub

Function Ui_S(ByVal v As Single) As Long
    Return CLng(v * gApp.sc)
End Function

Function Ui_FS(ByVal basePx As Long) As Long
    Dim As Single f = basePx * gApp.sc * gSet.fontPct / 100.0
    If gSet.childMode Then f *= 1.1
    If f < 10 Then f = 10
    Return CLng(f)
End Function

Function Ui_MX(ByVal x As Long, ByVal w As Long) As Long
    If gApp.rtl Then Return gApp.w - x - w
    Return x
End Function

Function Ui_FocusVisible() As Boolean
    Return focusVis <> 0
End Function

Function Ui_Hover(ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long) As Boolean
    Return gIn.mx >= x AndAlso gIn.mx < x + w AndAlso gIn.my >= y AndAlso gIn.my < y + h
End Function

Function Ui_Clicked(ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long) As Boolean
    Return gIn.mPressed <> 0 AndAlso Ui_Hover(x, y, w, h)
End Function

Function Ui_Key(ByVal k As Long, ByVal mods As Long = 0) As Boolean
    For i As Long = 0 To gIn.keyN - 1
        If keyUsed(i) = 0 AndAlso gIn.keys(i) = k AndAlso (gIn.keyMods(i) And (KM_CTRL Or KM_ALT)) = (mods And (KM_CTRL Or KM_ALT)) Then
            keyUsed(i) = 1
            Return True
        End If
    Next
    Return False
End Function

Sub Ui_ConsumeKey(ByVal k As Long)
    For i As Long = 0 To gIn.keyN - 1
        If gIn.keys(i) = k Then keyUsed(i) = 1
    Next
End Sub

Sub Ui_TestActivate(ByRef id As String)
    testAct = id
End Sub

Sub Ui_SetFocus(ByRef id As String)
    focusId = id
End Sub

Function Ui_HasFocus(ByRef id As String) As Boolean
    Return focusId = id
End Function

Dim Shared As Long focY = -1, focH

Private Sub Register(ByRef id As String, ByVal kind As Long, ByVal y As Long = -1, ByVal h As Long = 0)
    If fN < MAXF Then fIds(fN) = id: fKinds(fN) = kind: fN += 1
    If id = focusId AndAlso y >= 0 Then focY = y: focH = h
End Sub

' position of the focused widget in the last frame (-1 = none); lets scrolling panels follow the keyboard
Function Ui_FocusY(ByRef h As Long) As Long
    h = focH
    If focusVis = 0 Then Return -1
    Return focY
End Function

Private Function PrevIndexOf(ByRef id As String) As Long
    For i As Long = 0 To fPrevN - 1
        If fPrevIds(i) = id Then Return i
    Next
    Return -1
End Function

Private Sub MoveFocus(ByVal d As Long)
    If fPrevN = 0 Then Exit Sub
    Dim As Long i = PrevIndexOf(focusId)
    If i < 0 Then
        ' first Tab: start with the content, not the header buttons (Esc is "back" anyway)
        i = IIf(d > 0, 0, fPrevN - 1)
        If d > 0 Then
            For k As Long = 0 To fPrevN - 1
                If Left(fPrevIds(k), 4) <> "hdr." Then i = k: Exit For
            Next
        End If
    Else
        i = (i + d + fPrevN) Mod fPrevN
    End If
    focusId = fPrevIds(i)
    focusVis = 1
End Sub

Sub Ui_BeginFrame()
    ' remember last frame's focus chain
    For i As Long = 0 To fN - 1
        fPrevIds(i) = fIds(i): fPrevKinds(i) = fKinds(i)
    Next
    fPrevN = fN
    fN = 0
    focY = -1
    activateId = ""
    sliderDelta = 0
    For i As Long = 0 To 31: keyUsed(i) = 0: Next
    If gApp.entering Then focusId = "": focusVis = 0
    If Len(testAct) Then activateId = testAct: focusId = testAct: testAct = ""
    If gIn.mPressed Then focusVis = 0
    Dim As Long fi = PrevIndexOf(focusId)
    Dim As Long kind = IIf(fi >= 0, fPrevKinds(fi), -1)
    For i As Long = 0 To gIn.keyN - 1
        Dim As Long k = gIn.keys(i), m = gIn.keyMods(i)
        Select Case k
        Case KEY_TAB
            MoveFocus(IIf(m And KM_SHIFT, -1, 1)): keyUsed(i) = 1
        Case KEY_DOWN
            MoveFocus(1): keyUsed(i) = 1
        Case KEY_UP
            MoveFocus(-1): keyUsed(i) = 1
        Case KEY_LEFT, KEY_RIGHT
            Dim As Long d = IIf(k = KEY_RIGHT, 1, -1)
            If kind = FK_SLIDER Then
                sliderDelta = IIf(gApp.rtl, -d, d): keyUsed(i) = 1: focusVis = 1
            ElseIf kind = FK_TEXT Then
                keyUsed(i) = 1
            Else
                MoveFocus(IIf(gApp.rtl, -d, d)): keyUsed(i) = 1
            End If
        Case KEY_ENTER, KEY_SPACE
            If fi >= 0 AndAlso Not (kind = FK_TEXT AndAlso k = KEY_SPACE) AndAlso (focusVis <> 0 OrElse kind = FK_TEXT) Then
                activateId = focusId: keyUsed(i) = 1
            End If
        End Select
    Next
End Sub

Sub Ui_Toast(ByRef msg As String)
    toastMsg = msg
    toastT = gApp.now
End Sub

Sub Ui_EndFrame()
    If Len(toastMsg) AndAlso gApp.now - toastT < 2.8 Then
        Dim As Single a = 1
        Dim As Single age = gApp.now - toastT
        If age > 2.2 Then a = (2.8 - age) / 0.6
        Dim As Long fs = Ui_FS(FS_BODY)
        Dim As Long tw = Txt_Width(toastMsg, FACE_REGULAR, fs, App_DirText()) + Ui_S(48)
        Dim As Long th = Ui_S(54)
        Dim As Long x = (gApp.w - tw) \ 2, y = gApp.h - th - Ui_S(28)
        Cv_FillRoundRect(gCv, x, y, tw, th, th / 2, Col_Alpha(gTheme.title, CLng(230 * a)))
        Txt_DrawLine(gCv, x, y + (th - Txt_LineHeight(FACE_REGULAR, fs)) \ 2, tw, toastMsg, FACE_REGULAR, fs, Col_Alpha(&hFFFFFFFF, CLng(255 * a)), ALIGN_CENTER, App_DirText())
    End If
    ' focus that disappeared (screen changed) is dropped
    Dim As Long found = 0
    For i As Long = 0 To fN - 1
        If fIds(i) = focusId Then found = 1: Exit For
    Next
    If found = 0 AndAlso fN > 0 AndAlso Len(focusId) > 0 Then focusId = ""
End Sub

Private Sub DrawFocus(ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long, ByVal r As Single)
    Dim As Long g = Ui_S(4)
    Cv_RoundRectOutline(gCv, x - g, y - g, w + 2 * g, h + 2 * g, r + g, Ui_S(3) + 1, gTheme.focus)
End Sub

Private Function Radius(ByVal h As Long) As Single
    If gTheme.playful Then Return h * 0.42
    Return h * 0.22
End Function

Sub Ui_Panel(ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long, ByVal alpha As Long = 225)
    Dim As Single r = IIf(gTheme.playful, Ui_S(26), Ui_S(12))
    If gTheme.shadow Then Cv_FillRoundRect(gCv, x + Ui_S(3), y + Ui_S(6), w, h, r, gTheme.shadow)
    Cv_FillRoundRect(gCv, x, y, w, h, r, Col_Alpha(gTheme.panel, IIf(gSet.highContrast, 255, alpha)))
    Cv_RoundRectOutline(gCv, x, y, w, h, r, IIf(gSet.highContrast, 2, 1.5), gTheme.panelEdge)
End Sub

Function Ui_Button(ByRef id As String, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long, ByRef label As String, ByVal kind As Long = BTN_NORMAL, ByVal icon As Long = -1, ByVal tint As ULong = 0) As Boolean
    Register(id, FK_BUTTON, y, h)
    Dim As Boolean hov = Ui_Hover(x, y, w, h)
    Dim As Boolean clicked = (gIn.mPressed <> 0 AndAlso hov) OrElse activateId = id
    If (gIn.mPressed <> 0) AndAlso hov Then focusId = id
    If hov Then Plat_SetCursor(CURSOR_HAND)
    Dim As Single hv = Ui_Anim(id & "#h", IIf(hov OrElse CBool(focusVis <> 0 AndAlso focusId = id), 1.0, 0.0))
    Dim As Long lift = CLng(hv * Ui_S(3) * App_Motion())
    Dim As Single r = Radius(h)
    If kind = BTN_TILE Then r = IIf(gTheme.playful, Ui_S(28), Ui_S(12))
    Dim As ULong bg, fg
    Select Case kind
    Case BTN_PRIMARY
        bg = gTheme.primary: fg = gTheme.primaryText
        If hv > 0 Then bg = Col_Mix(bg, &hFFFFFFFF, hv * 0.15)
    Case BTN_SOFT
        bg = Col_Alpha(gTheme.btn, 170): fg = gTheme.btnText
        If hv > 0 Then bg = Col_Mix(bg, gTheme.btnHover, hv)
    Case Else
        bg = Col_Mix(gTheme.btn, gTheme.btnHover, hv): fg = gTheme.btnText
    End Select
    If tint <> 0 AndAlso gSet.highContrast = 0 Then bg = Col_Mix(bg, tint, IIf(kind = BTN_TILE, 0.35 + hv * 0.15, 0.25))
    Dim As Long yy = y - lift
    If gTheme.shadow Then Cv_FillRoundRect(gCv, x + Ui_S(2), y + Ui_S(5), w, h, r, gTheme.shadow)
    Cv_FillRoundRect(gCv, x, yy, w, h, r, bg)
    If gSet.highContrast Then Cv_RoundRectOutline(gCv, x, yy, w, h, r, 2, gTheme.panelEdge)
    If (focusVis <> 0) AndAlso focusId = id Then DrawFocus(x, yy, w, h, r)
    Dim As Long dirT = App_DirText()
    If kind = BTN_TILE Then
        Dim As Long isz = CLng(h * 0.46)
        If icon >= 0 Then Icon_Draw(icon, x + w / 2, yy + h * 0.38, isz, IIf(gSet.highContrast, gTheme.accent, IIf(tint, Col_Mix(tint, &hFF000000, 0.35), gTheme.title)), gApp.anim * hv)
        Dim As Long fs = Txt_FitSize(label, FACE_BOLD, Ui_FS(FS_BODY), w - Ui_S(16), Ui_FS(FS_BODY) * 6 \ 10, dirT)
        Txt_DrawLine(gCv, x + Ui_S(8), yy + CLng(h * 0.72) - Txt_LineHeight(FACE_BOLD, fs) \ 2, w - Ui_S(16), label, FACE_BOLD, fs, fg, ALIGN_CENTER, dirT)
    Else
        Dim As Long fs = Ui_FS(FS_BODY)
        Dim As Long avail = w - Ui_S(20) - IIf(icon >= 0, CLng(h * 0.5) + Ui_S(10), 0)
        fs = Txt_FitSize(label, FACE_BOLD, fs, avail, fs * 7 \ 10, dirT)
        Dim As Long lh = Txt_LineHeight(FACE_BOLD, fs)
        If icon >= 0 Then
            Dim As Long isz = CLng(h * 0.5)
            Dim As Long tw = Txt_Width(label, FACE_BOLD, fs, dirT)
            Dim As Long gap = IIf(Len(label), Ui_S(10), 0)
            Dim As Long total = isz + gap + tw
            If total > w - Ui_S(16) Then total = w - Ui_S(16)
            Dim As Long sx = x + (w - total) \ 2
            Dim As Long ix = IIf(gApp.rtl, sx + total - isz, sx)
            Dim As Long tx = IIf(gApp.rtl, sx, sx + isz + gap)
            Icon_Draw(icon, ix + isz / 2, yy + h / 2, isz, fg, 0)
            If Len(label) Then Txt_DrawLine(gCv, tx, yy + (h - lh) \ 2, total - isz - gap, label, FACE_BOLD, fs, fg, ALIGN_CENTER, dirT)
        Else
            Txt_DrawLine(gCv, x + Ui_S(10), yy + (h - lh) \ 2, w - Ui_S(20), label, FACE_BOLD, fs, fg, ALIGN_CENTER, dirT)
        End If
    End If
    If clicked Then Audio_Play(SND_CLICK)
    Return clicked
End Function

Function Ui_Toggle(ByRef id As String, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long, ByRef label As String, ByRef v As Long) As Boolean
    Register(id, FK_BUTTON, y, h)
    Dim As Boolean hov = Ui_Hover(x, y, w, h)
    Dim As Boolean clicked = (gIn.mPressed <> 0 AndAlso hov) OrElse activateId = id
    If (gIn.mPressed <> 0) AndAlso hov Then focusId = id
    If hov Then Plat_SetCursor(CURSOR_HAND)
    If clicked Then v = IIf(v, 0, 1): Audio_Play(SND_CLICK)
    Dim As Single on_ = Ui_Anim(id & "#t", IIf(v, 1.0, 0.0), 10)
    Dim As Long sw = Ui_S(60), sh = Ui_S(32)
    Dim As Long sx = Ui_MX(x + w - sw, sw) , sy = y + (h - sh) \ 2
    If gApp.rtl Then sx = x
    Dim As ULong tr = Col_Mix(gTheme.track, gTheme.primary, on_)
    Cv_FillRoundRect(gCv, sx, sy, sw, sh, sh / 2, tr)
    Dim As Single kx = IIf(gApp.rtl, sx + sw - sh / 2 - on_ * (sw - sh), sx + sh / 2 + on_ * (sw - sh))
    Cv_FillCircle(gCv, kx, sy + sh / 2, sh / 2 - Ui_S(3), IIf(gSet.highContrast, &hFF000000, &hFFFFFFFF))
    Dim As Long fs = Ui_FS(FS_BODY)
    Dim As Long lx = IIf(gApp.rtl, x + sw + Ui_S(12), x)
    Txt_DrawLine(gCv, lx, y + (h - Txt_LineHeight(FACE_REGULAR, fs)) \ 2, w - sw - Ui_S(12), label, FACE_REGULAR, fs, gTheme.text, ALIGN_START, App_DirText())
    If (focusVis <> 0) AndAlso focusId = id Then DrawFocus(x, y, w, h, Ui_S(10))
    Return clicked
End Function

Function Ui_Slider(ByRef id As String, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long, ByRef label As String, ByRef v As Long, ByVal lo As Long, ByVal hi As Long, ByVal stp As Long = 1, ByRef suffix As String = "") As Boolean
    Register(id, FK_SLIDER, y, h)
    Dim As Long old = v
    Dim As Long fs = Ui_FS(FS_BODY)
    Dim As Long lh = Txt_LineHeight(FACE_REGULAR, fs)
    Dim As String valTxt = Str(v) & suffix
    ' label row
    Txt_DrawLine(gCv, x, y, w, label, FACE_REGULAR, fs, gTheme.text, ALIGN_START, App_DirText())
    Txt_DrawLine(gCv, x, y, w, valTxt, FACE_BOLD, fs, gTheme.title, ALIGN_END, App_DirText())
    ' track
    Dim As Long ty = y + lh + Ui_S(8), th = Ui_S(10)
    Dim As Long tx = x + Ui_S(12), tw = w - Ui_S(24)
    Dim As Long hitY = ty - Ui_S(12), hitH = th + Ui_S(24)
    If Ui_Hover(x, hitY, w, hitH) Then Plat_SetCursor(CURSOR_HAND)
    Static As String dragId
    If (gIn.mPressed <> 0) AndAlso Ui_Hover(x, hitY, w, hitH) Then dragId = id: focusId = id
    If gIn.mDown = 0 AndAlso dragId = id Then dragId = ""
    If dragId = id AndAlso hi > lo Then
        Dim As Single f = (gIn.mx - tx) / IIf(tw > 0, tw, 1)
        If gApp.rtl Then f = 1 - f
        If f < 0 Then f = 0
        If f > 1 Then f = 1
        v = lo + CLng(f * (hi - lo) / stp) * stp
    End If
    If focusId = id AndAlso sliderDelta <> 0 Then v += sliderDelta * stp
    If v < lo Then v = lo
    If v > hi Then v = hi
    Dim As Single fv = IIf(hi > lo, (v - lo) / (hi - lo), 0)
    Cv_FillRoundRect(gCv, tx, ty, tw, th, th / 2, gTheme.track)
    Dim As Long fillW = CLng(tw * fv)
    If gApp.rtl Then
        Cv_FillRoundRect(gCv, tx + tw - fillW, ty, fillW, th, th / 2, gTheme.primary)
    Else
        Cv_FillRoundRect(gCv, tx, ty, fillW, th, th / 2, gTheme.primary)
    End If
    Dim As Single kx = IIf(gApp.rtl, tx + tw - fillW, tx + fillW)
    Cv_FillCircle(gCv, kx, ty + th / 2, Ui_S(13), IIf(gSet.highContrast, gTheme.accent, &hFFFFFFFF))
    Cv_Ring(gCv, kx, ty + th / 2, Ui_S(13), 2, gTheme.primary)
    If (focusVis <> 0) AndAlso focusId = id Then DrawFocus(x, y - Ui_S(2), w, ty + th + Ui_S(10) - y, Ui_S(10))
    Return v <> old
End Function

Function Ui_Choice(ByRef id As String, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long, ByRef label As String, ByRef opts As String, ByRef idx As Long) As Boolean
    Register(id, FK_SLIDER, y, h)
    ' options separated by "|"
    Dim As String o(0 To 15)
    Dim As Long n = 0, p = 1
    Do
        Dim As Long q = InStr(p, opts, "|")
        If q = 0 Then o(n) = Mid(opts, p): n += 1: Exit Do
        o(n) = Mid(opts, p, q - p): n += 1
        p = q + 1
    Loop While n < 16
    Dim As Long old = idx
    If idx < 0 OrElse idx >= n Then idx = 0
    Dim As Long fs = Ui_FS(FS_BODY)
    Dim As Long lh = Txt_LineHeight(FACE_REGULAR, fs)
    Dim As Long lw = w * 45 \ 100
    Dim As Long bw = w - lw
    Dim As Long lx = IIf(gApp.rtl, x + bw, x)
    Dim As Long bx = IIf(gApp.rtl, x, x + lw)
    Txt_DrawLine(gCv, lx, y + (h - lh) \ 2, lw - Ui_S(8), label, FACE_REGULAR, fs, gTheme.text, ALIGN_START, App_DirText())
    ' [<]  value  [>]
    Dim As Long ab = h
    Dim As Long leftX = bx, rightX = bx + bw - ab
    Dim As Boolean hl = Ui_Hover(leftX, y, ab, h), hr = Ui_Hover(rightX, y, ab, h)
    If hl OrElse hr Then Plat_SetCursor(CURSOR_HAND)
    Dim As Long dVis = 0
    If (gIn.mPressed <> 0) AndAlso hl Then dVis = -1: focusId = id
    If (gIn.mPressed <> 0) AndAlso hr Then dVis = 1: focusId = id
    ' the arrow pointing "back" in reading order decreases
    Dim As Long d = IIf(gApp.rtl, -dVis, dVis)
    If focusId = id AndAlso sliderDelta <> 0 Then d = sliderDelta
    If activateId = id Then d = 1
    If d <> 0 Then idx = (idx + d + n) Mod n: Audio_Play(SND_CLICK)
    Cv_FillRoundRect(gCv, bx, y, bw, h, Radius(h), gTheme.btn)
    If gSet.highContrast Then Cv_RoundRectOutline(gCv, bx, y, bw, h, Radius(h), 2, gTheme.panelEdge)
    Icon_Draw(ICON_ARROW_LEFT, leftX + ab / 2, y + h / 2, h * 0.45, IIf(hl, gTheme.primary, gTheme.textSoft), 0)
    Icon_Draw(ICON_ARROW_RIGHT, rightX + ab / 2, y + h / 2, h * 0.45, IIf(hr, gTheme.primary, gTheme.textSoft), 0)
    Txt_DrawLine(gCv, bx + ab, y + (h - lh) \ 2, bw - 2 * ab, o(idx), FACE_BOLD, fs, gTheme.btnText, ALIGN_CENTER, App_DirText())
    If (focusVis <> 0) AndAlso focusId = id Then DrawFocus(x, y, w, h, Ui_S(10))
    Return idx <> old
End Function

Function Ui_TextField(ByRef id As String, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long, ByRef txt As String, ByRef hint As String, ByVal maxChars As Long = 60) As Long
    Register(id, FK_TEXT, y, h)
    Dim As Boolean hov = Ui_Hover(x, y, w, h)
    If hov Then Plat_SetCursor(CURSOR_IBEAM)
    If (gIn.mPressed <> 0) AndAlso hov Then focusId = id
    Dim As Long res = 0
    Static As String activeId
    If focusId = id Then
        If activeId <> id Then Plat_TextInput(1): activeId = id
        If Len(gIn.text) Then
            If Utf8_Len(txt & gIn.text) <= maxChars Then txt &= gIn.text
        End If
        For i As Long = 0 To gIn.keyN - 1
            If gIn.keys(i) = KEY_BACKSPACE AndAlso keyUsed(i) = 0 Then
                keyUsed(i) = 1
                ' remove the last UTF-8 character
                Dim As Long k = Len(txt)
                While k > 0 AndAlso (txt[k - 1] And &hC0) = &h80: k -= 1: Wend
                If k > 0 Then txt = Left(txt, k - 1)
            ElseIf gIn.keys(i) = KEY_SPACE AndAlso keyUsed(i) = 0 Then
                keyUsed(i) = 1     ' typed via the text event
            End If
        Next
        If activateId = id Then res = 1
    ElseIf activeId = id Then
        Plat_TextInput(0): activeId = ""
    End If
    Dim As Single r = IIf(gTheme.playful, h * 0.3, h * 0.18)
    Cv_FillRoundRect(gCv, x, y, w, h, r, IIf(gSet.highContrast, &hFF000000, &hFFFFFFFF))
    Cv_RoundRectOutline(gCv, x, y, w, h, r, IIf(focusId = id, 3, 1.5), IIf(focusId = id, gTheme.focus, gTheme.panelEdge))
    Dim As Long fs = Ui_FS(FS_BODY)
    Dim As Long lh = Txt_LineHeight(FACE_REGULAR, fs)
    Dim As Long pad = Ui_S(14)
    If Len(txt) = 0 Then
        Txt_DrawLine(gCv, x + pad, y + (h - lh) \ 2, w - 2 * pad, hint, FACE_REGULAR, fs, Col_Alpha(gTheme.textSoft, 170), ALIGN_START, App_DirText())
    Else
        ' user text: direction from its first strong character
        Dim As String shown = txt
        Dim As Long tw = Txt_Width(shown, FACE_REGULAR, fs, DIR_AUTO)
        While tw > w - 2 * pad - Ui_S(6) AndAlso Len(shown) > 1
            Dim As Long k = 1
            While k < Len(shown) AndAlso (shown[k] And &hC0) = &h80: k += 1: Wend
            shown = Mid(shown, k + 1)
            tw = Txt_Width(shown, FACE_REGULAR, fs, DIR_AUTO)
        Wend
        Dim As Long cpsT(Any)
        Dim As Long nT = Utf8_Decode(shown, cpsT())
        Dim As Long rtlText = IIf(Bidi_FirstStrong(cpsT(), 0, nT) = 1, 1, 0)
        Dim As Long tx = IIf(rtlText, x + w - pad - tw, x + pad)
        Txt_Draw(gCv, tx, y + (h - lh) \ 2, shown, FACE_REGULAR, fs, gTheme.text, DIR_AUTO)
        If focusId = id AndAlso (CLng(gApp.now * 2) Mod 2) = 0 Then
            Dim As Long cx = IIf(rtlText, tx - Ui_S(3), tx + tw + Ui_S(2))
            Cv_FillRect(gCv, cx, y + (h - lh) \ 2 + Ui_S(2), 2, lh - Ui_S(4), gTheme.text)
        End If
    End If
    If Len(txt) = 0 AndAlso focusId = id AndAlso (CLng(gApp.now * 2) Mod 2) = 0 Then
        Dim As Long cx = IIf(gApp.rtl, x + w - pad, x + pad)
        Cv_FillRect(gCv, cx, y + (h - lh) \ 2 + Ui_S(2), 2, lh - Ui_S(4), gTheme.text)
    End If
    Return res
End Function

Sub Ui_Label(ByVal x As Long, ByVal y As Long, ByVal w As Long, ByRef txt As String, ByVal fs As Long, ByVal col As ULong, ByVal align As Long = ALIGN_START, ByVal face As Long = FACE_REGULAR)
    Txt_DrawLine(gCv, x, y, w, txt, face, fs, col, align, App_DirText())
End Sub

Function Ui_Para(ByVal x As Long, ByVal y As Long, ByVal w As Long, ByRef txt As String, ByVal fs As Long, ByVal col As ULong, ByVal align As Long = ALIGN_START, ByVal face As Long = FACE_REGULAR) As Long
    Return Txt_Wrap(gCv, x, y, w, txt, face, fs, col, align, App_DirText())
End Function

Function Ui_ParaHeight(ByRef txt As String, ByVal w As Long, ByVal fs As Long, ByVal face As Long = FACE_REGULAR) As Long
    Return Txt_WrapHeight(txt, w, face, fs, App_DirText())
End Function

Function Ui_BadgeW(ByRef txt As String, ByVal fs As Long) As Long
    Return Txt_Width(txt, FACE_BOLD, fs, App_DirText()) + fs
End Function

Sub Ui_Badge(ByVal x As Long, ByVal y As Long, ByRef txt As String, ByVal bg As ULong, ByVal fg As ULong, ByVal fs As Long)
    Dim As Long lh = Txt_LineHeight(FACE_BOLD, fs)
    Dim As Long w = Ui_BadgeW(txt, fs), h = lh + fs \ 3
    Cv_FillRoundRect(gCv, x, y, w, h, h / 2, bg)
    Txt_DrawLine(gCv, x, y + (h - lh) \ 2, w, txt, FACE_BOLD, fs, fg, ALIGN_CENTER, App_DirText())
End Sub

' The mandatory label for every simulated-biofeedback view.
Sub Ui_SimBanner(ByVal x As Long, ByVal y As Long, ByVal w As Long)
    Dim As Long fs = Ui_FS(FS_BODY)
    Dim As String t = L("sim.banner")
    Dim As Long lh = Txt_LineHeight(FACE_BOLD, fs)
    Dim As Long h = lh + Ui_S(14)
    Cv_FillRoundRect(gCv, x, y, w, h, Ui_S(10), IIf(gSet.highContrast, &hFF000000, &hFFFFF1D6))
    Cv_RoundRectOutline(gCv, x, y, w, h, Ui_S(10), 2, gTheme.sim)
    Dim As Long isz = Ui_S(22)
    Dim As Long ix = IIf(gApp.rtl, x + w - Ui_S(14) - isz, x + Ui_S(14))
    Icon_Draw(ICON_INFO, ix + isz / 2, y + h / 2, isz, gTheme.sim, 0)
    Dim As Long tx = IIf(gApp.rtl, x + Ui_S(10), x + Ui_S(14) + isz + Ui_S(8))
    Txt_DrawLine(gCv, tx, y + (h - lh) \ 2, w - isz - Ui_S(36), t, FACE_BOLD, fs, IIf(gSet.highContrast, gTheme.sim, &hFF7A3E0A), ALIGN_START, App_DirText())
End Sub

Function Ui_HeaderH() As Long
    Return Ui_S(72)
End Function

Function Ui_Header(ByRef title As String, ByVal showSim As Long = 0) As Boolean
    Dim As Long hh = Ui_HeaderH()
    Dim As Long bh = Ui_S(48), bw = Ui_S(140)
    Dim As Long pad = Ui_S(16)
    Dim As Boolean back = Ui_Button("hdr.back", Ui_MX(pad, bw), (hh - bh) \ 2, bw, bh, L("btn.back"), BTN_SOFT, IIf(gApp.rtl, ICON_ARROW_RIGHT, ICON_ARROW_LEFT))
    If Ui_Key(KEY_ESC) Then back = True
    ' mute (end side)
    Dim As Long mw = bh
    If Ui_Button("hdr.mute", Ui_MX(gApp.w - pad - mw, mw), (hh - bh) \ 2, mw, bh, "", BTN_SOFT, IIf(gSet.soundOn, ICON_SOUND, ICON_MUTE)) Then
        gSet.soundOn = IIf(gSet.soundOn, 0, 1)
        Audio_ApplySettings()
        App_SaveSettings()
        Ui_Toast(L(IIf(gSet.soundOn, "toast.sound_on", "toast.sound_off")))
    End If
    Dim As Long fs = Ui_FS(FS_LARGE + 4)
    Dim As Long tw = gApp.w - 2 * (pad + bw + Ui_S(12))
    ' soft pill behind the title keeps it readable on dark or busy pictures
    Dim As Long realW = Txt_Width(title, FACE_BOLD, fs, App_DirText()) + Ui_S(40)
    If realW > tw Then realW = tw
    Dim As Long pillH = Txt_LineHeight(FACE_BOLD, fs) + Ui_S(8)
    Cv_FillRoundRect(gCv, (gApp.w - realW) \ 2, (hh - pillH) \ 2, realW, pillH, pillH / 2, Col_Alpha(gTheme.panel, IIf(gSet.highContrast, 255, 150)))
    Txt_DrawLine(gCv, (gApp.w - tw) \ 2, (hh - Txt_LineHeight(FACE_BOLD, fs)) \ 2, tw, title, FACE_BOLD, fs, gTheme.title, ALIGN_CENTER, App_DirText())
    If showSim Then
        Dim As Long sw = gApp.w * 70 \ 100
        Ui_SimBanner((gApp.w - sw) \ 2, hh, sw)
    End If
    Return back
End Function
