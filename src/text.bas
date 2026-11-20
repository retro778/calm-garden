' text.bas - SDL2_ttf (HarfBuzz) shaping + UAX #9 bidi layout (see text.bi)
#include once "text.bi"
#include once "bidi.bi"
#include once "sdlttf.bi"

Const FONT_LATIN = 0
Const FONT_LATIN_B = 1
Const FONT_HEB = 2
Const FONT_HEB_B = 3
Const FONT_FALLBACK = 4
Const FONT_FILES = 5
Const MAX_PX = 160

Dim Shared As String gFontPath(0 To FONT_FILES - 1)
Dim Shared As Long gFontOk(0 To FONT_FILES - 1)
Dim Shared As TTF_Font Ptr gOpen(0 To FONT_FILES - 1, 0 To MAX_PX)
Dim Shared As Long gOpenCount
Dim Shared As Long gReady
Dim Shared As String gErr

' ---------------- run cache ----------------
Const RC_SIZE = 4096
Type RunEntry
    key As String
    w As Long          ' advance width (pixels)
    mw As Long         ' mask size
    mh As Long
    mask As UByte Ptr
End Type
Dim Shared As RunEntry gRC(0 To RC_SIZE - 1)
Dim Shared As Long gRCCount
Dim Shared As LongInt gRCBytes

Private Function ClampPx(ByVal size As Long) As Long
    If size < 6 Then Return 6
    If size > MAX_PX Then Return MAX_PX
    Return size
End Function

Private Sub CloseAllFonts()
    For f As Long = 0 To FONT_FILES - 1
        For s As Long = 0 To MAX_PX
            If gOpen(f, s) Then TTF_CloseFont(gOpen(f, s)): gOpen(f, s) = 0
        Next
    Next
    gOpenCount = 0
End Sub

Private Function GetFont(ByVal fileIdx As Long, ByVal size As Long) As TTF_Font Ptr
    If gReady = 0 Then Return 0
    If gFontOk(fileIdx) = 0 Then
        ' substitute: bold -> regular, Hebrew -> fallback, fallback -> Latin
        Select Case fileIdx
        Case FONT_LATIN_B: Return GetFont(FONT_LATIN, size)
        Case FONT_HEB_B: Return GetFont(FONT_HEB, size)
        Case FONT_HEB: Return GetFont(FONT_FALLBACK, size)
        Case FONT_FALLBACK: If gFontOk(FONT_LATIN) Then Return GetFont(FONT_LATIN, size)
        End Select
        Return 0
    End If
    size = ClampPx(size)
    If gOpen(fileIdx, size) = 0 Then
        If gOpenCount >= 48 Then CloseAllFonts()   ' many sizes after a lot of resizing
        gOpen(fileIdx, size) = TTF_OpenFont(StrPtr(gFontPath(fileIdx)), size)
        If gOpen(fileIdx, size) = 0 Then Return 0
        TTF_SetFontHinting(gOpen(fileIdx, size), TTF_HINTING_LIGHT)
        gOpenCount += 1
    End If
    Return gOpen(fileIdx, size)
End Function

Private Function HashStr(ByRef s As String) As ULong
    Dim As ULong h = 2166136261
    For i As Long = 0 To Len(s) - 1
        h = (h Xor s[i]) * 16777619
    Next
    Return h
End Function

Private Sub FreeEntry(ByRef e As RunEntry)
    If e.mask Then gRCBytes -= e.mw * e.mh: Deallocate(e.mask)
    e.mask = 0
    If Len(e.key) Then gRCCount -= 1
    e.key = ""
End Sub

Private Sub ClearRunCache()
    For i As Long = 0 To RC_SIZE - 1
        FreeEntry(gRC(i))
    Next
    gRCCount = 0
    gRCBytes = 0
End Sub

Function Txt_CacheCount() As Long
    Return gRCCount
End Function

Function Txt_LastError() As String
    Return gErr
End Function

Function Txt_Init(ByRef fontDir As String) As Boolean
    If TTF_WasInit() = 0 Then
        If TTF_Init() <> 0 Then gErr = "TTF_Init failed": Return False
    End If
    gFontPath(FONT_LATIN) = fontDir & "/NotoSans-Regular.ttf"
    gFontPath(FONT_LATIN_B) = fontDir & "/NotoSans-Bold.ttf"
    gFontPath(FONT_HEB) = fontDir & "/NotoSansHebrew-Regular.ttf"
    gFontPath(FONT_HEB_B) = fontDir & "/NotoSansHebrew-Bold.ttf"
    gFontPath(FONT_FALLBACK) = fontDir & "/DejaVuSans.ttf"
    Dim As Long any_ = 0
    For f As Long = 0 To FONT_FILES - 1
        Dim As Long fh = FreeFile
        gFontOk(f) = 0
        If Open(gFontPath(f) For Binary Access Read As #fh) = 0 Then
            If LOF(fh) > 100 Then gFontOk(f) = 1: any_ = 1
            Close #fh
        End If
    Next
    If gFontOk(FONT_LATIN) = 0 AndAlso gFontOk(FONT_FALLBACK) = 0 Then
        gErr = "No usable font found in " & fontDir
        Return False
    End If
    gReady = 1
    Return True
End Function

Sub Txt_Shutdown()
    ClearRunCache()
    CloseAllFonts()
    gReady = 0
    If TTF_WasInit() Then TTF_Quit()
End Sub

' ---------------- font choice per character ----------------

Private Function IsHebrew(ByVal cp As Long) As Boolean
    Return (cp >= &h0590 AndAlso cp <= &h05FF) OrElse (cp >= &hFB1D AndAlso cp <= &hFB4F)
End Function

Private Function IsControl(ByVal cp As Long) As Boolean
    Dim As Long c = Bidi_Class(cp)
    Return c = BC_BN OrElse c = BC_LRI OrElse c = BC_RLI OrElse c = BC_FSI OrElse c = BC_PDI OrElse cp = CP_LRM OrElse cp = CP_RLM
End Function

Private Function Provides(ByVal fileIdx As Long, ByVal size As Long, ByVal cp As Long) As Boolean
    Dim As TTF_Font Ptr f = GetFont(fileIdx, size)
    If f = 0 Then Return False
    Return TTF_GlyphIsProvided32(f, cp) <> 0
End Function

' fonts(i) for code points cps(s..e-1)
Private Sub ChooseFonts(cps() As Long, ByVal s As Long, ByVal e As Long, ByVal face As Long, ByVal size As Long, fonts() As Long)
    Dim As Long fL = IIf(face = FACE_BOLD, FONT_LATIN_B, FONT_LATIN)
    Dim As Long fH = IIf(face = FACE_BOLD, FONT_HEB_B, FONT_HEB)
    For i As Long = s To e - 1
        Dim As Long cp = cps(i)
        Dim As Long c = Bidi_Class(cp)
        If IsHebrew(cp) Then
            fonts(i) = fH
        ElseIf c = BC_L OrElse c = BC_EN OrElse c = BC_AN Then
            fonts(i) = fL
        Else
            fonts(i) = -1      ' neutral: decided below
        End If
    Next
    ' neutrals take the font of the previous character (or the next one) when it has the glyph
    For i As Long = s To e - 1
        If fonts(i) >= 0 Then Continue For
        Dim As Long cand = -1
        If i > s AndAlso fonts(i - 1) >= 0 Then cand = fonts(i - 1)
        If cand < 0 Then
            For j As Long = i + 1 To e - 1
                If fonts(j) >= 0 Then cand = fonts(j): Exit For
            Next
        End If
        If cand < 0 Then cand = fL
        If Not Provides(cand, size, cps(i)) Then cand = IIf(cand = fL, fH, fL)
        fonts(i) = cand
    Next
    ' anything still missing goes to the fallback font
    For i As Long = s To e - 1
        If IsControl(cps(i)) Then Continue For
        If Not Provides(fonts(i), size, cps(i)) Then
            If Provides(FONT_FALLBACK, size, cps(i)) Then fonts(i) = FONT_FALLBACK
        End If
    Next
End Sub

' ---------------- shaped runs ----------------

Private Function RunText(cps() As Long, ByVal s As Long, ByVal e As Long) As String
    Dim As String r
    For i As Long = s To e - 1
        If Not IsControl(cps(i)) Then r &= Utf8_Encode(cps(i))
    Next
    Return r
End Function

Private Function RunSlot(ByVal fileIdx As Long, ByVal size As Long, ByVal rtl As Long, ByRef txt As String, ByVal needMask As Long) As Long
    Dim As String key = Chr(48 + fileIdx, 48 + rtl) & MKL(size) & txt
    Dim As Long slot = HashStr(key) And (RC_SIZE - 1)
    If gRC(slot).key = key Then
        If needMask = 0 OrElse gRC(slot).mask <> 0 OrElse gRC(slot).w = 0 Then Return slot
    Else
        FreeEntry(gRC(slot))
        gRC(slot).key = key
        gRCCount += 1
        gRC(slot).w = -1
    End If
    If gRCBytes > 48 * 1024 * 1024 Then
        Dim As String k2 = gRC(slot).key
        ClearRunCache()
        gRC(slot).key = k2: gRCCount = 1: gRC(slot).w = -1
    End If
    Dim As TTF_Font Ptr f = GetFont(fileIdx, size)
    If f = 0 OrElse Len(txt) = 0 Then gRC(slot).w = 0: Return slot
    TTF_SetFontDirection(f, IIf(rtl, TTF_DIRECTION_RTL, TTF_DIRECTION_LTR))
    TTF_SetFontScriptName(f, IIf(fileIdx = FONT_HEB OrElse fileIdx = FONT_HEB_B, "Hebr", "Latn"))
    If gRC(slot).w < 0 Then
        Dim As Long w, h
        If TTF_SizeUTF8(f, StrPtr(txt), @w, @h) <> 0 Then w = 0
        gRC(slot).w = w
    End If
    If needMask AndAlso gRC(slot).mask = 0 Then
        Dim As SDL_Color white = Type(255, 255, 255, 255)
        Dim As SDL_Surface Ptr sf = TTF_RenderUTF8_Blended(f, StrPtr(txt), white)
        If sf Then
            Dim As SDL_Surface Ptr cs = sf
            If sf->format->BytesPerPixel <> 4 Then cs = SDL_ConvertSurfaceFormat(sf, SDL_PIXELFORMAT_ARGB8888, 0)
            If cs Then
                SDL_LockSurface(cs)
                Dim As Long mw = cs->w, mh = cs->h
                Dim As UByte Ptr m = Allocate(mw * mh)
                Dim As ULong amask = cs->format->Amask
                Dim As Long ashift = cs->format->Ashift
                For yy As Long = 0 To mh - 1
                    Dim As ULong Ptr row = CPtr(ULong Ptr, CPtr(UByte Ptr, cs->pixels) + yy * cs->pitch)
                    For xx As Long = 0 To mw - 1
                        m[yy * mw + xx] = (row[xx] And amask) Shr ashift
                    Next
                Next
                SDL_UnlockSurface(cs)
                gRC(slot).mask = m: gRC(slot).mw = mw: gRC(slot).mh = mh
                gRCBytes += mw * mh
                If cs <> sf Then SDL_FreeSurface(cs)
            End If
            SDL_FreeSurface(sf)
        End If
    End If
    Return slot
End Function

Private Function MaxAscent(ByVal face As Long, ByVal size As Long) As Long
    Dim As Long a = 0
    For f As Long = 0 To FONT_FILES - 1
        If (face = FACE_BOLD) <> (f = FONT_LATIN_B OrElse f = FONT_HEB_B) AndAlso f <> FONT_FALLBACK Then Continue For
        Dim As TTF_Font Ptr p = GetFont(f, size)
        If p AndAlso TTF_FontAscent(p) > a Then a = TTF_FontAscent(p)
    Next
    Return a
End Function

Function Txt_LineHeight(ByVal face As Long, ByVal size As Long) As Long
    Static As Long cacheH(0 To 1, 0 To MAX_PX)
    size = ClampPx(size)
    face = IIf(face = FACE_BOLD, 1, 0)
    If cacheH(face, size) = 0 Then
        Dim As Long h = 0
        Dim As Long fs(0 To 1) = {IIf(face, FONT_LATIN_B, FONT_LATIN), IIf(face, FONT_HEB_B, FONT_HEB)}
        For k As Long = 0 To 1
            Dim As TTF_Font Ptr p = GetFont(fs(k), size)
            If p AndAlso TTF_FontLineSkip(p) > h Then h = TTF_FontLineSkip(p)
        Next
        If h = 0 Then h = size + size \ 3
        cacheH(face, size) = h
    End If
    Return cacheH(face, size)
End Function

' ---------------- line layout ----------------

Type VRun
    s As Long          ' logical start / end (exclusive) in cps()
    e As Long
    font As Long
    rtl As Long
    w As Long
End Type

' Visual runs (left to right) of cps(ls .. le-1); levels from Bidi_Levels over the paragraph.
Private Function LayoutLine(cps() As Long, lev() As Long, ByVal ls As Long, ByVal le As Long, ByVal baseLevel As Long, ByVal face As Long, ByVal size As Long, runs() As VRun) As Long
    Dim As Long n = le - ls
    If n <= 0 Then Return 0
    Dim As Long fonts(Any)
    ReDim fonts(0 To UBound(cps))
    ChooseFonts(cps(), ls, le, face, size, fonts())
    Dim As Long ord(Any)
    Bidi_ReorderLine(cps(), lev(), ls, n, baseLevel, ord())
    ReDim runs(0 To n - 1)
    Dim As Long nr = 0, k = 0
    While k < n
        Dim As Long i0 = ord(k)
        Dim As Long rtl = lev(i0) And 1
        Dim As Long stp = IIf(rtl, -1, 1)
        Dim As Long k2 = k + 1
        While k2 < n
            Dim As Long ii = ord(k2)
            If ii <> ord(k2 - 1) + stp OrElse fonts(ii) <> fonts(i0) OrElse lev(ii) <> lev(i0) Then Exit While
            k2 += 1
        Wend
        Dim As Long a = ord(k), b = ord(k2 - 1)
        If a > b Then Swap a, b
        runs(nr).s = a: runs(nr).e = b + 1
        runs(nr).font = fonts(i0): runs(nr).rtl = rtl
        Dim As String t = RunText(cps(), a, b + 1)
        runs(nr).w = gRC(RunSlot(fonts(i0), size, rtl, t, 0)).w
        nr += 1
        k = k2
    Wend
    Return nr
End Function

Private Function RunsWidth(runs() As VRun, ByVal nr As Long) As Long
    Dim As Long w = 0
    For i As Long = 0 To nr - 1: w += runs(i).w: Next
    Return w
End Function

Private Sub DrawRuns(ByRef cv As Canvas, ByVal x As Long, ByVal y As Long, cps() As Long, runs() As VRun, ByVal nr As Long, ByVal face As Long, ByVal size As Long, ByVal col As ULong)
    Dim As Long ascM = MaxAscent(face, size)
    For i As Long = 0 To nr - 1
        Dim As String t = RunText(cps(), runs(i).s, runs(i).e)
        If Len(t) Then
            Dim As Long slot = RunSlot(runs(i).font, size, runs(i).rtl, t, 1)
            Dim As TTF_Font Ptr f = GetFont(runs(i).font, size)
            Dim As Long fa = IIf(f, TTF_FontAscent(f), ascM)
            If gRC(slot).mask Then Cv_BlitMask(cv, x, y + ascM - fa, gRC(slot).mask, gRC(slot).mw, gRC(slot).mh, col)
        End If
        x += runs(i).w
    Next
End Sub

Private Function ParaLevels(cps() As Long, ByVal n As Long, ByVal dir_ As Long, lev() As Long) As Long
    Return Bidi_Levels(cps(), n, IIf(dir_ = DIR_AUTO, -1, IIf(dir_ = DIR_RTL, 1, 0)), lev())
End Function

Function Txt_Width(ByRef s As String, ByVal face As Long, ByVal size As Long, ByVal dir_ As Long = DIR_AUTO) As Long
    If gReady = 0 OrElse Len(s) = 0 Then Return 0
    Dim As Long cps(Any), lev(Any)
    Dim As Long n = Utf8_Decode(s, cps())
    Dim As Long bl = ParaLevels(cps(), n, dir_, lev())
    Dim As VRun runs(Any)
    Dim As Long nr = LayoutLine(cps(), lev(), 0, n, bl, face, size, runs())
    Return RunsWidth(runs(), nr)
End Function

Sub Txt_Draw(ByRef cv As Canvas, ByVal x As Long, ByVal y As Long, ByRef s As String, ByVal face As Long, ByVal size As Long, ByVal col As ULong, ByVal dir_ As Long)
    If gReady = 0 OrElse Len(s) = 0 Then Exit Sub
    Dim As Long cps(Any), lev(Any)
    Dim As Long n = Utf8_Decode(s, cps())
    Dim As Long bl = ParaLevels(cps(), n, dir_, lev())
    Dim As VRun runs(Any)
    Dim As Long nr = LayoutLine(cps(), lev(), 0, n, bl, face, size, runs())
    DrawRuns(cv, x, y, cps(), runs(), nr, face, size, col)
End Sub

Function Txt_FitSize(ByRef s As String, ByVal face As Long, ByVal size As Long, ByVal maxW As Long, ByVal minSize As Long, ByVal dir_ As Long = DIR_AUTO) As Long
    Dim As Long sz = size
    While sz > minSize AndAlso Txt_Width(s, face, sz, dir_) > maxW
        sz -= 1
    Wend
    Return sz
End Function

Function Txt_Fit(ByRef s As String, ByVal face As Long, ByVal size As Long, ByVal maxW As Long, ByVal dir_ As Long = DIR_AUTO) As String
    If Txt_Width(s, face, size, dir_) <= maxW Then Return s
    Dim As Long cps(Any)
    Dim As Long n = Utf8_Decode(s, cps())
    Dim As String ell = Utf8_Encode(&h2026)
    For k As Long = n - 1 To 1 Step -1
        Dim As String t
        For i As Long = 0 To k - 1: t &= Utf8_Encode(cps(i)): Next
        t = RTrim(t) & ell
        If Txt_Width(t, face, size, dir_) <= maxW Then Return t
    Next
    Return ell
End Function

Private Function AlignX(ByVal x As Long, ByVal w As Long, ByVal lw As Long, ByVal align As Long, ByVal baseLevel As Long) As Long
    Select Case align
    Case ALIGN_CENTER: Return x + (w - lw) \ 2
    Case ALIGN_LEFT: Return x
    Case ALIGN_RIGHT: Return x + w - lw
    Case ALIGN_END: Return IIf(baseLevel And 1, x, x + w - lw)
    Case Else: Return IIf(baseLevel And 1, x + w - lw, x)
    End Select
End Function

Sub Txt_DrawLine(ByRef cv As Canvas, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByRef s As String, ByVal face As Long, ByVal size As Long, ByVal col As ULong, ByVal align As Long, ByVal dir_ As Long)
    If gReady = 0 OrElse Len(s) = 0 Then Exit Sub
    Dim As String t = Txt_Fit(s, face, size, w, dir_)
    Dim As Long cps(Any), lev(Any)
    Dim As Long n = Utf8_Decode(t, cps())
    Dim As Long bl = ParaLevels(cps(), n, dir_, lev())
    Dim As VRun runs(Any)
    Dim As Long nr = LayoutLine(cps(), lev(), 0, n, bl, face, size, runs())
    DrawRuns(cv, AlignX(x, w, RunsWidth(runs(), nr), align, bl), y, cps(), runs(), nr, face, size, col)
End Sub

' width of the logical span [s, e) of a paragraph (approximation used for line breaking)
Private Function SpanWidth(cps() As Long, lev() As Long, ByVal s As Long, ByVal e As Long, ByVal bl As Long, ByVal face As Long, ByVal size As Long) As Long
    Dim As VRun runs(Any)
    Dim As Long nr = LayoutLine(cps(), lev(), s, e, bl, face, size, runs())
    Return RunsWidth(runs(), nr)
End Function

Private Function IsSp(ByVal cp As Long) As Boolean
    Return cp = 32 OrElse cp = 9 OrElse cp = &hA0
End Function

Function Txt_Wrap(ByRef cv As Canvas, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByRef s As String, ByVal face As Long, ByVal size As Long, ByVal col As ULong, ByVal align As Long, ByVal dir_ As Long, ByVal doDraw As Long = 1) As Long
    If gReady = 0 Then Return 0
    Dim As Long lh = Txt_LineHeight(face, size)
    Dim As Long yy = y
    Dim As String rest = s
    Dim As Long p
    Do
        p = InStr(rest, !"\n")
        Dim As String para = IIf(p > 0, Left(rest, p - 1), rest)
        rest = IIf(p > 0, Mid(rest, p + 1), "")
        Dim As Long cps(Any), lev(Any)
        Dim As Long n = Utf8_Decode(para, cps())
        If n = 0 Then
            yy += lh \ 2
        Else
            Dim As Long bl = ParaLevels(cps(), n, dir_, lev())
            Dim As Long ls = 0
            While ls < n
                ' greedy: extend word by word while it fits
                Dim As Long le = ls, best = -1
                While le < n
                    Dim As Long we = le
                    While we < n AndAlso IsSp(cps(we)): we += 1: Wend
                    While we < n AndAlso Not IsSp(cps(we)): we += 1: Wend
                    If SpanWidth(cps(), lev(), ls, we, bl, face, size) <= w OrElse best < 0 Then
                        If SpanWidth(cps(), lev(), ls, we, bl, face, size) > w Then
                            ' a single word longer than the line: cut it by characters
                            Dim As Long ce = ls + 1
                            While ce < we AndAlso SpanWidth(cps(), lev(), ls, ce + 1, bl, face, size) <= w: ce += 1: Wend
                            best = ce
                            Exit While
                        End If
                        best = we
                        le = we
                    Else
                        Exit While
                    End If
                Wend
                If best <= ls Then best = ls + 1
                ' trim spaces at both ends of the line
                Dim As Long a = ls, b = best
                While b > a AndAlso IsSp(cps(b - 1)): b -= 1: Wend
                While a < b AndAlso IsSp(cps(a)): a += 1: Wend
                If doDraw AndAlso b > a Then
                    Dim As VRun runs(Any)
                    Dim As Long nr = LayoutLine(cps(), lev(), a, b, bl, face, size, runs())
                    DrawRuns(cv, AlignX(x, w, RunsWidth(runs(), nr), align, bl), yy, cps(), runs(), nr, face, size, col)
                End If
                yy += lh
                ls = best
                While ls < n AndAlso IsSp(cps(ls)): ls += 1: Wend
            Wend
        End If
    Loop While p > 0
    Return yy - y
End Function

Function Txt_WrapHeight(ByRef s As String, ByVal w As Long, ByVal face As Long, ByVal size As Long, ByVal dir_ As Long) As Long
    Dim As Canvas dummy
    Return Txt_Wrap(dummy, 0, 0, w, s, face, size, 0, ALIGN_START, dir_, 0)
End Function

Function Txt_DebugRuns(ByRef s As String, ByVal dir_ As Long) As String
    Dim As Long cps(Any), lev(Any)
    Dim As Long n = Utf8_Decode(s, cps())
    Dim As Long bl = ParaLevels(cps(), n, dir_, lev())
    Dim As VRun runs(Any)
    Dim As Long nr = LayoutLine(cps(), lev(), 0, n, bl, FACE_REGULAR, 20, runs())
    Dim As String r
    For i As Long = 0 To nr - 1
        If i > 0 Then r &= "|"
        r &= IIf(runs(i).rtl, "R:", "L:") & RunText(cps(), runs(i).s, runs(i).e)
    Next
    Return r
End Function
