' bidi.bas - Unicode Bidirectional Algorithm (subset documented in bidi.bi)
#include once "bidi.bi"

Function Utf8_Decode(ByRef s As String, cps() As Long) As Long
    Dim As Long n = 0, i = 0, L = Len(s)
    ReDim cps(0 To IIf(L > 0, L - 1, 0))
    While i < L
        Dim As Long c = s[i], cp, extra
        If c < &h80 Then
            cp = c: extra = 0
        ElseIf (c And &hE0) = &hC0 Then
            cp = c And &h1F: extra = 1
        ElseIf (c And &hF0) = &hE0 Then
            cp = c And &h0F: extra = 2
        ElseIf (c And &hF8) = &hF0 Then
            cp = c And &h07: extra = 3
        Else
            cp = &hFFFD: extra = 0
        End If
        i += 1
        For k As Long = 1 To extra
            If i < L AndAlso (s[i] And &hC0) = &h80 Then
                cp = (cp Shl 6) Or (s[i] And &h3F)
                i += 1
            Else
                cp = &hFFFD
                Exit For
            End If
        Next
        cps(n) = cp
        n += 1
    Wend
    Return n
End Function

Function Utf8_Encode(ByVal cp As Long) As String
    If cp < &h80 Then Return Chr(cp)
    If cp < &h800 Then Return Chr(&hC0 Or (cp Shr 6), &h80 Or (cp And &h3F))
    If cp < &h10000 Then Return Chr(&hE0 Or (cp Shr 12), &h80 Or ((cp Shr 6) And &h3F), &h80 Or (cp And &h3F))
    Return Chr(&hF0 Or (cp Shr 18), &h80 Or ((cp Shr 12) And &h3F), &h80 Or ((cp Shr 6) And &h3F), &h80 Or (cp And &h3F))
End Function

Function Utf8_Len(ByRef s As String) As Long
    Dim As Long n = 0
    For i As Long = 0 To Len(s) - 1
        If (s[i] And &hC0) <> &h80 Then n += 1
    Next
    Return n
End Function

' Bidi_Class: the ranges needed for Hebrew, Latin, digits, punctuation, symbols,
' with Arabic ranges included for correctness of AL/AN handling.
Function Bidi_Class(ByVal cp As Long) As Long
    If cp < 128 Then
        Select Case cp
        Case 9, 11, 31: Return BC_S
        Case 10, 13, 28 To 30: Return BC_B
        Case 12, 32: Return BC_WS
        Case 0 To 8, 14 To 27, 127: Return BC_BN
        Case 48 To 57: Return BC_EN
        Case 43, 45: Return BC_ES
        Case 35 To 37: Return BC_ET
        Case 44, 46, 47, 58: Return BC_CS
        Case 65 To 90, 97 To 122: Return BC_L
        Case Else: Return BC_ON
        End Select
    End If
    Select Case cp
    Case &h85: Return BC_B
    Case &h80 To &h84, &h86 To &h9F, &hAD: Return BC_BN
    Case &hA0: Return BC_CS
    Case &hA2 To &hA5, &hB0, &hB1: Return BC_ET
    Case &hB2, &hB3, &hB9: Return BC_EN
    Case &hAA, &hB5, &hBA: Return BC_L
    Case &hA1, &hA6 To &hA9, &hAB, &hAC, &hAE, &hAF, &hB4, &hB6 To &hB8, &hBB To &hBF, &hD7, &hF7: Return BC_ON
    Case &hC0 To &h2B8: Return BC_L
    Case &h2B9 To &h2BA, &h2C2 To &h2CF, &h2D2 To &h2DF, &h2E5 To &h2ED, &h2EF To &h2FF: Return BC_ON
    Case &h300 To &h36F, &h483 To &h489: Return BC_NSM
    Case &h3F6, &h58A, &h58D, &h58E: Return BC_ON
    Case &h58F: Return BC_ET
    Case &h374, &h375, &h37E, &h384, &h385, &h387: Return BC_ON
    ' Hebrew
    Case &h591 To &h5BD, &h5BF, &h5C1, &h5C2, &h5C4, &h5C5, &h5C7: Return BC_NSM
    Case &h590 To &h5FF: Return BC_R
    ' Arabic
    Case &h600 To &h605, &h660 To &h669, &h66B, &h66C, &h6DD, &h8E2: Return BC_AN
    Case &h60C: Return BC_CS
    Case &h606, &h607, &h60E, &h60F, &h6DE, &h6E9: Return BC_ON
    Case &h609, &h60A, &h66A: Return BC_ET
    Case &h610 To &h61A, &h64B To &h65F, &h670, &h6D6 To &h6DC, &h6DF To &h6E4, &h6E7, &h6E8, &h6EA To &h6ED: Return BC_NSM
    Case &h6F0 To &h6F9: Return BC_EN
    Case &h61C: Return BC_AL
    Case &h600 To &h6FF, &h700 To &h74F, &h750 To &h77F, &h8A0 To &h8FF: Return BC_AL
    Case &h7C0 To &h85F: Return BC_R
    Case &h1680: Return BC_WS
    Case &h2000 To &h200A: Return BC_WS
    Case &h200B To &h200D: Return BC_BN
    Case CP_LRM: Return BC_L
    Case CP_RLM: Return BC_R
    Case &h2028: Return BC_WS
    Case &h2029: Return BC_B
    Case &h202A To &h202E: Return BC_BN       ' explicit embeddings: not supported, ignored
    Case &h202F: Return BC_CS
    Case &h2030 To &h2034: Return BC_ET
    Case &h2044: Return BC_CS
    Case &h205F: Return BC_WS
    Case &h2060 To &h2064, &h206A To &h206F: Return BC_BN
    Case CP_LRI: Return BC_LRI
    Case CP_RLI: Return BC_RLI
    Case CP_FSI: Return BC_FSI
    Case CP_PDI: Return BC_PDI
    Case &h2070, &h2074 To &h2079, &h2080 To &h2089: Return BC_EN
    Case &h207A, &h207B, &h208A, &h208B: Return BC_ES
    Case &h207C To &h207E, &h208C To &h208E: Return BC_ON
    Case &h20A0 To &h20CF: Return BC_ET
    Case &h20D0 To &h20F0: Return BC_NSM
    Case &h2010 To &h2027, &h2035 To &h2043, &h2045 To &h205E: Return BC_ON
    Case &h2100 To &h2101, &h2103 To &h2106, &h2108, &h2109, &h2114, &h2116 To &h2118, &h211E To &h2123, &h2125, &h2127, &h2129, &h213A, &h213B, &h2140 To &h2144, &h214A To &h214D, &h2150 To &h215F: Return BC_ON
    Case &h212E: Return BC_ET
    Case &h2189 To &h218B: Return BC_ON
    Case &h2212: Return BC_ES
    Case &h2213: Return BC_ET
    Case &h2190 To &h2335, &h237B To &h2394, &h2396 To &h2429, &h2440 To &h244A, &h2460 To &h2487, &h24EA To &h26AB, &h26AD To &h27FF, &h2900 To &h2B73, &h2B76 To &h2BFF: Return BC_ON
    Case &h2488 To &h249B: Return BC_EN
    Case &h2E00 To &h2E7F, &h3001 To &h3004, &h3008 To &h3020: Return BC_ON
    Case &h3000: Return BC_WS
    Case &hFB1D: Return BC_R
    Case &hFB1E: Return BC_NSM
    Case &hFB1F To &hFB28, &hFB2A To &hFB4F: Return BC_R
    Case &hFB29: Return BC_ES
    Case &hFB50 To &hFDFF, &hFE70 To &hFEFE: Return BC_AL
    Case &hFE00 To &hFE0F, &hFE20 To &hFE2F: Return BC_NSM
    Case &hFE50, &hFE52, &hFE55: Return BC_CS
    Case &hFEFF: Return BC_BN
    Case &hFF0C, &hFF0E, &hFF0F, &hFF1A: Return BC_CS
    Case &hFF10 To &hFF19: Return BC_EN
    Case &hFF0B, &hFF0D: Return BC_ES
    Case &hFF03 To &hFF05: Return BC_ET
    Case &hFFF9 To &hFFFD: Return BC_ON
    Case &h1F000 To &h1FAFF: Return BC_ON
    End Select
    Return BC_L
End Function

Function Bidi_Mirror(ByVal cp As Long) As Long
    Select Case cp
    Case 40: Return 41
    Case 41: Return 40
    Case 60: Return 62
    Case 62: Return 60
    Case 91: Return 93
    Case 93: Return 91
    Case 123: Return 125
    Case 125: Return 123
    Case &hAB: Return &hBB
    Case &hBB: Return &hAB
    Case &h2039: Return &h203A
    Case &h203A: Return &h2039
    Case &h2264: Return &h2265
    Case &h2265: Return &h2264
    Case &h2045: Return &h2046
    Case &h2046: Return &h2045
    Case &h3008: Return &h3009
    Case &h3009: Return &h3008
    Case &h2329: Return &h232A
    Case &h232A: Return &h2329
    End Select
    Return cp
End Function

Private Function IsIsoInit(ByVal t As Long) As Boolean
    Return t = BC_LRI OrElse t = BC_RLI OrElse t = BC_FSI
End Function

' First strong direction in [s, e): 0 = L, 1 = R/AL, -1 = none (isolates skipped)
Function Bidi_FirstStrong(cps() As Long, ByVal s As Long, ByVal e As Long) As Long
    Dim As Long depth = 0
    For i As Long = s To e - 1
        Dim As Long t = Bidi_Class(cps(i))
        If IsIsoInit(t) Then
            depth += 1
        ElseIf t = BC_PDI Then
            If depth > 0 Then depth -= 1
        ElseIf depth = 0 Then
            If t = BC_L Then Return 0
            If t = BC_R OrElse t = BC_AL Then Return 1
        End If
    Next
    Return -1
End Function

' --- working state for one Bidi_Levels call
Dim Shared As Long bdCls(Any), bdT(Any), bdLev(Any), bdMatch(Any), bdCp(Any)

Private Function StrongDir(ByVal t As Long) As Long
    ' for N0/N1: L -> 0; R, EN, AN -> 1; else -1
    If t = BC_L Then Return 0
    If t = BC_R OrElse t = BC_EN OrElse t = BC_AN OrElse t = BC_AL Then Return 1
    Return -1
End Function

Private Function IsNI(ByVal t As Long) As Boolean
    Return t = BC_B OrElse t = BC_S OrElse t = BC_WS OrElse t = BC_ON OrElse t = BC_LRI OrElse t = BC_RLI OrElse t = BC_FSI OrElse t = BC_PDI
End Function

Private Function OpenBracketFor(ByVal cp As Long) As Long
    ' returns the matching closing bracket for an opening one, else 0
    Select Case cp
    Case 40: Return 41
    Case 91: Return 93
    Case 123: Return 125
    Case &h2045: Return &h2046
    Case &h3008, &h2329: Return &h3009     ' U+2329 is canonically equivalent to U+3008
    End Select
    Return 0
End Function

Private Function IsCloseBracket(ByVal cp As Long) As Boolean
    Return cp = 41 OrElse cp = 93 OrElse cp = 125 OrElse cp = &h2046 OrElse cp = &h3009 OrElse cp = &h232A
End Function

Private Sub ResolveSeq(ByVal s As Long, ByVal e As Long, ByVal level As Long)
    ' gather the isolating run sequence for [s, e) at this level
    Dim As Long idx(Any)
    Dim As Long cnt = 0
    ReDim idx(0 To e - s + 1)
    Dim As Long i = s
    While i < e
        Dim As Long c = bdCls(i)
        If c = BC_BN Then
            bdLev(i) = -1        ' filled in afterwards
            i += 1
            Continue While
        End If
        idx(cnt) = i: cnt += 1
        bdLev(i) = level
        If IsIsoInit(c) Then
            Dim As Long m = bdMatch(i)
            Dim As Long ce = IIf(m >= 0 AndAlso m < e, m, e)
            Dim As Long inner
            Dim As Long rtl
            If c = BC_RLI Then
                rtl = 1
            ElseIf c = BC_LRI Then
                rtl = 0
            Else
                rtl = IIf(Bidi_FirstStrong(bdCp(), i + 1, ce) = 1, 1, 0)
            End If
            If rtl Then inner = (level + 1) Or 1 Else inner = (level + 2) And Not 1
            If inner <= 125 Then
                ResolveSeq(i + 1, ce, inner)
            Else
                ResolveSeq(i + 1, ce, level)
            End If
            If m >= 0 AndAlso m < e Then
                idx(cnt) = m: cnt += 1
                bdLev(m) = level
                i = m + 1
            Else
                i = e
            End If
            Continue While
        End If
        i += 1
    Wend
    If cnt = 0 Then Exit Sub
    Dim As Long sos = IIf(level And 1, BC_R, BC_L)
    Dim As Long t(0 To cnt - 1)
    For k As Long = 0 To cnt - 1
        t(k) = bdCls(idx(k))
    Next
    ' W1
    For k As Long = 0 To cnt - 1
        If t(k) = BC_NSM Then
            If k = 0 Then
                t(k) = sos
            ElseIf IsIsoInit(t(k - 1)) OrElse t(k - 1) = BC_PDI Then
                t(k) = BC_ON
            Else
                t(k) = t(k - 1)
            End If
        End If
    Next
    ' W2
    Dim As Long lastStrong = sos
    For k As Long = 0 To cnt - 1
        If t(k) = BC_L OrElse t(k) = BC_R OrElse t(k) = BC_AL Then lastStrong = t(k)
        If t(k) = BC_EN AndAlso lastStrong = BC_AL Then t(k) = BC_AN
    Next
    ' W3
    For k As Long = 0 To cnt - 1
        If t(k) = BC_AL Then t(k) = BC_R
    Next
    ' W4
    For k As Long = 1 To cnt - 2
        If t(k) = BC_ES AndAlso t(k - 1) = BC_EN AndAlso t(k + 1) = BC_EN Then
            t(k) = BC_EN
        ElseIf t(k) = BC_CS AndAlso t(k - 1) = t(k + 1) AndAlso (t(k - 1) = BC_EN OrElse t(k - 1) = BC_AN) Then
            t(k) = t(k - 1)
        End If
    Next
    ' W5
    Dim As Long k = 0
    While k < cnt
        If t(k) = BC_ET Then
            Dim As Long r0 = k
            While k < cnt AndAlso t(k) = BC_ET: k += 1: Wend
            Dim As Long adj = 0
            If r0 > 0 AndAlso t(r0 - 1) = BC_EN Then adj = 1
            If k < cnt AndAlso t(k) = BC_EN Then adj = 1
            If adj Then
                For q As Long = r0 To k - 1: t(q) = BC_EN: Next
            End If
        Else
            k += 1
        End If
    Wend
    ' W6
    For k = 0 To cnt - 1
        If t(k) = BC_ES OrElse t(k) = BC_ET OrElse t(k) = BC_CS Then t(k) = BC_ON
    Next
    ' W7
    lastStrong = sos
    For k = 0 To cnt - 1
        If t(k) = BC_L OrElse t(k) = BC_R Then lastStrong = t(k)
        If t(k) = BC_EN AndAlso lastStrong = BC_L Then t(k) = BC_L
    Next
    ' N0: paired brackets
    Dim As Long embDir = IIf(level And 1, 1, 0)
    Dim As Long stkCp(0 To 62), stkPos(0 To 62), sp = 0
    Dim As Long pairO(Any), pairC(Any), np = 0
    For k = 0 To cnt - 1
        If t(k) <> BC_ON Then Continue For
        Dim As Long cp = bdCp(idx(k))
        If cp = &h232A Then cp = &h3009
        Dim As Long cl = OpenBracketFor(cp)
        If cl <> 0 Then
            If sp >= 63 Then Exit For
            stkCp(sp) = cl: stkPos(sp) = k: sp += 1
        ElseIf IsCloseBracket(cp) Then
            For q As Long = sp - 1 To 0 Step -1
                If stkCp(q) = cp Then
                    ReDim Preserve pairO(0 To np): ReDim Preserve pairC(0 To np)
                    pairO(np) = stkPos(q): pairC(np) = k: np += 1
                    sp = q
                    Exit For
                End If
            Next
        End If
    Next
    ' sort pairs by opening position
    For a As Long = 1 To np - 1
        Dim As Long b = a
        While b > 0 AndAlso pairO(b - 1) > pairO(b)
            Swap pairO(b - 1), pairO(b): Swap pairC(b - 1), pairC(b)
            b -= 1
        Wend
    Next
    For pidx As Long = 0 To np - 1
        Dim As Long o = pairO(pidx), cpos = pairC(pidx)
        Dim As Long foundE = 0, foundO = 0
        For q As Long = o + 1 To cpos - 1
            Dim As Long d = StrongDir(t(q))
            If d = embDir Then foundE = 1
            If d >= 0 AndAlso d <> embDir Then foundO = 1
        Next
        Dim As Long newDir = -1
        If foundE Then
            newDir = embDir
        ElseIf foundO Then
            Dim As Long ctx = IIf(sos = BC_R, 1, 0)
            For q As Long = o - 1 To 0 Step -1
                Dim As Long d = StrongDir(t(q))
                If d >= 0 Then ctx = d: Exit For
            Next
            newDir = IIf(ctx <> embDir, 1 - embDir, embDir)
        End If
        If newDir >= 0 Then
            Dim As Long nt = IIf(newDir = 1, BC_R, BC_L)
            t(o) = nt: t(cpos) = nt
            ' NSMs after a bracket take its new type
            For q As Long = o + 1 To cnt - 1
                If bdCls(idx(q)) = BC_NSM Then t(q) = nt Else Exit For
            Next
            For q As Long = cpos + 1 To cnt - 1
                If bdCls(idx(q)) = BC_NSM Then t(q) = nt Else Exit For
            Next
        End If
    Next
    ' N1 / N2
    k = 0
    While k < cnt
        If IsNI(t(k)) Then
            Dim As Long r0 = k
            While k < cnt AndAlso IsNI(t(k)): k += 1: Wend
            Dim As Long before = IIf(r0 > 0, StrongDir(t(r0 - 1)), IIf(sos = BC_R, 1, 0))
            Dim As Long after = IIf(k < cnt, StrongDir(t(k)), embDir)
            Dim As Long nd = IIf(before = after AndAlso before >= 0, before, embDir)
            For q As Long = r0 To k - 1
                t(q) = IIf(nd = 1, BC_R, BC_L)
            Next
        Else
            k += 1
        End If
    Wend
    ' I1 / I2
    For k = 0 To cnt - 1
        Dim As Long lv = level
        If (level And 1) = 0 Then
            If t(k) = BC_R Then
                lv = level + 1
            ElseIf t(k) = BC_AN OrElse t(k) = BC_EN Then
                lv = level + 2
            End If
        Else
            If t(k) = BC_L OrElse t(k) = BC_EN OrElse t(k) = BC_AN Then lv = level + 1
        End If
        ' isolate initiators and PDIs keep the sequence level for reordering (X5a/X6a),
        ' but take the resolved neutral direction like other neutrals
        bdLev(idx(k)) = lv
    Next
End Sub

' Resolves embedding levels. baseLevel: 0 = LTR, 1 = RTL, -1 = from first strong character.
' Returns the paragraph level used.
Function Bidi_Levels(cps() As Long, ByVal n As Long, ByVal baseLevel As Long, levels() As Long) As Long
    If baseLevel < 0 Then
        baseLevel = IIf(Bidi_FirstStrong(cps(), 0, n) = 1, 1, 0)
    End If
    ReDim levels(0 To IIf(n > 0, n - 1, 0))
    If n <= 0 Then Return baseLevel
    ReDim bdCls(0 To n - 1)
    ReDim bdLev(0 To n - 1)
    ReDim bdMatch(0 To n - 1)
    ReDim bdCp(0 To n - 1)
    For i As Long = 0 To n - 1
        bdCp(i) = cps(i)
        bdCls(i) = Bidi_Class(cps(i))
        bdMatch(i) = -1
    Next
    ' match isolate initiators with PDIs (BD9)
    Dim As Long stk(0 To 127), sp = 0
    For i As Long = 0 To n - 1
        If IsIsoInit(bdCls(i)) Then
            If sp < 128 Then stk(sp) = i: sp += 1
        ElseIf bdCls(i) = BC_PDI Then
            If sp > 0 Then
                sp -= 1
                bdMatch(stk(sp)) = i
            Else
                bdCls(i) = BC_ON     ' unmatched PDI behaves as a neutral
            End If
        ElseIf bdCls(i) = BC_B Then
            sp = 0
        End If
    Next
    ResolveSeq(0, n, baseLevel)
    ' BN characters take the level of the preceding character
    Dim As Long prev = baseLevel
    For i As Long = 0 To n - 1
        If bdLev(i) < 0 Then bdLev(i) = prev
        prev = bdLev(i)
        levels(i) = bdLev(i)
    Next
    Return baseLevel
End Function

' L1 + L2 for one line: order(k) receives the logical index of the k-th glyph from the left.
Sub Bidi_ReorderLine(cps() As Long, levels() As Long, ByVal start As Long, ByVal count As Long, ByVal baseLevel As Long, order() As Long)
    ReDim order(0 To IIf(count > 0, count - 1, 0))
    If count <= 0 Then Exit Sub
    Dim As Long lv(0 To count - 1)
    For k As Long = 0 To count - 1
        lv(k) = levels(start + k)
    Next
    ' L1: segment/paragraph separators, and whitespace (incl. isolate controls) before them and at line end
    Dim As Long trailing = 1
    For k As Long = count - 1 To 0 Step -1
        Dim As Long c = Bidi_Class(cps(start + k))
        If c = BC_S OrElse c = BC_B Then
            lv(k) = baseLevel
            trailing = 1
        ElseIf trailing <> 0 AndAlso (c = BC_WS OrElse c = BC_BN OrElse c = BC_LRI OrElse c = BC_RLI OrElse c = BC_FSI OrElse c = BC_PDI) Then
            lv(k) = baseLevel
        Else
            trailing = 0
        End If
    Next
    Dim As Long hi = 0, loOdd = 127
    For k As Long = 0 To count - 1
        order(k) = start + k
        If lv(k) > hi Then hi = lv(k)
        If (lv(k) And 1) AndAlso lv(k) < loOdd Then loOdd = lv(k)
    Next
    ' L2: reverse runs from the highest level down to the lowest odd level
    For lvl As Long = hi To loOdd Step -1
        Dim As Long k = 0
        While k < count
            If lv(k) >= lvl Then
                Dim As Long r0 = k
                While k < count AndAlso lv(k) >= lvl: k += 1: Wend
                Dim As Long a = r0, b = k - 1
                While a < b
                    Swap order(a), order(b)
                    Swap lv(a), lv(b)
                    a += 1: b -= 1
                Wend
            Else
                k += 1
            End If
        Wend
    Next
End Sub

' Visual-order string of a single line (mirroring applied, controls removed) - used by tests.
Function Bidi_VisualString(ByRef s As String, ByVal baseLevel As Long) As String
    Dim As Long cps(Any), lev(Any), ord(Any)
    Dim As Long n = Utf8_Decode(s, cps())
    Dim As Long bl = Bidi_Levels(cps(), n, baseLevel, lev())
    Bidi_ReorderLine(cps(), lev(), 0, n, bl, ord())
    Dim As String r
    For k As Long = 0 To n - 1
        Dim As Long i = ord(k)
        Dim As Long c = Bidi_Class(cps(i))
        If c = BC_BN OrElse IsIsoInit(c) OrElse c = BC_PDI Then Continue For
        Dim As Long cp = cps(i)
        If lev(i) And 1 Then cp = Bidi_Mirror(cp)
        r &= Utf8_Encode(cp)
    Next
    Return r
End Function

' Wraps text in a left-to-right isolate (for notation inside right-to-left text).
Function Bidi_Iso(ByRef s As String) As String
    Return Utf8_Encode(CP_LRI) & s & Utf8_Encode(CP_PDI)
End Function

Function Bidi_HasRTL(ByRef s As String) As Boolean
    Dim As Long cps(Any)
    Dim As Long n = Utf8_Decode(s, cps())
    For i As Long = 0 To n - 1
        Dim As Long c = Bidi_Class(cps(i))
        If c = BC_R OrElse c = BC_AL Then Return True
    Next
    Return False
End Function
