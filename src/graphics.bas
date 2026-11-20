' graphics.bas - software canvas and anti-aliased drawing
#include once "graphics.bi"
#include once "crt/string.bi"

Function MkColor(ByVal r As Long, ByVal g As Long, ByVal b As Long, ByVal a As Long = 255) As ULong
    If r < 0 Then r = 0
    If r > 255 Then r = 255
    If g < 0 Then g = 0
    If g > 255 Then g = 255
    If b < 0 Then b = 0
    If b > 255 Then b = 255
    If a < 0 Then a = 0
    If a > 255 Then a = 255
    Return (CULng(a) Shl 24) Or (CULng(r) Shl 16) Or (CULng(g) Shl 8) Or CULng(b)
End Function

Function Col_Mix(ByVal c1 As ULong, ByVal c2 As ULong, ByVal t As Single) As ULong
    If t < 0 Then t = 0
    If t > 1 Then t = 1
    Return MkColor(CLng(ARGB_R(c1) + (ARGB_R(c2) - ARGB_R(c1)) * t), _
                   CLng(ARGB_G(c1) + (ARGB_G(c2) - ARGB_G(c1)) * t), _
                   CLng(ARGB_B(c1) + (ARGB_B(c2) - ARGB_B(c1)) * t), _
                   CLng(ARGB_A(c1) + (ARGB_A(c2) - ARGB_A(c1)) * t))
End Function

Function Col_Alpha(ByVal c As ULong, ByVal a As Long) As ULong
    Return MkColor(ARGB_R(c), ARGB_G(c), ARGB_B(c), a)
End Function

Function Col_Lum(ByVal c As ULong) As Single
    Return (0.299 * ARGB_R(c) + 0.587 * ARGB_G(c) + 0.114 * ARGB_B(c)) / 255.0
End Function

' Blend col into *p with coverage a (0..256, already including the colour alpha).
#macro BLENDPX(p, col, a)
    Scope
        Dim As Long _a = (a)
        If _a >= 256 Then
            *(p) = (col) Or &hFF000000
        ElseIf _a > 0 Then
            Dim As ULong _d = *(p)
            Dim As Long _dr = ARGB_R(_d), _dg = ARGB_G(_d), _db = ARGB_B(_d)
            _dr += ((ARGB_R(col) - _dr) * _a) Shr 8
            _dg += ((ARGB_G(col) - _dg) * _a) Shr 8
            _db += ((ARGB_B(col) - _db) * _a) Shr 8
            *(p) = &hFF000000 Or (CULng(_dr) Shl 16) Or (CULng(_dg) Shl 8) Or CULng(_db)
        End If
    End Scope
#endmacro

Sub Cv_Create(ByRef c As Canvas, ByVal w As Long, ByVal h As Long)
    If c.px Then Deallocate(c.px)
    If w < 1 Then w = 1
    If h < 1 Then h = 1
    c.w = w: c.h = h
    c.px = Callocate(w * h, SizeOf(ULong))
    c.cx0 = 0: c.cy0 = 0: c.cx1 = w: c.cy1 = h
    c.clipSP = 0
End Sub

Sub Cv_Free(ByRef c As Canvas)
    If c.px Then Deallocate(c.px)
    c.px = 0
    c.w = 0: c.h = 0
End Sub

Sub Cv_Clear(ByRef c As Canvas, ByVal col As ULong)
    Dim As ULong v = col Or &hFF000000
    For i As Long = 0 To c.w * c.h - 1
        c.px[i] = v
    Next
End Sub

Sub Cv_PushClip(ByRef c As Canvas, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long)
    If c.clipSP <= 60 Then
        c.clipStack(c.clipSP) = c.cx0: c.clipStack(c.clipSP + 1) = c.cy0
        c.clipStack(c.clipSP + 2) = c.cx1: c.clipStack(c.clipSP + 3) = c.cy1
        c.clipSP += 4
    End If
    If x > c.cx0 Then c.cx0 = x
    If y > c.cy0 Then c.cy0 = y
    If x + w < c.cx1 Then c.cx1 = x + w
    If y + h < c.cy1 Then c.cy1 = y + h
    If c.cx1 < c.cx0 Then c.cx1 = c.cx0
    If c.cy1 < c.cy0 Then c.cy1 = c.cy0
End Sub

Sub Cv_PopClip(ByRef c As Canvas)
    If c.clipSP >= 4 Then
        c.clipSP -= 4
        c.cx0 = c.clipStack(c.clipSP): c.cy0 = c.clipStack(c.clipSP + 1)
        c.cx1 = c.clipStack(c.clipSP + 2): c.cy1 = c.clipStack(c.clipSP + 3)
    Else
        c.cx0 = 0: c.cy0 = 0: c.cx1 = c.w: c.cy1 = c.h
    End If
End Sub

Sub Cv_FillRect(ByRef c As Canvas, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long, ByVal col As ULong)
    Dim As Long x0 = x, y0 = y, x1 = x + w, y1 = y + h
    If x0 < c.cx0 Then x0 = c.cx0
    If y0 < c.cy0 Then y0 = c.cy0
    If x1 > c.cx1 Then x1 = c.cx1
    If y1 > c.cy1 Then y1 = c.cy1
    If x1 <= x0 OrElse y1 <= y0 Then Exit Sub
    Dim As Long a = ARGB_A(col)
    a += a Shr 7
    For yy As Long = y0 To y1 - 1
        Dim As ULong Ptr p = c.px + yy * c.w + x0
        If a >= 256 Then
            Dim As ULong v = col Or &hFF000000
            For xx As Long = x0 To x1 - 1
                *p = v: p += 1
            Next
        Else
            For xx As Long = x0 To x1 - 1
                BLENDPX(p, col, a)
                p += 1
            Next
        End If
    Next
End Sub

Sub Cv_Rect(ByRef c As Canvas, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long, ByVal t As Long, ByVal col As ULong)
    Cv_FillRect(c, x, y, w, t, col)
    Cv_FillRect(c, x, y + h - t, w, t, col)
    Cv_FillRect(c, x, y + t, t, h - 2 * t, col)
    Cv_FillRect(c, x + w - t, y + t, t, h - 2 * t, col)
End Sub

Sub Cv_VGradient(ByRef c As Canvas, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long, ByVal c1 As ULong, ByVal c2 As ULong)
    If h <= 0 Then Exit Sub
    For yy As Long = 0 To h - 1
        Cv_FillRect(c, x, y + yy, w, 1, Col_Mix(c1, c2, yy / IIf(h > 1, h - 1, 1)))
    Next
End Sub

Private Function Clampf(ByVal v As Single) As Single
    If v < 0 Then Return 0
    If v > 1 Then Return 1
    Return v
End Function

' approximate pixel coverage of a rounded box from its signed distance
Private Function RRCov(ByVal px As Single, ByVal py As Single, ByVal hx As Single, ByVal hy As Single, ByVal cx As Single, ByVal cy As Single, ByVal r As Single) As Single
    Dim As Single qx = Abs(px - cx) - (hx - r)
    Dim As Single qy = Abs(py - cy) - (hy - r)
    Dim As Single mx = IIf(qx > 0, qx, 0), my = IIf(qy > 0, qy, 0)
    Dim As Single inside = IIf(qx > qy, qx, qy)
    If inside > 0 Then inside = 0
    Dim As Single d = Sqr(mx * mx + my * my) + inside - r
    Return Clampf(0.5 - d)
End Function

Sub Cv_FillRoundRect(ByRef c As Canvas, ByVal x As Single, ByVal y As Single, ByVal w As Single, ByVal h As Single, ByVal r As Single, ByVal col As ULong)
    If w <= 0 OrElse h <= 0 Then Exit Sub
    If r > w / 2 Then r = w / 2
    If r > h / 2 Then r = h / 2
    If r < 0 Then r = 0
    Dim As Single hx = w / 2, hy = h / 2, cx = x + hx, cy = y + hy
    Dim As Long ix0 = Int(x), iy0 = Int(y), ix1 = -Int(-(x + w)), iy1 = -Int(-(y + h))
    If ix0 < c.cx0 Then ix0 = c.cx0
    If iy0 < c.cy0 Then iy0 = c.cy0
    If ix1 > c.cx1 Then ix1 = c.cx1
    If iy1 > c.cy1 Then iy1 = c.cy1
    If ix1 <= ix0 OrElse iy1 <= iy0 Then Exit Sub
    Dim As Long ca = ARGB_A(col)
    ca += ca Shr 7
    ' interior columns that are fully covered in "straight" rows
    Dim As Long fx0 = -Int(-(x + 1)), fx1 = Int(x + w - 1)
    For py As Long = iy0 To iy1 - 1
        Dim As Single yc = py + 0.5
        Dim As ULong Ptr rowp = c.px + py * c.w
        Dim As Long straight = (yc - 0.5 >= y + r + 0.5) AndAlso (yc + 0.5 <= y + h - r - 0.5)
        If straight AndAlso fx1 > fx0 Then
            For px As Long = ix0 To ix1 - 1
                If px >= fx0 AndAlso px < fx1 Then
                    If px < c.cx1 Then
                        Dim As Long e = fx1
                        If e > ix1 Then e = ix1
                        For q As Long = px To e - 1
                            BLENDPX(rowp + q, col, ca)
                        Next
                        px = e - 1
                    End If
                Else
                    Dim As Single cv = RRCov(px + 0.5, yc, hx, hy, cx, cy, r)
                    BLENDPX(rowp + px, col, CLng(cv * ca))
                End If
            Next
        Else
            For px As Long = ix0 To ix1 - 1
                Dim As Single cv = RRCov(px + 0.5, yc, hx, hy, cx, cy, r)
                If cv > 0 Then
                    BLENDPX(rowp + px, col, CLng(cv * ca))
                End If
            Next
        End If
    Next
End Sub

Sub Cv_RoundRectOutline(ByRef c As Canvas, ByVal x As Single, ByVal y As Single, ByVal w As Single, ByVal h As Single, ByVal r As Single, ByVal t As Single, ByVal col As ULong)
    If w <= 0 OrElse h <= 0 Then Exit Sub
    If r > w / 2 Then r = w / 2
    If r > h / 2 Then r = h / 2
    Dim As Single hx = w / 2, hy = h / 2, cx = x + hx, cy = y + hy
    Dim As Single ihx = hx - t, ihy = hy - t, ir = r - t
    If ir < 0 Then ir = 0
    Dim As Long ix0 = Int(x), iy0 = Int(y), ix1 = -Int(-(x + w)), iy1 = -Int(-(y + h))
    If ix0 < c.cx0 Then ix0 = c.cx0
    If iy0 < c.cy0 Then iy0 = c.cy0
    If ix1 > c.cx1 Then ix1 = c.cx1
    If iy1 > c.cy1 Then iy1 = c.cy1
    Dim As Long ca = ARGB_A(col)
    ca += ca Shr 7
    Dim As Long band = CLng(t + r + 2)
    For py As Long = iy0 To iy1 - 1
        Dim As Single yc = py + 0.5
        Dim As ULong Ptr rowp = c.px + py * c.w
        Dim As Long nearTB = (yc < y + band) OrElse (yc > y + h - band)
        For px As Long = ix0 To ix1 - 1
            If nearTB = 0 AndAlso px > x + band AndAlso px < x + w - band Then
                px = CLng(x + w - band)
                Continue For
            End If
            Dim As Single co = RRCov(px + 0.5, yc, hx, hy, cx, cy, r)
            If co <= 0 Then Continue For
            Dim As Single ci = 0
            If ihx > 0 AndAlso ihy > 0 Then ci = RRCov(px + 0.5, yc, ihx, ihy, cx, cy, ir)
            Dim As Single cv = co - ci
            If cv > 0 Then
                BLENDPX(rowp + px, col, CLng(cv * ca))
            End If
        Next
    Next
End Sub

Sub Cv_FillCircle(ByRef c As Canvas, ByVal cx As Single, ByVal cy As Single, ByVal r As Single, ByVal col As ULong)
    Dim As Long ix0 = Int(cx - r - 1), iy0 = Int(cy - r - 1), ix1 = Int(cx + r + 2), iy1 = Int(cy + r + 2)
    If ix0 < c.cx0 Then ix0 = c.cx0
    If iy0 < c.cy0 Then iy0 = c.cy0
    If ix1 > c.cx1 Then ix1 = c.cx1
    If iy1 > c.cy1 Then iy1 = c.cy1
    Dim As Long ca = ARGB_A(col)
    ca += ca Shr 7
    For py As Long = iy0 To iy1 - 1
        Dim As Single dy = py + 0.5 - cy
        For px As Long = ix0 To ix1 - 1
            Dim As Single dx = px + 0.5 - cx
            Dim As Single cv = Clampf(r + 0.5 - Sqr(dx * dx + dy * dy))
            If cv > 0 Then
                BLENDPX(c.px + py * c.w + px, col, CLng(cv * ca))
            End If
        Next
    Next
End Sub

Sub Cv_Ring(ByRef c As Canvas, ByVal cx As Single, ByVal cy As Single, ByVal r As Single, ByVal t As Single, ByVal col As ULong)
    Dim As Long ix0 = Int(cx - r - 1), iy0 = Int(cy - r - 1), ix1 = Int(cx + r + 2), iy1 = Int(cy + r + 2)
    If ix0 < c.cx0 Then ix0 = c.cx0
    If iy0 < c.cy0 Then iy0 = c.cy0
    If ix1 > c.cx1 Then ix1 = c.cx1
    If iy1 > c.cy1 Then iy1 = c.cy1
    Dim As Long ca = ARGB_A(col)
    ca += ca Shr 7
    Dim As Single rm = r - t / 2
    For py As Long = iy0 To iy1 - 1
        Dim As Single dy = py + 0.5 - cy
        For px As Long = ix0 To ix1 - 1
            Dim As Single dx = px + 0.5 - cx
            Dim As Single cv = Clampf(t / 2 + 0.5 - Abs(Sqr(dx * dx + dy * dy) - rm))
            If cv > 0 Then
                BLENDPX(c.px + py * c.w + px, col, CLng(cv * ca))
            End If
        Next
    Next
End Sub

Sub Cv_BlitMask(ByRef c As Canvas, ByVal x As Long, ByVal y As Long, ByVal mask As UByte Ptr, ByVal mw As Long, ByVal mh As Long, ByVal col As ULong)
    If mask = 0 Then Exit Sub
    Dim As Long x0 = x, y0 = y, x1 = x + mw, y1 = y + mh
    If x0 < c.cx0 Then x0 = c.cx0
    If y0 < c.cy0 Then y0 = c.cy0
    If x1 > c.cx1 Then x1 = c.cx1
    If y1 > c.cy1 Then y1 = c.cy1
    If x1 <= x0 OrElse y1 <= y0 Then Exit Sub
    Dim As Long ca = ARGB_A(col)
    ca += ca Shr 7
    For yy As Long = y0 To y1 - 1
        Dim As UByte Ptr m = mask + (yy - y) * mw + (x0 - x)
        Dim As ULong Ptr p = c.px + yy * c.w + x0
        For xx As Long = x0 To x1 - 1
            Dim As Long a = *m
            If a Then
                a += a Shr 7
                BLENDPX(p, col, (a * ca) Shr 8)
            End If
            m += 1: p += 1
        Next
    Next
End Sub

' ---------------- rasterizer ----------------

Dim Shared As Raster gRas
Dim Shared As UByte Ptr gMask
Dim Shared As Long gMaskCap

Sub Ras_Begin(ByRef r As Raster, ByVal w As Long, ByVal h As Long)
    Dim As Long need = w * h + w + 4
    If need > r.cap Then
        If r.acc Then Deallocate(r.acc)
        r.acc = Allocate(need * SizeOf(Single))
        r.cap = need
    End If
    memset(r.acc, 0, need * SizeOf(Single))
    r.w = w: r.h = h
End Sub

Sub Ras_Free(ByRef r As Raster)
    If r.acc Then Deallocate(r.acc)
    r.acc = 0: r.cap = 0
End Sub

Private Sub Ras_LineRaw(ByRef r As Raster, ByVal x0 As Single, ByVal y0 As Single, ByVal x1 As Single, ByVal y1 As Single)
    If Abs(y0 - y1) < 1e-6 Then Exit Sub
    Dim As Single dir1 = 1
    If y0 > y1 Then
        Swap x0, x1: Swap y0, y1
        dir1 = -1
    End If
    Dim As Single dxdy = (x1 - x0) / (y1 - y0)
    Dim As Single x = x0
    If y0 < 0 Then x -= y0 * dxdy
    Dim As Long ys = IIf(y0 > 0, Int(y0), 0)
    Dim As Long ye = -Int(-y1)
    If ye > r.h Then ye = r.h
    Dim As Single Ptr a = r.acc
    Dim As Long w = r.w
    For y As Long = ys To ye - 1
        Dim As Long ls = y * w
        Dim As Single ytop = IIf(y > y0, CSng(y), y0)
        Dim As Single ybot = IIf(y + 1 < y1, CSng(y + 1), y1)
        Dim As Single dy = ybot - ytop
        Dim As Single xnext = x + dxdy * dy
        Dim As Single d = dy * dir1
        Dim As Single xa = x, xb = xnext
        If xa > xb Then Swap xa, xb
        Dim As Single xa_fl = Int(xa)
        Dim As Long xai = CLng(xa_fl)
        Dim As Single xb_ce = -Int(-xb)
        Dim As Long xbi = CLng(xb_ce)
        If xai < 0 Then xai = 0
        If xbi <= xai + 1 Then
            Dim As Single xmf = 0.5 * (x + xnext) - xa_fl
            a[ls + xai] += d - d * xmf
            a[ls + xai + 1] += d * xmf
        Else
            Dim As Single s = 1.0 / (xb - xa)
            Dim As Single x0f = xa - xa_fl
            Dim As Single a0 = 0.5 * s * (1 - x0f) * (1 - x0f)
            Dim As Single x1f = xb - xb_ce + 1
            Dim As Single am = 0.5 * s * x1f * x1f
            a[ls + xai] += d * a0
            If xbi = xai + 2 Then
                a[ls + xai + 1] += d * (1 - a0 - am)
            Else
                Dim As Single a1 = s * (1.5 - x0f)
                a[ls + xai + 1] += d * (a1 - a0)
                For xi As Long = xai + 2 To xbi - 2
                    a[ls + xi] += d * s
                Next
                Dim As Single a2 = a1 + (xbi - xai - 3) * s
                a[ls + xbi - 1] += d * (1 - a2 - am)
            End If
            a[ls + xbi] += d * am
        End If
        x = xnext
    Next
End Sub

' Clips against x = 0 and x = w: parts outside become vertical edges on the border,
' which keeps the winding accumulation correct for the visible pixels.
Sub Ras_Line(ByRef r As Raster, ByVal x0 As Single, ByVal y0 As Single, ByVal x1 As Single, ByVal y1 As Single)
    Dim As Single lim(0 To 1) = {0, CSng(r.w)}
    ' split at x = 0 and x = w
    Dim As Single xs(0 To 3), ys(0 To 3)
    Dim As Long n = 0
    xs(0) = x0: ys(0) = y0: n = 1
    Dim As Single tvals(0 To 1)
    Dim As Long nt = 0
    For k As Long = 0 To 1
        If (x0 - lim(k)) * (x1 - lim(k)) < 0 Then
            tvals(nt) = (lim(k) - x0) / (x1 - x0): nt += 1
        End If
    Next
    If nt = 2 AndAlso tvals(0) > tvals(1) Then Swap tvals(0), tvals(1)
    For k As Long = 0 To nt - 1
        xs(n) = x0 + (x1 - x0) * tvals(k): ys(n) = y0 + (y1 - y0) * tvals(k): n += 1
    Next
    xs(n) = x1: ys(n) = y1: n += 1
    For k As Long = 0 To n - 2
        Dim As Single ax = xs(k), bx = xs(k + 1)
        Dim As Single mx = (ax + bx) / 2
        If mx <= 0 Then
            ax = 0: bx = 0
        ElseIf mx >= r.w Then
            ax = r.w: bx = r.w
        Else
            If ax < 0 Then ax = 0
            If bx < 0 Then bx = 0
            If ax > r.w Then ax = r.w
            If bx > r.w Then bx = r.w
        End If
        Ras_LineRaw(r, ax, ys(k), bx, ys(k + 1))
    Next
End Sub

Sub Ras_End(ByRef r As Raster, ByVal outMask As UByte Ptr)
    Dim As Single acc = 0
    Dim As Long n = r.w * r.h
    For i As Long = 0 To n - 1
        acc += r.acc[i]
        Dim As Single v = Abs(acc)
        If v > 1 Then v = 1
        outMask[i] = CLng(v * 255)      ' CLng rounds; a rounded 255.5 would wrap to 0 in a UByte
    Next
End Sub

Sub Cv_FillPoly(ByRef c As Canvas, xs() As Single, ys() As Single, ByVal n As Long, ByVal col As ULong)
    If n < 3 Then Exit Sub
    Dim As Single mnx = xs(0), mxx = xs(0), mny = ys(0), mxy = ys(0)
    For i As Long = 1 To n - 1
        If xs(i) < mnx Then mnx = xs(i)
        If xs(i) > mxx Then mxx = xs(i)
        If ys(i) < mny Then mny = ys(i)
        If ys(i) > mxy Then mxy = ys(i)
    Next
    Dim As Long bx0 = Int(mnx), by0 = Int(mny), bx1 = -Int(-mxx) + 1, by1 = -Int(-mxy) + 1
    If bx0 < c.cx0 Then bx0 = c.cx0
    If by0 < c.cy0 Then by0 = c.cy0
    If bx1 > c.cx1 Then bx1 = c.cx1
    If by1 > c.cy1 Then by1 = c.cy1
    Dim As Long bw = bx1 - bx0, bh = by1 - by0
    If bw <= 0 OrElse bh <= 0 Then Exit Sub
    Ras_Begin(gRas, bw, bh)
    For i As Long = 0 To n - 1
        Dim As Long j = (i + 1) Mod n
        Ras_Line(gRas, xs(i) - bx0, ys(i) - by0, xs(j) - bx0, ys(j) - by0)
    Next
    If bw * bh > gMaskCap Then
        If gMask Then Deallocate(gMask)
        gMaskCap = bw * bh
        gMask = Allocate(gMaskCap)
    End If
    Ras_End(gRas, gMask)
    Cv_BlitMask(c, bx0, by0, gMask, bw, bh, col)
End Sub

Sub Cv_Line(ByRef c As Canvas, ByVal x0 As Single, ByVal y0 As Single, ByVal x1 As Single, ByVal y1 As Single, ByVal t As Single, ByVal col As ULong)
    Dim As Single dx = x1 - x0, dy = y1 - y0
    Dim As Single ln = Sqr(dx * dx + dy * dy)
    If ln < 0.01 Then Exit Sub
    Dim As Single nx = -dy / ln * t / 2, ny = dx / ln * t / 2
    Dim As Single xs(0 To 3) = {x0 + nx, x1 + nx, x1 - nx, x0 - nx}
    Dim As Single ys(0 To 3) = {y0 + ny, y1 + ny, y1 - ny, y0 - ny}
    Cv_FillPoly(c, xs(), ys(), 4, col)
End Sub

Sub Cv_Arrow(ByRef c As Canvas, ByVal x0 As Single, ByVal y0 As Single, ByVal x1 As Single, ByVal y1 As Single, ByVal t As Single, ByVal col As ULong)
    Dim As Single dx = x1 - x0, dy = y1 - y0
    Dim As Single ln = Sqr(dx * dx + dy * dy)
    If ln < 1 Then Exit Sub
    Dim As Single ux = dx / ln, uy = dy / ln
    Dim As Single hl = t * 2.6, hw = t * 1.6
    If hl > ln * 0.6 Then hl = ln * 0.6
    Dim As Single bxp = x1 - ux * hl, byp = y1 - uy * hl
    Dim As Single nx = -uy, ny = ux
    Dim As Single xs(0 To 6) = {x0 + nx * t / 2, bxp + nx * t / 2, bxp + nx * hw, x1, bxp - nx * hw, bxp - nx * t / 2, x0 - nx * t / 2}
    Dim As Single ys(0 To 6) = {y0 + ny * t / 2, byp + ny * t / 2, byp + ny * hw, y1, byp - ny * hw, byp - ny * t / 2, y0 - ny * t / 2}
    Cv_FillPoly(c, xs(), ys(), 7, col)
End Sub

Function Cv_SaveBMP(ByRef c As Canvas, ByRef fileName As String) As Boolean
    Dim As Long rowBytes = ((c.w * 3 + 3) \ 4) * 4
    Dim As Long imgSize = rowBytes * c.h
    Dim As Long f = FreeFile
    If Open(fileName For Binary Access Write As #f) <> 0 Then Return False
    Dim As UByte hdr(0 To 53)
    Dim As ULong fsize = 54 + imgSize
    hdr(0) = Asc("B"): hdr(1) = Asc("M")
    For i As Long = 0 To 3: hdr(2 + i) = (fsize Shr (8 * i)) And 255: Next
    hdr(10) = 54
    hdr(14) = 40
    For i As Long = 0 To 3
        hdr(18 + i) = (CULng(c.w) Shr (8 * i)) And 255
        hdr(22 + i) = (CULng(c.h) Shr (8 * i)) And 255
        hdr(34 + i) = (CULng(imgSize) Shr (8 * i)) And 255
    Next
    hdr(26) = 1: hdr(28) = 24
    Put #f, , hdr()
    Dim As UByte rowb(0 To rowBytes - 1)
    For y As Long = c.h - 1 To 0 Step -1
        For x As Long = 0 To c.w - 1
            Dim As ULong v = c.px[y * c.w + x]
            rowb(x * 3) = v And 255
            rowb(x * 3 + 1) = (v Shr 8) And 255
            rowb(x * 3 + 2) = (v Shr 16) And 255
        Next
        Put #f, , rowb()
    Next
    Close #f
    Return True
End Function

' ---------------- Calm Garden additions ----------------

' Soft, glowing disc: full alpha in the centre fading smoothly to zero at radius r.
Sub Cv_SoftCircle(ByRef c As Canvas, ByVal cx As Single, ByVal cy As Single, ByVal r As Single, ByVal col As ULong)
    If r < 1 Then Exit Sub
    Dim As Long ix0 = Int(cx - r), iy0 = Int(cy - r), ix1 = Int(cx + r + 1), iy1 = Int(cy + r + 1)
    If ix0 < c.cx0 Then ix0 = c.cx0
    If iy0 < c.cy0 Then iy0 = c.cy0
    If ix1 > c.cx1 Then ix1 = c.cx1
    If iy1 > c.cy1 Then iy1 = c.cy1
    Dim As Long ca = ARGB_A(col)
    Dim As Single inv = 1.0 / (r * r)
    For py As Long = iy0 To iy1 - 1
        Dim As Single dy = py + 0.5 - cy
        For px As Long = ix0 To ix1 - 1
            Dim As Single dx = px + 0.5 - cx
            Dim As Single d2 = (dx * dx + dy * dy) * inv
            If d2 < 1 Then
                Dim As Single f = 1 - d2
                BLENDPX(c.px + py * c.w + px, col, CLng(f * f * ca))
            End If
        Next
    Next
End Sub

' Rotated filled ellipse (petals, leaves, fish bodies, clouds).
Sub Cv_FillEllipse(ByRef c As Canvas, ByVal cx As Single, ByVal cy As Single, ByVal rx As Single, ByVal ry As Single, ByVal ang As Single, ByVal col As ULong)
    If rx < 0.3 OrElse ry < 0.3 Then Exit Sub
    Dim As Long n = 20 + CLng((rx + ry) / 6)
    If n > 72 Then n = 72
    Dim As Single xs(0 To n - 1), ys(0 To n - 1)
    Dim As Single ca = Cos(ang), sa = Sin(ang)
    For i As Long = 0 To n - 1
        Dim As Single t = i * 6.2831853 / n
        Dim As Single ex = Cos(t) * rx, ey = Sin(t) * ry
        xs(i) = cx + ex * ca - ey * sa
        ys(i) = cy + ex * sa + ey * ca
    Next
    Cv_FillPoly(c, xs(), ys(), n, col)
End Sub

' Three-stop vertical gradient (sky: top -> middle -> bottom)
Sub Cv_VGradient3(ByRef c As Canvas, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long, ByVal c1 As ULong, ByVal c2 As ULong, ByVal c3 As ULong)
    Dim As Long h1 = h \ 2
    Cv_VGradient(c, x, y, w, h1, c1, c2)
    Cv_VGradient(c, x, y + h1, w, h - h1, c2, c3)
End Sub
