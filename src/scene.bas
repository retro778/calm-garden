' scene.bas - procedural icons and nature artwork (see scene.bi)
#include once "scene.bi"

Const PI = 3.14159265
Const TAU = 6.2831853

Dim Shared As Canvas Ptr iconCv

Sub Scene_SetIconCanvas(ByVal c As Canvas Ptr)
    iconCv = c
End Sub

Function Scene_Rand(ByVal i As Long) As Single
    Dim As ULong h = CULng(i) * 2654435761UL
    h = (h Xor (h Shr 15)) * 2246822519UL
    h = h Xor (h Shr 13)
    Return (h And &hFFFFFF) / 16777216.0
End Function

Sub Scene_ThemeSky(ByVal theme As Long, ByRef topC As ULong, ByRef midC As ULong, ByRef bot As ULong)
    Select Case theme
    Case 1   ' sunset
        topC = &hFFB9A6E8: midC = &hFFFFC6B8: bot = &hFFFFE7C2
    Case 2   ' ocean
        topC = &hFF9FD8F5: midC = &hFFCDEFFB: bot = &hFFE8FBF6
    Case 3   ' night
        topC = &hFF1D2350: midC = &hFF39407A: bot = &hFF6A5C96
    Case Else ' garden
        topC = &hFFBFE3FF: midC = &hFFE4F4FF: bot = &hFFFFF0E6
    End Select
End Sub

' ---------------- nature ----------------

Sub Scene_Cloud(ByRef c As Canvas, ByVal x As Single, ByVal y As Single, ByVal s As Single, ByVal col As ULong)
    Cv_FillEllipse(c, x, y, s * 1.1, s * 0.42, 0, col)
    Cv_FillCircle(c, x - s * 0.45, y - s * 0.12, s * 0.38, col)
    Cv_FillCircle(c, x + s * 0.05, y - s * 0.3, s * 0.5, col)
    Cv_FillCircle(c, x + s * 0.55, y - s * 0.1, s * 0.34, col)
End Sub

Sub Scene_Flower(ByRef c As Canvas, ByVal x As Single, ByVal y As Single, ByVal size As Single, ByVal petals As Long, ByVal petalCol As ULong, ByVal centerCol As ULong, ByVal openF As Single, ByVal rot As Single)
    If petals < 3 Then petals = 3
    Dim As Single pl = size * (0.35 + 0.65 * openF)
    Dim As Single pw = size * (0.18 + 0.2 * openF)
    Dim As ULong inner = Col_Mix(petalCol, &hFFFFFFFF, 0.35)
    For i As Long = 0 To petals - 1
        Dim As Single a = rot + i * TAU / petals
        Cv_FillEllipse(c, x + Cos(a) * pl * 0.55, y + Sin(a) * pl * 0.55, pl * 0.55, pw, a, petalCol)
    Next
    For i As Long = 0 To petals - 1
        Dim As Single a = rot + (i + 0.5) * TAU / petals
        Cv_FillEllipse(c, x + Cos(a) * pl * 0.33, y + Sin(a) * pl * 0.33, pl * 0.36, pw * 0.7, a, inner)
    Next
    Cv_FillCircle(c, x, y, size * 0.2, centerCol)
    Cv_FillCircle(c, x - size * 0.05, y - size * 0.06, size * 0.07, Col_Mix(centerCol, &hFFFFFFFF, 0.5))
End Sub

Sub Scene_FlowerStem(ByRef c As Canvas, ByVal x As Single, ByVal groundY As Single, ByVal headY As Single, ByVal sway As Single, ByVal col As ULong)
    Dim As Single h = groundY - headY
    Dim As Long seg = 10
    Dim As Single px = x, py = groundY
    For i As Long = 1 To seg
        Dim As Single f = i / seg
        Dim As Single nx = x + sway * f * f, ny = groundY - h * f
        Cv_Line(c, px, py, nx, ny, IIf(h > 60, 4, 3), col)
        px = nx: py = ny
    Next
    Dim As Single ly = groundY - h * 0.4
    Cv_FillEllipse(c, x + sway * 0.16 + h * 0.12, ly, h * 0.13, h * 0.05, -0.5, col)
    Cv_FillEllipse(c, x + sway * 0.25 - h * 0.11, ly - h * 0.12, h * 0.12, h * 0.045, 0.5, col)
End Sub

Sub Scene_Tree(ByRef c As Canvas, ByVal x As Single, ByVal groundY As Single, ByVal size As Single, ByVal growth As Single, ByVal leafCol As ULong, ByVal sway As Single)
    If growth <= 0.01 Then Exit Sub
    Dim As Single h = size * (0.3 + 0.7 * growth)
    Dim As Single tw = size * 0.09 * (0.5 + 0.5 * growth)
    Dim As Single xs(0 To 3) = {x - tw, x + tw, x + tw * 0.6 + sway * 0.3, x - tw * 0.6 + sway * 0.3}
    Dim As Single ys(0 To 3) = {groundY, groundY, groundY - h * 0.62, groundY - h * 0.62}
    Cv_FillPoly(c, xs(), ys(), 4, &hFF9A6A45)
    Dim As Single cx = x + sway * 0.4, cy = groundY - h * 0.7
    Dim As Single r = size * 0.3 * (0.35 + 0.65 * growth)
    Dim As ULong dark = Col_Mix(leafCol, &hFF000000, 0.15)
    Dim As ULong light = Col_Mix(leafCol, &hFFFFFFFF, 0.25)
    Cv_FillCircle(c, cx - r * 0.55, cy + r * 0.15, r * 0.7, dark)
    Cv_FillCircle(c, cx + r * 0.55, cy + r * 0.15, r * 0.7, dark)
    Cv_FillCircle(c, cx, cy - r * 0.25, r * 0.85, leafCol)
    Cv_FillCircle(c, cx - r * 0.25, cy - r * 0.45, r * 0.35, light)
End Sub

Sub Scene_Butterfly(ByRef c As Canvas, ByVal x As Single, ByVal y As Single, ByVal size As Single, ByVal t As Single, ByVal col As ULong)
    Dim As Single flap = 0.35 + 0.65 * Abs(Sin(t * 5))
    Dim As ULong c2 = Col_Mix(col, &hFFFFFFFF, 0.4)
    Cv_FillEllipse(c, x - size * 0.45 * flap, y - size * 0.25, size * 0.5 * flap, size * 0.38, -0.4, col)
    Cv_FillEllipse(c, x + size * 0.45 * flap, y - size * 0.25, size * 0.5 * flap, size * 0.38, 0.4, col)
    Cv_FillEllipse(c, x - size * 0.32 * flap, y + size * 0.22, size * 0.32 * flap, size * 0.26, 0.5, c2)
    Cv_FillEllipse(c, x + size * 0.32 * flap, y + size * 0.22, size * 0.32 * flap, size * 0.26, -0.5, c2)
    Cv_FillEllipse(c, x, y, size * 0.08, size * 0.42, 0, &hFF4A3F5C)
End Sub

Sub Scene_Bird(ByRef c As Canvas, ByVal x As Single, ByVal y As Single, ByVal size As Single, ByVal t As Single, ByVal col As ULong)
    Dim As Single f = Sin(t * 4) * size * 0.35
    Cv_Line(c, x - size, y - f, x, y, size * 0.12 + 1, col)
    Cv_Line(c, x, y, x + size, y - f, size * 0.12 + 1, col)
End Sub

Sub Scene_Fish(ByRef c As Canvas, ByVal x As Single, ByVal y As Single, ByVal size As Single, ByVal dirX As Single, ByVal col As ULong, ByVal t As Single)
    Dim As Single d = IIf(dirX < 0, -1, 1)
    Dim As Single wag = Sin(t * 6) * size * 0.18
    ' tail
    Dim As Single xs(0 To 2) = {x - d * size * 0.75, x - d * size * 1.25, x - d * size * 1.25}
    Dim As Single ys(0 To 2) = {y, y - size * 0.4 + wag, y + size * 0.4 + wag}
    Cv_FillPoly(c, xs(), ys(), 3, Col_Mix(col, &hFF000000, 0.12))
    Cv_FillEllipse(c, x, y, size * 0.85, size * 0.48, 0, col)
    Cv_FillEllipse(c, x - d * size * 0.05, y - size * 0.42, size * 0.3, size * 0.12, d * 0.3, Col_Mix(col, &hFFFFFFFF, 0.3))
    Cv_FillCircle(c, x + d * size * 0.45, y - size * 0.1, size * 0.12, &hFFFFFFFF)
    Cv_FillCircle(c, x + d * size * 0.48, y - size * 0.1, size * 0.06, &hFF2A2A40)
End Sub

Sub Scene_Star(ByRef c As Canvas, ByVal x As Single, ByVal y As Single, ByVal r As Single, ByVal rot As Single, ByVal col As ULong)
    Dim As Single xs(0 To 9), ys(0 To 9)
    For i As Long = 0 To 9
        Dim As Single a = rot - PI / 2 + i * PI / 5
        Dim As Single rr = IIf(i Mod 2 = 0, r, r * 0.45)
        xs(i) = x + Cos(a) * rr
        ys(i) = y + Sin(a) * rr
    Next
    Cv_FillPoly(c, xs(), ys(), 10, col)
End Sub

Sub Scene_Balloon(ByRef c As Canvas, ByVal x As Single, ByVal y As Single, ByVal r As Single, ByVal col As ULong, ByVal stretch As Single)
    Dim As Single ry = r * (1.12 + stretch * 0.05)
    ' string
    Dim As Single sy = y + ry
    For i As Long = 0 To 7
        Dim As Single y0 = sy + i * r * 0.18, y1 = sy + (i + 1) * r * 0.18
        Cv_Line(c, x + Sin(i * 1.3) * r * 0.06, y0, x + Sin((i + 1) * 1.3) * r * 0.06, y1, 1.5, &hFF8A8A9A)
    Next
    ' knot
    Dim As Single kx(0 To 2) = {x, x - r * 0.1, x + r * 0.1}
    Dim As Single ky(0 To 2) = {sy - r * 0.04, sy + r * 0.1, sy + r * 0.1}
    Cv_FillPoly(c, kx(), ky(), 3, Col_Mix(col, &hFF000000, 0.2))
    Cv_FillEllipse(c, x, y, r, ry, 0, col)
    Cv_FillEllipse(c, x - r * 0.38, y - ry * 0.4, r * 0.16, ry * 0.26, 0.5, Col_Alpha(&hFFFFFFFF, 140))
End Sub

' filled area below a sine wave, down to the bottom of the clip
Sub Scene_Wave(ByRef c As Canvas, ByVal baseY As Single, ByVal amp As Single, ByVal wl As Single, ByVal phase As Single, ByVal col As ULong)
    Dim As Long n = c.w \ 16 + 3
    Dim As Single xs(0 To n + 1), ys(0 To n + 1)
    For i As Long = 0 To n - 1
        Dim As Single xx = (i - 1) * 16
        xs(i) = xx
        ys(i) = baseY + Sin(xx / wl * TAU + phase) * amp + Sin(xx / wl * 2.7 + phase * 1.6) * amp * 0.3
    Next
    xs(n) = xs(n - 1): ys(n) = c.h + 2
    xs(n + 1) = xs(0): ys(n + 1) = c.h + 2
    Cv_FillPoly(c, xs(), ys(), n + 2, col)
End Sub

Sub Scene_Hill(ByRef c As Canvas, ByVal baseY As Single, ByVal amp As Single, ByVal wl As Single, ByVal phase As Single, ByVal col As ULong)
    Scene_Wave(c, baseY, amp, wl, phase, col)
End Sub

Sub Scene_Leaf(ByRef c As Canvas, ByVal x As Single, ByVal y As Single, ByVal size As Single, ByVal ang As Single, ByVal col As ULong)
    Cv_FillEllipse(c, x, y, size, size * 0.42, ang, col)
    Cv_Line(c, x - Cos(ang) * size * 0.9, y - Sin(ang) * size * 0.9, x + Cos(ang) * size * 0.9, y + Sin(ang) * size * 0.9, 1.2, Col_Mix(col, &hFF000000, 0.25))
End Sub

Sub Scene_MenuBackground(ByRef c As Canvas, ByVal t As Double, ByVal theme As Long, ByVal motion As Single, ByVal hc As Long)
    Dim As ULong topC, midC, bot
    If hc Then
        Cv_Clear(c, &hFF000000)
        Exit Sub
    End If
    Scene_ThemeSky(theme, topC, midC, bot)
    Cv_VGradient3(c, 0, 0, c.w, c.h, topC, midC, bot)
    Dim As Single w = c.w, h = c.h
    Dim As Single s = IIf(w / 1024 < h / 768, w / 1024, h / 768)
    Dim As Single tm = t * motion
    ' sun or moon with a soft glow
    If theme = 3 Then
        For i As Long = 0 To 40
            Dim As Single tw = 0.6 + 0.4 * Sin(tm * 0.8 + i * 1.7)
            Cv_FillCircle(c, Scene_Rand(i) * w, Scene_Rand(i + 99) * h * 0.55, 1.2 + Scene_Rand(i + 7) * 1.5, Col_Alpha(&hFFFFF8E0, CLng(120 + 100 * tw)))
        Next
        Cv_SoftCircle(c, w * 0.82, h * 0.18, 110 * s, &h50FFF4D0)
        Cv_FillCircle(c, w * 0.82, h * 0.18, 42 * s, &hFFFFF4D0)
    Else
        Dim As ULong sunCol = IIf(theme = 1, &hFFFFB38A, &hFFFFE38A)
        Cv_SoftCircle(c, w * 0.82, h * 0.17, 140 * s, Col_Alpha(sunCol, 110))
        Cv_FillCircle(c, w * 0.82, h * 0.17, 52 * s, sunCol)
    End If
    ' drifting clouds
    Dim As ULong cloudCol = IIf(theme = 3, &h40FFFFFF, &hD0FFFFFF)
    For i As Long = 0 To 4
        Dim As Single sp = 8 + Scene_Rand(i + 20) * 10
        Dim As Single cxp = ((Scene_Rand(i + 30) * (w + 400) + tm * sp * s) Mod (w + 400)) - 200
        Scene_Cloud(c, cxp, h * (0.1 + Scene_Rand(i + 40) * 0.3), (40 + Scene_Rand(i + 50) * 40) * s, cloudCol)
    Next
    ' hills
    Dim As ULong h1 = IIf(theme = 3, &hFF3E4E7A, IIf(theme = 2, &hFF8FD7C7, &hFFA8E0A0))
    Dim As ULong h2 = IIf(theme = 3, &hFF2E3B62, IIf(theme = 2, &hFF6CC4B5, &hFF84CF8A))
    Scene_Hill(c, h * 0.8, 22 * s, 900 * s, 0.5, h1)
    Scene_Hill(c, h * 0.88, 16 * s, 700 * s, 2.1, h2)
    ' flowers along the bottom, gently swaying
    Dim As ULong pc(0 To 4) = {&hFFFF9EB5, &hFFFFD36E, &hFFB9A2FF, &hFFFF8C8C, &hFF8FD3FF}
    Dim As Long nf = CLng(w / (90 * s)) + 1
    For i As Long = 0 To nf - 1
        Dim As Single fx = (i + 0.5) * w / nf + (Scene_Rand(i + 60) - 0.5) * 40 * s
        Dim As Single gy = h * 0.9 + Scene_Rand(i + 70) * h * 0.08
        Dim As Single fh = (40 + Scene_Rand(i + 80) * 45) * s
        Dim As Single sway = Sin(tm * 0.9 + i) * 6 * s
        Scene_FlowerStem(c, fx, gy + 6 * s, gy - fh, sway, &hFF5DAE6A)
        Scene_Flower(c, fx + sway, gy - fh, (14 + Scene_Rand(i + 90) * 8) * s, 5 + (i Mod 3), pc(i Mod 5), &hFFFFD86B, 1, tm * 0.1 + i)
    Next
    ' two butterflies
    If theme <> 3 Then
        For i As Long = 0 To 1
            Dim As Single bx = w * (0.25 + 0.5 * i) + Sin(tm * 0.31 + i * 2) * w * 0.18
            Dim As Single by = h * 0.62 + Sin(tm * 0.53 + i) * h * 0.08
            Scene_Butterfly(c, bx, by, 16 * s, tm * IIf(motion < 1, 0.3, 1) + i, IIf(i = 0, &hFFFFA6C9, &hFFA6C8FF))
        Next
    End If
End Sub

' ---------------- icons ----------------

Sub Icon_Draw(ByVal icon As Long, ByVal cx As Single, ByVal cy As Single, ByVal size As Single, ByVal col As ULong, ByVal t As Single)
    If iconCv = 0 Then Exit Sub
    Dim ByRef As Canvas c = *iconCv
    Dim As Single r = size / 2
    Dim As Single lw = size / 12 + 1
    Select Case icon
    Case ICON_FLOWER
        Scene_Flower(c, cx, cy, r * 0.95, 6, col, Col_Mix(col, &hFFFFD86B, 0.7), 1, t * 0.3)
    Case ICON_WIND
        For i As Long = 0 To 2
            Dim As Single yy = cy - r * 0.5 + i * r * 0.5
            Dim As Single x0 = cx - r * 0.85, x1 = cx + r * (0.35 - (i Mod 2) * 0.25)
            Cv_Line(c, x0, yy, x1, yy, lw, col)
            Cv_Ring(c, x1, yy - r * 0.18, r * 0.18, lw, col)
        Next
    Case ICON_MOON
        ' crescent: outer arc of one circle, inner arc of an offset circle
        Dim As Single xs(0 To 47), ys(0 To 47)
        For i As Long = 0 To 23
            Dim As Single a = PI * 0.28 + i / 23 * PI * 1.44
            xs(i) = cx + Cos(a) * r * 0.82
            ys(i) = cy + Sin(a) * r * 0.82
        Next
        For i As Long = 0 To 23
            Dim As Single a = PI * 1.72 - i / 23 * PI * 1.44 + PI * 0.0
            Dim As Single a2 = PI * 0.28 + (23 - i) / 23 * PI * 1.44
            xs(24 + i) = cx + r * 0.38 + Cos(a2) * r * 0.62
            ys(24 + i) = cy - r * 0.12 + Sin(a2) * r * 0.62
        Next
        Cv_FillPoly(c, xs(), ys(), 48, col)
        Cv_FillCircle(c, cx + r * 0.55, cy - r * 0.62, r * 0.09, col)
        Cv_FillCircle(c, cx + r * 0.8, cy - r * 0.25, r * 0.06, col)
    Case ICON_LOTUS
        For i As Long = -2 To 2
            Dim As Single a = -PI / 2 + i * 0.42
            Cv_FillEllipse(c, cx + Cos(a) * r * 0.42, cy + r * 0.1 + Sin(a) * r * 0.42, r * 0.5, r * 0.2, a, IIf(i = 0, col, Col_Mix(col, &hFFFFFFFF, 0.3)))
        Next
        Cv_FillEllipse(c, cx, cy + r * 0.62, r * 0.9, r * 0.14, 0, Col_Mix(col, &hFF000000, 0.2))
    Case ICON_WAVE
        For i As Long = 0 To 48
            Dim As Single xx = cx - r + i * size / 48
            Dim As Single yy = cy + Sin(i / 48 * TAU * 1.5 + t) * r * 0.45
            Cv_FillCircle(c, xx, yy, lw * 0.75, col)
        Next
    Case ICON_KITE
        Dim As Single xs(0 To 3) = {cx, cx + r * 0.6, cx, cx - r * 0.6}
        Dim As Single ys(0 To 3) = {cy - r * 0.9, cy - r * 0.2, cy + r * 0.5, cy - r * 0.2}
        Cv_FillPoly(c, xs(), ys(), 4, col)
        Cv_Line(c, cx, cy + r * 0.5, cx - r * 0.3, cy + r * 0.95, lw * 0.7, col)
    Case ICON_TIMER
        Cv_Ring(c, cx, cy + r * 0.08, r * 0.78, lw, col)
        Cv_Line(c, cx, cy + r * 0.08, cx, cy - r * 0.42, lw, col)
        Cv_Line(c, cx, cy + r * 0.08, cx + r * 0.35, cy + r * 0.25, lw, col)
        Cv_FillRoundRect(c, cx - r * 0.2, cy - r * 0.98, r * 0.4, r * 0.18, 2, col)
    Case ICON_CHART
        For i As Long = 0 To 3
            Dim As Single bh = r * (0.5 + 0.35 * ((i * 7) Mod 4) / 3 + i * 0.1)
            Cv_FillRoundRect(c, cx - r * 0.85 + i * r * 0.46, cy + r * 0.8 - bh, r * 0.32, bh, 2, col)
        Next
    Case ICON_GEAR
        For i As Long = 0 To 7
            Dim As Single a = i * TAU / 8 + t * 0.2
            Cv_FillEllipse(c, cx + Cos(a) * r * 0.72, cy + Sin(a) * r * 0.72, r * 0.2, r * 0.16, a, col)
        Next
        Cv_Ring(c, cx, cy, r * 0.5, r * 0.28, col)
    Case ICON_INFO
        Cv_Ring(c, cx, cy, r * 0.85, lw, col)
        Cv_FillCircle(c, cx, cy - r * 0.38, r * 0.11, col)
        Cv_FillRoundRect(c, cx - r * 0.09, cy - r * 0.15, r * 0.18, r * 0.62, 1, col)
    Case ICON_ARROW_LEFT, ICON_ARROW_RIGHT
        Dim As Single d = IIf(icon = ICON_ARROW_LEFT, -1, 1)
        Cv_Line(c, cx - d * r * 0.6, cy, cx + d * r * 0.6, cy, lw * 1.3, col)
        Cv_Line(c, cx + d * r * 0.6, cy, cx + d * r * 0.1, cy - r * 0.5, lw * 1.3, col)
        Cv_Line(c, cx + d * r * 0.6, cy, cx + d * r * 0.1, cy + r * 0.5, lw * 1.3, col)
    Case ICON_SOUND, ICON_MUTE
        Dim As Single xs(0 To 5) = {cx - r * 0.8, cx - r * 0.4, cx + r * 0.05, cx + r * 0.05, cx - r * 0.4, cx - r * 0.8}
        Dim As Single ys(0 To 5) = {cy - r * 0.3, cy - r * 0.3, cy - r * 0.75, cy + r * 0.75, cy + r * 0.3, cy + r * 0.3}
        Cv_FillPoly(c, xs(), ys(), 6, col)
        If icon = ICON_SOUND Then
            Dim As Single px = 0, py = 0
            For k As Long = 1 To 2
                Dim As Single rr = r * (0.35 + k * 0.25)
                For i As Long = 0 To 8
                    Dim As Single a = -0.8 + i * 0.2
                    Dim As Single xx = cx + Cos(a) * rr, yy = cy + Sin(a) * rr
                    If i > 0 Then Cv_Line(c, px, py, xx, yy, lw * 0.9, col)
                    px = xx: py = yy
                Next
            Next
        Else
            Cv_Line(c, cx + r * 0.3, cy - r * 0.35, cx + r * 0.9, cy + r * 0.35, lw * 1.1, col)
            Cv_Line(c, cx + r * 0.3, cy + r * 0.35, cx + r * 0.9, cy - r * 0.35, lw * 1.1, col)
        End If
    Case ICON_PLAY
        Dim As Single xs(0 To 2) = {cx - r * 0.45, cx + r * 0.7, cx - r * 0.45}
        Dim As Single ys(0 To 2) = {cy - r * 0.7, cy, cy + r * 0.7}
        Cv_FillPoly(c, xs(), ys(), 3, col)
    Case ICON_PAUSE
        Cv_FillRoundRect(c, cx - r * 0.55, cy - r * 0.65, r * 0.38, r * 1.3, 2, col)
        Cv_FillRoundRect(c, cx + r * 0.17, cy - r * 0.65, r * 0.38, r * 1.3, 2, col)
    Case ICON_STOP
        Cv_FillRoundRect(c, cx - r * 0.6, cy - r * 0.6, r * 1.2, r * 1.2, r * 0.2, col)
    Case ICON_STAR
        Scene_Star(c, cx, cy, r * 0.95, t * 0.2, col)
    Case ICON_BALLOON
        Scene_Balloon(c, cx, cy - r * 0.25, r * 0.55, col, 0)
    Case ICON_CLOUD
        Scene_Cloud(c, cx, cy + r * 0.2, r * 0.7, col)
    Case ICON_SUN
        For i As Long = 0 To 7
            Dim As Single a = i * TAU / 8 + t * 0.2
            Cv_Line(c, cx + Cos(a) * r * 0.6, cy + Sin(a) * r * 0.6, cx + Cos(a) * r * 0.92, cy + Sin(a) * r * 0.92, lw, col)
        Next
        Cv_FillCircle(c, cx, cy, r * 0.45, col)
    Case ICON_FISH
        Scene_Fish(c, cx + r * 0.15, cy, r * 0.62, 1, col, t)
    Case ICON_TREE
        Scene_Tree(c, cx, cy + r * 0.9, size * 0.95, 1, col, 0)
    Case ICON_HEART
        Cv_FillCircle(c, cx - r * 0.38, cy - r * 0.2, r * 0.42, col)
        Cv_FillCircle(c, cx + r * 0.38, cy - r * 0.2, r * 0.42, col)
        Dim As Single xs(0 To 2) = {cx - r * 0.78, cx + r * 0.78, cx}
        Dim As Single ys(0 To 2) = {cy - r * 0.05, cy - r * 0.05, cy + r * 0.8}
        Cv_FillPoly(c, xs(), ys(), 3, col)
    Case ICON_CHECK
        Cv_Line(c, cx - r * 0.6, cy, cx - r * 0.15, cy + r * 0.45, lw * 1.5, col)
        Cv_Line(c, cx - r * 0.15, cy + r * 0.45, cx + r * 0.7, cy - r * 0.5, lw * 1.5, col)
    Case ICON_EYE
        Cv_FillEllipse(c, cx, cy, r * 0.9, r * 0.5, 0, col)
        Cv_FillEllipse(c, cx, cy, r * 0.75, r * 0.36, 0, &hFFFFFFFF)
        Cv_FillCircle(c, cx, cy, r * 0.3, col)
    Case ICON_LEAF
        Scene_Leaf(c, cx, cy, r * 0.85, -0.7, col)
    Case ICON_BELL
        Cv_FillEllipse(c, cx, cy - r * 0.1, r * 0.55, r * 0.62, 0, col)
        Cv_FillRoundRect(c, cx - r * 0.75, cy + r * 0.25, r * 1.5, r * 0.25, r * 0.1, col)
        Cv_FillCircle(c, cx, cy + r * 0.68, r * 0.15, col)
    Case ICON_PLUS
        Cv_Line(c, cx - r * 0.65, cy, cx + r * 0.65, cy, lw * 1.5, col)
        Cv_Line(c, cx, cy - r * 0.65, cx, cy + r * 0.65, lw * 1.5, col)
    Case ICON_TRASH
        Cv_FillRoundRect(c, cx - r * 0.5, cy - r * 0.45, r, r * 1.3, r * 0.12, col)
        Cv_FillRoundRect(c, cx - r * 0.7, cy - r * 0.68, r * 1.4, r * 0.16, 1, col)
        Cv_FillRoundRect(c, cx - r * 0.2, cy - r * 0.85, r * 0.4, r * 0.18, 1, col)
    Case ICON_HAND
        Cv_FillRoundRect(c, cx - r * 0.45, cy - r * 0.1, r * 0.9, r * 0.9, r * 0.3, col)
        For i As Long = 0 To 3
            Cv_FillRoundRect(c, cx - r * 0.45 + i * r * 0.24, cy - r * 0.8, r * 0.19, r * 0.85, r * 0.09, col)
        Next
        Cv_FillEllipse(c, cx - r * 0.6, cy + r * 0.05, r * 0.32, r * 0.12, -0.8, col)
    Case ICON_BODY
        Cv_FillCircle(c, cx, cy - r * 0.62, r * 0.25, col)
        Cv_FillRoundRect(c, cx - r * 0.3, cy - r * 0.3, r * 0.6, r * 0.75, r * 0.2, col)
        Cv_Line(c, cx - r * 0.3, cy - r * 0.2, cx - r * 0.75, cy + r * 0.2, lw * 1.3, col)
        Cv_Line(c, cx + r * 0.3, cy - r * 0.2, cx + r * 0.75, cy + r * 0.2, lw * 1.3, col)
        Cv_Line(c, cx - r * 0.15, cy + r * 0.4, cx - r * 0.25, cy + r * 0.95, lw * 1.3, col)
        Cv_Line(c, cx + r * 0.15, cy + r * 0.4, cx + r * 0.25, cy + r * 0.95, lw * 1.3, col)
    End Select
End Sub
