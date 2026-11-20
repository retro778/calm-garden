' minigames.bas - Zen Garden, Balloon Journey, Floating Leaves, Night Sky, Peaceful Aquarium.
' Design rules: no scores, no countdown pressure, no losing, no loud effects,
' no flashing. Everything moves slowly and respects the reduced-motion setting.
#include once "screens.bi"
#include once "session.bi"
#include once "scene.bi"
#include once "localization.bi"
#include once "audio.bi"
#include once "progress.bi"

Const G_ZEN = 0
Const G_JOURNEY = 1
Const G_LEAVES = 2
Const G_NIGHT = 3
Const G_AQUA = 4

Dim Shared As SessFlow gmSess
Dim Shared As BreathPattern gmPat
Dim Shared As Double gmT
Dim Shared As Single gmAmt

Private Function GKey(ByVal g As Long) As String
    Select Case g
    Case G_JOURNEY: Return "journey"
    Case G_LEAVES: Return "leaves"
    Case G_NIGHT: Return "night"
    Case G_AQUA: Return "aquarium"
    Case Else: Return "zen"
    End Select
End Function

Private Function GAct(ByVal g As Long) As Long
    Select Case g
    Case G_JOURNEY: Return ACT_JOURNEY
    Case G_LEAVES: Return ACT_LEAVES
    Case G_NIGHT: Return ACT_NIGHT
    Case G_AQUA: Return ACT_AQUARIUM
    Case Else: Return ACT_ZEN
    End Select
End Function

Sub GameList_Frame()
    Scr_Background()
    If Ui_Header(L("games.title")) Then App_Go(SCR_MENU): Exit Sub
    Dim As String labels(0 To 4), descs(0 To 4)
    Dim As Long icons(0 To 4) = {ICON_TREE, ICON_BALLOON, ICON_LEAF, ICON_STAR, ICON_FISH}
    Dim As ULong tints(0 To 4) = {&hFF86D3B4, &hFFFF8C8C, &hFFB5D98A, &hFF9FA8E8, &hFF8FD3FF}
    For i As Long = 0 To 4
        labels(i) = L("game." & GKey(i))
        descs(i) = L("game." & GKey(i) & ".desc")
    Next
    Dim As Long fs = Ui_FS(FS_BODY)
    Ui_Label(Ui_S(40), Ui_HeaderH(), gApp.w - Ui_S(80), L("games.intro"), fs, gTheme.textSoft, ALIGN_CENTER)
    Dim As Long pick = Scr_TileGrid("gl.", labels(), icons(), tints(), 5, 3, Ui_HeaderH() + Ui_S(44), descs())
    If pick >= 0 Then App_Go(SCR_GAME, pick)
End Sub

' ---------------- shared ripples / sparkles (click feedback) ----------------
Const MAXR = 24
Dim Shared As Single rpX(0 To MAXR - 1), rpY(0 To MAXR - 1), rpAge(0 To MAXR - 1)
Dim Shared As Long rpKind(0 To MAXR - 1)

Private Sub AddRipple(ByVal x As Single, ByVal y As Single, ByVal kind As Long)
    For i As Long = 0 To MAXR - 1
        If rpAge(i) <= 0 OrElse rpAge(i) > 2.5 Then
            rpX(i) = x: rpY(i) = y: rpAge(i) = 0.001: rpKind(i) = kind
            Exit Sub
        End If
    Next
End Sub

Private Sub DrawRipples()
    Dim As Single s = gApp.sc
    For i As Long = 0 To MAXR - 1
        If rpAge(i) > 0 AndAlso rpAge(i) < 2.5 Then
            rpAge(i) += gApp.dt
            Dim As Single f = rpAge(i) / 2.5
            If rpKind(i) = 0 Then
                Cv_Ring(gCv, rpX(i), rpY(i), (8 + f * 70) * s, 2 * s, Col_Alpha(&hFFFFFFFF, CLng(200 * (1 - f))))
            Else
                For k As Long = 0 To 5
                    Dim As Single a = k * 1.047 + f
                    Scene_Star(gCv, rpX(i) + Cos(a) * f * 40 * s, rpY(i) + Sin(a) * f * 40 * s - f * 20 * s, 6 * s * (1 - f), a, Col_Alpha(&hFFFFE58A, CLng(230 * (1 - f))))
                Next
            End If
        End If
    Next
End Sub

Private Sub ClearRipples()
    For i As Long = 0 To MAXR - 1: rpAge(i) = 0: Next
End Sub

' ---------------- Zen Garden ----------------

Private Sub ZenDraw(ByVal level As Long, ByVal tm As Double)
    Dim As Single w = gApp.w, h = gApp.h, s = gApp.sc, mo = App_Motion()
    Dim As ULong t1, t2, t3
    Scene_ThemeSky(gSet.theme, t1, t2, t3)
    If gSet.highContrast Then Cv_Clear(gCv, &hFF000000) Else Cv_VGradient3(gCv, 0, 0, w, h, t1, t2, t3)
    Dim As Single groundY = h * 0.58
    If gSet.highContrast = 0 Then
        Cv_SoftCircle(gCv, w * 0.85, h * 0.14, 110 * s, &h70FFF0B0)
        Cv_FillCircle(gCv, w * 0.85, h * 0.14, 38 * s, IIf(gSet.theme = 3, &hFFFFF4D0, &hFFFFE38A))
        For i As Long = 0 To 2
            Scene_Cloud(gCv, ((Scene_Rand(i) * w + tm * 8 * s * mo) Mod (w + 300)) - 150, h * (0.1 + i * 0.08), (40 + i * 10) * s, &hC0FFFFFF)
        Next
    End If
    Scene_Hill(gCv, groundY, 18 * s, 1000 * s, 0.4, IIf(gSet.highContrast, &hFF004000, &hFFB5E3A0))
    Scene_Hill(gCv, groundY + 40 * s, 10 * s, 700 * s, 2.0, IIf(gSet.highContrast, &hFF003000, &hFF9BD68C))
    ' raked sand path (zen lines)
    If gSet.highContrast = 0 Then
        For k As Long = 0 To 4
            Dim As Single py = groundY + 120 * s + k * 9 * s
            Dim As Single px0 = 0
            For i As Long = 0 To 40
                Dim As Single xx = i * w / 40
                Dim As Single yy = py + Sin(xx / (160 * s)) * 6 * s
                If i > 0 Then Cv_Line(gCv, px0, py + Sin(px0 / (160 * s)) * 6 * s, xx, yy, 1.5, &h50FFFFFF)
                px0 = xx
            Next
        Next
    End If
    ' pond (appears at level 1, lily pads and fish later)
    Dim As Single pondX = w * 0.68, pondY = groundY + 85 * s
    If level >= 1 Then
        Cv_FillEllipse(gCv, pondX, pondY, 150 * s, 42 * s, 0, IIf(gSet.highContrast, &hFF0050FF, &hFF8CC8E8))
        Cv_FillEllipse(gCv, pondX, pondY - 4 * s, 130 * s, 32 * s, 0, IIf(gSet.highContrast, &hFF0030C0, &hFFA8D8F0))
        If level >= 8 Then
            For i As Long = 0 To 2
                Cv_FillEllipse(gCv, pondX - 70 * s + i * 60 * s, pondY + (i Mod 2) * 10 * s - 5 * s, 18 * s, 7 * s, 0, &hFF6DB57A)
            Next
            Scene_Flower(gCv, pondX - 10 * s, pondY - 6 * s, 9 * s, 6, &hFFFFC0D8, &hFFFFE38A, 1, 0)
        End If
        If level >= 12 Then
            For i As Long = 0 To 1
                Dim As Single fx = pondX + Sin(tm * 0.4 * mo + i * 3) * 90 * s
                Scene_Fish(gCv, fx, pondY + (i * 10 - 5) * s, 9 * s, Cos(tm * 0.4 * mo + i * 3), &hFFFFA060, tm * mo)
            Next
        End If
    End If
    ' trees
    If level >= 3 Then Scene_Tree(gCv, w * 0.15, groundY + 30 * s, 230 * s, Clamp01((level - 2) / 4), &hFF7DBE7A, Sin(tm * 0.5 * mo) * 4 * s)
    If level >= 10 Then Scene_Tree(gCv, w * 0.9, groundY + 20 * s, 200 * s, Clamp01((level - 9) / 4), &hFF8ACB86, Sin(tm * 0.5 * mo + 1) * 4 * s)
    ' one flower per completed session (up to 40)
    Dim As Long nf = level
    If nf > 40 Then nf = 40
    Dim As ULong pc(0 To 5) = {&hFFFF9EB5, &hFFFFD36E, &hFFB9A2FF, &hFFFF8C8C, &hFF8FD3FF, &hFFFFB38A}
    For i As Long = 0 To nf - 1
        Dim As Single fx = w * (0.05 + Scene_Rand(i * 3 + 1) * 0.9)
        If Abs(fx - pondX) < 160 * s AndAlso level >= 1 Then fx = IIf(fx < pondX, pondX - 170 * s - Scene_Rand(i) * 80 * s, pondX + 170 * s + Scene_Rand(i) * 40 * s)
        Dim As Single gy = groundY + 25 * s + Scene_Rand(i * 3 + 2) * 170 * s
        Dim As Single fh = (35 + Scene_Rand(i * 7) * 35) * s
        Dim As Single sway = Sin(tm * 0.8 * mo + i) * 4 * s
        Scene_FlowerStem(gCv, fx, gy, gy - fh, sway, &hFF5DAE6A)
        Scene_Flower(gCv, fx + sway, gy - fh, (12 + Scene_Rand(i + 50) * 6) * s, 5 + (i Mod 3), pc(i Mod 6), &hFFFFD86B, 1, i)
    Next
    ' butterflies and birds
    If level >= 5 Then
        For i As Long = 0 To IIf(level >= 15, 2, 0)
            Scene_Butterfly(gCv, w * (0.3 + i * 0.25) + Sin(tm * 0.3 * mo + i) * w * 0.1, groundY - 40 * s + Sin(tm * 0.5 * mo + i * 2) * 30 * s, 15 * s, tm * IIf(mo < 1, 0.2, 1) + i, IIf(i = 1, &hFFA6C8FF, &hFFFFA6C9))
        Next
    End If
    If level >= 7 Then
        For i As Long = 0 To 1
            Dim As Single bx = ((Scene_Rand(i + 70) * w + tm * 25 * s * mo) Mod (w + 200)) - 100
            Scene_Bird(gCv, bx, h * (0.2 + i * 0.05), 10 * s, tm * mo + i, &hFF6A6A80)
        Next
    End If
End Sub

Private Sub ZenFrame()
    Dim As Long level = Progress_GardenLevel()
    ZenDraw(level, gApp.anim)
    DrawRipples()
    If Ui_Header(L("game.zen")) Then Sess_Leave(gmSess): App_Go(SCR_GAME_LIST): Exit Sub
    If gApp.entering Then Sess_Begin(gmSess, 0, 0): ClearRipples()
    Sess_Tick(gmSess)
    If gIn.mPressed AndAlso gIn.my > Ui_HeaderH() Then AddRipple(gIn.mx, gIn.my, 1): Audio_Play(SND_POP)
    ' friendly, non-competitive explanation of how the garden grows
    Dim As Long fs = Ui_FS(FS_BODY)
    Dim As String msg = IIf(level = 0, L("zen.empty"), Loc_F("zen.level", Str(level)))
    If Progress_Tracking() = 0 Then msg &= " " & L("zen.notracking")
    Dim As Long pw = Ui_S(720)
    If pw > gApp.w - Ui_S(40) Then pw = gApp.w - Ui_S(40)
    Dim As Long th = Ui_ParaHeight(msg, pw - Ui_S(40), fs) + Ui_S(20)
    Cv_FillRoundRect(gCv, (gApp.w - pw) \ 2, Ui_HeaderH() + Ui_S(8), pw, th, Ui_S(18), Col_Alpha(gTheme.panel, 205))
    Ui_Para((gApp.w - pw) \ 2 + Ui_S(20), Ui_HeaderH() + Ui_S(18), pw - Ui_S(40), msg, fs, gTheme.text, ALIGN_CENTER)
    Dim As Long bw = Ui_S(170), bh = Ui_S(50)
    If Ui_Button("zen.done", Ui_MX(gApp.w - bw - Ui_S(16), bw), gApp.h - bh - Ui_S(16), bw, bh, L("btn.done"), BTN_SOFT, ICON_CHECK) Then
        gmSess.completed = 1
        Sess_Finish(gmSess, 1, 0)
        Sess_Leave(gmSess)
        App_Go(SCR_GAME_LIST)
    End If
End Sub

' ---------------- Balloon Journey ----------------

Dim Shared As Single bjDist, bjY

Private Sub JourneyDraw(ByVal dist As Single, ByVal amt As Single, ByVal tm As Double)
    Dim As Single w = gApp.w, h = gApp.h, s = gApp.sc, mo = App_Motion()
    ' the sky slowly changes from morning to sunset along the journey
    Dim As Single day = Clamp01(dist / (4000 * s))
    Dim As ULong top = Col_Mix(&hFFA8D8FF, &hFFB9A6E8, day)
    Dim As ULong midC = Col_Mix(&hFFDDF0FF, &hFFFFC6B8, day)
    Dim As ULong bot = Col_Mix(&hFFF4FAFF, &hFFFFE7C2, day)
    If gSet.highContrast Then Cv_Clear(gCv, &hFF000000) Else Cv_VGradient3(gCv, 0, 0, w, h, top, midC, bot)
    If gSet.highContrast = 0 Then
        Dim As Single sunY = h * (0.15 + 0.35 * day)
        Cv_SoftCircle(gCv, w * 0.8, sunY, 120 * s, Col_Alpha(Col_Mix(&hFFFFE38A, &hFFFFA070, day), 110))
        Cv_FillCircle(gCv, w * 0.8, sunY, 42 * s, Col_Mix(&hFFFFE38A, &hFFFFA070, day))
        ' parallax layers
        For i As Long = 0 To 6
            Dim As Single par = 0.15 + Scene_Rand(i) * 0.2
            Dim As Single cx = ((Scene_Rand(i + 10) * (w + 400) - dist * par) Mod (w + 400))
            If cx < 0 Then cx += w + 400
            Scene_Cloud(gCv, w + 200 - cx, h * (0.1 + Scene_Rand(i + 20) * 0.55), (35 + Scene_Rand(i + 30) * 45) * s, &hD0FFFFFF)
        Next
        Scene_Hill(gCv, h * 0.78, 40 * s, 900 * s, -dist * 0.3 / (900 * s) * 6.283, Col_Mix(&hFFB8DDB0, &hFFC9A8C8, day))
        Scene_Hill(gCv, h * 0.87, 22 * s, 600 * s, -dist * 0.6 / (600 * s) * 6.283, Col_Mix(&hFF92CF8A, &hFFA889B0, day))
        ' little houses and trees passing by
        For i As Long = 0 To 7
            Dim As Single hx = ((i * 330 * s - dist * 0.6) Mod (w + 400 * s))
            If hx < -200 * s Then hx += w + 400 * s
            If i Mod 2 = 0 Then
                Scene_Tree(gCv, hx, h * 0.92, 90 * s, 1, &hFF6DB57A, 0)
            Else
                Cv_FillRect(gCv, hx - 22 * s, h * 0.86, 44 * s, 34 * s, &hFFFFF0E0)
                Dim As Single rx(0 To 2) = {hx - 28 * s, hx + 28 * s, hx}
                Dim As Single ry(0 To 2) = {h * 0.86, h * 0.86, h * 0.82}
                Cv_FillPoly(gCv, rx(), ry(), 3, &hFFE08A7A)
            End If
        Next
    End If
    ' balloon height follows the breathing guide
    Dim As Single by = h * (0.62 - 0.3 * amt)
    bjY = by
    Dim As Single bx = w * 0.35 + Sin(tm * 0.3 * mo) * 8 * s
    If gApp.rtl Then bx = w - bx
    Dim As Single r = 48 * s
    ' basket
    Cv_Line(gCv, bx - r * 0.5, by + r * 0.9, bx - r * 0.3, by + r * 1.7, 1.5, &hFF8A6A50)
    Cv_Line(gCv, bx + r * 0.5, by + r * 0.9, bx + r * 0.3, by + r * 1.7, 1.5, &hFF8A6A50)
    Cv_FillRoundRect(gCv, bx - r * 0.35, by + r * 1.65, r * 0.7, r * 0.45, 4 * s, &hFFB08860)
    ' envelope with stripes
    Cv_FillEllipse(gCv, bx, by, r, r * 1.12, 0, IIf(gSet.highContrast, &hFFFF4040, &hFFFF8C8C))
    Cv_FillEllipse(gCv, bx, by, r * 0.55, r * 1.1, 0, IIf(gSet.highContrast, &hFFFFFF00, &hFFFFD36E))
    Cv_FillEllipse(gCv, bx, by, r * 0.18, r * 1.08, 0, IIf(gSet.highContrast, &hFFFF4040, &hFFFF8C8C))
    Cv_FillEllipse(gCv, bx - r * 0.4, by - r * 0.45, r * 0.12, r * 0.25, 0.4, &h90FFFFFF)
End Sub

' ---------------- Floating Leaves ----------------

Const MAXLV = 18
Type Leaf
    x As Single
    y As Single
    ang As Single
    spin As Single
    size As Single
    col As ULong
    alive As Long
End Type
Dim Shared As Leaf lv(0 To MAXLV - 1)
Dim Shared As Double lvNext

Private Sub AddLeaf(ByVal x As Single, ByVal y As Single)
    Dim As ULong cols(0 To 3) = {&hFFE8A05A, &hFFD9C35A, &hFF9CC46A, &hFFE07A5A}
    For i As Long = 0 To MAXLV - 1
        If lv(i).alive = 0 Then
            lv(i).x = x: lv(i).y = y
            lv(i).ang = Rnd * 6.28: lv(i).spin = (Rnd - 0.5) * 0.4
            lv(i).size = (16 + Rnd * 10) * gApp.sc
            lv(i).col = cols(Int(Rnd * 4))
            lv(i).alive = 1
            Exit Sub
        End If
    Next
End Sub

Private Sub LeavesFrame(ByVal running As Long)
    Dim As Single w = gApp.w, h = gApp.h, s = gApp.sc, mo = App_Motion()
    Dim As Single tm = gApp.anim
    If gSet.highContrast Then Cv_Clear(gCv, &hFF000000) Else Cv_VGradient3(gCv, 0, 0, w, h, &hFFCDEBD8, &hFFB8E0C4, &hFFA8D6B8)
    ' banks and stream
    Dim As Single waterTop = h * 0.4, waterBot = h * 0.8
    If gSet.highContrast = 0 Then
        Cv_VGradient(gCv, 0, waterTop, w, waterBot - waterTop, &hFF8CC8E0, &hFF6FB4D6)
        For k As Long = 0 To 10
            Dim As Single yy = waterTop + (k + 0.5) * (waterBot - waterTop) / 11
            Dim As Single off = ((tm * 30 * s * mo + k * 97) Mod (w * 0.5))
            For j As Long = 0 To 3
                Dim As Single xx = IIf(gApp.rtl, w - (off + j * w * 0.5 - 100 * s), off + j * w * 0.5 - 100 * s)
                Cv_Line(gCv, xx, yy, xx + 60 * s, yy, 1.5, &h50FFFFFF)
            Next
        Next
        For i As Long = 0 To 9
            Scene_Tree(gCv, (i + 0.3) * w / 9, waterTop + 8 * s, 120 * s, 1, IIf(i Mod 2, &hFF7DBE7A, &hFF6DB57A), Sin(tm * 0.5 * mo + i) * 3 * s)
        Next
        Cv_FillRect(gCv, 0, waterBot, w, h - waterBot, &hFF9BD68C)
        For i As Long = 0 To 14
            Dim As Single gx = Scene_Rand(i + 5) * w
            Cv_Line(gCv, gx, waterBot + 2, gx + Sin(tm * 0.8 * mo + i) * 4 * s, waterBot - 18 * s, 2, &hFF6DB57A)
        Next
    Else
        Cv_FillRect(gCv, 0, waterTop, w, waterBot - waterTop, &hFF0030C0)
    End If
    ' leaves drift with the current (left -> right, or right -> left in RTL)
    Dim As Single dir_ = IIf(gApp.rtl, -1, 1)
    If running Then
        If gApp.now > lvNext Then
            AddLeaf(IIf(gApp.rtl, w + 30 * s, -30 * s), waterTop + 20 * s + Rnd * (waterBot - waterTop - 40 * s))
            lvNext = gApp.now + 3.5 + Rnd * 3
        End If
        If gIn.mPressed AndAlso gIn.my > waterTop AndAlso gIn.my < waterBot Then
            AddLeaf(gIn.mx, gIn.my): AddRipple(gIn.mx, gIn.my, 0): Audio_Play(SND_POP)
        End If
    End If
    For i As Long = 0 To MAXLV - 1
        With lv(i)
            If .alive = 0 Then Continue For
            If running AndAlso gmSess.clk.paused = 0 Then
                Dim As Single spd = (26 + 10 * Sin(.y * 0.01)) * s * IIf(gSet.reducedMotion, 0.5, 1)
                .x += dir_ * spd * gApp.dt
                .y += Sin(tm * 0.5 + i) * 4 * s * gApp.dt
                .ang += .spin * gApp.dt * mo
            End If
            Cv_FillEllipse(gCv, .x + 3 * s, .y + 4 * s, .size, .size * 0.42, .ang, &h30000000)
            Scene_Leaf(gCv, .x, .y, .size, .ang, IIf(gSet.highContrast, &hFFFFFF00, .col))
            If .x > w + 60 * s OrElse .x < -60 * s Then .alive = 0
        End With
    Next
End Sub

' ---------------- Night Sky ----------------

Private Sub NightDraw(ByVal lit As Single, ByVal tm As Double)
    Dim As Single w = gApp.w, h = gApp.h, s = gApp.sc, mo = App_Motion()
    If gSet.highContrast Then Cv_Clear(gCv, &hFF000000) Else Cv_VGradient3(gCv, 0, 0, w, h, &hFF0E1230, &hFF1D2352, &hFF3A3570)
    ' faint background stars
    For i As Long = 0 To 50
        Cv_FillCircle(gCv, Scene_Rand(i + 500) * w, Scene_Rand(i + 600) * h * 0.8, 0.9 * s, &h50FFFFFF)
    Next
    ' 40 stars light up gradually (lit = 0..40), each fading in over a few seconds
    Dim As Long nStars = 40
    For i As Long = 0 To nStars - 1
        Dim As Single a = Clamp01(lit - i)
        If a <= 0 Then Exit For
        Dim As Single sx = w * (0.06 + Scene_Rand(i * 2 + 1) * 0.88)
        Dim As Single sy = h * (0.12 + Scene_Rand(i * 2 + 2) * 0.6)
        Dim As Single tw = 0.75 + 0.25 * Sin(tm * (0.4 + Scene_Rand(i) * 0.4) * mo + i)
        Dim As Single r = (2.2 + Scene_Rand(i + 77) * 2.5) * s
        Cv_SoftCircle(gCv, sx, sy, r * 6, Col_Alpha(&hFFFFF4C8, CLng(70 * a * tw)))
        Scene_Star(gCv, sx, sy, r * 1.8, 0, Col_Alpha(IIf(gSet.highContrast, &hFFFFFF00, &hFFFFF4C8), CLng(255 * a)))
        ' gentle constellation lines between neighbours in groups of five
        If i Mod 5 <> 0 Then
            Dim As Single px = w * (0.06 + Scene_Rand((i - 1) * 2 + 1) * 0.88), py = h * (0.12 + Scene_Rand((i - 1) * 2 + 2) * 0.6)
            Dim As Single d2 = (px - sx) * (px - sx) + (py - sy) * (py - sy)
            If d2 < (260 * s) ^ 2 Then Cv_Line(gCv, px, py, sx, sy, 1, Col_Alpha(&hFFB8C4FF, CLng(70 * a)))
        End If
    Next
    ' hills and a little house with a warm window
    If gSet.highContrast = 0 Then
        Scene_Hill(gCv, h * 0.86, 18 * s, 900 * s, 1.1, &hFF1E2348)
        Cv_FillRect(gCv, w * 0.2 - 30 * s, h * 0.8, 60 * s, 46 * s, &hFF2E3360)
        Dim As Single rx(0 To 2) = {w * 0.2 - 38 * s, w * 0.2 + 38 * s, w * 0.2}
        Dim As Single ry(0 To 2) = {h * 0.8, h * 0.8, h * 0.75}
        Cv_FillPoly(gCv, rx(), ry(), 3, &hFF262A52)
        Cv_FillRect(gCv, w * 0.2 - 8 * s, h * 0.815, 16 * s, 14 * s, &hFFFFD98A)
    End If
End Sub

' ---------------- Peaceful Aquarium ----------------

Const NFISH = 9
Type Fish
    x As Single
    y As Single
    vx As Single
    vy As Single
    tx As Single
    ty As Single
    size As Single
    col As ULong
    ph As Single
End Type
Dim Shared As Fish fishes(0 To NFISH - 1)
Dim Shared As Single foodX, foodY, foodAge
Dim Shared As Long foodOn

Private Sub AquaInit()
    Dim As ULong cols(0 To 5) = {&hFFFFA060, &hFFFFD36E, &hFF8FD3FF, &hFFFF9EB5, &hFFB9A2FF, &hFF86D3B4}
    For i As Long = 0 To NFISH - 1
        With fishes(i)
            .x = gApp.w * (0.1 + Rnd * 0.8): .y = gApp.h * (0.3 + Rnd * 0.45)
            .vx = 0: .vy = 0
            .tx = .x: .ty = .y
            .size = (16 + Rnd * 16) * gApp.sc
            .col = cols(i Mod 6)
            .ph = Rnd * 6
        End With
    Next
    foodOn = 0
End Sub

Private Sub AquaFrame(ByVal running As Long)
    Dim As Single w = gApp.w, h = gApp.h, s = gApp.sc, mo = App_Motion()
    Dim As Single tm = gApp.anim
    If gSet.highContrast Then Cv_Clear(gCv, &hFF000000) Else Cv_VGradient3(gCv, 0, 0, w, h, &hFF7CCDE8, &hFF4FA8D0, &hFF2E7FB0)
    ' soft light rays
    If gSet.highContrast = 0 Then
        For i As Long = 0 To 4
            Dim As Single x0 = w * (0.1 + i * 0.2) + Sin(tm * 0.1 * mo + i) * 30 * s
            Dim As Single xs(0 To 3) = {x0, x0 + 50 * s, x0 + 160 * s, x0 + 60 * s}
            Dim As Single ys(0 To 3) = {0, 0, h, h}
            Cv_FillPoly(gCv, xs(), ys(), 4, &h12FFFFFF)
        Next
        ' sand and plants
        Scene_Hill(gCv, h * 0.88, 10 * s, 600 * s, 0.4, &hFFE8D6A8)
        For i As Long = 0 To 7
            Dim As Single px = (i + 0.5) * w / 8
            Dim As Single ph = (60 + Scene_Rand(i + 3) * 70) * s
            Dim As Single lx = px, ly = h * 0.9
            For k As Long = 1 To 8
                Dim As Single f = k / 8
                Dim As Single nx = px + Sin(tm * 0.7 * mo + i + f * 2) * 12 * s * f, ny = h * 0.9 - ph * f
                Cv_Line(gCv, lx, ly, nx, ny, 5 * s * (1.2 - f), IIf(i Mod 2, &hFF4FA86A, &hFF6DBE7A))
                lx = nx: ly = ny
            Next
        Next
    End If
    ' bubbles
    For i As Long = 0 To 14
        Dim As Single sp = 18 + Scene_Rand(i) * 20
        Dim As Single by = h - ((tm * sp * s * mo + Scene_Rand(i + 9) * h) Mod (h + 40 * s))
        Dim As Single bx = Scene_Rand(i + 30) * w + Sin(tm + i) * 6 * s
        Cv_Ring(gCv, bx, by, (3 + Scene_Rand(i + 50) * 4) * s, 1.2, &h90FFFFFF)
    Next
    ' food: fish swim calmly towards it
    If running AndAlso gIn.mPressed AndAlso gIn.my > Ui_HeaderH() AndAlso gIn.my < h - Ui_S(90) Then
        foodX = gIn.mx: foodY = gIn.my: foodAge = 0: foodOn = 1
        AddRipple(gIn.mx, gIn.my, 0)
        Audio_Play(SND_POP)
    End If
    If foodOn Then
        foodAge += gApp.dt
        foodY += 12 * s * gApp.dt
        For k As Long = 0 To 4
            Cv_FillCircle(gCv, foodX + (k - 2) * 5 * s, foodY + Sin(k * 2.1) * 4 * s, 2.5 * s, &hFFD9A060)
        Next
        If foodAge > 8 Then foodOn = 0
    End If
    For i As Long = 0 To NFISH - 1
        With fishes(i)
            If running AndAlso gmSess.clk.paused = 0 Then
                ' wander towards a target; pick a new one when close
                Dim As Single dx = .tx - .x, dy = .ty - .y
                If dx * dx + dy * dy < (30 * s) ^ 2 OrElse Rnd < 0.002 Then
                    .tx = w * (0.08 + Rnd * 0.84): .ty = h * (0.18 + Rnd * 0.62)
                End If
                If foodOn AndAlso i < 5 Then .tx = foodX + (i - 2) * 20 * s: .ty = foodY
                dx = .tx - .x: dy = .ty - .y
                Dim As Single d = Sqr(dx * dx + dy * dy) + 0.001
                Dim As Single maxV = (40 + i * 3) * s * IIf(gSet.reducedMotion, 0.5, 1)
                .vx += (dx / d * maxV - .vx) * gApp.dt * 0.8
                .vy += (dy / d * maxV * 0.5 - .vy) * gApp.dt * 0.8
                .x += .vx * gApp.dt
                .y += .vy * gApp.dt
            End If
            Scene_Fish(gCv, .x, .y, .size, IIf(.vx < 0, -1, 1), IIf(gSet.highContrast, &hFFFFFF00, .col), tm * mo + .ph)
        End With
    Next
End Sub

' ---------------- shared flow ----------------

Private Function GameIntro(ByVal g As Long) As Boolean
    Dim As Long pw = Ui_S(640), fs = Ui_FS(FS_BODY)
    If pw > gApp.w - Ui_S(40) Then pw = gApp.w - Ui_S(40)
    Dim As Long pad = Ui_S(26)
    Dim As String desc = L("game." & GKey(g) & ".intro")
    Dim As Long hDesc = Ui_ParaHeight(desc, pw - 2 * pad, fs)
    Dim As Long ph = pad + hDesc + Ui_S(16) + Sess_BeforeRatingH() + Ui_S(60) + pad
    Dim As Long px = (gApp.w - pw) \ 2, py = (gApp.h - ph) \ 2 + Ui_S(20)
    If py < Ui_HeaderH() Then py = Ui_HeaderH()
    Ui_Panel(px, py, pw, ph, 235)
    Dim As Long y = py + pad
    y += Ui_Para(px + pad, y, pw - 2 * pad, desc, fs, gTheme.text) + Ui_S(16)
    y += Sess_BeforeRating(gmSess, px + pad, y, pw - 2 * pad)
    Dim As Long favW = (pw - 2 * pad) * 38 \ 100
    Sess_FavButton(gmSess, IIf(gApp.rtl, px + pw - pad - favW, px + pad), y + Ui_S(5), favW)
    Dim As Long sw = pw - 2 * pad - favW - Ui_S(12)
    If gApp.entering Then Ui_SetFocus("gm.start")
    Return Ui_Button("gm.start", IIf(gApp.rtl, px + pad, px + pad + favW + Ui_S(12)), y, sw, Ui_S(56), L("btn.start"), BTN_PRIMARY, ICON_PLAY)
End Function

Sub Game_Frame()
    Dim As Long g = gApp.arg
    If g < 0 OrElse g > 4 Then g = 0
    If gApp.entering Then
        Sess_Reset(gmSess, GAct(g))
        ClearRipples()
        gmAmt = 0.3: gmT = 0: bjDist = 0
        For i As Long = 0 To MAXLV - 1: lv(i).alive = 0: Next
        If g = G_LEAVES Then
            For i As Long = 0 To 5
                AddLeaf(gApp.w * (0.1 + i * 0.16), gApp.h * (0.45 + Scene_Rand(i) * 0.3))
            Next
        End If
        If g = G_AQUA Then AquaInit()
    End If
    If g = G_ZEN Then ZenFrame(): Exit Sub
    Dim As Long running = IIf(gmSess.state = SS_RUN, 1, 0)
    If running Then
        Sess_Tick(gmSess)
        If gmSess.clk.paused = 0 Then gmT += gApp.dt
    End If
    ' breathing guide for the journey and the night sky
    Dim As BreathState st
    If running AndAlso (g = G_JOURNEY OrElse g = G_NIGHT) Then
        Breath_Eval(gmPat, gmT, st)
    Else
        Breath_Natural(gApp.anim, st)
    End If
    gmAmt = Approach(gmAmt, st.amount, IIf(running, 10, 2), gApp.dt)
    Select Case g
    Case G_JOURNEY
        If running AndAlso gmSess.clk.paused = 0 Then bjDist += 60 * gApp.sc * gApp.dt
        JourneyDraw(bjDist, gmAmt, gApp.anim)
    Case G_LEAVES
        LeavesFrame(running)
    Case G_NIGHT
        Dim As Single lit = 2
        If gmSess.state = SS_RUN Then lit = 2 + Clock_Frac(gmSess.clk) * 38
        If gmSess.state = SS_DONE Then lit = 40
        NightDraw(lit, gApp.anim)
    Case G_AQUA
        AquaFrame(running)
    End Select
    DrawRipples()
    If Ui_Header(L("game." & GKey(g))) Then Sess_Leave(gmSess): App_Go(SCR_GAME_LIST): Exit Sub
    Select Case gmSess.state
    Case SS_INTRO
        If GameIntro(g) Then
            Breath_MakePattern(gmPat, gSet.inhaleSec, gSet.exhaleSec, gSet.pauseOn, gSet.pauseSec)
            gmT = 0
            ' open-ended games have no clock pressure; journey/night follow the session length
            Sess_Begin(gmSess, IIf(g = G_JOURNEY OrElse g = G_NIGHT, Sess_Minutes(gSet.sessionMin) * 60, 0))
        End If
    Case SS_RUN
        If g = G_JOURNEY OrElse g = G_NIGHT Then
            Dim As String ins = L(IIf(st.phase = BP_IN, "breath.in", IIf(st.phase = BP_OUT, "breath.out", "breath.rest")))
            If gmSess.clk.paused Then ins = L("sess.paused")
            Dim As Long fs = Ui_FS(FS_LARGE)
            Dim As Long tw = Txt_Width(ins, FACE_BOLD, fs, App_DirText()) + Ui_S(40)
            Dim As Long lh = Txt_LineHeight(FACE_BOLD, fs)
            Cv_FillRoundRect(gCv, (gApp.w - tw) \ 2, Ui_HeaderH() + Ui_S(10), tw, lh + Ui_S(10), (lh + Ui_S(10)) / 2, Col_Alpha(gTheme.panel, 190))
            Ui_Label(0, Ui_HeaderH() + Ui_S(15), gApp.w, ins, fs, gTheme.title, ALIGN_CENTER, FACE_BOLD)
            Sess_Progress(gmSess, gApp.h - Sess_ControlsH() - Ui_S(56))
        Else
            Dim As Long fs = Ui_FS(FS_BODY)
            Dim As String hint = L("game." & GKey(g) & ".hint")
            Dim As Long tw = Txt_Width(hint, FACE_REGULAR, fs, App_DirText()) + Ui_S(40)
            If tw > gApp.w - Ui_S(40) Then tw = gApp.w - Ui_S(40)
            Dim As Long lh = Txt_LineHeight(FACE_REGULAR, fs)
            Cv_FillRoundRect(gCv, (gApp.w - tw) \ 2, Ui_HeaderH() + Ui_S(8), tw, lh + Ui_S(10), (lh + Ui_S(10)) / 2, Col_Alpha(gTheme.panel, 180))
            Ui_Label((gApp.w - tw) \ 2, Ui_HeaderH() + Ui_S(13), tw, hint, fs, gTheme.text, ALIGN_CENTER)
        End If
        If Sess_Controls(gmSess, 0) Then Sess_Finish(gmSess, IIf(gmSess.clk.total = 0 OrElse gmSess.clk.elapsed >= gmSess.clk.total * 0.5, 1, 0))
        If Clock_Done(gmSess.clk) Then Sess_Finish(gmSess, 1)
    Case SS_DONE
        Select Case Sess_DonePanel(gmSess, L("game." & GKey(g) & ".done"))
        Case 1: gmSess.state = SS_INTRO: bjDist = 0
        Case 2: Sess_Leave(gmSess): App_Go(SCR_GAME_LIST)
        End Select
    End Select
End Sub
